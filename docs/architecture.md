# Arsitektur MEDITRACE

```text
ESP32-C3 + sensor/RTC/alarm
          ↕ BLE
Flutter Android (gateway)
          ↕ HTTPS
Laravel API → MySQL → push caregiver
```

## Status implementasi

- Phase 1: Flutter scan/connect/read/write/notify dan firmware BLE tersedia.
- Phase 2: modul sensor IR/reed, RTC DS3231, alarm, dan NVS tersedia; menunggu
  validasi pada hardware fisik.
- Phase 3–5: belum diimplementasikan.
- Phase 6: belum dimulai; PHP dan Composer belum tersedia di mesin ini.
- Phase 7–8: belum dimulai.

Flutter memakai `BleService` sebagai batas antara UI/state dan plugin Bluetooth.
Dengan demikian BLE dapat di-mock pada test dan implementasi plugin dapat diganti
tanpa mengubah layar.
