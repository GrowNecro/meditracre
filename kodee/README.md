# Firmware MEDITRACE

Folder ini hanya berisi firmware produksi untuk **ESP32-C3**.

- Project PlatformIO: [`meditrace_full_esp32_c3`](./meditrace_full_esp32_c3)
- Dokumentasi wiring dan OTA: [`README_FULL_FIRMWARE.md`](./README_FULL_FIRMWARE.md)

Build dari project firmware:

```powershell
cd D:\Work\flutter\medbox\kodee\meditrace_full_esp32_c3
pio run
pio run --target upload
```

Binary untuk GitHub Release:

```powershell
Copy-Item .pio\build\esp32-c3\firmware.bin meditrace-esp32-c3.bin
```

Nama asset release harus `meditrace-esp32-c3.bin` agar aplikasi dapat mengambil
firmware terbaru melalui GitHub Releases.
