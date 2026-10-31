#pragma once

#include <Arduino.h>
#include <functional>
#include <string>

class BleManager {
 public:
  using InfoProvider = std::function<String()>;
  using PayloadHandler = std::function<void(const String&)>;
  using OtaChunkHandler = std::function<void(const std::string&)>;

  void begin(
      InfoProvider infoProvider,
      PayloadHandler commandHandler,
      PayloadHandler configHandler);
  void setOtaChunkHandler(OtaChunkHandler handler);
  void update();
  void notifyStatus(const String& payload);
  void notifyEvent(const String& payload);
  void setConfigValue(const String& payload);

  bool connected() const;
  const String& deviceId() const;
  const String& deviceName() const;
};
