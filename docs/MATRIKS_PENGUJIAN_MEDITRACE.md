# Matriks Pengujian MEDITRACE

Dokumen ini adalah acuan uji akhir. Status **siap diuji** berarti alurnya
sudah tersedia pada kode saat ini, bukan berarti otomatis sudah lulus uji
fisik. Catat hasil aktual, waktu kejadian, dan bukti foto/video pada setiap
sesi.

## Ruang lingkup prototipe

- RTC di luar ruang lingkup. Alarm jadwal dijalankan aplikasi melalui BLE saat
  aplikasi dan MEDBOX terhubung; notifikasi Android tetap dijadwalkan lokal.
- Perangkat keras yang terpasang saat ini baru dapat membuktikan kanal sensor
  yang benar-benar terhubung. Kode mendukung lima kompartemen, tetapi kelima
  sensor/limit switch harus dipasang untuk menguji semuanya.
- Nilai baterai pada firmware masih nilai sementara; belum berasal dari
  pembacaan tegangan baterai.
- Uji daya memerlukan alat ukur eksternal (USB power meter, multimeter/INA219,
  atau battery analyser).

Legenda: **Siap diuji** = alur tersedia; **Sebagian** = ada tetapi belum sesuai
seluruh kriteria; **Belum** = perlu implementasi; **Fisik** = perlu komponen
atau alat ukur.

## Paket A — Medication Monitoring & Reminder

| ID | Status | Prosedur & hasil yang harus dicatat |
| --- | --- | --- |
| A1 | Siap diuji | Buka kompartemen; aplikasi/BLE harus menerima `DOOR_OPEN`. |
| A2 | Siap diuji | Tutup kembali kompartemen; harus menerima `DOOR_CLOSED`. Pastikan limit switch NC dibaca HIGH saat tertutup. |
| A3 | Siap diuji | Masukkan obat hingga sinar IR terhalang; status kompartemen harus menjadi berisi. |
| A4 | Siap diuji | Keluarkan obat dari kompartemen yang sebelumnya berisi; harus tercatat `DOSE_REMOVED`. |
| A5 | Siap diuji | Konfirmasi sebelum jam jadwal dicatat sebagai `EARLY`; bukti IR dari kompartemen mana pun dapat membuka konfirmasi jadwal yang tidak terikat ruang. |
| A6 | Siap diuji | Konfirmasi hingga batas toleransi keterlambatan dicatat sebagai `ON_TIME`. |
| A7 | Siap diuji | Konfirmasi setelah toleransi dicatat sebagai `LATE`, sebelum batas missed dua jam. |
| A8 | Siap diuji | Saat aplikasi aktif/dibuka, jadwal yang belum dikonfirmasi lebih dari dua jam setelah waktu dosis dicatat sebagai `MISSED`. |
| A9 | Siap dengan aplikasi terhubung | Pada menit jadwal, aplikasi mengirim `ALARM_1000` via BLE sehingga buzzer/LED aktif 1 detik. Uji dilakukan ketika BLE terhubung. |
| A10 | Siap diuji | Buat jadwal lalu tunggu waktu notifikasi lokal aplikasi; catat waktu target dan waktu notifikasi muncul. |
| A11 | Siap diuji | Notifikasi lokal pengisian ulang dijadwalkan setiap pukul 08.00, ditambah peringatan saat sensor berubah kosong. |
| A12 | Siap diuji | Keluarkan obat sampai IR tidak mendeteksi obat; status kompartemen harus kosong. |
| A13 | Siap diuji | Isi ulang kompartemen kosong; status harus berubah kembali menjadi berisi. |
| A14 | Siap diuji | Lepaskan koneksi, lakukan kejadian sensor, sambungkan lagi, lalu cek riwayat tersinkron dari NVS/perangkat. |
| A15 | Siap secara kode / Fisik | Ulangi A1–A4 pada kanal 1–5. Lulus hanya jika kelima IR dan limit switch benar-benar terpasang dan terbaca. |
| A16 | Siap diuji | Buat beberapa jadwal tanpa memilih kompartemen. Ambil obat dari kompartemen mana pun lalu lakukan konfirmasi dosis di aplikasi. |

## Paket B — Separation Alert & Caregiver Escalation

| ID | Status | Prosedur & hasil yang harus dicatat |
| --- | --- | --- |
| B1 | Siap diuji | Putuskan BLE mendadak (jauhkan perangkat atau matikan MEDBOX); aplikasi harus mencatat putus koneksi. |
| B2 | Siap diuji | Setelah disconnect tidak disengaja, notifikasi pasien dijadwalkan 60 detik kemudian. |
| B3 | Siap diuji | Sambungkan kembali sebelum timer selesai; timer/notifikasi lokal dibatalkan. Verifikasi tidak ada peringatan tersisa. |
| B4 | Siap diuji | Setelah 60 detik peringatan pasien dan tambahan 5 menit tanpa reconnect, backend mengirim alert ke caregiver. |
| B5 | Siap diuji | Menu Keluarga & Profil memiliki tombol **Saya meninggalkan MEDBOX** untuk eskalasi langsung. |
| B6 | Siap diuji | Reconnect setelah peringatan pasien menghasilkan event `SEPARATION_FALSE_ALARM` di riwayat. |
| B7 | Siap diuji | Riwayat menyimpan status latensi dalam milidetik untuk peringatan pasien dan eskalasi caregiver. |

## Paket C — System Reliability & Recovery

| ID | Status | Prosedur & hasil yang harus dicatat |
| --- | --- | --- |
| C1 | Siap diuji | Putuskan koneksi BLE tanpa menekan disconnect; cek aplikasi tetap stabil dan mencatat status terputus. |
| C2 | Siap diuji | Aktifkan reconnect otomatis, pulihkan daya/jarak MEDBOX, lalu ukur lama sampai BLE terhubung lagi. |
| C3 | Belum / Fisik | Belum ada pembacaan tegangan baterai nyata; indikator baterai firmware masih sementara. Perlu rangkaian pembagi tegangan atau fuel-gauge. |
| C4 | Siap diuji | Kirim perintah reset dari alat uji/BLE, lalu pastikan firmware kembali mengiklankan perangkat. |
| C5 | Siap diuji | Ubah konfigurasi, reboot ESP32-C3, lalu cek konfigurasi dan event offline tetap ada dari NVS. |
| C6 | Tidak diuji | RTC tidak digunakan pada prototipe ini; item ini dikeluarkan dari kriteria penerimaan. |
| C7 | Siap sebagian | Konfigurasi/event perangkat dipulihkan dari NVS dan jadwal/riwayat aplikasi dari SQLite; status dosis yang belum diklasifikasi otomatis perlu perbaikan A5–A8. |

## Paket D — Battery Endurance

Semua item D memerlukan pengukuran fisik; aplikasi tidak boleh dipakai sebagai
bukti arus atau durasi baterai.

| ID | Status | Cara uji |
| --- | --- | --- |
| D1 | Fisik | Ukur arus rata-rata MEDBOX saat standby dengan sensor aktif dan BLE idle. |
| D2 | Fisik | Ukur arus rata-rata saat BLE advertising dan saat terhubung aplikasi. |
| D3 | Fisik | Bandingkan arus dengan IR dimatikan/dihidupkan atau catat arus tiap sensor aktif. |
| D4 | Fisik | Ukur arus puncak dan durasi saat buzzer berbunyi. |
| D5 | Fisik | Jalankan pola penggunaan normal yang didefinisikan, mulai dari baterai penuh hingga batas aman, lalu catat durasi dan tegangan akhir. |

## Format catatan setiap sesi

Catat minimal: tanggal, penguji, versi APK, versi firmware, nomor
kompartemen, kondisi awal, langkah uji, hasil yang diharapkan, hasil aktual,
waktu target, waktu kejadian, status lulus/gagal, dan tautan foto/video.

## Prioritas sebelum menyatakan seluruh paket lulus

1. Lakukan uji nyata A1–C7 sesuai prosedur dan simpan bukti.
2. Tambahkan pembacaan baterai fisik.
3. Lakukan seluruh Paket D menggunakan alat ukur eksternal.
