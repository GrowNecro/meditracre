# MEDITRACE Flutter

Aplikasi Android MEDITRACE untuk menemukan dan berkomunikasi dengan firmware MEDITRACE
ESP32-C3 melalui Bluetooth Low Energy.

Package Android sekarang `com.example.meditrace` dan database baru bernama
`meditrace_local.db`. Ini dianggap aplikasi baru oleh Android: jadwal, riwayat,
dan pairing dari APK lama tidak otomatis berpindah. Folder sumber bernama
`meditrace_app`; protokol UUID BLE tidak diubah. Scanner menerima
advertising `MEDITRACE-*` dan `MEDBOX-*` untuk perangkat firmware lama.
Akun dan grup keluarga memakai Firebase. Jadwal/riwayat tetap lokal di SQLite.

## Menjalankan

```powershell
flutter pub get
flutter run --dart-define-from-file=config/app.local.env
```

Konfigurasi aplikasi ada di `config/app.local.env` (diabaikan Git). Firebase
Auth/Firestore memakai proyek `meditrace-84207`; operasi grup dan pengiriman
push memakai Firebase Cloud Functions di `../firebase_backend/README.md`.
Selama konfigurasi backend belum aktif, login Google dasar tetap dapat digunakan,
tetapi layar grup dan push ditandai belum aktif.
`MEDBOX_API_URL` dari konfigurasi lama tidak lagi digunakan.

Untuk membuat APK:

```powershell
flutter build apk --debug --dart-define-from-file=config/app.local.env
```

Jika membuat salinan proyek, mulai dari `config/app.example.env`. File ini
dibaca saat **build**, jadi perubahan nilai memerlukan build/instal APK baru.
Jangan simpan client secret, password MySQL, atau service-account JSON di sini:
nilai `--dart-define` ikut tertanam dalam aplikasi dan bukan tempat rahasia.

Aktifkan Windows Developer Mode bila Flutter meminta dukungan symbolic link.

## Jadwal dan konfirmasi dosis

Jadwal baru memilih nomor ruang obat (1–5 untuk C3, atau sesuai perangkat yang sedang
terhubung). Jadwal lama tetap ada setelah migrasi SQLite versi 2 dan awalnya
bertanda **Ruang belum dipilih**; nomor ruang bisa diatur lewat ikon edit.
Pengingat HP menyebut nomor ruang bila tersedia.
Jadwal lama yang menunjuk ruang 6 tetap tersimpan, tetapi ditandai agar
pengguna memilih ulang; aplikasi C3 kini hanya menampilkan ruang 1–5 dan
mengabaikan kanal keenam dari payload firmware lama. Firmware C3 versi 0.6.0
di folder `kodee` sudah memakai 5 kanal; unggah versi itu ke board fisik.

Tombol **Saya sudah minum obat** membuat catatan konfirmasi pengguna di
riwayat lokal. Event sensor **obat diambil** tetap terpisah dan tidak otomatis
dianggap sebagai bukti obat telah diminum. Konfirmasi dapat dibatalkan.

Firmware ESP32 v0.8.0 tidak memakai RTC/DS3231. GPIO 5/6 tetap dipakai untuk
PCF8575 melalui I²C, sementara jadwal dan notifikasi waktu dijalankan oleh
aplikasi/ponsel. Karena itu alat perlu tersambung ke aplikasi untuk pembaruan
status BLE secara langsung; event sensor tanpa RTC diberi waktu saat diterima
oleh aplikasi. Jadwal masih bersifat lokal untuk tiap HP; berbagi jadwal antar
akun belum disediakan karena perlu aturan perubahan dan persetujuan caregiver
yang belum ditetapkan.

## Peringatan keluarga

Saat login Google dan menjadi pemilik grup, aplikasi mengirim peringatan
`low_supply` bila sensor valid baru mendeteksi ruang kosong, serta
`device_disconnected` bila koneksi BLE belum pulih setelah batas waktu
peringatan tertinggal. Pemutusan koneksi manual tidak dilaporkan. Jika pemilik
punya beberapa grup, pilih **Grup penerima peringatan MEDITRACE** di layar Akun &
Grup Keluarga. Tanpa login/grup pemilik, fitur lokal tetap berfungsi.

Kejadian yang gagal dikirim disimpan di SQLite dan dicoba ulang berkala saat
aplikasi aktif. Backend memakai `clientEventId` untuk mencegah duplikasi.
Antrean akun lama dihapus saat logout. Ini belum menjamin pengiriman ketika
Android menghentikan aplikasi.

Firebase Cloud Functions mengirim Firebase Cloud Messaging ke perangkat anggota
lain. Email belum diaktifkan; perlu konfigurasi pengirim email terpisah. Kotak
masuk Firestore dibaca lewat tombol segarkan. Periksa aturan Firestore dan
Functions sudah dipublikasikan sebelum menguji grup dan push antar-HP.

## Catatan lisensi BLE

Build pengembangan saat ini menggunakan `flutter_blue_plus` dengan
`License.nonprofit`. Sebelum mendistribusikan aplikasi untuk penggunaan
komersial/organisasi profit, beli lisensi komersial package tersebut atau ganti
implementasi `BleService` dengan library BLE berlisensi permisif. Abstraksi BLE
dipisahkan dari UI agar penggantian ini tidak mengubah layar aplikasi.

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
