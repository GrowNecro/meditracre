# Aplikasi Android MEDITRACE

Aplikasi Flutter untuk kotak obat ESP32-C3 lima kompartemen. Versi saat ini
**1.0.4+10**, package **`com.example.meditrace`**, database lokal
**`meditrace_local.db`**. Firmware pasangannya **0.9.7**.

## Fitur

- Tab Home, Jadwal, Riwayat, Perangkat, dan Profil.
- Pencarian BLE nama `MEDITRACE-*`/`MEDBOX-*` atau service UUID MEDITRACE.
  Hasil tampil saat ditemukan dan diurutkan berdasarkan kekuatan sinyal.
- Status isi/pintu lima ruang. Sensor tidak valid tidak dianggap semua kosong.
- Jadwal harian, notifikasi HP, riwayat, konfirmasi **Sudah minum**, dan pembatalan.
- Login Google, grup keluarga, undangan kode/email, dan peringatan melalui backend.
- Update APK dan firmware manual dari GitHub Release terbaru.

## Menjalankan dan build

Dari folder `meditrace_app`:

1. Pasang Flutter yang memenuhi SDK Dart pada `pubspec.yaml` (`^3.13.5`),
   Android SDK, dan toolchain Android.
2. Salin konfigurasi Firebase Android ke `android/app/google-services.json`.
   Package harus cocok dengan `com.example.meditrace`.
3. Aktifkan Google Sign-In di Firebase dan daftarkan fingerprint sertifikat
   yang benar-benar menandatangani APK. Sertifikat debug lokal belum tentu
   sama dengan sertifikat build GitHub.
4. Bila perlu override, salin `config/app.example.env` ke `config/app.local.env`.
   Kode sekarang membaca `GOOGLE_WEB_CLIENT_ID` dan `FAMILY_API_URL` melalui
   dart-define. Firebase Android diinisialisasi dari `google-services.json`;
   entri `FIREBASE_*` pada contoh env bukan pengganti berkas native tersebut.
5. Untuk build release, konfigurasi keystore tetap sesuai
   [panduan signing](../docs/android-signing.md). Build debug tidak memerlukannya.

```powershell
flutter pub get
flutter run
flutter build apk --release
```

Dengan override lokal:

```powershell
flutter run --dart-define-from-file=config/app.local.env
flutter build apk --release --dart-define-from-file=config/app.local.env
```

Proyek Firebase yang digunakan adalah `meditrace-84207`. Default API keluarga
pada kode adalah `https://meditrace.grownecro.tech`, melalui endpoint HTTP
`/v1/*` dengan Firebase ID token; lihat [panduan Worker](../meditrace_worker/README.md).
Keberadaan konfigurasi tidak menjamin layanan sudah dideploy atau aktif.
Nilai dart-define tertanam dalam APK; jangan isi client secret atau service account.
Aktifkan Windows Developer Mode jika Flutter meminta dukungan symbolic link.

Build release memakai keystore tetap dari `android/key.properties` atau
environment signing. Penggantian sertifikat memerlukan penyesuaian fingerprint
Firebase dan perencanaan migrasi APK lama. Build release tanpa konfigurasi
signing akan gagal; tidak ada fallback ke debug key.

## Jadwal, sensor, dan konfirmasi

Jadwal baru cukup memilih jam dan berulang setiap hari tanpa memilih ruang.
Jadwal lama dengan nomor ruang tetap dapat dibaca. C3 hanya menampilkan ruang
1–5 dan mengabaikan kanal keenam dari payload firmware lama.

Firmware tidak menjalankan jadwal obat mandiri. Aplikasi menyinkronkan waktu
melalui `SYNC_TIME`, memantau jadwal saat aktif, dan memicu buzzer lewat BLE.
Notifikasi lokal dijadwalkan pada HP. DS3231/RTC eksternal tidak dipakai dan
jadwal belum disinkronkan antar-HP.

Event sensor `DOSE_REMOVED` diproses sebagai `DOSE_CONFIRMED`, dengan status
lebih awal, tepat waktu, atau terlambat jika ada jadwal terkait. Tombol
**Sudah minum** menyediakan konfirmasi pengguna dan pembatalannya.
Pengisian kembali ruang yang sama dalam 15 menit dapat membatalkan konfirmasi
sebelumnya. Sensor menunjukkan pengambilan/pengembalian, bukan bukti obat ditelan.

## BLE dan peringatan tertinggal

Pairing disimpan setelah pengguna memilih perangkat. Reconnect mulai mencari
sekitar 0,5 detik setelah putus tak disengaja, dengan jeda retry 2 detik.
Scan dapat berlangsung sampai 12 detik dan timeout koneksi 15 detik; angka
jeda bukan jaminan waktu tersambung. Scan aktif dipakai kembali, dan percobaan
saat sibuk atau scan gagal dijadwalkan ulang. **Putuskan koneksi** menonaktifkan
reconnect sampai perangkat dipilih secara manual lagi.

Pasien diperingatkan setelah putus 30 detik. Jika belum pulih 5 menit
setelahnya (total sekitar 5 menit 30 detik), aplikasi mengirim eskalasi keluarga.
Putus manual tidak memicu alur ini. Peringatan sinyal lemah juga tersedia.
Android yang menghentikan aplikasi dapat menghentikan BLE dan timer; pemantauan
terus-menerus saat aplikasi dimatikan belum dijamin.

## Estimasi baterai

Firmware 0.9.7 menghitung waktu perangkat menyala dengan asumsi kapasitas
1500 mAh dan arus rata-rata 150 mA: sekitar 10 jam dari penuh atau 1% per 6 menit.
Label 3,7 V adalah nominal baterai; tidak dipakai untuk membuat angka tegangan.

Status BLE mengirim `battery_estimated:true` dan `battery_voltage:null`.
Aplikasi menampilkan **Estimasi baterai** dan menyembunyikan tegangan ADC lama.
Pemasangan pertama mengasumsikan penuh. Setelah dicas penuh, gunakan
**Perangkat → Detail perangkat → Tandai baterai penuh**, lalu konfirmasi.

Pengisian tidak dideteksi otomatis. Pemakaian disimpan setiap 5 menit dan
sebelum restart normal/OTA; mati mendadak dapat kehilangan catatan sekitar
5 menit. Waktu mati, pengosongan alami, kondisi sel, dan perubahan beban tidak
dihitung. Persentase/durasi bukan pengukuran sisa energi sebenarnya.

## Keluarga dan backend

BLE, jadwal, dan riwayat lokal tersedia tanpa login. Fitur keluarga membutuhkan
Firebase Auth, Firestore, API HTTP Worker, internet, dan keanggotaan grup.
Grup penerima dapat dipilih. Kode undangan berlaku 7 hari dan sekali pakai.

Peringatan mencakup ruang kosong, status pengambilan obat, eskalasi koneksi
putus, dan laporan **Saya meninggalkan MEDITRACE**. Antrean lokal mencoba ulang
kejadian yang sudah diantrikan dengan ID tetap untuk mencegah duplikasi.
Worker menyediakan FCM dan email Resend; pengiriman bergantung konfigurasi,
token perangkat, serta alamat anggota. Lihat [panduan Worker](../meditrace_worker/README.md).

## Pembaruan dan GitHub Release

- **Profil → Perbarui aplikasi** membuka unduhan `meditrace.apk`; instal manual.
- **Perangkat → Update firmware terbaru** mengunduh `meditrace-esp32-c3.bin`
  dari release terbaru dan meminta konfirmasi sebelum transfer BLE.
- **Pilih file .bin lokal** tersedia untuk binary yang sudah diunduh.
- Perangkat memverifikasi ukuran/CRC32, lalu restart. BLE putus sementara dan
  aplikasi mencoba reconnect.
- Belum ada pemeriksaan versi, pengingat update, atau instalasi otomatis.

Workflow berjalan saat tag `v*` dipush. Repository secret `GOOGLE_SERVICES_JSON`
harus berisi seluruh konfigurasi Firebase Android; workflow menuliskannya ke
`android/app/google-services.json`. Secret kosong menggagalkan build.
Jangan memakai JSON Firebase Admin SDK sebagai konfigurasi Android.
Signing GitHub juga membutuhkan `ANDROID_KEYSTORE_BASE64`,
`ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, dan `ANDROID_KEY_PASSWORD`.
Lihat [langkah pembuatan keystore dan secrets](../docs/android-signing.md).

## Pengujian

```powershell
flutter analyze
flutter test
```

Tes otomatis mencakup UI, sensor, jadwal, reconnect, antrean peringatan, dan
mode estimasi baterai. Arus, runtime nyata, jangkauan BLE, dan perilaku
background tetap perlu diuji pada perangkat fisik.

## Lisensi BLE

Kode memakai `flutter_blue_plus` dengan `License.nonprofit`. Penggunaan
komersial perlu menyesuaikan lisensi package atau implementasi `BleService`.
Abstraksi BLE dipisahkan dari UI.
