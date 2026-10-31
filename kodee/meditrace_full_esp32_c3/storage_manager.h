#pragma once

#include <Arduino.h>
#include <Preferences.h>

class StorageManager {
 public:
  bool begin();
  bool enqueueEvent(const String& payload);
  size_t eventCount() const { return count_; }
  String eventAt(size_t index);
  void clearEvents();
  bool saveConfig(const String& payload);
  String loadConfig();

 private:
  String keyFor(size_t slot) const;
  Preferences preferences_;
  size_t head_ = 0;
  size_t count_ = 0;
};
