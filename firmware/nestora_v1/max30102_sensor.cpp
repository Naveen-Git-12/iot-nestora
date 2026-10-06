#include "max30102_sensor.h"
#include "config.h"
#include <MAX30105.h>
#include "spo2_algorithm.h"

// Max physiological slew: displayed HR chases the median at most
// this fast, so single bad blocks never flash on screen.
#define SLEW_PER_STEP 4

static MAX30105 particleSensor;

Max30102Sensor::Max30102Sensor() {}

bool Max30102Sensor::begin(TwoWire *bus, uint8_t address) {
  bus_ = bus;
  // Probe first: begin() can hang on some wiring faults.
  bus_->beginTransmission(address);
  if (bus_->endTransmission() != 0) {
    online_ = false;
    return false;
  }
  if (!particleSensor.begin(*bus_, I2C_SPEED_FAST)) {
    online_ = false;
    return false;
  }
  // Full proven LED config: the brownout theory is dead (every boot
  // reports rst=POWERON), and trimmed current weakens the AC pulse wave,
  // which makes the peak detector double-count the dicrotic notch.
  particleSensor.setup(
      60,   // LED brightness
      4,    // sampleAverage
      2,    // ledMode: red + IR
      100,  // sampleRate Hz
      411,  // pulseWidth us
      4096  // adcRange
  );
  particleSensor.setPulseAmplitudeRed(0x24);
  particleSensor.setPulseAmplitudeIR(0x24);  // IR emission required
  particleSensor.setPulseAmplitudeGreen(0);
  online_ = true;
  resetBeatState();
  return true;
}

void Max30102Sensor::resetBeatState() {
  currentBpm_ = -1;
  displayedBpm_ = -1;
  spo2_ = -1;
  histCount_ = 0;
  histIdx_ = 0;
  bufIdx_ = 0;
  filled_ = 0;
  blockIrSum_ = 0;
  blockIrCount_ = 0;
  minBpm_ = -1;
  maxBpm_ = -1;
  beatConsistency_ = 0.0f;
  prevBpm_ = -1;
  for (int i = 0; i < HIST_N; i++) histBuf_[i] = 0;
}

void Max30102Sensor::update() {
  if (!online_) return;

  // One FIFO sample per call: MPU + BLE stay live while blocks fill.
  if (!particleSensor.available()) {
    particleSensor.check();
    if (!particleSensor.available()) return;
  }
  lastRed_ = particleSensor.getRed();
  lastIr_ = particleSensor.getIR();
  particleSensor.nextSample();

  irBuf_[bufIdx_] = lastIr_;
  redBuf_[bufIdx_] = lastRed_;
  bufIdx_++;
  if (filled_ < BLOCK_N) filled_++;
  blockIrSum_ += lastIr_;
  blockIrCount_++;

  // Non-overlapping blocks: compute when full (proven pattern).
  if (bufIdx_ >= BLOCK_N && filled_ >= BLOCK_N) {
    bufIdx_ = 0;
    runMaximBlock();
  }
}

void Max30102Sensor::runMaximBlock() {
  // Buffers hold exactly one contiguous BLOCK_N block (non-overlapping),
  // matching the proven hardware-test sketch. Never pass a longer or
  // reassembled window: the Maxim routine processes its own internal
  // BUFFER_SIZE and mismatched lengths corrupt the peak statistics.
  uint32_t avgIr =
      blockIrCount_ > 0 ? (uint32_t)(blockIrSum_ / blockIrCount_) : 0;
  blockIrSum_ = 0;
  blockIrCount_ = 0;
  unsigned long now = millis();

  // No skin contact: invalidate, never freeze old values.
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
  // Block verdict (temporary diagnostic; proves why blocks pass/fail).
  Serial.printf("BLK avgIr=%lu validHr=%d hr=%ld validSpO2=%d spo2=%ld\n",
                (unsigned long)avgIr, (int)validHr, (long)hr,
                (int)validSpo2, (long)spo2);

  if (validHr && hr >= MIN_VALID_BPM && hr <= MAX_VALID_BPM) {
    if (prevBpm_ > 0) {
      float diff = fabsf((float)hr - (float)prevBpm_) / (float)prevBpm_;
      float sample = 1.0f - fminf(diff * 2.0f, 1.0f);
      beatConsistency_ = beatConsistency_ * 0.7f + sample * 0.3f;
    }
    prevBpm_ = hr;
    currentBpm_ = hr;
    if (minBpm_ < 0 || hr < minBpm_) minBpm_ = hr;
    if (maxBpm_ < 0 || hr > maxBpm_) maxBpm_ = hr;
    pushBlock(hr);
  }

  if (validSpo2 && spo2 >= 70 && spo2 <= 100) {
    spo2_ = spo2;
  } else {
    spo2_ = -1;
  }

  // Slew-limited display: chase the median, never jump to it.
  int med = median();
  if (med > 0) {
    if (displayedBpm_ < 0) {
      displayedBpm_ = med;  // first lock: snap, nothing prior to protect
    } else if (med > displayedBpm_) {
      displayedBpm_ += (med - displayedBpm_ > SLEW_PER_STEP)
                           ? SLEW_PER_STEP
                           : (med - displayedBpm_);
    } else if (med < displayedBpm_) {
      displayedBpm_ -= (displayedBpm_ - med > SLEW_PER_STEP)
                           ? SLEW_PER_STEP
                           : (displayedBpm_ - med);
    }
  }
}

void Max30102Sensor::pushBlock(int bpm) {
  histBuf_[histIdx_] = bpm;
  histIdx_ = (histIdx_ + 1) % HIST_N;
  if (histCount_ < HIST_N) histCount_++;
}

int Max30102Sensor::median() const {
  if (histCount_ == 0) return -1;
  int tmp[HIST_N];
  for (int i = 0; i < histCount_; i++) tmp[i] = histBuf_[i];
  // Insertion sort (HIST_N is tiny).
  for (int i = 1; i < histCount_; i++) {
    int key = tmp[i], j = i - 1;
    while (j >= 0 && tmp[j] > key) {
      tmp[j + 1] = tmp[j];
      j--;
    }
    tmp[j + 1] = key;
  }
  return tmp[histCount_ / 2];
}

int Max30102Sensor::currentBpm() const {
  if (!contact_ || displayedBpm_ < 0) return -1;
  return displayedBpm_;
}

int Max30102Sensor::averageBpm() const {
  int med = median();
  if (!contact_ || med < 0) return -1;
  return med;
}

int Max30102Sensor::buffered() {
  if (!online_) return 0;
  return particleSensor.available();
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
