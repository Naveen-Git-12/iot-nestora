#include "max30102_sensor.h"
#include "config.h"
#include <MAX30105.h>
#include "spo2_algorithm.h"

// ── HR estimation ───────────────────────────────────────────────────────────
// Why not the stock Maxim heart rate: its peak detector allows only 4
// samples (40 ms) between accepted peaks, so the dicrotic notch (which
// lands ~200-300 ms after the main systolic peak) is counted as a second
// beat. That doubles the reported rate - which is exactly what we saw
// (stable 150 at rest => real ~75).
//
// Autocorrelation over the whole block measures PERIODICITY, not
// individual peaks, so an echo inside one beat cannot create a spurious
// period: the only strong periodicity in a 1 s window is the true beat.
#define FS_HZ 100
#define HR_MIN 40
#define HR_MAX 200
// period bounds in samples: 6000/200=30 .. 6000/40=150
#define LAG_MIN 30
#define LAG_MAX 150
// a believable periodicity must correlate at least this well
#define AC_MIN_PEAK 0.30f

static MAX30105 particleSensor;

Max30102Sensor::Max30102Sensor() {}

bool Max30102Sensor::begin(TwoWire *bus, uint8_t address) {
  bus_ = bus;
  bus_->beginTransmission(address);
  if (bus_->endTransmission() != 0) {
    online_ = false;
    return false;
  }
  if (!particleSensor.begin(*bus_, I2C_SPEED_FAST)) {
    online_ = false;
    return false;
  }
  // Full proven LED config. (A trimmed-current experiment weakened the
  // AC wave; every boot reported rst=POWERON, so brownout was not a
  // factor.)
  particleSensor.setup(
      60,   // LED brightness
      4,    // sampleAverage
      2,    // ledMode: red + IR
      100,  // sampleRate Hz
      411,  // pulseWidth us
      4096  // adcRange
  );
  particleSensor.setPulseAmplitudeRed(0x24);
  particleSensor.setPulseAmplitudeIR(0x24);
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

  if (bufIdx_ >= BLOCK_N && filled_ >= BLOCK_N) {
    bufIdx_ = 0;
    runMaximBlock();
  }
}

// Autocorrelation HR. Returns BPM, or -1 when no periodicity stands out.
// n must be exactly Max30102Sensor::BLOCK_N (1 s @100 Hz).
static int estimateBpmAutocorr(const uint32_t *samples, int n) {
  static float x[100];
  const int NN = n > 100 ? 100 : n;
  float mean = 0;
  for (int i = 0; i < NN; i++) mean += (float)samples[i];
  mean /= NN;
  for (int i = 0; i < NN; i++) x[i] = (float)samples[i] - mean;

  // energy-normalised autocorrelation for each candidate lag
  float best = 0;
  int bestLag = 0;
  for (int lag = LAG_MIN; lag <= LAG_MAX && lag < NN; lag++) {
    float num = 0, d1 = 0, d2 = 0;
    for (int i = 0; i + lag < NN; i++) {
      num += x[i] * x[i + lag];
      d1 += x[i] * x[i];
      d2 += x[i + lag] * x[i + lag];
    }
    float den = sqrtf(d1 * d2);
    if (den <= 0) continue;
    float r = num / den;
    if (r > best) {
      best = r;
      bestLag = lag;
    }
  }
  if (bestLag == 0 || best < AC_MIN_PEAK) return -1;

  // Parabolic refinement around the correlation peak for sub-sample lag.
  float prev = 0, cur = 0, next = 0;
  {
    auto corrAt = [&](int lag) -> float {
      if (lag < LAG_MIN || lag > LAG_MAX || lag >= n) return 0;
      float num = 0, d1 = 0, d2 = 0;
      for (int i = 0; i + lag < NN; i++) {
        num += x[i] * x[i + lag];
        d1 += x[i] * x[i];
        d2 += x[i + lag] * x[i + lag];
      }
      float den = sqrtf(d1 * d2);
      return den > 0 ? num / den : 0;
    };
    cur = corrAt(bestLag);
    prev = corrAt(bestLag - 1);
    next = corrAt(bestLag + 1);
  }
  float shift = 0.0f;
  float denom = (prev - 2 * cur + next);
  if (fabsf(denom) > 1e-9f) shift = 0.5f * (prev - next) / denom;
  float lagEst = bestLag + shift;
  if (lagEst <= 0) return -1;

  float bpm = (FS_HZ * 60.0f) / lagEst;
  if (bpm < HR_MIN || bpm > HR_MAX) return -1;
  return (int)(bpm + 0.5f);
}

void Max30102Sensor::runMaximBlock() {
  uint32_t avgIr =
      blockIrCount_ > 0 ? (uint32_t)(blockIrSum_ / blockIrCount_) : 0;
  blockIrSum_ = 0;
  blockIrCount_ = 0;
  unsigned long now = millis();

  if (avgIr < contactThreshold) {
    contact_ = false;
    if (contactLostAt_ == 0) contactLostAt_ = now;
    if (now - contactLostAt_ > CONTACT_LOSS_RESET_MS) resetBeatState();
    return;
  }
  if (!contact_) resetBeatState();
  contact_ = true;
  contactLostAt_ = 0;

  int bpm = estimateBpmAutocorr(irBuf_, BLOCK_N);
  if (bpm > 0) {
    if (prevBpm_ > 0) {
      float diff = fabsf((float)bpm - (float)prevBpm_) / (float)prevBpm_;
      float sample = 1.0f - fminf(diff * 2.0f, 1.0f);
      beatConsistency_ = beatConsistency_ * 0.7f + sample * 0.3f;
    }
    prevBpm_ = bpm;
    currentBpm_ = bpm;
    if (minBpm_ < 0 || bpm < minBpm_) minBpm_ = bpm;
    if (maxBpm_ < 0 || bpm > maxBpm_) maxBpm_ = bpm;
    pushBlock(bpm);
  }

  // SpO2 still from Maxim, validity-gated (real value or unavailable).
  int32_t spo2 = 0, hrMax = 0;
  int8_t validSpo2 = 0, validHrMax = 0;
  maxim_heart_rate_and_oxygen_saturation(
      irBuf_, BLOCK_N, redBuf_, &spo2, &validSpo2, &hrMax, &validHrMax);
  Serial.printf("SPO2 valid=%d val=%ld | HR_AC=%d\n",
                (int)validSpo2, (long)spo2, bpm);
  if (validSpo2 && spo2 >= 70 && spo2 <= 100) spo2_ = spo2;
  else spo2_ = -1;

  int med = median();
  if (med > 0) {
    if (displayedBpm_ < 0) {
      displayedBpm_ = med;
    } else if (med > displayedBpm_) {
      int d = med - displayedBpm_;
      displayedBpm_ += (d > 4) ? 4 : d;
    } else if (med < displayedBpm_) {
      int d = displayedBpm_ - med;
      displayedBpm_ -= (d > 4) ? 4 : d;
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

int Max30102Sensor::buffered() {
  if (!online_) return 0;
  return particleSensor.available();
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