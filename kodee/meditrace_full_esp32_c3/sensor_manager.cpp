#include "sensor_manager.h"

#if defined(CONFIG_IDF_TARGET_ESP32C3)
#include <Wire.h>
#endif

void SensorManager::begin() {
#if defined(CONFIG_IDF_TARGET_ESP32C3)
  pinMode(MeditraceConfig::PCF8575_INT_PIN, INPUT_PULLUP);
  pinMode(MeditraceConfig::IR_POWER_ENABLE_PIN, OUTPUT);
  digitalWrite(MeditraceConfig::IR_POWER_ENABLE_PIN, LOW);
  expanderReady_ = beginExpander();
  if (expanderReady_) {
    checkIrNow();
    nextInputReadAtMs_ = millis();
  } else {
    retryAtMs_ = millis() + 2000;
    if (MeditraceConfig::DEBUG_LOGS) {
      Serial.println("PCF8575 tidak ditemukan pada alamat 0x20-0x27");
    }
  }
#else
  for (size_t i = 0; i < MeditraceConfig::SENSOR_COUNT; ++i) {
    pinMode(MeditraceConfig::IR_SENSOR_PINS[i], INPUT_PULLUP);
    const bool active = digitalRead(MeditraceConfig::IR_SENSOR_PINS[i]) ==
                        MeditraceConfig::IR_OCCUPIED_LEVEL;
    ir_[i] = {active, active, millis()};
  }
  for (size_t i = 0; i < MeditraceConfig::REED_COUNT; ++i) {
    pinMode(MeditraceConfig::REED_PINS[i], INPUT_PULLUP);
    const bool active = digitalRead(MeditraceConfig::REED_PINS[i]) ==
                        MeditraceConfig::REED_CLOSED_LEVEL;
    reed_[i] = {active, active, millis()};
  }
#endif
}

#if defined(CONFIG_IDF_TARGET_ESP32C3)
bool SensorManager::readPorts(uint16_t& ports) {
  if (Wire.requestFrom(expanderAddress_,
                       static_cast<uint8_t>(2)) != 2) {
    return false;
  }
  const uint8_t low = Wire.read();
  const uint8_t high = Wire.read();
  ports = static_cast<uint16_t>(low) |
          (static_cast<uint16_t>(high) << 8);
  return true;
}

bool SensorManager::beginExpander() {
  // PCF8575: input = tulis HIGH. Port 0 bit 0..4 = penerima IR,
  // port 1 bit 0..4 = limit switch NC pintu. P05/P15 cadangan; semua
  // port ditulis HIGH. Kontak NC tertutup menarik pin LOW.
  // Tidak ada register arah seperti MCP23017.
  const auto tryAddress = [this](uint8_t address) {
    Wire.beginTransmission(address);
    Wire.write(0xFF);
    Wire.write(0xFF);
    if (Wire.endTransmission() != 0) return false;
    expanderAddress_ = address;
    uint16_t ports;
    return readPorts(ports);
  };
  if (!tryAddress(MeditraceConfig::PCF8575_PREFERRED_ADDRESS)) {
    bool found = false;
    for (uint8_t address = 0x20; address <= 0x27; ++address) {
      if (address == MeditraceConfig::PCF8575_PREFERRED_ADDRESS) continue;
      if (tryAddress(address)) {
        found = true;
        break;
      }
    }
    if (!found) return false;
  }
  uint16_t ports;
  if (!readPorts(ports)) return false;
  for (size_t i = 0; i < MeditraceConfig::REED_COUNT; ++i) {
    const bool active = ((ports >> (i + 8)) & 1) ==
                        MeditraceConfig::REED_CLOSED_LEVEL;
    reed_[i] = {active, active, millis()};
  }
  irKnown_ = false;
  irCheckValid_ = false;
  if (MeditraceConfig::DEBUG_LOGS) {
    Serial.printf("PCF8575 siap di 0x%02X: %u IR + %u saklar pintu\n",
                  expanderAddress_,
                  static_cast<unsigned>(MeditraceConfig::SENSOR_COUNT),
                  static_cast<unsigned>(MeditraceConfig::REED_COUNT));
  }

  return true;
}

uint8_t SensorManager::expanderAddress() const {
  return expanderAddress_;
}

void SensorManager::queueEvent(const SensorEvent& event) {
  if (eventCount_ >= 12) return;
  events_[(eventHead_ + eventCount_) % 12] = event;
  ++eventCount_;
}
#endif

bool SensorManager::checkIrNow() {
#if defined(CONFIG_IDF_TARGET_ESP32C3)
  if (!expanderReady_) return false;
  digitalWrite(MeditraceConfig::IR_POWER_ENABLE_PIN, HIGH);
  delay(MeditraceConfig::IR_WARMUP_MS);
  uint16_t first = 0;
  const bool firstOk = readPorts(first);
  delay(MeditraceConfig::SENSOR_DEBOUNCE_MS);
  uint16_t second = 0;
  const bool secondOk = readPorts(second);
  digitalWrite(MeditraceConfig::IR_POWER_ENABLE_PIN, LOW);

  if (!firstOk || !secondOk) {
    expanderReady_ = false;
    irKnown_ = false;
    irCheckValid_ = false;
    retryAtMs_ = millis() + 2000;
    if (MeditraceConfig::DEBUG_LOGS) {
      Serial.println("PCF8575 gagal dibaca; sensor akan dicoba ulang");
    }
    return false;
  }
  // Jangan campur pembacaan lama dan baru bila satu kanal masih berubah.
  for (size_t i = 0; i < MeditraceConfig::SENSOR_COUNT; ++i) {
    if (((first >> i) & 1) != ((second >> i) & 1)) {
      irCheckValid_ = false;
      return false;
    }
  }
  for (size_t i = 0; i < MeditraceConfig::SENSOR_COUNT; ++i) {
    const bool secondLevel = ((second >> i) & 1) ==
                             MeditraceConfig::IR_OCCUPIED_LEVEL;
    if (irKnown_ && ir_[i].stable != secondLevel) {
      queueEvent({SensorEventType::doseChanged, i, ir_[i].stable, secondLevel});
    }
    ir_[i] = {secondLevel, secondLevel, millis()};
  }
  irKnown_ = true;
  irCheckValid_ = true;
  return true;
#else
  return true; // Versi Classic membaca IR langsung di poll().
#endif
}

#if defined(CONFIG_IDF_TARGET_ESP32C3)
bool SensorManager::irCheckActive() const {
  return irCheckAtMs_ != 0;
}

void SensorManager::requestIrCheck() {
  if (!expanderReady_ || irCheckActive()) return;
  digitalWrite(MeditraceConfig::IR_POWER_ENABLE_PIN, HIGH);
  irCheckAtMs_ = millis() + MeditraceConfig::IR_WARMUP_MS;
  irFirstReadOk_ = false;
}

void SensorManager::applyIrReading(uint16_t first, uint16_t second) {
  for (size_t i = 0; i < MeditraceConfig::SENSOR_COUNT; ++i) {
    if (((first >> i) & 1) != ((second >> i) & 1)) {
      irCheckValid_ = false;
      return;
    }
  }
  for (size_t i = 0; i < MeditraceConfig::SENSOR_COUNT; ++i) {
    const bool occupied = ((second >> i) & 1) ==
                          MeditraceConfig::IR_OCCUPIED_LEVEL;
    if (irKnown_ && ir_[i].stable != occupied) {
      queueEvent({SensorEventType::doseChanged, i, ir_[i].stable, occupied});
    }
    ir_[i] = {occupied, occupied, millis()};
  }
  irKnown_ = true;
  irCheckValid_ = true;
}

void SensorManager::updateIrCheck() {
  if (!irCheckActive() ||
      static_cast<int32_t>(millis() - irCheckAtMs_) < 0) {
    return;
  }
  if (!irFirstReadOk_) {
    irFirstReadOk_ = readPorts(irFirstReading_);
    if (!irFirstReadOk_) {
      digitalWrite(MeditraceConfig::IR_POWER_ENABLE_PIN, LOW);
      irCheckAtMs_ = 0;
      expanderReady_ = false;
      irKnown_ = false;
      irCheckValid_ = false;
      retryAtMs_ = millis() + 2000;
      return;
    }
    irCheckAtMs_ = millis() + MeditraceConfig::SENSOR_DEBOUNCE_MS;
    return;
  }
  uint16_t second = 0;
  const bool secondOk = readPorts(second);
  digitalWrite(MeditraceConfig::IR_POWER_ENABLE_PIN, LOW);
  irCheckAtMs_ = 0;
  irFirstReadOk_ = false;
  if (!secondOk) {
    expanderReady_ = false;
    irKnown_ = false;
    irCheckValid_ = false;
    retryAtMs_ = millis() + 2000;
    return;
  }
  applyIrReading(irFirstReading_, second);
}
#endif

bool SensorManager::updateInput(uint8_t pin, bool activeLevel,
                                DebouncedInput& input, bool& previous,
                                bool& current) {
  const bool raw = digitalRead(pin) == activeLevel;
  if (raw != input.raw) {
    input.raw = raw;
    input.changedAt = millis();
  }
  if (raw == input.stable ||
      millis() - input.changedAt < MeditraceConfig::SENSOR_DEBOUNCE_MS) {
    return false;
  }
  previous = input.stable;
  input.stable = raw;
  current = input.stable;
  return true;
}

bool SensorManager::poll(SensorEvent& event) {
#if defined(CONFIG_IDF_TARGET_ESP32C3)
  updateIrCheck();
  if (eventCount_ > 0) {
    event = events_[eventHead_];
    eventHead_ = (eventHead_ + 1) % 12;
    --eventCount_;
    return true;
  }
  if (!expanderReady_) {
    if (static_cast<int32_t>(millis() - retryAtMs_) >= 0) {
      expanderReady_ = beginExpander();
      retryAtMs_ = millis() + 2000;
      if (expanderReady_) {
        requestIrCheck();
        nextInputReadAtMs_ = millis();
      }
    }
    return false;
  }
  if (static_cast<int32_t>(millis() - nextInputReadAtMs_) < 0) {
    return false;
  }
  nextInputReadAtMs_ = millis() + MeditraceConfig::PCF_INPUT_POLL_INTERVAL_MS;

  uint16_t ports;
  if (!readPorts(ports)) {
    expanderReady_ = false;
    irKnown_ = false;
    irCheckValid_ = false;
    retryAtMs_ = millis() + 2000;
    return false;
  }
  bool reedChanged = false;
  bool doorOpened = false;
  bool doorClosed = false;
  for (size_t i = 0; i < MeditraceConfig::REED_COUNT; ++i) {
    auto& input = reed_[i];
    const bool raw = ((ports >> (i + 8)) & 1) ==
                     MeditraceConfig::REED_CLOSED_LEVEL;
    if (raw != input.raw) {
      input.raw = raw;
      input.changedAt = millis();
    }
    if (raw != input.stable &&
        millis() - input.changedAt >= MeditraceConfig::SENSOR_DEBOUNCE_MS) {
      queueEvent({SensorEventType::doorChanged, i, input.stable, raw});
      doorOpened = doorOpened || !raw;
      doorClosed = doorClosed || raw;
      input.stable = raw;
      reedChanged = true;
    }
  }
  if (doorOpened) {
    // Pantau isi kompartemen selama aktivitas membuka kotak.
    irMonitorUntilMs_ = millis() + MeditraceConfig::IR_MONITOR_DURATION_MS;
    nextIrMonitorAtMs_ = millis() + MeditraceConfig::IR_MONITOR_INTERVAL_MS;
    requestIrCheck();
  } else if (doorClosed && !anyDoorOpen()) {
    // Pastikan kondisi akhir terbaca sebelum pemancar dimatikan kembali.
    requestIrCheck();
    irMonitorUntilMs_ = 0;
    nextIrMonitorAtMs_ = 0;
  } else if (reedChanged && anyDoorOpen()) {
    requestIrCheck();
  }
  if (irMonitorUntilMs_ != 0 &&
      static_cast<int32_t>(millis() - irMonitorUntilMs_) >= 0) {
    irMonitorUntilMs_ = 0;
    nextIrMonitorAtMs_ = 0;
  } else if (irMonitorUntilMs_ != 0 &&
             static_cast<int32_t>(millis() - nextIrMonitorAtMs_) >= 0) {
    requestIrCheck();
    const uint32_t elapsed = millis() -
                             (irMonitorUntilMs_ -
                              MeditraceConfig::IR_MONITOR_DURATION_MS);
    const uint32_t interval = elapsed < MeditraceConfig::IR_MONITOR_FAST_DURATION_MS
                                  ? MeditraceConfig::IR_MONITOR_INTERVAL_MS
                                  : MeditraceConfig::IR_MONITOR_SLOW_INTERVAL_MS;
    nextIrMonitorAtMs_ = millis() + interval;
  }
  if (eventCount_ == 0) return false;
  event = events_[eventHead_];
  eventHead_ = (eventHead_ + 1) % 12;
  --eventCount_;
  return true;
#else
  for (size_t i = 0; i < MeditraceConfig::SENSOR_COUNT; ++i) {
    bool previous = false;
    bool current = false;
    if (updateInput(MeditraceConfig::IR_SENSOR_PINS[i],
                    MeditraceConfig::IR_OCCUPIED_LEVEL,
                    ir_[i], previous, current)) {
      event = {SensorEventType::doseChanged, i, previous, current};
      return true;
    }
  }
  for (size_t i = 0; i < MeditraceConfig::REED_COUNT; ++i) {
    bool previous = false;
    bool current = false;
    if (updateInput(MeditraceConfig::REED_PINS[i],
                    MeditraceConfig::REED_CLOSED_LEVEL,
                    reed_[i], previous, current)) {
      event = {SensorEventType::doorChanged, i, previous, current};
      return true;
    }
  }
  return false;
#endif
}

bool SensorManager::available() const {
#if defined(CONFIG_IDF_TARGET_ESP32C3)
  return expanderReady_;
#else
  return true;
#endif
}

bool SensorManager::occupied(size_t index) const {
#if defined(CONFIG_IDF_TARGET_ESP32C3)
  return expanderReady_ && irKnown_ &&
         index < MeditraceConfig::SENSOR_COUNT && ir_[index].stable;
#else
  return index < MeditraceConfig::SENSOR_COUNT && ir_[index].stable;
#endif
}

bool SensorManager::doorClosed(size_t index) const {
  return index < MeditraceConfig::REED_COUNT && reed_[index].stable;
}

bool SensorManager::anyDoorOpen() const {
  for (size_t i = 0; i < MeditraceConfig::REED_COUNT; ++i) {
    if (!reed_[i].stable) return true;
  }
  return false;
}

String SensorManager::statusJson() const {
#if defined(CONFIG_IDF_TARGET_ESP32C3)
  if (!expanderReady_ || !irKnown_ || !irCheckValid_) {
    return "{\"sensors\":[],\"doors\":[],\"sensor_valid\":false}";
  }
#endif
  String output = "{\"sensors\":[";
  for (size_t i = 0; i < MeditraceConfig::SENSOR_COUNT; ++i) {
    if (i > 0) output += ',';
    output += ir_[i].stable ? "1" : "0";
  }
  output += "],\"doors\":[";
  for (size_t i = 0; i < MeditraceConfig::REED_COUNT; ++i) {
    if (i > 0) output += ',';
    output += reed_[i].stable ? "1" : "0";
  }
  output += "]";
#if defined(CONFIG_IDF_TARGET_ESP32C3)
  output += ",\"sensor_valid\":true";
#endif
  output += "}";
  return output;
}
