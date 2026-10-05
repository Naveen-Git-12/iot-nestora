// ============================================================
// NESTORA V1 — ESP32-S3 Super Mini wearable firmware
// Sensors: MAX30102 (HR/PPG, bus 1: GPIO8/9 @0x57)
//          MPU6050 (accel/gyro, bus 0: GPIO12/13 @0x68)
// Flow: WEARABLE -> BLE -> Flutter gateway -> FastAPI -> Dashboard
//
// Build (no Arduino IDE needed):
//   ./build.sh        (compile check, no device required)
//   ./upload.sh       (needs /dev/ttyACM0)
// ============================================================
#include <Arduino.h>
#include <Wire.h>
#include "config.h"
#include "models.h"
#include "max30102_sensor.h"
#include "mpu6050_sensor.h"
#include "activity_engine.h"
#include "health_engine.h"
#include "ble_service.h"

TwoWire MPU_BUS = TwoWire(0);
TwoWire MAX_BUS = TwoWire(1);

static Max30102Sensor maxSensor;
static Mpu6050Sensor mpuSensor;
static ActivityEngine activity;
static BleService ble;

static bool mpuOnline = false;
static bool maxOnline = false;

static unsigned long lastMpu = 0;
static unsigned long lastActivity = 0;
static unsigned long lastHr = 0;
static unsigned long lastBle = 0;
static unsigned long lastDiag = 0;

static void i2cScan(TwoWire &bus, const char *label) {
  Serial.printf("[%s] scanning...\n", label);
  for (uint8_t addr = 1; addr < 127; addr++) {
    bus.beginTransmission(addr);
    if (bus.endTransmission() == 0) {
      Serial.printf("[%s] Found 0x%02X\n", label, addr);
    }
  }
}

void setup() {
  Serial.begin(SERIAL_BAUD);
  unsigned long t0 = millis();
  while (!Serial && (millis() - t0) < 2000) {
    // USB-CDC grace period; never block forever on battery.
  }

  Serial.println();
  Serial.println("================================");
  Serial.println("         NESTORA V1");
  Serial.println("================================");
  Serial.println("MCU: ESP32-S3 Super Mini");
  Serial.println();

  MPU_BUS.begin(MPU_SDA, MPU_SCL);
  MAX_BUS.begin(MAX_SDA, MAX_SCL);

  Serial.printf("MPU BUS:\nSDA = GPIO%d\nSCL = GPIO%d\n", MPU_SDA, MPU_SCL);
  i2cScan(MPU_BUS, "MPU BUS");
  mpuOnline = mpuSensor.begin(&MPU_BUS, MPU_ADDRESS);
  Serial.println(mpuOnline ? "MPU6050 ONLINE" : "MPU6050 OFFLINE");

  Serial.printf("MAX BUS:\nSDA = GPIO%d\nSCL = GPIO%d\n", MAX_SDA, MAX_SCL);
  i2cScan(MAX_BUS, "MAX BUS");
  maxOnline = maxSensor.begin(&MAX_BUS, MAX_ADDRESS);
  Serial.println(maxOnline ? "MAX30102 ONLINE" : "MAX30102 OFFLINE");

  ble.begin();
  Serial.println();
  Serial.println("BLE:");
  Serial.println(BLE_DEVICE_NAME);
  Serial.println("READY");
  Serial.println();
}

void loop() {
  unsigned long now = millis();

  // MAX30102: poll every loop (FIFO drain + beat detect). No-op offline.
  maxSensor.update();

  // MPU6050 @ ~40 Hz
  if (now - lastMpu >= MPU_SAMPLE_MS) {
    lastMpu = now;
    mpuSensor.update();
    activity.feed(mpuSensor.magnitude(), now);
  }

  // Activity context log @ 2 Hz (serial only)
  if (now - lastActivity >= ACTIVITY_UPDATE_MS) {
    lastActivity = now;
  }

  // HR snapshot @ 1 Hz (serial only)
  if (now - lastHr >= HEART_RATE_UPDATE_MS) {
    lastHr = now;
  }

  // BLE notify @ 1 Hz
  if (now - lastBle >= BLE_NOTIFY_MS) {
    lastBle = now;

    WearableReading r;
    strncpy(r.device_id, DEVICE_ID, sizeof(r.device_id));
    r.timestamp = now;
    r.heart_rate = maxOnline ? maxSensor.currentBpm() : -1;
    r.heart_rate_avg = maxOnline ? maxSensor.averageBpm() : -1;
    r.spo2 = -1;  // not reliably measurable yet -> null, never faked
    r.steps = activity.steps();
    strncpy(r.activity, activity.activity(), sizeof(r.activity));
    r.activity[sizeof(r.activity) - 1] = '\0';
    r.movement = activity.movement();
    r.rest_seconds = activity.restSeconds();
    r.contact = maxOnline ? maxSensor.hasContact() : false;
    r.signal_quality = maxOnline ? maxSensor.signalQuality() : 0;
    r.fall_candidate = activity.fallCandidate();

    char payload[256];
    if (wearable_to_json(r, payload, sizeof(payload)) > 0) {
      ble.notifyVitals(payload);
    }

    char status[160];
    snprintf(status, sizeof(status),
             "{\"device_id\":\"%s\",\"uptime_s\":%lu,"
             "\"mpu\":%s,\"max\":%s,\"clients\":%d}",
             DEVICE_ID, now / 1000,
             mpuOnline ? "true" : "false",
             maxOnline ? "true" : "false",
             ble.clients());
    ble.setStatus(status);
  }

  // Periodic serial diagnostics @ 5 s
  if (now - lastDiag >= DIAG_PRINT_MS) {
    lastDiag = now;
    char ctx[160];
    HealthEngine::contextMessage(
        maxSensor.currentBpm(), activity.activity(),
        maxSensor.hasContact(), ctx, sizeof(ctx));
    Serial.printf(
        "IR=%lu BPM=%d AVG=%d | mag=%.2f steps=%lu act=%s rest=%lus "
        "qual=%d fall=%d | %s\n",
        (unsigned long)maxSensor.ir(), maxSensor.currentBpm(),
        maxSensor.averageBpm(), mpuSensor.magnitude(), activity.steps(),
        activity.activity(), (unsigned long)activity.restSeconds(),
        maxSensor.signalQuality(),
        activity.fallCandidate() ? 1 : 0, ctx);
  }

  ble.update();
}
