#pragma once
#include <Arduino.h>
#include <Wire.h>

// MAX30102 driver (PROVEN config from hardware test sketch):
// shared bus with MPU6050 (SDA GPIO12 / SCL GPIO13, addr 0x57),
// LED brightness 60, red+IR mode @100 Hz, both amplitudes 0x24.
// Block-based Maxim algorithm (HR + SpO2 with validity flags),
// collected non-blockingly: one FIFO sample per update() call,
// Maxim runs every 100 samples (~1 s). Validity-gated:
// HR 40-200, SpO2 70-100, else reported unavailable (never faked).
class Max30102Sensor {
 public:
  Max30102Sensor();

  // True if the sensor answers. Never crashes when missing.
  bool begin(TwoWire *bus, uint8_t address);

  // Call as often as possible. Drains one FIFO sample per call.
  void update();

  bool online() const { return online_; }
  bool hasContact() const { return contact_; }
  uint32_t ir() const { return lastIr_; }
  uint32_t red() const { return lastRed_; }

  // Valid values, or -1 when unavailable.
  int currentBpm() const;
  int averageBpm() const;
  int spo2() const { return spo2_; }
  int minBpm() const { return minBpm_; }
  int maxBpm() const { return maxBpm_; }

  // Prototype 0-100 heuristic.
  int signalQuality();

  unsigned long contactThreshold = 10000UL;  // block-average IR

 private:
  void resetBeatState();
  void pushAverage(int bpm);
  void runMaximBlock();

  static const int BLOCK_N = 100;
  uint32_t irBuf_[BLOCK_N] = {0};
  uint32_t redBuf_[BLOCK_N] = {0};
  int bufIdx_ = 0;
  uint64_t blockIrSum_ = 0;

  TwoWire *bus_ = nullptr;
  bool online_ = false;
  bool contact_ = false;
  unsigned long contactLostAt_ = 0;
  uint32_t lastIr_ = 0;
  uint32_t lastRed_ = 0;

  int currentBpm_ = -1;
  int spo2_ = -1;
  static const int AVG_N = 8;
  int avgBuf_[AVG_N] = {0};
  int avgCount_ = 0;
  int avgIdx_ = 0;
  int validBlocks_ = 0;
  int minBpm_ = -1;
  int maxBpm_ = -1;
  float beatConsistency_ = 0.0f;
  int prevBpm_ = -1;
};
