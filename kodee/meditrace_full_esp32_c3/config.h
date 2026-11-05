#pragma once

#include <Arduino.h>

namespace MeditraceConfig {

inline constexpr char FIRMWARE_VERSION[] = "0.9.6";
inline constexpr bool DEBUG_LOGS = false;

inline constexpr char SERVICE_UUID[] = "7d2ea28a-f7bd-485a-bd9d-92ad6ecfe001";
inline constexpr char DEVICE_INFO_UUID[] = "7d2ea28a-f7bd-485a-bd9d-92ad6ecfe002";
inline constexpr char COMMAND_UUID[] = "7d2ea28a-f7bd-485a-bd9d-92ad6ecfe003";
inline constexpr char STATUS_UUID[] = "7d2ea28a-f7bd-485a-bd9d-92ad6ecfe004";
inline constexpr char CONFIG_UUID[] = "7d2ea28a-f7bd-485a-bd9d-92ad6ecfe005";
inline constexpr char EVENT_UUID[] = "7d2ea28a-f7bd-485a-bd9d-92ad6ecfe006";
inline constexpr char OTA_UUID[] = "7d2ea28a-f7bd-485a-bd9d-92ad6ecfe007";

// Receiver break-beam yang terpasang mengeluarkan HIGH ketika beam terhalang.
// Beam terhalang berarti obat masih berada di kompartemen.
inline constexpr bool IR_OCCUPIED_LEVEL = HIGH;
// Limit switch NC pintu: COM ke P10..P14 dan NC ke GND. Pada pemasangan alat
// saat ini, pintu tertutup menekan limit sehingga kontak NC terbuka dan
// PCF8575 membaca HIGH. LOW berarti pintu terbuka.
inline constexpr bool LIMIT_SWITCH_CLOSED_LEVEL = HIGH;
// Alias kompatibilitas untuk modul sensor yang sebelumnya bernama "reed".
inline constexpr bool REED_CLOSED_LEVEL = LIMIT_SWITCH_CLOSED_LEVEL;

// Profil pin dipilih otomatis dari target board di Arduino IDE/PlatformIO.
#if defined(CONFIG_IDF_TARGET_ESP32C3)
inline constexpr size_t SENSOR_COUNT = 5;
inline constexpr size_t REED_COUNT = 5;
static_assert(SENSOR_COUNT == REED_COUNT && SENSOR_COUNT <= 8,
              "PCF8575: IR di port 0 dan saklar pintu di port 1 harus berpasangan");
inline constexpr uint8_t PCF8575_PREFERRED_ADDRESS = 0x21;
inline constexpr char BOARD_TYPE[] = "ESP32-C3";
inline constexpr char DEVICE_NAME_PREFIX[] = "MEDITRACE-C3-";
inline constexpr uint8_t LED_PIN = 8;
inline constexpr uint8_t BUZZER_PIN = 3;
inline constexpr bool LED_ACTIVE_LOW = true;
inline constexpr bool STATUS_LED_ENABLED = false;
// Bus I2C hanya untuk PCF8575. RTC DS3231 tidak digunakan pada versi alat ini.
inline constexpr uint8_t I2C_SDA_PIN = 5;
inline constexpr uint8_t I2C_SCL_PIN = 6;
inline constexpr uint8_t PCF8575_INT_PIN = 4;
inline constexpr uint8_t IR_POWER_ENABLE_PIN = 7; // EN load switch pemancar IR, aktif HIGH.
inline constexpr uint8_t BATTERY_ADC_PIN = 0;
inline constexpr float BATTERY_DIVIDER_RATIO = 2.0f; // 100k / 100k.
inline constexpr uint32_t BATTERY_READ_INTERVAL_MS = 30'000;
inline constexpr uint32_t IR_WARMUP_MS = 100;
// Pemancar IR hanya aktif setelah pintu berubah atau saat diminta aplikasi.
// Tidak ada polling periodik agar pemancar tidak menguras baterai saat idle.
inline constexpr uint32_t IR_MONITOR_INTERVAL_MS = 2000;
inline constexpr uint32_t IR_MONITOR_SLOW_INTERVAL_MS = 5000;
inline constexpr uint32_t IR_MONITOR_FAST_DURATION_MS = 60000;
inline constexpr uint32_t IR_MONITOR_DURATION_MS = 120000;
// Pintu tetap dipantau lebih sering, tetapi tidak perlu dibaca pada setiap
// iterasi loop karena perubahan mekanis sudah didebounce.
// Limit switch harus terasa hampir real-time; debounce tetap mencegah
// bouncing mekanis menghasilkan event palsu.
inline constexpr uint32_t PCF_INPUT_POLL_INTERVAL_MS = 20;
#elif defined(CONFIG_IDF_TARGET_ESP32)
inline constexpr size_t SENSOR_COUNT = 2;
inline constexpr size_t REED_COUNT = 1;
inline constexpr char BOARD_TYPE[] = "ESP32-CLASSIC";
inline constexpr char DEVICE_NAME_PREFIX[] = "MEDITRACE-CLASSIC-";
inline constexpr uint8_t LED_PIN = 2;
inline constexpr uint8_t BUZZER_PIN = 25;
inline constexpr bool LED_ACTIVE_LOW = false;
inline constexpr uint8_t IR_SENSOR_PINS[SENSOR_COUNT] = {32, 33};
inline constexpr uint8_t REED_PINS[REED_COUNT] = {27};
#else
#error "Target tidak didukung. Gunakan ESP32 Dev Module atau ESP32C3 Dev Module."
#endif

inline constexpr uint32_t SENSOR_DEBOUNCE_MS = 80;
inline constexpr uint32_t ALARM_DURATION_MS = 30'000;
inline constexpr size_t MAX_OFFLINE_EVENTS = 24;
inline constexpr size_t MAX_SCHEDULES = 8;

}  // namespace MeditraceConfig
