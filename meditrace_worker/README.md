# MEDITRACE Cloudflare Worker

Backend Worker untuk menggantikan Node.js shared hosting. Kode produksi akan
dipasang ke Worker `meditrace` melalui Cloudflare Dashboard. Jangan simpan
service-account Firebase atau API key Resend dalam berkas proyek ini.

## Secrets yang diperlukan

- `FIREBASE_PROJECT_ID`
- `FIREBASE_SERVICE_ACCOUNT`
- `RESEND_API_KEY`

## Variable

- `EMAIL_FROM`
- `ANDROID_SHA256_CERT_FINGERPRINTS` — fingerprint SHA-256 sertifikat APK,
  dipisahkan koma jika ada lebih dari satu (debug/release).

## Deploy dengan Wrangler

```powershell
npm install
npm run deploy
```

Login Cloudflare sekali saja dengan `npx wrangler login`. Untuk development
lokal, salin `.dev.vars.example` menjadi `.dev.vars`, isi rahasianya, lalu
jalankan `npm run dev`. Jangan pernah memasukkan service account atau Resend
API key ke `wrangler.toml`, `package.json`, maupun Git.

Untuk menyimpan secret produksi:

```powershell
npx wrangler secret put FIREBASE_PROJECT_ID
npx wrangler secret put FIREBASE_SERVICE_ACCOUNT
npx wrangler secret put RESEND_API_KEY
```

## Endpoint aktif

- `GET /healthz` — memeriksa konfigurasi Worker tanpa membuka rahasia.
- `POST /v1/ensureUser` — membutuhkan Firebase ID token; membuat atau
  memperbarui profil pengguna saat login Google.
- `POST /v1/testEmail` — membutuhkan Firebase ID token dan `{ "email": "…" }`.
- `POST /v1/testPush` — membutuhkan Firebase ID token dan `{ "token": "…" }`.
- `POST /v1/createFamily`, `/v1/updateFamily`, `/v1/deleteFamily`,
  `/v1/joinFamily`, `/v1/createInvitation` — grup dan undangan keluarga.
- `POST /v1/sendInvitationEmail` — mengirim kode undangan melalui Resend.
- `GET /.well-known/assetlinks.json` — konfigurasi Android App Links dari
  `ANDROID_SHA256_CERT_FINGERPRINTS`.
- `GET /invite/<kode>` — halaman undangan dengan tombol membuka aplikasi,
  unduhan APK, dan kode untuk dimasukkan manual jika aplikasi belum terpasang.
- `POST /v1/registerDevice`, `/v1/unregisterDevice` — token perangkat untuk
  notifikasi.
- `POST /v1/sendAlert`, `/v1/acknowledgeAlert`, `/v1/deleteAlert`,
  `/v1/clearAlerts` — kirim, tangani, hapus satu, atau hapus semua salinan
  peringatan keluarga milik akun yang login.

Seluruh endpoint `POST /v1/*` membutuhkan Firebase ID token; Worker memeriksa
token sebelum membaca atau menulis data Firestore.

## Tautan undangan Android

`ANDROID_SHA256_CERT_FINGERPRINTS` harus mencakup sertifikat debug lokal dan
release tetap yang menandatangani APK GitHub. SHA release saat ini berawalan
`FE:B8:C1:10`; nilai lengkap tersimpan pada `wrangler.toml`. Perubahan fingerprint
Firebase tidak otomatis memperbarui konfigurasi domain App Links.

Undangan baru memakai 24 karakter heksadesimal. Undangan lama dengan sembilan
karakter alfanumerik tetap didukung sampai kedaluwarsa. Kode tidak dipotong saat
diterima backend. Halaman browser hanya menampilkan kode dan membuka aplikasi;
kunjungan browser atau pemindai tautan email tidak mengonsumsi undangan.

Di aplikasi, tautan membuka Profil dengan kartu undangan. Pengguna masuk bila
diperlukan, lalu menekan **Gabung sekarang**. Undangan tetap tersimpan ketika
login dan baru ditandai selesai setelah backend menerima penggabungan grup.

Validasi dan deploy sambil mempertahankan variable/secrets produksi lain:

```powershell
npm test
npm run check -- --keep-vars
npm run deploy -- --keep-vars
```

Setelah memperbarui aplikasi, izinkan **Open supported links / Buka tautan yang
didukung** pada pengaturan Android untuk MEDITRACE. Perubahan manifest dan
penanganan tautan di Flutter memerlukan APK baru; perubahan Worker saja tidak
mengganti kode APK yang sudah terpasang.

Peringatan `separation_escalation` dan `medbox_left_behind` dikirim melalui
FCM dan email ke anggota grup selain pengirim jika profil mereka memiliki email.
