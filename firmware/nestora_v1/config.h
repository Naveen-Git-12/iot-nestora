#pragma once

// ============================================================
// NESTORA V1 — central configuration
// ESP32-S3 Super Mini + MAX30102 + MPU6050
// Two SEPARATE I2C buses. Do NOT combine. Do NOT remap GPIOs.
// ============================================================

// ---- MPU6050 bus (bus 0) ----
// ESP32-S3 GPIO12 -> MPU SDA, GPIO13 -> MPU SCL
#define MPU_SDA 12
#define MPU_SCL 13
#define MPU_ADDRESS 0x68

// ---- MAX30102 bus (bus 1) ----
// ESP32-S3 GPIO8 -> MAX SDA, GPIO9 -> MAX SCL
#define MAX_SDA 8
#define MAX_SCL 9
#define MAX_ADDRESS 0x57

// ---- Misc ----
#define SERIAL_BAUD 115200
#define DEVICE_ID "NESTORA-V1-001"
#define BLE_DEVICE_NAME "Nestora-V1"

// ---- Scheduling (millis, never long delay) ----
#define HEART_RATE_UPDATE_MS 1000
#define ACTIVITY_UPDATE_MS 500
#define BLE_NOTIFY_MS 1000
#define MPU_SAMPLE_MS 25        // ~40 Hz
#define DIAG_PRINT_MS 5000

// ---- Heart-rate validation ----
#define MIN_VALID_BPM 40
#define MAX_VALID_BPM 200
// Consecutive valid beats required before HR is published
// (keeps startup garbage out of averages)
#define MIN_BEATS_TO_LOCK 3
// IR reading above this means skin contact (tune per unit)
#define CONTACT_IR_THRESHOLD 50000UL
// ms without contact before beat history is reset
#define CONTACT_LOSS_RESET_MS 3000

// ---- Steps (prototype) ----
#define STEP_THRESHOLD_G 1.15f
#define STEP_DEBOUNCE_MS 300

// ---- Fall candidate (prototype, NOT a diagnosis) ----
#define FALL_SPIKE_G 2.5f
#define FALL_QUIET_MS 2000

// ---- BLE ----
#define BLE_SERVICE_UUID "7e570001-7e57-4e57-9e57-7e5700000001"
#define BLE_VITALS_CHAR_UUID "7e570002-7e57-4e57-9e57-7e5700000002"
#define BLE_STATUS_CHAR_UUID "7e570003-7e57-4e57-9e57-7e5700000003"
#define BLE_PREFERRED_MTU 247
