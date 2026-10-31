# MEDITRACE

Smart medication reminder dengan aplikasi Android, firmware ESP32-C3, simulator
BLE, dan backend keluarga Firebase.

| Folder | Isi |
| --- | --- |
| `meditrace_app/` | Aplikasi Flutter utama (package `com.example.meditrace`) |
| `meditrace_dummy/` | Simulator BLE Android (package `com.example.meditrace_dummy`) |
| `kodee/` | Firmware produksi ESP32-C3 |
| `firebase_backend/` | Cloud Functions, Firestore Rules, panduan deploy |
| `docs/` | Rangkaian, protokol, dan arsitektur |

Nama folder proyek, aplikasi, package Android, nama BLE firmware, dan database
SQLite memakai MEDITRACE. UUID BLE tetap sama agar firmware lama masih dapat
dicari. File konfigurasi Firebase dan hasil build sengaja tidak masuk Git.

Mulai dari `meditrace_app/README.md` untuk menjalankan aplikasi dan
`firebase_backend/README.md` untuk konfigurasi akun keluarga. Firebase belum
terhubung sampai project ID dan konfigurasi aplikasi Android diisi.
