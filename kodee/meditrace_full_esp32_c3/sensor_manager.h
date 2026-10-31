#pragma once

#include <Arduino.h>

#include "config.h"

enum class SensorEventType { none, doseChanged, doorChanged };

struct SensorEvent {
  SensorEventType type = SensorEventType::none;
  size_t sensorId = 0;
  bool previousState = false;
  bool currentState = false;

  bool doseRemoved() const {
    return type == SensorEventType::doseChanged && previousState && !currentState;
  }
};

class SensorManager {
 public:
  void begin();
  bool poll(SensorEvent& event);
  bool occupied(size_t index) const;
  bool doorClosed(size_t index) const;
  bool anyDoorOpen() const;
  bool available() const;
  bool checkIrNow();
  String statusJson() const;

 private:
  struct DebouncedInput {
    bool stable = false;
    bool raw = false;
    uint32_t changedAt = 0;
  };

  bool updateInput(
      uint8_t pin,
      bool activeLevel,
      DebouncedInput& input,
      bool& previous,
      bool& current);

#if defined(CONFIG_IDF_TARGET_ESP32C3)
  bool beginExpander();
  bool readPorts(uint16_t& ports);
  void queueEvent(const SensorEvent& event);
  void requestIrCheck();
  void updateIrCheck();
  void applyIrReading(uint16_t first, uint16_t second);
  bool irCheckActive() const;
  bool expanderReady_ = false;
  bool irKnown_ = false;
  bool irCheckValid_ = false;
  uint32_t retryAtMs_ = 0;
  uint32_t nextInputReadAtMs_ = 0;
  uint32_t nextIrMonitorAtMs_ = 0;
  uint32_t irMonitorUntilMs_ = 0;
  uint32_t irCheckAtMs_ = 0;
  uint16_t irFirstReading_ = 0;
  bool irFirstReadOk_ = false;
  SensorEvent events_[12];
  uint8_t eventHead_ = 0;
  uint8_t eventCount_ = 0;
#endif

  DebouncedInput ir_[MeditraceConfig::SENSOR_COUNT];
  DebouncedInput reed_[MeditraceConfig::REED_COUNT];
};
