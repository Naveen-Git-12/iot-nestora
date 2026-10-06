#include "max30102_sensor.h"
#include "config.h"
#include <MAX30105.h>
#include "spo2_algorithm.h"

static MAX30105 particleSensor;

Max30102Sensor::Max30102Sensor() {}

bool Max30102Sensor::begin(TwoWire *bus, uint8_t address) {
  bus_ = bus;
  // Probe the address first: SparkFun begin() can hang on some
  // wiring faults, so verify ACK explicitly.
  bus_->beginTransmission(address);
  if (bus_->endTransmission() != 0) {
    online_ = false;
    return false;
  }
  if (!particleSensor.begin(*bus_, I2C_SPEED_FAST)) {
    online_ = false;
    return false;
  }
  // PROVEN hardware-test values (do not "tune" blindly):
  particleSensor.setup(
      60,   // LED brightness
      4,    // sampleAverage
      2,    // ledMode: red + IR
      100,  // sampleRate Hz
      411,  // pulseWidth us
      4096  // adcRange
  );
  particleSensor.setPulseAmplitudeRed(0x24);
  particleSensor.setPulseAmplitudeIR(0x24);  // <-- IR emission required
  particleSensor.setPulseAmplitudeGreen(0);
  online_ = true;
  resetBeatState();
  return true;
}

void Max30102Sensor::resetBeatState() {
  currentBpm_ = -1;
  spo2_ = -1;
  avgCount_ = 0;
  avgIdx_ = 0;
  validBlocks_ = 0;
  minBpm_ = -1;
  maxBpm_ = -1;
  beatConsistency_ = 0.0f;
  prevBpm_ = -1;
  bufIdx_ = 0;
  blockIrSum_ = 0;
  for (int i = 0; i < AVG_N; i++) avgBuf_[i] = 0;
}

void Max30102Sensor::update() {
  if (!online_) return;

  // Drain exactly one FIFO sample per call (non-blocking; MPU + BLE
  // stay live while the 100-sample block accumulates).
  if (!particleSensor.available()) {
    particleSensor.check();
    if (!particleSensor.available()) return;
  }
  lastRed_ = particleSensor.getRed();
  lastIr_ = particleSensor.getIR();
  particleSensor.nextSample();

  irBuf_[bufIdx_] = lastIr_;
  redBuf_[bufIdx_] = lastRed_;
  blockIrSum_ += lastIr_;
  bufIdx_++;

  if (bufIdx_ >= BLOCK_N) {
    bufIdx_ = 0;
    runMaximBlock();
  }
}

void Max30102Sensor::runMaximBlock() {
  uint32_t avgIr = (uint32_t)(blockIrSum_ / BLOCK_N);
  blockIrSum_ = 0;
  unsigned long now = millis();

  // No skin contact: invalidate, don't freeze old values.
  if (avgIr < contactThreshold) {
    contact_ = false;
    if (contactLostAt_ == 0) contactLostAt_ = now;
    if (now - contactLostAt_ > CONTACT_LOSS_RESET_MS) resetBeatState();
    return;
  }
  if (!contact_) resetBeatState();  // fresh touch: start clean
  contact_ = true;
  contactLostAt_ = 0;

  int32_t spo2 = 0, hr = 0;
  int8_t validSpo2 = 0, validHr = 0;
  maxim_heart_rate_and_oxygen_saturation(
      irBuf_, BLOCK_N, redBuf_, &spo2, &validSpo2, &hr, &validHr);

  if (validHr && hr >= MIN_VALID_BPM && hr <= MAX_VALID_BPM) {
    if (prevBpm_ > 0) {
      float diff = fabsf((float)hr - (float)prevBpm_) / (float)prevBpm_;
      float sample = 1.0f - fminf(diff * 2.0f, 1.0f);
      beatConsistency_ = beatConsistency_ * 0.7f + sample * 0.3f;
    }
    prevBpm_ = hr;
    currentBpm_ = hr;
    validBlocks_++;
    if (minBpm_ < 0 || hr < minBpm_) minBpm_ = hr;
    if (maxBpm_ < 0 || hr > maxBpm_) maxBpm_ = hr;
    pushAverage(hr);
  }

  // SpO2 only when the algorithm itself flags it valid AND sane.
  if (validSpo2 && spo2 >= 70 && spo2 <= 100) {
    spo2_ = spo2;
  } else {
    spo2_ = -1;
  }
}

void Max30102Sensor::pushAverage(int bpm) {
  avgBuf_[avgIdx_] = bpm;
  avgIdx_ = (avgIdx_ + 1) % AVG_N;
  if (avgCount_ < AVG_N) avgCount_++;
}

int Max30102Sensor::currentBpm() const {
  if (!contact_ || validBlocks_ < 1) return -1;
  return currentBpm_;
}

int Max30102Sensor::averageBpm() const {
  if (!contact_ || avgCount_ == 0) return -1;
  long sum = 0;
  for (int i = 0; i < avgCount_; i++) sum += avgBuf_[i];
  return (int)(sum / avgCount_);
}

int Max30102Sensor::signalQuality() {
  if (!online_) return 0;
  if (!contact_) return 0;
  int q = 40;
  float irScore = fminf((float)lastIr_ / 150000.0f, 1.0f) * 30.0f;
  q += (int)irScore;
  q += (int)(beatConsistency_ * 30.0f);
  if (q > 100) q = 100;
  return q;
}
