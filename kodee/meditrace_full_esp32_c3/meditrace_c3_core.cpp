#include <Arduino.h>
#include <Update.h>

#if defined(CONFIG_IDF_TARGET_ESP32C3)
#include <Wire.h>
#endif

#include "alarm_manager.h"
#include "ble_manager.h"
#include "config.h"
#include "sensor_manager.h"
#include "storage_manager.h"

AlarmManager alarmManager;
BleManager bleManager;
SensorManager sensorManager;
StorageManager storageManager;

uint8_t batteryLevel = 0;
float batteryVoltage = 0.0f;
uint32_t lastBatteryReadMs = 0;
uint32_t syncedEpoch = 0;
uint32_t syncedAtMs = 0;
size_t otaExpectedSize = 0;
uint32_t otaExpectedCrc = 0;
uint32_t otaRunningCrc = 0xFFFFFFFF;
size_t otaBytesWritten = 0;
bool otaActive = false;

uint32_t currentUnixTime() {
  if (syncedEpoch == 0) return 0;
  return syncedEpoch + (millis() - syncedAtMs) / 1000;
}

uint32_t crc32Update(uint32_t crc, const uint8_t* data, size_t length) {
  while (length-- > 0) {
    crc ^= *data++;
    for (uint8_t bit = 0; bit < 8; ++bit) {
      crc = (crc >> 1) ^ (0xEDB88320 & (-(static_cast<int32_t>(crc & 1))));
    }
  }
  return crc;
}

uint8_t batteryPercentForVoltage(float voltage) {
  if (voltage >= 4.20f) return 100;
  if (voltage >= 4.10f) return 90;
  if (voltage >= 4.00f) return 75;
  if (voltage >= 3.90f) return 60;
  if (voltage >= 3.80f) return 40;
  if (voltage >= 3.70f) return 25;
  if (voltage >= 3.60f) return 10;
  if (voltage >= 3.30f) return 3;
  return 0;
}

void updateBatteryReading() {
#if defined(CONFIG_IDF_TARGET_ESP32C3)
  const uint32_t now = millis();
  if (lastBatteryReadMs != 0 &&
      now - lastBatteryReadMs < MeditraceConfig::BATTERY_READ_INTERVAL_MS) {
    return;
  }
  lastBatteryReadMs = now;

  uint32_t adcMillivolts = 0;
  constexpr uint8_t sampleCount = 8;
  for (uint8_t sample = 0; sample < sampleCount; ++sample) {
    adcMillivolts += analogReadMilliVolts(MeditraceConfig::BATTERY_ADC_PIN);
    delay(1);
  }
  const float adcVoltage = (adcMillivolts / static_cast<float>(sampleCount)) / 1000.0f;
  batteryVoltage = adcVoltage * MeditraceConfig::BATTERY_DIVIDER_RATIO;
  batteryLevel = batteryPercentForVoltage(batteryVoltage);
#endif
}

// Diagnostik ini hanya membaca bus/pin yang sudah dipakai firmware. Tidak
// mengubah konfigurasi PCF8575 atau mengaktifkan pin tambahan.
void printHardwareReport() {
#if defined(CONFIG_IDF_TARGET_ESP32C3)
  Serial.println("\n=== MEDITRACE C3 hardware report ===");
  Serial.printf("I2C: SDA GPIO%u, SCL GPIO%u, 100 kHz\n",
                MeditraceConfig::I2C_SDA_PIN,
                MeditraceConfig::I2C_SCL_PIN);
  Serial.printf("Expected: PCF8575 0x%02X (RTC tidak digunakan)\n",
                MeditraceConfig::PCF8575_ADDRESS);
  Serial.print("I2C found:");
  bool foundAny = false;
  for (uint8_t address = 0x03; address < 0x78; ++address) {
    Wire.beginTransmission(address);
    if (Wire.endTransmission() == 0) {
      Serial.printf(" 0x%02X", address);
      foundAny = true;
    }
  }
  if (!foundAny) Serial.print(" none");
  Serial.println();
  Serial.printf("PCF ready: %s | RTC: not used\n",
                sensorManager.available() ? "yes" : "no");
  Serial.println("Inputs: IR P00..P04 (HIGH=beam blocked), NC limit P10..P14 (HIGH=closed).");
  Serial.println("Sensor snapshot (P00..P04 / P10..P14): " +
                 sensorManager.statusJson());
  Serial.println("Commands: HELP, DIAG, I2C, SENSOR, TEST");
  Serial.println("====================================\n");
#else
  Serial.println("Hardware report is available on the ESP32-C3 build.");
#endif
}

// Uji seluruh jalur hardware C3: PCF8575, IR P00..P04, limit NC P10..P14,
// dan buzzer GPIO3. RTC tetap sengaja tidak digunakan.
String installedHardwareTestJson() {
  const bool irReadOk = sensorManager.checkIrNow();
  const bool pcfReady = sensorManager.available();
  const String sensorStatus = sensorManager.statusJson();
  const String fields = sensorStatus.length() >= 2
                            ? sensorStatus.substring(1, sensorStatus.length() - 1)
                            : "\"sensors\":[],\"doors\":[],\"sensor_valid\":false";
  return String("{\"test\":\"installed_hardware\",\"pcf8575\":") +
         (pcfReady ? "true" : "false") +
         ",\"ir_read\":" + (irReadOk ? "true" : "false") +
         ",\"buzzer_gpio\":" +
         String(static_cast<unsigned>(MeditraceConfig::BUZZER_PIN)) +
         ",\"rtc\":\"not_used\"," + fields + "}";
}

void runInstalledHardwareTest() {
  // Bunyi singkat untuk membuktikan jalur GPIO3 -> S8050 -> buzzer.
  alarmManager.start(1000);
  const String result = installedHardwareTestJson();
  Serial.println("\n=== MEDITRACE all-hardware test ===");
  Serial.println(result);
  Serial.println("Buzzer GPIO3 active for 1 second.");
  Serial.println("IR P00..P04: 1 = beam blocked/obat ada.");
  Serial.println("Limit P10..P14: 1 = limit pressed/pintu tertutup.");
  Serial.println("RTC intentionally not used.");
  Serial.println("==========================================\n");
}

void processSerialConsole() {
  static String line;
  while (Serial.available() > 0) {
    const char character = static_cast<char>(Serial.read());
    if (character == '\r') continue;
    if (character != '\n') {
      if (line.length() < 40) line += character;
      continue;
    }

    line.trim();
    line.toUpperCase();
    if (line == "HELP") {
      Serial.println("Commands: DIAG/I2C, SENSOR, TEST");
    } else if (line == "DIAG" || line == "I2C") {
      printHardwareReport();
    } else if (line == "SENSOR") {
      const bool readOk = sensorManager.checkIrNow();
      Serial.printf("IR read: %s | %s\n", readOk ? "OK" : "FAILED",
                    sensorManager.statusJson().c_str());
    } else if (line == "TEST") {
      runInstalledHardwareTest();
    } else if (!line.isEmpty()) {
      Serial.println("Unknown command. Use: HELP, DIAG, I2C, SENSOR, TEST");
    }
    line = "";
  }
}

String normalizedCommand(const String& payload) {
  String value = payload;
  value.trim();
  if (!value.startsWith("{")) {
    value.toUpperCase();
    return value;
  }
  const int key = value.indexOf("\"command\"");
  const int colon = key < 0 ? -1 : value.indexOf(':', key);
  const int start = colon < 0 ? -1 : value.indexOf('"', colon);
  const int end = start < 0 ? -1 : value.indexOf('"', start + 1);
  if (start < 0 || end < 0) return "";
  value = value.substring(start + 1, end);
  value.toUpperCase();
  return value;
}

String deviceInfoJson() {
  return String("{\"device_id\":\"") + bleManager.deviceId() +
         "\",\"device_name\":\"" + bleManager.deviceName() +
         "\",\"board\":\"" + MeditraceConfig::BOARD_TYPE +
         "\",\"firmware\":\"" + MeditraceConfig::FIRMWARE_VERSION +
         "\",\"battery\":" + batteryLevel +
         ",\"battery_voltage\":" + String(batteryVoltage, 2) + "}";
}

String statusJson() {
  return String("{\"battery\":") + batteryLevel +
         ",\"battery_voltage\":" + String(batteryVoltage, 2) +
         ",\"rtc\":false,\"clock\":\"APP\",\"time_synced\":" +
         (syncedEpoch == 0 ? "false" : "true") +
         ",\"epoch\":" + currentUnixTime() +
         ",\"alarm\":" + (alarmManager.active() ? "true" : "false") +
         ",\"pending\":" + storageManager.eventCount() + "}";
}

void handleOtaChunk(const std::string& chunk) {
  if (!otaActive || chunk.empty()) return;
  const size_t written = Update.write(
      const_cast<uint8_t*>(
          reinterpret_cast<const uint8_t*>(chunk.data())),
      chunk.size());
  if (written != chunk.size()) {
    otaActive = false;
    Update.abort();
    bleManager.notifyStatus("{\"ota\":\"write_failed\"}");
    return;
  }
  otaBytesWritten += written;
  otaRunningCrc = crc32Update(otaRunningCrc,
                              reinterpret_cast<const uint8_t*>(chunk.data()),
                              chunk.size());
}

String responseJson(bool success, const String& command) {
  return String("{\"success\":") + (success ? "true" : "false") +
         ",\"command\":\"" + command + "\"}";
}

void saveConfig(const String& payload) {
  String config = payload;
  config.trim();
  if (config.isEmpty()) config = "{}";
  storageManager.saveConfig(config);
  bleManager.setConfigValue(config);
  bleManager.notifyStatus(responseJson(true, "SET_CONFIG"));
}

void sendPendingEvents() {
  for (size_t i = 0; i < storageManager.eventCount(); ++i) {
    const String event = storageManager.eventAt(i);
    if (!event.isEmpty()) {
      bleManager.notifyEvent(event);
      delay(30);
    }
  }
  bleManager.notifyStatus(
      String("{\"pending_events\":") + storageManager.eventCount() + "}");
}

void handleCommand(const String& payload) {
  const String command = normalizedCommand(payload);
  if (MeditraceConfig::DEBUG_LOGS) {
    Serial.printf("Command: %s\n", command.c_str());
  }

  if (command == "PING") {
    bleManager.notifyStatus(responseJson(true, command));
  } else if (command == "GET_STATUS") {
    bleManager.notifyStatus(statusJson());
  } else if (command == "LED_ON") {
    alarmManager.setLed(true);
    bleManager.notifyStatus(responseJson(true, command));
  } else if (command == "LED_OFF") {
    alarmManager.setLed(false);
    bleManager.notifyStatus(responseJson(true, command));
  } else if (command == "BUZZER_ON") {
    alarmManager.setBuzzer(true);
    bleManager.notifyStatus(responseJson(true, command));
  } else if (command == "BUZZER_OFF") {
    alarmManager.setBuzzer(false);
    bleManager.notifyStatus(responseJson(true, command));
  } else if (command == "ALARM_1000") {
    // Alarm jadwal dipicu aplikasi via BLE. RTC sengaja tidak digunakan pada
    // prototipe ini, sehingga perangkat tidak menyimpan jadwal mandiri.
    alarmManager.start(1000);
    bleManager.notifyStatus(responseJson(true, command));
  } else if (command.startsWith("SYNC_TIME:")) {
    const uint32_t epoch = strtoul(command.substring(10).c_str(), nullptr, 10);
    if (epoch < 1700000000UL) {
      bleManager.notifyStatus(responseJson(false, "SYNC_TIME_INVALID"));
    } else {
      syncedEpoch = epoch;
      syncedAtMs = millis();
      bleManager.notifyStatus(statusJson());
    }
  } else if (command.startsWith("OTA_BEGIN:")) {
    const int separator = command.indexOf(':', 10);
    const size_t size = separator < 0
                            ? 0
                            : strtoul(command.substring(10, separator).c_str(),
                                      nullptr, 10);
    const uint32_t crc = separator < 0
                             ? 0
                             : strtoul(command.substring(separator + 1).c_str(),
                                       nullptr, 16);
    otaActive = size > 0 && size <= 0xF0000 && Update.begin(size);
    otaExpectedSize = size;
    otaExpectedCrc = crc;
    otaRunningCrc = 0xFFFFFFFF;
    otaBytesWritten = 0;
    bleManager.notifyStatus(otaActive ? "{\"ota\":\"ready\"}"
                                      : "{\"ota\":\"begin_failed\"}");
  } else if (command == "OTA_END") {
    const uint32_t finalCrc = otaRunningCrc ^ 0xFFFFFFFF;
    const bool valid = otaActive && otaBytesWritten == otaExpectedSize &&
                       finalCrc == otaExpectedCrc;
    otaActive = false;
    if (!valid || !Update.end(false)) {
      Update.abort();
      bleManager.notifyStatus("{\"ota\":\"checksum_failed\"}");
    } else {
      bleManager.notifyStatus("{\"ota\":\"complete\"}");
      delay(500);
      ESP.restart();
    }
  } else if (command == "GET_SENSOR") {
    sensorManager.checkIrNow();
    bleManager.notifyStatus(sensorManager.statusJson());
  } else if (command == "SELF_TEST" || command == "TEST_ALL") {
    alarmManager.start(1000);
    bleManager.notifyStatus(installedHardwareTestJson());
  } else if (command.startsWith("SET_SCHEDULE")) {
    saveConfig(payload);
  } else if (command == "GET_PENDING_EVENTS") {
    sendPendingEvents();
  } else if (command == "CLEAR_SYNCED_EVENTS") {
    storageManager.clearEvents();
    bleManager.notifyStatus(responseJson(true, command));
  } else if (command == "RESET") {
    bleManager.notifyStatus(responseJson(true, command));
    delay(200);
    ESP.restart();
  } else {
    bleManager.notifyStatus(responseJson(false, command));
  }
}

String sensorEventJson(const SensorEvent& event) {
  const char* name = event.doseRemoved()
                         ? "DOSE_REMOVED"
                         : event.type == SensorEventType::doseChanged
                               ? "DOSE_STATE_CHANGED"
                               : "DOOR_STATE_CHANGED";
  return String("{\"event\":\"") + name +
         "\",\"sensor_id\":" + (event.sensorId + 1) +
         ",\"state\":" + (event.currentState ? "true" : "false") + "}";
}

void processSensors() {
  SensorEvent event;
  if (!sensorManager.poll(event)) return;
  const String payload = sensorEventJson(event);
  if (event.doseRemoved()) {
    storageManager.enqueueEvent(payload);
  }
  bleManager.notifyEvent(payload);
  // Status lengkap ikut dikirim agar APK langsung memperbarui lima
  // kompartemen setelah IR atau limit switch berubah.
  bleManager.notifyStatus(sensorManager.statusJson());
  if (MeditraceConfig::DEBUG_LOGS) {
    Serial.println(payload);
  }
}

void setup() {
  Serial.begin(115200);
  delay(300);
#if defined(CONFIG_IDF_TARGET_ESP32C3)
  analogSetPinAttenuation(MeditraceConfig::BATTERY_ADC_PIN, ADC_11db);
  updateBatteryReading();
#endif
  alarmManager.begin();
  storageManager.begin();
#if defined(CONFIG_IDF_TARGET_ESP32C3)
  Wire.begin(MeditraceConfig::I2C_SDA_PIN, MeditraceConfig::I2C_SCL_PIN);
  Wire.setClock(100000);
#endif
  sensorManager.begin(); // PCF8575 memakai bus I2C GPIO 5/6 pada C3.
  printHardwareReport();

  const String savedConfig = storageManager.loadConfig();
  bleManager.begin(deviceInfoJson, handleCommand, saveConfig);
  bleManager.setOtaChunkHandler(handleOtaChunk);
  bleManager.setConfigValue(savedConfig);
  Serial.printf(
      "%s ready, board %s, firmware %s\n",
      bleManager.deviceName().c_str(),
      MeditraceConfig::BOARD_TYPE,
      MeditraceConfig::FIRMWARE_VERSION);
}

void loop() {
  processSerialConsole();
  updateBatteryReading();
  bleManager.update();
  alarmManager.update();
  processSensors();
  delay(10);
}
