# Uji MEDITRACE dengan Dummy BLE

Gunakan dua HP Android. HP A memasang APK MEDITRACE utama, HP B memasang
MEDITRACE Dummy. Jangan pasang dua aplikasi itu pada HP yang sama untuk uji
BLE peripheral, karena dukungan advertising tiap ponsel berbeda.

## APK

- MEDITRACE utama: `meditrace_app/build/app/outputs/flutter-apk/app-debug.apk`
- MEDITRACE Dummy: `meditrace_dummy/build/app/outputs/flutter-apk/app-debug.apk`

## Urutan uji

1. Di HP B, buka Dummy, pilih **C3 · 5**, kemudian tekan **Mulai siarkan**
   dan berikan izin Perangkat terdekat.
2. Di HP A, buka MEDITRACE, aktifkan Bluetooth/izin, cari
   `MEDITRACE-DUMMY`, lalu hubungkan. Home harus menunjukkan lima ruang dan
   keadaan obat/pintu.
3. Di Dummy, ubah **Obat ada** pada satu ruang menjadi **Obat kosong**.
   HP A harus memperbarui status ruang, mencatat event, dan saat akun/grup
   aktif mengantrekan peringatan isi ulang ke keluarga.
4. Tekan **Simulasikan alarm jadwal ruang ini**. HP A harus menyimpan event
   `DOSE_ALARM`; bila izin notifikasi aktif akan tampil notifikasi alarm.
   Coba saat ruang kosong juga untuk memastikan status event `RUANG_KOSONG`.
5. Pilih sinyal **Jauh**, tunggu sekitar 45 detik, lalu pilih **Dekat** untuk
   menguji peringatan sinyal lemah dan pemulihannya.
6. Tekan **Simulasikan tertinggal**. HP A harus mencoba auto-connect lagi.
   Setelah jeda yang dipilih di menu Lainnya, notifikasi tertinggal lokal dan
   peringatan keluarga terjadi hanya bila pemutusan bukan dari tombol putus
   manual di aplikasi utama.
7. Untuk uji keluarga, pasang APK utama juga pada HP C, login akun Google lain,
   buat grup di HP A, undang HP C, dan pastikan peringatan kosong/terputus
   terlihat pada Kotak Masuk HP C.

## Batas hasil dummy

Dummy menguji protokol BLE, tampilan status, event, alarm jadwal, retry
koneksi, dan alur notifikasi aplikasi. Ia tidak menguji catu daya, PCF8575,
DS3231, reed switch, break-beam, buzzer, atau arus pemancar IR. Lakukan uji
yang sama lagi setelah firmware v0.7.0 diunggah ke ESP32-C3 fisik.
