# Protokol BLE MEDITRACE v0.1

Service: `7d2ea28a-f7bd-485a-bd9d-92ad6ecfe001`

| Characteristic | UUID akhir | Arah | Properti |
| --- | --- | --- | --- |
| Device Info | `e002` | ESP32 → Flutter | Read |
| Command | `e003` | Flutter → ESP32 | Write |
| Status | `e004` | ESP32 → Flutter | Read, Notify |
| Config | `e005` | dua arah | Read, Write |
| Event | `e006` | ESP32 → Flutter | Notify |

Semua payload memakai UTF-8. Command yang tersedia: `PING`, `GET_STATUS`,
`LED_ON`, `LED_OFF`, `BUZZER_ON`, `BUZZER_OFF`, `SYNC_TIME:<unix>`,
`GET_SENSOR`, `SET_SCHEDULE`, `GET_PENDING_EVENTS`, `CLEAR_SYNCED_EVENTS`, dan
`RESET`. Command juga dapat dibungkus JSON dengan field `command`.

Contoh konfigurasi jadwal melalui CONFIG characteristic:

```json
{"schedule":["08:00","13:00","20:00"]}
```

`GET_STATUS` menghasilkan status baterai, RTC, alarm, dan jumlah event pending.

Mulai firmware C3 0.9.7, baterai memakai estimasi waktu aktif berdasarkan
1500 mAh / 150 mA (10 jam). `battery_estimated: true` dan
`battery_voltage: null` menandakan persentase bukan hasil pengukuran ADC.
Pemasangan pertama mengasumsikan 100%; pengisian tidak dideteksi otomatis.
Kirim `BATTERY_FULL` setelah pengguna mengonfirmasi baterai sudah dicas penuh
untuk memulai kembali estimasi dari 100%. Status baterai dikirim setiap 30 detik.
Pemakaian disimpan di NVS setiap 5 menit dan sebelum restart normal/OTA;
mati mendadak bisa kehilangan catatan maksimal sekitar 5 menit. Waktu mati
dan pengosongan alami baterai tidak dihitung. Kapasitas dan arus ini adalah
asumsi, sehingga persentase dan durasi dapat berbeda dari kondisi sebenarnya.

```json
{"battery":82,"rtc":true,"alarm":false,"pending":0}
```

Device Info menghasilkan JSON dengan `device_id`, `device_name`, `firmware`, dan
`battery`. Payload CONFIG dan event sensor dipersistenkan melalui NVS.
