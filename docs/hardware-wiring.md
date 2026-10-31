# Wiring MEDITRACE ESP32-C3 (5 kompartemen)

Lihat [gambar rangkaian lengkap](rangkaian-meditrace-c3-5-kompartemen.svg) dan
[gambar sakelar IR dari komponen langsung](sakelar-ir-komponen-langsung.svg).
Keduanya mengikuti `kodee/meditrace_full_esp32_c3/config.h`; gambar menunjukkan sambungan
fungsional, bukan nomor kaki fisik tiap modul.

| Fungsi | ESP32-C3 / PCF8575 | Sambungan |
| --- | --- | --- |
| I²C SDA | GPIO5 | SDA PCF8575 |
| I²C SCL | GPIO6 | SCL PCF8575 |
| PCF8575 INT | GPIO4 | Opsional, sesuai firmware |
| Sakelar daya pemancar IR | GPIO7 | Basis 2N3904 melalui 10 kΩ; driver gate AO3401A |
| Buzzer | GPIO3 | Melalui driver transistor, bukan beban besar langsung ke GPIO |
| LED board | GPIO8 | Opsional, aktif LOW sesuai firmware |
| Penerima break-beam 1–5 | PCF P00–P04 | OUT masing-masing penerima, VCC 3,3 V dan GND |
| Reed pintu 1–5 | PCF P10–P14 | Kontak masing-masing ke GND |
| Alamat PCF8575 | A0, A1, A2 ke GND | Alamat I²C 0x20 |

Semua GND beban harus bersama. Pull-up SDA/SCL hanya ke 3,3 V. Verifikasi tegangan kerja pemancar/penerima break-beam sebelum merakit. ESP32-C3
tidak memakai RTC hardware; waktu disinkronkan dari aplikasi setelah BLE tersambung.
Jika memakai LED IR polos, pasang resistor pembatas untuk setiap LED.
Jangan menghubungkan keluaran 5 V sensor langsung ke input PCF8575 3,3 V.
