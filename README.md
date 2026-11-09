# MEDITRACE

Kotak obat lima kompartemen dengan aplikasi Android, pemantauan isi dan pintu
melalui ESP32-C3/Bluetooth Low Energy, serta fitur keluarga.

## Spesifikasi produk saat ini

| Bagian | Spesifikasi |
| --- | --- |
| Aplikasi | Flutter Android, package `com.example.meditrace`, versi `1.0.5+11` |
| Firmware | ESP32-C3, versi `0.9.7` |
| Kompartemen | 5 ruang dengan sensor IR break-beam dan limit switch pintu NC |
| Ekspander input | PCF8575 pada I²C GPIO5/GPIO6; alamat `0x20–0x27`, prioritas `0x21` |
| Buzzer | GPIO3 melalui driver transistor |
| Daya pemancar IR | GPIO7 mengendalikan EN sakelar daya, aktif HIGH |
| LED board | GPIO8, aktif LOW; dinonaktifkan dalam konfigurasi saat ini |
| Koneksi | BLE `MEDITRACE-C3-XXXX`; scanner juga menerima nama lama `MEDBOX-*` |
| Jadwal dan riwayat | Lokal pada HP, SQLite `meditrace_local.db` |
| Sumber waktu | Ponsel; DS3231/RTC eksternal tidak digunakan |
| Baterai acuan | Li-ion 1 sel berlabel 3,7 V 1500 mAh |
| Indikator baterai | Estimasi waktu aktif dengan asumsi 150 mA; bukan pengukuran tegangan |
| Keluarga | Google Sign-In/Firebase Auth, Firestore, dan API keluarga HTTP Worker |
| Pembaruan | APK dan firmware dari GitHub Releases, dipilih manual oleh pengguna |

## Fitur dan batasan

- Jadwal harian dan notifikasi HP. Jadwal baru cukup memilih jam, tanpa wajib
  memilih ruang. Buzzer alat dipicu aplikasi saat aktif dan BLE tersambung;
  firmware belum menjalankan jadwal secara mandiri.
- Lima status isi dan pintu. Pengambilan obat diproses sebagai konfirmasi
  berdasarkan sensor; ini bukan bukti obat benar-benar ditelan. Tombol
  **Sudah minum** dan pembatalan tersedia. Pengembalian ke ruang yang sama
  dalam 15 menit dapat membatalkan catatan konfirmasi sebelumnya.
- Pairing disimpan. Setelah putus tak disengaja, reconnect mulai dicoba setelah
  0,5 detik; jeda retry 2 detik, di luar durasi scan/koneksi. Putus manual
  menonaktifkan reconnect sampai perangkat dipilih secara manual lagi.
- Pasien diperingatkan setelah BLE putus 30 detik; eskalasi keluarga 5 menit
  kemudian jika belum pulih. Tombol **Saya meninggalkan MEDITRACE** tersedia
  untuk melaporkan langsung. Keluarga membutuhkan login, grup, internet,
  dan backend yang dikonfigurasi.
- Estimasi baterai dari penuh sekitar 10 jam, atau turun 1% tiap 6 menit aktif.
  Setelah dicas penuh, pilih **Perangkat → Detail perangkat → Tandai baterai penuh**.
  Pengisian tidak dideteksi otomatis; durasi nyata dapat berbeda.
- Belum ada pengingat versi baru atau instalasi APK/firmware otomatis. Android
  yang menghentikan aplikasi dapat menghentikan BLE dan pemrosesan peringatan.

## Menggunakan dan memperbarui

1. Instal `meditrace.apk` dari [GitHub Releases](https://github.com/GrowNecro/meditracre/releases/latest).
2. Nyalakan kotak obat, izinkan Bluetooth/notifikasi, lalu cari dan hubungkan
   MEDITRACE. Fitur lokal dapat digunakan sebagai tamu; login untuk keluarga.
3. Tambahkan jadwal di tab **Jadwal** dan lihat isi/pintu di **Home** atau **Perangkat**.
4. Untuk APK baru, pilih **Profil → Perbarui aplikasi**, lalu unduh dan instal manual.
5. Untuk firmware, pilih **Perangkat → Update firmware terbaru**, lalu konfirmasi.
   Aplikasi mengambil `meditrace-esp32-c3.bin` dan mengirim melalui BLE.
   Pilihan file `.bin` lokal juga tersedia. Alat restart setelah update berhasil;
   BLE putus sementara dan aplikasi mencoba reconnect.

## Struktur proyek

| Folder | Isi |
| --- | --- |
| [meditrace_app/](meditrace_app/README.md) | Aplikasi Android, konfigurasi, dan pengujian |
| [kodee/](kodee/README.md) | Firmware ESP32-C3 dan [spesifikasi firmware](kodee/README_FULL_FIRMWARE.md) |
| [meditrace_worker/](meditrace_worker/README.md) | API HTTP keluarga, Firebase, FCM, email Resend |
| [firebase_backend/](firebase_backend/README.md) | Implementasi Cloud Functions alternatif dan Firestore Rules |
| [meditrace_dummy/](meditrace_dummy/README.md) | Simulator BLE Android untuk pengujian |
| [docs/](docs/) | Rangkaian, protokol, arsitektur, dan catatan pengujian |

## Build dan release

Lihat [README aplikasi](meditrace_app/README.md) untuk Flutter dan
[README firmware](kodee/README_FULL_FIRMWARE.md) untuk build/upload ESP32-C3.

Workflow [Release MEDITRACE](.github/workflows/release.yml) berjalan saat tag
`v*` dipush, membangun `meditrace.apk` dan `meditrace-esp32-c3.bin`, lalu
menerbitkan keduanya sebagai asset release.

Repository secret **`GOOGLE_SERVICES_JSON`** wajib berisi seluruh JSON
konfigurasi Firebase Android untuk `com.example.meditrace`. Build berhenti
jika secret kosong. File konfigurasi lokal, service account, dan hasil build
diabaikan Git. Service account tidak dimasukkan ke APK.

APK release memakai keystore tetap, dengan empat secret signing Android.
Ikuti [panduan signing dan fingerprint Firebase](docs/android-signing.md)
sebelum membuat tag release berikutnya. Build release gagal jika signing belum
dikonfigurasi; debug key hanya digunakan untuk build debug.
