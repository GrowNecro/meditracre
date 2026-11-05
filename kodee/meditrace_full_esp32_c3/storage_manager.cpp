#include "storage_manager.h"

#include "config.h"

bool StorageManager::begin() {
  if (!preferences_.begin("meditrace", false)) {
    return false;
  }
  head_ = preferences_.getUInt("event_head", 0) % MeditraceConfig::MAX_OFFLINE_EVENTS;
  count_ = min(
      static_cast<size_t>(preferences_.getUInt("event_count", 0)),
      MeditraceConfig::MAX_OFFLINE_EVENTS);
  return true;
}

bool StorageManager::enqueueEvent(const String& payload) {
  size_t slot = (head_ + count_) % MeditraceConfig::MAX_OFFLINE_EVENTS;
  if (count_ == MeditraceConfig::MAX_OFFLINE_EVENTS) {
    slot = head_;
    head_ = (head_ + 1) % MeditraceConfig::MAX_OFFLINE_EVENTS;
  } else {
    ++count_;
  }
  const bool written = preferences_.putString(keyFor(slot).c_str(), payload) > 0;
  preferences_.putUInt("event_head", head_);
  preferences_.putUInt("event_count", count_);
  return written;
}

String StorageManager::eventAt(size_t index) {
  if (index >= count_) {
    return "";
  }
  const size_t slot = (head_ + index) % MeditraceConfig::MAX_OFFLINE_EVENTS;
  return preferences_.getString(keyFor(slot).c_str(), "");
}

void StorageManager::clearEvents() {
  for (size_t i = 0; i < count_; ++i) {
    const size_t slot = (head_ + i) % MeditraceConfig::MAX_OFFLINE_EVENTS;
    preferences_.remove(keyFor(slot).c_str());
  }
  head_ = 0;
  count_ = 0;
  preferences_.putUInt("event_head", 0);
  preferences_.putUInt("event_count", 0);
}

bool StorageManager::saveConfig(const String& payload) {
  return preferences_.putString("device_config", payload) > 0;
}

String StorageManager::loadConfig() {
  return preferences_.getString("device_config", "{}");
}

uint32_t StorageManager::loadBatteryUsedMs() {
  return preferences_.getUInt("battery_used_ms", 0);
}

bool StorageManager::saveBatteryUsedMs(uint32_t usedMs) {
  return preferences_.putUInt("battery_used_ms", usedMs) == sizeof(usedMs);
}

String StorageManager::keyFor(size_t slot) const {
  return String("event_") + slot;
}
