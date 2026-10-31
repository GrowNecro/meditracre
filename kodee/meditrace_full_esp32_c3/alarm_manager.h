#pragma once

#include <Arduino.h>

class AlarmManager {
 public:
  void begin();
  void update();
  void start(uint32_t durationMs);
  void stop();
  void setLed(bool enabled);
  void setBuzzer(bool enabled);

  bool ledState() const { return ledState_; }
  bool buzzerState() const { return buzzerState_; }
  bool active() const { return active_; }

 private:
  void applyLed();
  bool ledState_ = false;
  bool buzzerState_ = false;
  bool active_ = false;
  uint32_t stopAtMs_ = 0;
};
