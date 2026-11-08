# Firmware MEDITRACE ESP32-C3

Firmware **0.9.7** untuk kotak obat **5 kompartemen**, dengan BLE, sensor isi/pintu,
buzzer, penyimpanan konfigurasi/event offline, estimasi baterai, dan OTA BLE.
Konfigurasi sumber: [`config.h`](meditrace_full_esp32_c3/config.h).

## Hardware dan pin

| Fungsi | Pin / sambungan |
| --- | --- |
| Buzzer | GPIO3 melalui driver transistor |
| SDA / SCL PCF8575 | GPIO5 / GPIO6 |
| INT PCF8575 | GPIO4 disiapkan; belum dipakai untuk interrupt |
| Sakelar daya pemancar IR | GPIO7, EN aktif HIGH |
| LED board | GPIO8 aktif LOW; `STATUS_LED_ENABLED = false` |
| GPIO0 / ADC baterai | Tidak dipakai oleh mode estimasi firmware 0.9.7 |
| RTC DS3231 | Tidak digunakan |

PCF8575 dipindai pada alamat `0x20–0x27`, dengan prioritas `0x21`.
VCC dan pull-up I²C memakai 3,3 V; semua GND beban bersama dengan ESP32-C3.
Output sensor ke input PCF8575 harus sesuai rel logika 3,3 V.
GPIO7 mengendalikan sakelar daya, bukan menyuplai kelima pemancar langsung.

| Ruang | Penerima IR break-beam | Limit switch pintu NC |
| --- | --- | --- |
| 1 | P00 | P10 |
| 2 | P01 | P11 |
| 3 | P02 | P12 |
| 4 | P03 | P13 |
| 5 | P04 | P14 |

P05/P15 tidak dipakai. Pada pemasangan saat ini, IR **HIGH** berarti beam
terhalang/obat ada. COM limit switch ke P10–P14 dan NC ke GND: pintu tertutup
menekan switch sehingga kontak NC terbuka dan input terbaca **HIGH**; **LOW**
berarti pintu terbuka. Polaritas diatur oleh `IR_OCCUPIED_LEVEL` dan
`LIMIT_SWITCH_CLOSED_LEVEL`.

Input pintu dipoll setiap 20 ms dengan debounce 80 ms. IR diperiksa saat boot,
`GET_SENSOR`, dan perubahan pintu. Selama pintu terbuka, IR dibaca tiap
2 detik pada menit pertama, lalu tiap 5 detik hingga batas 2 menit; penutupan
pintu memicu pemeriksaan terakhir. Kegagalan sensor menghasilkan
`sensor_valid:false`, bukan status semua ruang kosong.

## BLE, waktu, dan jadwal

Nama advertising: **`MEDITRACE-C3-XXXX`**. UUID service/characteristic ada di
`config.h` dan [protokol BLE](../docs/ble-protocol.md).

Advertising memakai interval **100–150 ms** dan TX **0 dBm**. Saat tersambung,
firmware meminta connection interval 100–200 ms, slave latency 4, supervision
timeout 6 detik; ponsel dapat menegosiasikan nilai lain. Belum ada deep sleep
atau BLE berkala.

Waktu disinkronkan dari HP melalui `SYNC_TIME:<unix-seconds>` setelah koneksi.
Firmware tidak menjalankan jadwal obat secara mandiri. Aplikasi mengelola
jadwal, notifikasi, dan pemicu buzzer selama aktif serta tersambung.
Event tanpa waktu tersinkron mendapat waktu penerimaan dari aplikasi.

## Estimasi baterai

Baterai acuan berlabel **3,7 V 1500 mAh**. Firmware memperkirakan pemakaian
berdasarkan waktu aktif dan arus rata-rata **150 mA**: sekitar **10 jam** dari
penuh atau turun **1% tiap 6 menit**. Ini bukan pengukuran tegangan GPIO0 atau
bukti runtime nyata.

INFO/STATUS menyertakan `battery`, `battery_estimated:true`, dan
`battery_voltage:null`. Status berkala dikirim setiap 30 detik. Pemasangan
pertama mengasumsikan 100%; pengisian tidak terdeteksi otomatis. Setelah dicas
penuh, pilih **Perangkat → Detail perangkat → Tandai baterai penuh** di APK.
Perintah `BATTERY_FULL` mereset estimasi setelah konfirmasi pengguna.

Pemakaian disimpan di NVS setiap 5 menit dan sebelum restart normal/OTA.
Restart tidak otomatis mereset persentase. Mati mendadak dapat kehilangan
catatan sekitar 5 menit. Waktu mati, pengosongan alami, penuaan sel, dan beban
sebenarnya tidak diperhitungkan. Konstanta kapasitas/arus ada di `config.h`.

## Build dan upload

Dari root repository:

```powershell
cd kodee/meditrace_full_esp32_c3
pio run
pio run --target upload
```

Binary aplikasi berada di `.pio/build/esp32-c3/firmware.bin`. Upload pertama
menggunakan USB/PlatformIO; binary ini juga menjadi payload OTA.
Project memakai board `esp32-c3-devkitm-1` dan framework Arduino.
Dependensi `platformio.ini`: NimBLE-Arduino dan RTClib; DS3231 tetap tidak
dipakai oleh implementasi saat ini.

Untuk Arduino IDE, buka `meditrace_full_esp32_c3.ino`, pilih **ESP32C3 Dev Module**,
dan pasang library sesuai project. Serial Monitor: **115200 baud**.
Perintah diagnostik mencakup `HELP`, `DIAG`, `I2C`, `SENSOR`, `TEST`.

## OTA dan GitHub Release

Pilih **Perangkat → Update firmware terbaru** atau **Pilih file .bin lokal**
di aplikasi. Transfer dimulai setelah konfirmasi. Perangkat memverifikasi
ukuran/CRC32, lalu restart setelah berhasil. BLE putus sementara dan aplikasi
mencoba reconnect saat perangkat tersedia lagi. Jaga daya/koneksi selama transfer.

Asset release harus bernama **`meditrace-esp32-c3.bin`**. Workflow
[release.yml](../.github/workflows/release.yml) membangun firmware dan APK saat
tag `v*` dipush. Firmware diunduh dari:

`https://github.com/GrowNecro/meditracre/releases/latest/download/meditrace-esp32-c3.bin`

Belum ada pemeriksaan versi atau pemasangan otomatis. Reconnect diatur APK:
jeda awal 0,5 detik dan retry 2 detik, ditambah durasi scan/koneksi.
Pemutusan manual menonaktifkan reconnect sampai pairing manual lagi.
