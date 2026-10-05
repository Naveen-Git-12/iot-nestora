#include "max30102_sensor.h"
#include "config.h"
#include <MAX30105.h>
#include "heartRate.h"

static MAX30105 particleSensor;

Max30102Sensor::Max30102Sensor() {}

bool Max30102Sensor::begin(TwoWire *bus, uint8_t address) {
  bus_ = bus;
  // SparkFun begin returns false when nothing answers at 0x57.
  if (!particleSensor.begin(*bus_, I2C_SPEED_FAST)) {
    online_ = false;
    return false;
  }
  particleSensor.setup(
      0x1F,  // LED power (tune later for battery)
      4,     // sampleAverage
      2,     // ledMode: red + IR
      100,   // sampleRate Hz
      411,   // pulseWidth us
      4096   // adcRange
  );
  particleSensor.setPulseAmplitudeRed(0x0A);
  particleSensor.setPulseAmplitudeGreen(0);
  online_ = true;
  resetBeatState();
  return true;
}

void Max30102Sensor::resetBeatState() {
  currentBpm_ = -1;
  avgCount_ = 0;
  avgIdx_ = 0;
  validBeats_ = 0;
  minBpm_ = -1;
  maxBpm_ = -1;
  lastBeatAt_ = 0;
  prevBeatAt_ = 0;
  beatConsistency_ = 0.0f;
  for (int i = 0; i < AVG_N; i++) avgBuf_[i] = 0;
}

void Max30102Sensor::update() {
  if (!online_) return;

  lastRed_ = particleSensor.getRed();
  lastIr_ = particleSensor.getIR();

  bool contact = lastIr_ > contactThreshold;
  unsigned long now = millis();

  if (!contact) {
    contact_ = false;
    if (contactLostAt_ == 0) contactLostAt_ = now;
    // After a grace period with no finger, drop stale HR instead of
    // freezing the last BPM forever.
    if (now - contactLostAt_ > CONTACT_LOSS_RESET_MS) resetBeatState();
    return;
  }

  if (!contact_) {
    // Fresh touch: start clean so old beats can't pollute averages.
    resetBeatState();
  }
  contact_ = true;
  contactLostAt_ = 0;

  if (checkForBeat((int32_t)lastIr_)) {
    unsigned long interval = (lastBeatAt_ == 0) ? 0 : (now - lastBeatAt_);
    prevBeatAt_ = lastBeatAt_;
    lastBeatAt_ = now;
    if (interval == 0) return;

    float bpm = 60000.0f / (float)interval;
    if (bpm < MIN_VALID_BPM || bpm > MAX_VALID_BPM) return;  // reject garbage

    // Beat-to-beat regularity (steady rhythm => higher consistency).
    if (prevBeatAt_ != 0) {
      unsigned long prev = lastBeatAt_ - prevBeatAt_;
      float diff = fabsf((float)interval - (float)prev) / (float)prev;
      float sample = 1.0f - fminf(diff * 2.0f, 1.0f);
      beatConsistency_ = beatConsistency_ * 0.7f + sample * 0.3f;
    }

    int ibpm = (int)(bpm + 0.5f);
    currentBpm_ = ibpm;
    validBeats_++;
    if (minBpm_ < 0 || ibpm < minBpm_) minBpm_ = ibpm;
    if (maxBpm_ < 0 || ibpm > maxBpm_) maxBpm_ = ibpm;
    pushAverage(ibpm);
  }
}

void Max30102Sensor::pushAverage(int bpm) {
  avgBuf_[avgIdx_] = bpm;
  avgIdx_ = (avgIdx_ + 1) % AVG_N;
  if (avgCount_ < AVG_N) avgCount_++;
}

int Max30102Sensor::currentBpm() const {
  if (!contact_ || validBeats_ < MIN_BEATS_TO_LOCK) return -1;
  return currentBpm_;
}

int Max30102Sensor::averageBpm() const {
  if (!contact_ || validBeats_ < MIN_BEATS_TO_LOCK || avgCount_ == 0) return -1;
  long sum = 0;
  for (int i = 0; i < avgCount_; i++) sum += avgBuf_[i];
  return (int)(sum / avgCount_);
}

int Max30102Sensor::signalQuality() {
  if (!online_) return 0;
  if (!contact_) return 0;
  int q = 40;  // contact established
  // IR strength: full marks near/above ~150k, scaled below.
  float irScore = fminf((float)lastIr_ / 150000.0f, 1.0f) * 30.0f;
  q += (int)irScore;
  q += (int)(beatConsistency_ * 30.0f);
  if (q > 100) q = 100;
  return q;
}
