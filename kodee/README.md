# Firmware MEDITRACE

Folder ini hanya berisi firmware produksi untuk **ESP32-C3**.

Versi saat ini **0.9.7** untuk **5 kompartemen**, dengan IR break-beam,
limit switch pintu NC, PCF8575, buzzer, OTA BLE, dan estimasi baterai berbasis
waktu aktif. RTC eksternal dan ADC baterai tidak digunakan pada mode ini.

- Project PlatformIO: [`meditrace_full_esp32_c3`](./meditrace_full_esp32_c3)
- Dokumentasi wiring dan OTA: [`README_FULL_FIRMWARE.md`](./README_FULL_FIRMWARE.md)

Build dari project firmware:

```powershell
cd kodee/meditrace_full_esp32_c3
pio run
pio run --target upload
```

Binary untuk GitHub Release:

```powershell
Copy-Item .pio\build\esp32-c3\firmware.bin meditrace-esp32-c3.bin
```

Nama asset release harus `meditrace-esp32-c3.bin` agar aplikasi dapat mengambil
firmware terbaru melalui GitHub Releases. Workflow `.github/workflows/release.yml`
juga membuat APK `meditrace.apk` dan firmware tersebut otomatis saat tag `v*`
dipush ke GitHub.

Update pada alat tetap manual melalui halaman **Perangkat** aplikasi.
Push tag tidak langsung memperbarui alat. Perangkat restart setelah OTA
berhasil, kemudian aplikasi mencoba reconnect. Lihat panduan lengkap untuk
pin, polaritas sensor, asumsi estimasi baterai, dan jadwal dari ponsel.
