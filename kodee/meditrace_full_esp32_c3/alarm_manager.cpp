#include "alarm_manager.h"

#include "config.h"

void AlarmManager::begin() {
  if (MeditraceConfig::STATUS_LED_ENABLED) {
    pinMode(MeditraceConfig::LED_PIN, OUTPUT);
  }
  pinMode(MeditraceConfig::BUZZER_PIN, OUTPUT);
  stop();
}

void AlarmManager::update() {
  if (active_ && static_cast<int32_t>(millis() - stopAtMs_) >= 0) {
    stop();
  }
}

void AlarmManager::start(uint32_t durationMs) {
  active_ = true;
  setLed(true);
  setBuzzer(true);
  stopAtMs_ = millis() + durationMs;
}

void AlarmManager::stop() {
  active_ = false;
  setLed(false);
  setBuzzer(false);
}

void AlarmManager::setLed(bool enabled) {
  ledState_ = enabled;
  applyLed();
}

void AlarmManager::setBuzzer(bool enabled) {
  buzzerState_ = enabled;
  digitalWrite(MeditraceConfig::BUZZER_PIN, enabled ? HIGH : LOW);
}

void AlarmManager::applyLed() {
  if (!MeditraceConfig::STATUS_LED_ENABLED) return;
  const uint8_t level = (ledState_ != MeditraceConfig::LED_ACTIVE_LOW) ? HIGH : LOW;
  digitalWrite(MeditraceConfig::LED_PIN, level);
}
