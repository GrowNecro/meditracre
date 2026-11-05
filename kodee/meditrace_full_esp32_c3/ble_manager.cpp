#include "ble_manager.h"

#include <NimBLEDevice.h>
#include <utility>

#include "config.h"

namespace {

NimBLECharacteristic* statusCharacteristic = nullptr;
NimBLECharacteristic* eventCharacteristic = nullptr;
NimBLECharacteristic* configCharacteristic = nullptr;
NimBLECharacteristic* otaCharacteristic = nullptr;
BleManager::InfoProvider infoProvider;
BleManager::PayloadHandler commandHandler;
BleManager::PayloadHandler configHandler;
BleManager::OtaChunkHandler otaChunkHandler;
String meditraceDeviceId;
String meditraceDeviceName;
String lastStatusPayload;
bool deviceConnected = false;
bool restartAdvertising = false;

class OtaCallbacks final : public NimBLECharacteristicCallbacks {
  void onWrite(NimBLECharacteristic* characteristic, NimBLEConnInfo&) override {
    if (otaChunkHandler) {
      otaChunkHandler(characteristic->getValue());
    }
  }
};

class ServerCallbacks final : public NimBLEServerCallbacks {
  void onConnect(NimBLEServer* server, NimBLEConnInfo& connection) override {
    deviceConnected = true;
    lastStatusPayload = "";
    // Request a relaxed connection schedule. The phone may negotiate a
    // different value, but this keeps the peripheral's radio duty cycle low.
    server->updateConnParams(
        connection.getConnHandle(),
        80,   // 100 ms minimum, units of 1.25 ms.
        160,  // 200 ms maximum.
        4,    // Skip up to four connection events when idle.
        600); // 6 s supervision timeout, units of 10 ms.
    if (MeditraceConfig::DEBUG_LOGS) {
      Serial.printf("BLE connected: %s\n",
                    connection.getAddress().toString().c_str());
    }

  }

  void onDisconnect(NimBLEServer*, NimBLEConnInfo&, int reason) override {
    deviceConnected = false;
    restartAdvertising = true;
    if (MeditraceConfig::DEBUG_LOGS) {
      Serial.printf("BLE disconnected (reason=%d)\n", reason);
    }
  }
};

class CommandCallbacks final : public NimBLECharacteristicCallbacks {
  void onWrite(NimBLECharacteristic* characteristic, NimBLEConnInfo&) override {
    if (commandHandler) {
      commandHandler(String(characteristic->getValue().c_str()));
    }
  }
};

class ConfigCallbacks final : public NimBLECharacteristicCallbacks {
  void onWrite(NimBLECharacteristic* characteristic, NimBLEConnInfo&) override {
    const String payload(characteristic->getValue().c_str());
    if (configHandler) {
      configHandler(payload);
    }
  }
};

ServerCallbacks serverCallbacks;
CommandCallbacks commandCallbacks;
ConfigCallbacks configCallbacks;
OtaCallbacks otaCallbacks;

void startAdvertising() {
  NimBLEDevice::getAdvertising()->start();
  if (MeditraceConfig::DEBUG_LOGS) {
    Serial.printf("Advertising as %s\n", meditraceDeviceName.c_str());
  }
}

}  // namespace

void BleManager::setOtaChunkHandler(OtaChunkHandler handler) {
  otaChunkHandler = std::move(handler);
  if (otaCharacteristic != nullptr) {
    otaCharacteristic->setCallbacks(&otaCallbacks);
  }
}

void BleManager::begin(
    InfoProvider nextInfoProvider,
    PayloadHandler nextCommandHandler,
    PayloadHandler nextConfigHandler) {
  infoProvider = std::move(nextInfoProvider);
  commandHandler = std::move(nextCommandHandler);
  configHandler = std::move(nextConfigHandler);

  const uint16_t suffix = static_cast<uint16_t>(ESP.getEfuseMac() & 0xFFFF);
  char suffixText[5];
  snprintf(suffixText, sizeof(suffixText), "%04X", suffix);
  meditraceDeviceId = String(MeditraceConfig::DEVICE_NAME_PREFIX) + suffixText;
  meditraceDeviceName = meditraceDeviceId;

  NimBLEDevice::init(meditraceDeviceName.c_str());
  // 0 dBm is sufficient for a nearby phone and avoids the highest TX
  // consumption while the device is advertising or connected.
  NimBLEDevice::setPower(ESP_PWR_LVL_N0);
  NimBLEServer* server = NimBLEDevice::createServer();
  server->setCallbacks(&serverCallbacks, false);

  NimBLEService* service = server->createService(MeditraceConfig::SERVICE_UUID);
  NimBLECharacteristic* deviceInfo = service->createCharacteristic(
      MeditraceConfig::DEVICE_INFO_UUID,
      NIMBLE_PROPERTY::READ);
  deviceInfo->setValue(infoProvider().c_str());

  NimBLECharacteristic* command = service->createCharacteristic(
      MeditraceConfig::COMMAND_UUID,
      NIMBLE_PROPERTY::WRITE | NIMBLE_PROPERTY::WRITE_NR);
  command->setCallbacks(&commandCallbacks);

  statusCharacteristic = service->createCharacteristic(
      MeditraceConfig::STATUS_UUID,
      NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::NOTIFY);
  statusCharacteristic->setValue("{\"boot\":true}");

  configCharacteristic = service->createCharacteristic(
      MeditraceConfig::CONFIG_UUID,
      NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::WRITE);
  configCharacteristic->setValue("{}");
  configCharacteristic->setCallbacks(&configCallbacks);

  otaCharacteristic = service->createCharacteristic(
      MeditraceConfig::OTA_UUID, NIMBLE_PROPERTY::WRITE | NIMBLE_PROPERTY::WRITE_NR);
  otaCharacteristic->setCallbacks(&otaCallbacks);

  eventCharacteristic = service->createCharacteristic(
      MeditraceConfig::EVENT_UUID,
      NIMBLE_PROPERTY::NOTIFY);

  NimBLEAdvertising* advertising = NimBLEDevice::getAdvertising();
  advertising->addServiceUUID(MeditraceConfig::SERVICE_UUID);
  advertising->setName(meditraceDeviceName.c_str());
  // Advertise frequently so nearby phones can discover the device quickly.
  advertising->setMinInterval(160);  // 100 ms, BLE units of 0.625 ms.
  advertising->setMaxInterval(240);  // 150 ms.
  advertising->enableScanResponse(true);
  startAdvertising();
}

void BleManager::update() {
  if (!restartAdvertising) {
    return;
  }
  restartAdvertising = false;
  delay(100);
  startAdvertising();
}

void BleManager::notifyStatus(const String& payload) {
  if (statusCharacteristic == nullptr) return;
  if (payload == lastStatusPayload) return;
  lastStatusPayload = payload;
  statusCharacteristic->setValue(payload.c_str());
  if (deviceConnected) statusCharacteristic->notify();
  if (MeditraceConfig::DEBUG_LOGS) {
    Serial.printf("Status: %s\n", payload.c_str());
  }
}

void BleManager::notifyEvent(const String& payload) {
  if (eventCharacteristic == nullptr || !deviceConnected) return;
  eventCharacteristic->setValue(payload.c_str());
  eventCharacteristic->notify();
  if (MeditraceConfig::DEBUG_LOGS) {
    Serial.printf("Event: %s\n", payload.c_str());
  }
}

void BleManager::setConfigValue(const String& payload) {
  if (configCharacteristic != nullptr) {
    configCharacteristic->setValue(payload.c_str());
  }
}

bool BleManager::connected() const {
  return deviceConnected;
}

const String& BleManager::deviceId() const {
  return meditraceDeviceId;
}

const String& BleManager::deviceName() const {
  return meditraceDeviceName;
}
