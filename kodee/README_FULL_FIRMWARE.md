# Firmware MEDITRACE ESP32-C3

Firmware menyediakan BLE MEDITRACE, sinkronisasi waktu dari ponsel, buzzer,
jadwal obat, penyimpanan konfigurasi/event offline, dan OTA melalui BLE.

## Build ESP32-C3

Buka `meditrace_full_esp32_c3/meditrace_full_esp32_c3.ino`, lalu pilih
**ESP32C3 Dev Module**.

| Fungsi | GPIO |
|---|---:|
| LED | 8 |
| Buzzer | 3 |
| SDA PCF8575 | 5 |
| SCL PCF8575 | 6 |
| INT PCF8575 (disiapkan, belum dipakai firmware) | 4 |
| EN load switch lima pemancar IR (aktif HIGH) | 7 |

Nama BLE: `MEDITRACE-C3-XXXX`.

Dengan PlatformIO:

```powershell
cd D:\Work\flutter\medbox\kodee\meditrace_full_esp32_c3
pio run
pio run --target upload
```

Binary hasil build berada di `.pio/build/esp32-c3/firmware.bin`.
Untuk update online, unggah binary tersebut ke GitHub Release dengan nama asset
`meditrace-esp32-c3.bin`. Aplikasi mengambil asset dari release terbaru melalui
URL:

`https://github.com/GrowNecro/meditracre/releases/latest/download/meditrace-esp32-c3.bin`

## Sinkronisasi waktu dan update BLE

ESP32-C3 tidak memiliki RTC hardware. Setelah setiap boot/reset, aplikasi harus
mengirim `SYNC_TIME:<unix-seconds>` sebelum timer jadwal perangkat diaktifkan.
Aplikasi melakukan sinkronisasi otomatis saat BLE tersambung.

Update firmware dapat dilakukan dari halaman **Perangkat** aplikasi dengan file
`.bin` hasil build PlatformIO. Transfer memakai characteristic OTA BLE, ukuran
dan CRC32 diverifikasi di perangkat, lalu ESP32 restart hanya setelah transfer
valid. Jangan memutus koneksi atau mematikan perangkat selama proses update.

Hubungkan PCF8575 dengan **VCC 3,3 V** dan GND bersama ESP32-C3. A0, A1,
Firmware memindai alamat PCF8575 `0x20–0x27` dan memprioritaskan `0x21`, sehingga
perubahan jumper A0–A2 tidak memerlukan perubahan kode. Pasang pull-up I²C ke
**3,3 V**, jangan ke 5 V. Gunakan
**PCF8575**, bukan PCF8575C (varian C memerlukan tegangan suplai lebih tinggi).

| Kanal kotak | Input IR digital | Reed switch |
|---|---|---|
| 1 | P00 | P10 |
| 2 | P01 | P11 |
| 3 | P02 | P12 |
| 4 | P03 | P13 |
| 5 | P04 | P14 |

P05 dan P15 tidak dipakai. Keluaran digital **penerima** break-beam masuk
P00–P04; VCC kelima penerima tetap pada rel 3,3 V. Daya kelima **pemancar**
boleh lewat load switch aktif-HIGH yang dikendalikan GPIO7. Cocokkan tegangan,
arus, dan polaritas OUT dengan datasheet modul sensor yang dipakai.

Sisi lain setiap reed ke GND. Kode menganggap reed tertutup = LOW dan output
IR mendeteksi obat = LOW. Jika modul IR Anda bekerja sebaliknya, ubah
`REED_CLOSED_LEVEL` atau `IR_OCCUPIED_LEVEL` di `meditrace_full_esp32_c3/config.h`.
Output IR ke PCF8575 **tidak boleh melebihi 3,3 V**; modul IR 5 V perlu
level shifter atau output open-collector dengan pull-up ke 3,3 V. Port
PCF8575 mempunyai pull-up internal yang lemah; untuk kabel reed panjang,
pertimbangkan pull-up eksternal ke 3,3 V dan penyaringan gangguan.

GPIO7 hanya mengendalikan pin EN **load switch high-side aktif HIGH** yang
menyuplai VCC kelima pemancar IR. Jangan memberi daya pemancar langsung dari
GPIO7. Jika belum ada load switch, pemancar dapat diberi daya terus untuk uji
awal, tetapi konsumsi baterai meningkat dan kendali GPIO7 tidak berfungsi.
Periksa kebutuhan arus modul IR dan kemampuan load switch sebelum merakit.

IR dinyalakan sebentar saat boot dan perintah `GET_SENSOR`. Saat pintu dibuka,
IR memantau setiap 2 detik selama maksimal 2 menit; saat pintu ditutup,
dilakukan satu pembacaan terakhir. Bila pembacaan I²C/IR gagal, firmware
mengirim
`sensor_valid:false` dengan daftar sensor kosong, bukan menganggap kotak
kosong. Reed dipantau setiap 20 ms ketika ESP32-C3 aktif, dengan debounce 80
ms sehingga perubahan stabil terdeteksi sekitar 80–100 ms. GPIO4/INT belum
digunakan untuk interrupt. BLE memakai daya TX 0 dBm dan advertising 400–1000
ms untuk mengurangi konsumsi. IR memantau tiap 2 detik pada 60 detik pertama,
lalu tiap 5 detik sampai batas 2 menit; firmware ini **belum menerapkan deep sleep
atau BLE berkala**.

Saat ponsel tersambung, firmware meminta connection interval 100–200 ms dengan
slave latency 4 dan supervision timeout 6 detik. Ponsel dapat menegosiasikan
nilai lain, tetapi konfigurasi ini mengurangi event radio saat koneksi idle
tanpa memutus koneksi BLE.

Untuk baterai 1500 mAh, ukur arus pada sisi baterai setelah optimasi. Runtime
10 jam berarti rata-rata sekitar 150 mA dari baterai; angka ini sering lebih
besar daripada konsumsi idle ESP32-C3 dan mengindikasikan pemancar IR, buzzer,
peripheral 5 V, atau step-up sebagai beban utama. Load switch GPIO7 wajib
benar-benar memutus VCC pemancar IR saat LOW; mengubah GPIO saja tidak cukup
jika pemancar masih terhubung langsung ke rel 5 V.

## Pemantauan baterai

ESP32-C3 membaca baterai Li-ion 1 sel melalui pembagi tegangan 100 kΩ + 100 kΩ
ke GPIO0. Hubungkan resistor atas ke **B+ TP4056**, titik tengah ke GPIO0, dan
resistor bawah ke GND. Kapasitor polar 100 nF dipasang dengan kaki positif di
titik tengah dan kaki negatif ke GND. B− TP4056, GND ESP32-C3, dan GND converter
harus tersambung bersama. Nilai baterai dikirim melalui field `battery` dan
`battery_voltage` pada status BLE.

## Library Arduino IDE

Install melalui Library Manager:

- **NimBLE-Arduino by h2zero**
- **RTClib by Adafruit**

Serial Monitor menggunakan **115200 baud**.
