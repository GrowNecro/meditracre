# MEDITRACE Dummy

Aplikasi Android kedua yang mensimulasikan perangkat MEDITRACE lewat BLE. Sensor IR dan reed
switch di layar adalah **nilai buatan**, bukan pembacaan sensor fisik HP.

Selain BLE, dummy ini juga menyediakan panel pengujian Worker/notifikasi dan
kontrol massal status obat, kompartemen, baterai, RSSI, serta koneksi BLE.

APK dummy memakai application ID `com.example.meditrace_dummy`, sehingga dapat
dipasang berdampingan dengan aplikasi utama. Firebase hanya aktif jika
konfigurasi Android untuk application ID ini disediakan; fungsi BLE tetap dapat
dipakai tanpa Firebase.

## Menjalankan

```powershell
flutter run
```

Atau buat APK dengan `flutter build apk --debug`; hasilnya di
`build/app/outputs/flutter-apk/app-debug.apk`.

1. Pasang **MEDITRACE Dummy** di HP kedua yang mendukung BLE Peripheral/advertising.
2. Aktifkan Bluetooth dan izinkan akses *Perangkat terdekat*, lalu tekan
   **Mulai siarkan MEDITRACE Dummy**. Sebelum mulai, Anda dapat mengubah nama
   BLE pada kolom **Nama perangkat BLE**. Android memakai nama Bluetooth HP
   kedua itu sementara selama penyiaran; nama semula dipulihkan saat siaran
   dihentikan. Biarkan aplikasi terbuka selama pengujian.
3. Di HP pertama, buka aplikasi MEDITRACE utama → cari perangkat → pilih entri
   dengan nama BLE yang dipilih atau service UUID MEDITRACE. ID internal tetap
   `MEDITRACE-DUMMY`, sedangkan `device_info` menampilkan nama yang dipilih.
4. Ubah sakelar **Obat ada/kosong** (IR) atau **Pintu tertutup/terbuka** (reed)
   pada HP kedua. Status dan event akan dikirim ke aplikasi utama.
5. Untuk menguji peringatan jarak, pilih **Jauh** di bagian *Simulasi jarak*.
   Dummy mengirim `simulated_rssi: -90` lewat status BLE. Setelah tiga pemeriksaan
   (sekitar 45 detik), aplikasi utama menampilkan peringatan sinyal lemah.
   Pilih **Dekat** (`-60`) untuk menguji pemulihan, atau **RSSI asli** untuk
   kembali memakai kuat sinyal Bluetooth yang sebenarnya.
6. Untuk menguji peringatan tertinggal, tekan **Simulasikan tertinggal (putus
   BLE)**. Dummy menghentikan siaran dan memutus koneksi; aplikasi utama
   memberi notifikasi setelah jeda 2/5/10 menit sesuai pengaturan di Lainnya.
   Mulai siarkan lagi untuk menguji sambung ulang otomatis.
7. Pada **Pemeriksaan sistem**, tekan *Cek Worker* dan pastikan Firebase serta
   email berstatus `OK`. Masukkan email lalu tekan *Login Google & kirim email
   tes*. Tekan *tes push* untuk mengirim notifikasi ke HP dummy.
8. Pada **Kontrol cepat alat dummy**, gunakan isi/kosongkan obat, tutup/buka
   pintu, dan baterai 15%/82% untuk menguji pembaruan massal pada aplikasi
   utama. Kontrol hanya mengirim event apabila BLE sedang disiarkan.

Simulator hanya mensimulasikan ESP32-C3 lima kompartemen. Simulator memakai UUID
dari `meditrace_app/lib/core/constants/ble_constants.dart` dan menyediakan
characteristic `device_info` (read), `command` (write), `status` (read/notify),
`config` (read/write), `event` (notify), serta OTA (write). Perintah
`GET_STATUS`, `GET_SENSOR`, `PING`, `SET_SCHEDULE`, dan perintah dasar lain
direspons untuk pengujian UI. `SYNC_TIME` mengubah `time_synced` menjadi true;
`OTA_BEGIN`, chunk biner, dan `OTA_END` disimulasikan tanpa menulis firmware.
Tidak ada pengingat obat nyata, RTC fisik, penyimpanan kejadian, atau sensor
perangkat keras.

Estimasi baterai dummy menggunakan kapasitas nominal 1500 mAh dan arus rata-rata
150 mA: 100% sekitar 10 jam, 82% sekitar 8 jam 12 menit, dan 15% sekitar
1 jam 30 menit. Angka ini hanya model pengujian; ukur arus dan runtime perangkat
fisik sebelum menentukan spesifikasi produk.

`simulated_rssi` hanya dihormati oleh aplikasi utama jika `device_id` tepat
`MEDITRACE-DUMMY` (atau ID dummy lama `MEDBOX-DUMMY`); perangkat ESP32 asli tetap menggunakan RSSI radio nyata.

BLE Peripheral bergantung kemampuan chipset/ROM HP. Jika muncul pesan
"tidak mendukung BLE Peripheral", gunakan HP lain; emulator Android dan satu
HP yang menjalankan kedua aplikasi sekaligus bukan pengujian BLE yang andal.

## Batas pengujian

Dummy menguji alur aplikasi dan jaringan, bukan sensor IR/tact switch fisik.
RTC/DS3231 tidak digunakan pada rancangan alat. Tes pengambilan obat nyata dan
voltase baterai fisik tetap harus dilakukan pada ESP32 setelah tes dummy lulus.
