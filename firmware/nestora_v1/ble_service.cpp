#include "ble_service.h"
#include "config.h"
#include <NimBLEDevice.h>

static NimBLEServer *pServer = nullptr;
static NimBLECharacteristic *pVitals = nullptr;
static NimBLECharacteristic *pStatus = nullptr;
static BleService *self_ = nullptr;

class BleConnCallbacks : public NimBLEServerCallbacks {
  void onConnect(NimBLEServer *s, NimBLEConnInfo &info) override {
    if (self_) self_->clients_++;
    // Ask for a bigger MTU so JSON notifies are never truncated.
    s->updateConnParams(info.getConnHandle(), 12, 24, 0, 60);
  }
  void onDisconnect(NimBLEServer *s, NimBLEConnInfo &info,
                    int reason) override {
    if (self_ && self_->clients_ > 0) self_->clients_--;
    NimBLEDevice::startAdvertising();
  }
  void onMTUChange(uint16_t MTU, NimBLEConnInfo &info) override {}
};

BleService::BleService() { self_ = this; }

void BleService::begin() {
  NimBLEDevice::init(BLE_DEVICE_NAME);
  NimBLEDevice::setMTU(BLE_PREFERRED_MTU);
  NimBLEDevice::setPower(ESP_PWR_LVL_P9);

  pServer = NimBLEDevice::createServer();
  pServer->setCallbacks(new BleConnCallbacks());

  NimBLEService *svc = pServer->createService(BLE_SERVICE_UUID);

  pVitals = svc->createCharacteristic(
      BLE_VITALS_CHAR_UUID,
      NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::NOTIFY);
  pVitals->setValue("{}");

  pStatus = svc->createCharacteristic(
      BLE_STATUS_CHAR_UUID,
      NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::NOTIFY);
  pStatus->setValue(status_);

  svc->start();

  NimBLEAdvertising *adv = NimBLEDevice::getAdvertising();
  adv->addServiceUUID(BLE_SERVICE_UUID);
  adv->start();
}

void BleService::update() {
  if (clients_ == 0 &&
      !NimBLEDevice::getAdvertising()->isAdvertising()) {
    NimBLEDevice::startAdvertising();
  }
}

void BleService::notifyVitals(const char *json) {
  if (pVitals && clients_ > 0) {
    pVitals->setValue((uint8_t *)json, strlen(json));
    pVitals->notify();
  }
}

void BleService::setStatus(const char *json) {
  strncpy(status_, json, sizeof(status_) - 1);
  status_[sizeof(status_) - 1] = '\0';
  if (pStatus) pStatus->setValue(status_);
}
