# Keystore tetap untuk APK MEDITRACE

Release GitHub memakai keystore yang sama pada setiap build. Jangan membuat
keystore baru setiap mengganti tag. Simpan salinan keystore dan password di
tempat pribadi yang aman; jangan commit berkas atau password ke Git.

## 1. Buat keystore sekali

Dari root repository, jalankan di PowerShell:

```powershell
$signingKeytool = 'C:/Program Files/Android/Android Studio/jbr/bin/keytool.exe'
& $signingKeytool -genkeypair -v -keystore meditrace_app/android/app/meditrace-release.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias meditrace
```

Isi password keystore dan identitas sertifikat ketika diminta. Pada pertanyaan
password key, tekan Enter untuk memakai password yang sama. Jika berkas sudah
ada, gunakan keystore tersebut; jangan menggantinya. Berkas `.jks` pada folder
Android sudah diabaikan Git.

## 2. Isi GitHub Actions Secrets

Buka repository → **Settings → Secrets and variables → Actions**.
Buat empat **Repository secrets**:

| Nama | Isi |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | Isi keystore yang dikonversi menjadi Base64 |
| `ANDROID_KEYSTORE_PASSWORD` | Password keystore dari langkah 1 |
| `ANDROID_KEY_ALIAS` | `meditrace` |
| `ANDROID_KEY_PASSWORD` | Password key; sama dengan keystore jika tadi menekan Enter |

Untuk menyalin Base64 ke clipboard tanpa mencetaknya di terminal:

```powershell
$signingKeyFile = (Resolve-Path meditrace_app/android/app/meditrace-release.jks).Path
[Convert]::ToBase64String([IO.File]::ReadAllBytes($signingKeyFile)) | Set-Clipboard
```

Tempel clipboard ke nilai `ANDROID_KEYSTORE_BASE64`. Base64 ini berisi private
key, sehingga perlakukan seperti berkas keystore asli.

Secret `GOOGLE_SERVICES_JSON` tetap diperlukan dan berisi seluruh konfigurasi
Firebase Android. Itu berbeda dari keystore dan dari Firebase Admin SDK.

### Mengisi kelima secret melalui PowerShell

Jika ingin menghindari salin-tempel manual, install GitHub CLI dan login dengan
akun yang memiliki akses pengaturan Actions secrets repository:

```powershell
winget install --id GitHub.cli
gh auth login
./scripts/configure-release-secrets.ps1 -KeystorePath ./meditrace_app/android/app/meditrace-release.jks
```

Jalankan dari root repository. Skrip memakai `google-services.json` di root,
meminta password secara tersembunyi, lalu mengisi kelima repository secrets.
Gunakan `-GoogleServicesPath` bila file Firebase berada di lokasi lain dan
`-KeyAlias` bila alias keystore bukan `meditrace`. Skrip memakai keystore yang
sudah ada; jika belum punya, lakukan langkah 1 terlebih dahulu.

Jangan kirim password atau Base64 keystore melalui chat atau commit Git.

## 3. Daftarkan fingerprint di Firebase

Tampilkan sertifikat dengan perintah berikut; masukkan password saat diminta:

```powershell
& $signingKeytool -list -v -keystore meditrace_app/android/app/meditrace-release.jks -alias meditrace
```

Di Firebase Console, pilih proyek `meditrace-84207` → **Project settings →
General → Your apps → com.example.meditrace → Add fingerprint**. Tambahkan
SHA-1 dan SHA-256 dari keystore tetap ini. Pastikan provider Google aktif.
Unduh ulang `google-services.json`, salin ke
`meditrace_app/android/app/google-services.json`, dan perbarui isi repository
secret `GOOGLE_SERVICES_JSON` dengan seluruh JSON terbaru.

Workflow menampilkan SHA-1 dan SHA-256 pada ringkasan run GitHub Actions.
Langkah **Validate Android signing key** sengaja gagal jika SHA-1 keystore
release belum tercantum di OAuth Android pada JSON. Salin fingerprint dari
ringkasan run, daftarkan di Firebase, unduh ulang JSON, perbarui secret, lalu
jalankan ulang job. Jangan sekadar mengedit `certificate_hash` di JSON:
pendaftaran OAuth dilakukan melalui Firebase/Google Cloud.

Sertifikat debug lokal dan release boleh didaftarkan bersamaan. Jangan hapus
fingerprint debug lokal yang masih dipakai untuk pengembangan.

Gunakan fingerprint keystore tetap untuk release berikutnya, bukan fingerprint
debug runner GitHub. Jika memakai Android App Links, sesuaikan juga variable
Worker `ANDROID_SHA256_CERT_FINGERPRINTS` dengan SHA-256 sertifikat ini.

## 4. Build lokal atau GitHub

Untuk release lokal, buat `meditrace_app/android/key.properties` (diabaikan Git):

```properties
storePassword=PASSWORD_KEYSTORE
keyPassword=PASSWORD_KEY
keyAlias=meditrace
storeFile=app/meditrace-release.jks
```

Ganti placeholder password dengan nilai sebenarnya. Path relatif `storeFile`
dihitung dari folder `meditrace_app/android`. Lalu dari `meditrace_app`:

```powershell
flutter build apk --release
```

Untuk GitHub, commit/push konfigurasi signing, lalu push tag `v*` baru setelah
semua secret terisi. Workflow memulihkan keystore di direktori sementara,
memeriksa alias, menampilkan fingerprint, menandatangani APK, lalu menghapus
berkas sementara. Password key yang salah akan menggagalkan signing.
Build release tidak kembali menggunakan debug key ketika konfigurasi kosong.
Build debug lokal tetap memakai debug key.

### Temuan pada APK GitHub v1.0.2

Pemeriksaan APK publik `v1.0.2` menunjukkan sertifikat berikut:

```text
SHA-1   51:4F:FB:B8:15:7D:6C:D2:CD:D0:CE:83:BF:B7:39:54:C2:52:AB:99
SHA-256 5E:7F:81:81:0E:FC:40:80:8C:2D:C0:06:BD:6C:EA:3C:4C:10:82:B9:47:3D:87:D2:6F:24:72:F8:C2:9C:E2:4A
```

Nilai ini berbeda dari sertifikat debug lokal yang tercantum di JSON Firebase.
Project ID, app ID, API key, dan OAuth Web client yang tertanam di APK tersebut
cocok dengan konfigurasi lokal saat pemeriksaan. Endpoint `/healthz` backend
juga merespons normal untuk proyek `meditrace-84207`.

Untuk mengaktifkan Google Login pada **APK v1.0.2 yang sudah diunduh**, daftarkan
SHA di atas pada aplikasi Android Firebase `com.example.meditrace`. Tidak perlu
membuat OAuth client ID sendiri atau mengganti project Firebase. Keberhasilan
login tetap perlu diuji di HP setelah perubahan Firebase berlaku.

Fingerprint di atas hanya milik APK v1.0.2 yang diperiksa. Untuk build berikutnya,
gunakan fingerprint **keystore release tetap** dari langkah 1, yang dapat
berbeda dari fingerprint v1.0.2. Jangan kembali memakai debug key acak runner.
App Links publik saat pemeriksaan hanya memuat SHA-256 debug lokal; tambahkan
SHA-256 sertifikat APK yang didistribusikan pada konfigurasi Worker, lalu deploy
Worker tersebut agar tautan undangan juga dikenali Android.

### Pemeriksaan workflow dan menjalankan ulang release

Workflow memakai Flutter `3.47.6` (Dart `3.13.5`), Java 17, Python 3.12,
dan PlatformIO `6.2.0`. Commit `pubspec.lock` bersama perubahan dependensi.
Sebelum build, workflow memeriksa lima secret, JSON Firebase, kecocokan package,
Base64 keystore, password keystore, alias, analisis Flutter, dan tes aplikasi.

Commit seluruh perubahan aplikasi, termasuk `lib/l10n/` dan `l10n.yaml`, sebelum
menandai release. Tag harus menunjuk ke commit yang memuat workflow dan skrip CI
baru. Menjalankan ulang run lama tetap memakai workflow pada commit lama.

Untuk membuat release baru setelah commit dan push perubahan:

```powershell
git tag v1.0.3
git push origin v1.0.3
```

Gunakan nomor tag yang belum ada dan sesuaikan versi di `pubspec.yaml` sebelum
commit bila diperlukan. Alternatifnya, buka **Actions → Release MEDITRACE →
Run workflow** dan isi tag `v*` yang sudah ada serta memuat konfigurasi baru.
Jika hanya memperbaiki secret, gunakan **Re-run failed jobs** pada run tersebut.

APK dan firmware disimpan sebagai build artifacts. Publikasi memakai draft
untuk release baru, mengunggah kedua aset, lalu memublikasikannya. Menjalankan
ulang tag yang sama mengganti aset dengan nama yang sama sehingga tidak gagal
karena release atau aset sudah ada. Release yang sudah dipublikasikan tetap
terlihat selama unggahan ulang berlangsung.

## APK yang sudah terpasang

APK lama dari runner GitHub memakai debug certificate yang berbeda. Android
tidak mengizinkan pembaruan langsung dengan sertifikat baru yang berbeda.
Jangan menghapus APK lama sebelum mempertimbangkan data jadwal/riwayat lokal:
uninstall dapat menghapus data aplikasi, dan migrasi otomatis untuk pergantian
sertifikat belum disediakan. Setelah beralih ke keystore tetap, pertahankan
keystore yang sama untuk pembaruan berikutnya.

Referensi: [panduan signing Flutter](https://docs.flutter.dev/deployment/android)
dan [Google Sign-In Firebase](https://firebase.google.com/docs/auth/android/google-signin).
