import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/medication_schedule.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Bangkok'));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
  }

  Future<bool> requestPermission() async =>
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission() ??
      true;

  Future<void> scheduleMedication(MedicationSchedule schedule) async {
    await _plugin.cancel(id: 1000 + schedule.id);
    if (!schedule.enabled) return;
    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      schedule.hour,
      schedule.minute,
    );
    if (!when.isAfter(now)) when = when.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      id: 1000 + schedule.id,
      title: 'Waktunya minum obat',
      body: schedule.compartmentNumber == null
          ? '${schedule.label} • ${schedule.timeText}. Buka MEDITRACE sekarang.'
          : '${schedule.label} • ${schedule.timeText}. Periksa ruang ${schedule.compartmentNumber}.',
      scheduledDate: when,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_reminders',
          'Pengingat obat',
          channelDescription: 'Pengingat jadwal obat harian MEDITRACE',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'schedule',
    );
  }

  Future<void> scheduleSeparationAlert(Duration delay) async {
    await _plugin.cancel(id: 2001);
    await _plugin.zonedSchedule(
      id: 2001,
      title: 'MEDITRACE tidak terdeteksi',
      body: 'Pastikan kotak obat tidak tertinggal.',
      scheduledDate: tz.TZDateTime.now(tz.local).add(delay),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'device_alerts',
          'Peringatan perangkat',
          channelDescription: 'Peringatan koneksi dan isi ulang MEDITRACE',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'separation',
    );
  }

  Future<void> cancelSeparationAlert() => _plugin.cancel(id: 2001);

  Future<void> scheduleMorningRefill() async {
    await _plugin.cancel(id: 2004);
    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(tz.local, now.year, now.month, now.day, 8);
    if (!when.isAfter(now)) when = when.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      id: 2004,
      title: 'Periksa isi MEDITRACE',
      body: 'Pagi ini, pastikan kompartemen obat telah terisi untuk jadwal berikutnya.',
      scheduledDate: when,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'device_alerts',
          'Peringatan perangkat',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'morning_refill',
    );
  }

  Future<void> showWeakSignalAlert() => _plugin.show(
    id: 2003,
    title: 'MEDITRACE mulai jauh',
    body: 'Sinyal MEDITRACE lemah. Pastikan kotak obat masih bersama Anda.',
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'device_alerts',
        'Peringatan perangkat',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
  );

  Future<void> showRefillAlert() => _plugin.show(
    id: 2002,
    title: 'MEDITRACE perlu diisi',
    body: 'Satu atau lebih ruang obat terdeteksi kosong.',
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'device_alerts',
        'Peringatan perangkat',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
  );

  Future<void> showScheduledDoseAlert(String body) => _plugin.show(
    id: DateTime.now().millisecondsSinceEpoch.remainder(1000000) + 4000,
    title: 'Alarm MEDITRACE',
    body: body,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'medication_reminders',
        'Pengingat obat',
        channelDescription: 'Pengingat jadwal obat harian MEDITRACE',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
  );

  Future<void> showDoseTakenAlert(String body) => _plugin.show(
    id: DateTime.now().millisecondsSinceEpoch.remainder(1000000) + 4000,
    title: 'Obat diminum',
    body: body,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'medication_reminders',
        'Pengingat obat',
        channelDescription: 'Status minum obat MEDITRACE',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
  );

  Future<void> showFamilyAlert(String title) => _plugin.show(
    id: DateTime.now().millisecondsSinceEpoch.remainder(1000000) + 3000,
    title: 'Peringatan keluarga MEDITRACE',
    body: title,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'family_alerts',
        'Peringatan keluarga',
        channelDescription: 'Peringatan dari anggota keluarga MEDITRACE',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
  );
}
