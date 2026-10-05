#pragma once
#include <Arduino.h>
#include <Wire.h>

// MAX30102 driver wrapper (dedicated bus MAX_BUS, addr 0x57).
// Exposes: RED/IR raw PPG, contact flag, current + smoothed BPM,
// rolling average HR, prototype signal quality.
// SpO2 is intentionally NOT faked: spo2() returns -1 (unavailable).
class Max30102Sensor {
 public:
  Max30102Sensor();

  // Returns true if sensor answered on the bus. Never crashes when
  // hardware is missing; update() becomes a no-op.
  bool begin(TwoWire *bus, uint8_t address);

  // Call as often as possible from loop() (drains FIFO, runs beat
  // detector). Cheap when offline.
  void update();

  bool online() const { return online_; }
  bool hasContact() const { return contact_; }
  uint32_t ir() const { return lastIr_; }
  uint32_t red() const { return lastRed_; }

  // Valid BPM or -1 when unavailable (no contact / not yet locked).
  int currentBpm() const;
  int averageBpm() const;
  int minBpm() const { return minBpm_; }
  int maxBpm() const { return maxBpm_; }

  // Prototype 0-100 heuristic (contact + IR strength + beat regularity).
  int signalQuality();

  unsigned long contactThreshold = 50000UL;  // tunable per unit

 private:
  void resetBeatState();
  void pushAverage(int bpm);

  TwoWire *bus_ = nullptr;
  bool online_ = false;
  bool contact_ = false;
  unsigned long contactLostAt_ = 0;
  uint32_t lastIr_ = 0;
  uint32_t lastRed_ = 0;

  int currentBpm_ = -1;
  static const int AVG_N = 8;
  int avgBuf_[AVG_N] = {0};
  int avgCount_ = 0;
  int avgIdx_ = 0;
  int validBeats_ = 0;
  int minBpm_ = -1;
  int maxBpm_ = -1;
  unsigned long lastBeatAt_ = 0;
  unsigned long prevBeatAt_ = 0;
  float beatConsistency_ = 0.0f;  // 0..1, higher = steadier rhythm
};
