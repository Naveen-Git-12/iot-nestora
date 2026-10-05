#!/usr/bin/env bash
# Upload NESTORA V1 firmware to ESP32-S3 Super Mini.
# Expects /dev/ttyACM0 (override: PORT=/dev/ttyACM1 ./upload.sh)
set -e
PORT="${PORT:-/dev/ttyACM0}"
if [ ! -e "$PORT" ]; then
  echo "ERROR: $PORT not found. Plug in the ESP32-S3 and check dmesg."
  exit 1
fi
cd "$(dirname "$0")/nestora_v1"
arduino-cli upload \
  -p "$PORT" \
  --fqbn esp32:esp32:esp32s3 \
  .
echo "--- serial monitor (Ctrl-C to exit) ---"
arduino-cli monitor -p "$PORT" -c baudrate=115200
