import '../l10n/localization.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/medication_schedule.dart';

class NotificationService {
  String languageCode = 'en';
  AppLocalizations get l10n => stringsForLanguage(languageCode);
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
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          AndroidNotificationChannel(
            'family_alerts',
            l10n.familyAlert,
            description: l10n.alertsFromCaregiversAndFamilyMembers,
            importance: Importance.high,
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
      title: l10n.timeToTakeMedication2,
      body: schedule.compartmentNumber == null
          ? l10n.openMeditraceNow(
              (schedule.label).toString(),
              (schedule.timeText).toString(),
            )
          : l10n.checkCompartment(
              (schedule.label).toString(),
              (schedule.timeText).toString(),
              (schedule.compartmentNumber).toString(),
            ),
      scheduledDate: when,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_reminders',
          l10n.medicationReminder,
          channelDescription: l10n.dailyMeditraceMedicationReminders,
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
      title: l10n.meditraceNotDetected,
      body: l10n.makeSureTheMedicationBoxHasNotBeen,
      scheduledDate: tz.TZDateTime.now(tz.local).add(delay),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'device_alerts',
          l10n.deviceAlerts,
          channelDescription: l10n.meditraceConnectionAndRefillAlerts,
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
      title: l10n.checkMeditraceContents,
      body: l10n.thisMorningMakeSureTheMedicationCompartmentsAre,
      scheduledDate: when,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'device_alerts',
          l10n.deviceAlerts,
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
    title: l10n.meditraceIsMovingOutOfRange,
    body: l10n.meditraceSignalIsWeakMakeSureTheMedication,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        'device_alerts',
        l10n.deviceAlerts,
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
  );

  Future<void> showRefillAlert() => _plugin.show(
    id: 2002,
    title: l10n.meditraceNeedsARefill,
    body: l10n.oneOrMoreMedicationCompartmentsAreEmpty,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        'device_alerts',
        l10n.deviceAlerts,
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
  );

  Future<void> showScheduledDoseAlert(String body) => _plugin.show(
    id: DateTime.now().millisecondsSinceEpoch.remainder(1000000) + 4000,
    title: l10n.meditraceAlarm,
    body: body,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        'medication_reminders',
        l10n.medicationReminder,
        channelDescription: l10n.dailyMeditraceMedicationReminders,
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
  );

  Future<void> showDoseTakenAlert(String body) => _plugin.show(
    id: DateTime.now().millisecondsSinceEpoch.remainder(1000000) + 4000,
    title: l10n.medicationTaken3,
    body: body,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        'medication_reminders',
        l10n.medicationReminder,
        channelDescription: l10n.meditraceMedicationStatus,
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
  );

  Future<void> showFamilyAlert(String title) => _plugin.show(
    id: DateTime.now().millisecondsSinceEpoch.remainder(1000000) + 3000,
    title: l10n.meditraceFamilyAlert,
    body: title,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        'family_alerts',
        l10n.familyAlert,
        channelDescription: l10n.alertsFromMeditraceFamilyMembers,
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
  );
}
