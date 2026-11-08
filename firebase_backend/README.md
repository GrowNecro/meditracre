# Backend Firebase MEDITRACE

Implementasi Cloud Functions untuk fitur grup keluarga dan push notification
MEDITRACE, beserta Firestore Rules.

> **Kesesuaian dengan aplikasi saat ini:** APK 1.0.2 memakai Firebase Auth,
> Firestore, dan endpoint HTTP `/v1/*` dengan default
> `https://meditrace.grownecro.tech`. Implementasi backend HTTP di repository
> ada pada [Cloudflare Worker](../meditrace_worker/README.md), termasuk email
> Resend. Deploy Functions di folder ini saja tidak mengalihkan APK ke
> callable Functions. Panduan di bawah adalah jalur Functions alternatif
> yang perlu disesuaikan dengan klien sebelum dipakai.

Backend grup keluarga memakai Firebase Auth, Cloud Firestore, Cloud Functions
dan Firebase Cloud Messaging. Tidak perlu Laravel/MySQL/share hosting untuk
alur ini. BLE, jadwal, dan riwayat obat tetap lokal pada aplikasi Flutter.

## Konfigurasi akun Firebase

Proyek pengembangan yang terhubung saat ini: **`meditrace-84207`** dengan
aplikasi Android **`com.example.meditrace`**. Berkas
`meditrace_app/android/app/google-services.json` dan konfigurasi lokal Flutter
sudah dipasang. Konfigurasi OAuth Android untuk sertifikat debug dan OAuth Web
client ID sekarang sudah tercantum dalam berkas dan `app.local.env`.

Untuk menuntaskan Google Sign-In pada APK debug, buka Firebase Console →
Project settings → Your apps → aplikasi Android MEDITRACE → **Add fingerprint**.
Tambahkan kedua sidik jari dari debug keystore komputer ini:

```text
SHA-1   F0:DF:2A:AC:7B:35:09:2A:47:AA:B8:C7:43:B9:F4:D3:CE:97:57:BE
SHA-256 38:41:FC:6E:BD:EC:F5:F2:C2:8C:7E:71:64:25:E9:0F:3D:FA:DD:65:ED:4F:76:78:C0:8D:38:B7:20:FF:5F:1F
```

Aktifkan Authentication → Sign-in method → Google, lalu unduh ulang
`google-services.json` setelah perubahan. Isi `GOOGLE_WEB_CLIENT_ID` di
`meditrace_app/config/app.local.env` dengan **OAuth Web client ID** dari proyek
yang sama (bukan Android client ID atau client secret). Sidik jari APK release
harus didaftarkan terpisah bila memakai sertifikat release berbeda.

1. Buat atau hubungkan project di Firebase Console. Aktifkan Authentication
   **Google**, buat database Cloud Firestore, dan upgrade ke **Blaze** untuk
   deploy Cloud Functions. Billing mungkin berlaku; pantau kuota.
2. Tambahkan aplikasi Android dengan package **`com.example.meditrace`**.
   Jangan ubah package ini tanpa rencana migrasi karena APK lama menyimpan
   jadwal SQLite dan pairing di package yang sama.
3. Tambahkan SHA-1 dan SHA-256 sertifikat debug/release ke aplikasi Android
   Firebase. Google OAuth Android client harus cocok dengan package dan SHA.
   Gunakan Web Client ID dari proyek Firebase/Google Cloud yang sama.
4. Pasang konfigurasi Firebase Android di
   `../meditrace_app/android/app/google-services.json`. Untuk override OAuth,
   salin `../meditrace_app/config/app.example.env` menjadi `app.local.env`
   dan isi `GOOGLE_WEB_CLIENT_ID` (OAuth web client ID). Klien saat ini
   membaca Firebase dari berkas native; entri `FIREBASE_*` pada contoh env
   tidak menggantikan `google-services.json`. Ini konfigurasi aplikasi,
   **bukan** client secret/service account. Jangan masukkan service account ke APK.
5. Pastikan perangkat mengizinkan notifikasi. Login Google akan mendaftarkan
   token FCM ke Functions; anggota lain akan menerima push saat ada alert.

## Deploy

Pasang Node.js 22 dan Firebase CLI pada komputer pengembang. Dari folder ini:

```powershell
npm --prefix functions install
npx firebase-tools login
npx firebase-tools use --add
npx firebase-tools deploy --only functions,firestore:rules
```

Firebase CLI akan membuat `.firebaserc` lokal saat `use --add`. Jangan deploy
ke project yang salah. Fungsi ditempatkan di region `asia-southeast2` dan
aplikasi memanggil region yang sama. Setelah deploy:

```powershell
cd ..\meditrace_app
flutter pub get
flutter run --dart-define-from-file=config/app.local.env
```

Untuk APK: `flutter build apk --debug --dart-define-from-file=config/app.local.env`.
Login Google pertama otomatis membuat profil Firebase. Kode undangan acak
berlaku 7 hari dan sekali pakai. Firestore Rules menolak penulisan langsung
dari APK; tindakan grup/alert berjalan lewat callable Functions. Event alert
memakai ID tetap untuk retry agar tidak membuat dua dokumen.

## Belum termasuk

Data Laravel/MySQL lama **tidak dimigrasikan** otomatis; akun Firebase baru
memakai UID berbeda. Email tambahan belum tersedia. Push memerlukan internet
dan layanan Google Play pada HP. Alert saat aplikasi dimatikan sebelum sempat
mengantrikannya tetap tidak dapat dikirim oleh backend.
