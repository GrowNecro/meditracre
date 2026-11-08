import '../l10n/localization.dart';

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/dose_event.dart';
import '../models/medication_schedule.dart';
import '../services/local_database.dart';
import '../services/family_alert_relay.dart';
import '../services/notification_service.dart';

class AppProvider extends ChangeNotifier {
  AppProvider({LocalDatabase? database})
    : _database = database ?? LocalDatabase();

  final LocalDatabase _database;
  late final FamilyAlertRelay familyAlerts = FamilyAlertRelay(_database);
  Timer? _familyRetryTimer;
  StreamSubscription<RemoteMessage>? _familyPushMessages;
  final NotificationService notifications = NotificationService();
  List<MedicationSchedule> schedules = [];
  List<DoseEvent> history = [];
  String _languageCode = 'en';
  String get languageCode => _languageCode;
  AppLocalizations get l10n => stringsForLanguage(_languageCode);
  String? _patientName;
  String get patientName => _patientName ?? l10n.meditraceUser;
  set patientName(String value) => _patientName = value;
  String? _familyName;
  String get familyName => _familyName ?? l10n.myFamily;
  set familyName(String value) => _familyName = value;
  int? patientAge;
  String emergencyPhone = '';
  String emergencyEmail = '';
  int separationMinutes = 5;
  String? pairedDeviceId;
  bool autoReconnectEnabled = false;
  bool initialized = false;
  static const int missedGraceMinutes = 120;

  /// Membuat ID yang aman untuk SQLite dan Android notification ID.
  ///
  /// Jangan memakai timestamp modulo karena nilainya akan berulang dan dapat
  /// menimpa jadwal yang sudah ada.
  int createScheduleId() {
    final random = Random.secure();
    var id = random.nextInt(0x7fffffff - 1000) + 1000;
    while (schedules.any((schedule) => schedule.id == id)) {
      id = random.nextInt(0x7fffffff - 1000) + 1000;
    }
    return id;
  }

  /// Meminta izin dari aksi pengguna, saat tidak ada dialog Flutter yang
  /// sedang ditutup. Penolakan izin tidak boleh membatalkan penyimpanan lokal.
  Future<bool> requestNotificationPermission() async {
    try {
      return await notifications.requestPermission();
    } catch (_) {
      return false;
    }
  }

  Future<void> initialize() async {
    try {
      final saved = await _database.getSetting('language_code');
      _languageCode = saved == 'id' ? 'id' : 'en';
      notifyListeners();
    } catch (_) {
      // English is the default when local storage is unavailable.
    }
    notifications.languageCode = _languageCode;
    try {
      await notifications.initialize();
    } catch (_) {
      // Plugin native tidak tersedia pada unit/widget test.
    }
    try {
      if (Firebase.apps.isNotEmpty) {
        _familyPushMessages = FirebaseMessaging.onMessage.listen((message) {
          final title = message.notification?.body;
          if (title != null && title.isNotEmpty) {
            unawaited(notifications.showFamilyAlert(title));
          }
        });
      }
    } catch (_) {
      // Firebase belum dikonfigurasi pada build lokal/test.
    }
    try {
      _patientName = await _database.getSetting('patient_name');
      _familyName = await _database.getSetting('family_name');
      patientAge = int.tryParse(
        await _database.getSetting('patient_age') ?? '',
      );
      emergencyPhone = await _database.getSetting('emergency_phone') ?? '';
      emergencyEmail = await _database.getSetting('emergency_email') ?? '';
      separationMinutes =
          int.tryParse(
            await _database.getSetting('separation_minutes') ?? '',
          ) ??
          5;
      pairedDeviceId = await _database.getSetting('paired_device_id');
      autoReconnectEnabled =
          (await _database.getSetting('auto_reconnect_enabled')) == 'true';
      schedules = await _database.loadSchedules();
      history = await _database.loadEvents();
      await familyAlerts.initialize();
      await refreshMissedDoses();
      await _scheduleMorningRefillSafely();
    } catch (_) {
      // State default tetap membuat aplikasi dapat berjalan pada test.
    }
    initialized = true;
    _familyRetryTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => unawaited(familyAlerts.flush()),
    );
    notifyListeners();
  }

  Future<void> saveSchedule(MedicationSchedule value) async {
    // Tulis data terlebih dahulu. Jika SQLite gagal, state layar tidak berubah.
    final saved = value.copyWith(updatedAt: DateTime.now());
    await _database.saveSchedule(saved);

    final index = schedules.indexWhere((item) => item.id == saved.id);
    if (index < 0) {
      schedules = [...schedules, saved];
    } else {
      schedules = [...schedules]..[index] = saved;
    }
    schedules.sort(
      (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
    );
    notifyListeners();

    // Notifikasi bersifat pelengkap: kegagalan plugin/izin tidak boleh
    // membatalkan jadwal lokal atau merusak lifecycle UI.
    unawaited(_scheduleNotificationSafely(saved));
  }

  Future<void> _scheduleNotificationSafely(MedicationSchedule value) async {
    try {
      await notifications.scheduleMedication(value);
    } catch (_) {
      // Jadwal tetap tersimpan di SQLite dan masih dapat disinkronkan ke ESP32.
    }
  }

  Future<void> _scheduleMorningRefillSafely() async {
    try {
      await notifications.scheduleMorningRefill();
    } catch (_) {
      // Pengingat lokal tidak boleh menghambat data jadwal atau BLE.
    }
  }

  Future<void> removeSchedule(int id) async {
    await _database.deleteSchedule(id);
    schedules = schedules.where((item) => item.id != id).toList();
    notifyListeners();
    unawaited(
      _scheduleNotificationSafely(
        MedicationSchedule(
          id: id,
          label: '',
          hour: 0,
          minute: 0,
          enabled: false,
        ),
      ),
    );
  }

  Future<bool> addEvent(DoseEvent event) async {
    if (event.type == 'DOSE_CONFIRMED' &&
        event.scheduleId != null &&
        _doseConfirmedOnDate(event.scheduleId!, event.timestamp)) {
      return false;
    }
    history = [event, ...history].take(100).toList();
    notifyListeners();
    await _database.addEvent(event);
    return true;
  }

  bool doseConfirmedToday(int scheduleId) {
    return _doseConfirmedOnDate(scheduleId, DateTime.now());
  }

  bool _doseConfirmedOnDate(int scheduleId, DateTime date) {
    final localDate = date.toLocal();
    for (final event in history) {
      if (event.scheduleId != scheduleId ||
          (event.type != 'DOSE_CONFIRMED' &&
              event.type != 'DOSE_CONFIRMATION_REVOKED')) {
        continue;
      }
      final time = event.timestamp.toLocal();
      if (time.year == localDate.year &&
          time.month == localDate.month &&
          time.day == localDate.day) {
        return event.type == 'DOSE_CONFIRMED';
      }
    }
    return false;
  }

  /// Pengambilan sensor tetap berdiri sendiri; pengguna tetap menekan
  /// “Sudah minum”. Untuk jadwal baru yang tidak terikat ruang, bukti sensor
  /// dari kompartemen mana pun dapat dipakai untuk membuka konfirmasi.
  bool hasDoseRemovedTodayFor(MedicationSchedule schedule, {DateTime? now}) {
    final room = schedule.compartmentNumber;
    final today = (now ?? DateTime.now()).toLocal();
    return history.any((event) {
      final time = event.timestamp.toLocal();
      return event.type == 'DOSE_REMOVED' &&
          (room == null || event.sensorId == room) &&
          time.year == today.year &&
          time.month == today.month &&
          time.day == today.day;
    });
  }

  String doseRemovalNotificationText(DoseEvent event) {
    final schedule = _scheduleForDoseEvent(event);
    if (schedule == null) {
      return l10n.medicationTakenBasedOnRemoval;
    }
    final status = _doseTimingStatusAt(schedule, event.timestamp.toLocal());
    final timing = switch (status) {
      'EARLY' => l10n.early,
      'ON_TIME' => l10n.onTime,
      _ => l10n.late,
    };
    return l10n.medicationTaken((timing).toString());
  }

  DoseEvent doseTakenFromRemoval(DoseEvent event) {
    final schedule = _scheduleForDoseEvent(event);
    return DoseEvent(
      type: 'DOSE_CONFIRMED',
      timestamp: event.timestamp,
      sensorId: event.sensorId,
      scheduleId: event.scheduleId ?? schedule?.id,
      status: schedule == null
          ? event.status
          : _doseTimingStatusAt(schedule, event.timestamp.toLocal()),
    );
  }

  Future<bool> handleCompartmentRefilled(
    int compartment,
    DateTime returnedAt,
  ) async {
    DoseEvent? confirmed;
    for (final event in history) {
      if (event.type == 'DOSE_CONFIRMED' && event.sensorId == compartment) {
        confirmed = event;
        break;
      }
    }
    if (confirmed == null) return false;
    final elapsed = returnedAt.difference(confirmed.timestamp).abs();
    if (elapsed > const Duration(minutes: 15)) return false;
    if (confirmed.scheduleId != null &&
        !_doseConfirmedOnDate(confirmed.scheduleId!, confirmed.timestamp)) {
      return false;
    }
    await addEvent(
      DoseEvent(
        type: 'DOSE_CONFIRMATION_REVOKED',
        timestamp: returnedAt,
        sensorId: compartment,
        scheduleId: confirmed.scheduleId,
        status: 'DIKEMBALIKAN_DALAM_15_MENIT',
      ),
    );
    return true;
  }

  MedicationSchedule? _scheduleForDoseEvent(DoseEvent event) {
    final candidates = schedules
        .where(
          (schedule) =>
              schedule.enabled &&
              (schedule.compartmentNumber == null ||
                  schedule.compartmentNumber == event.sensorId),
        )
        .toList();
    if (candidates.isEmpty) return null;
    final eventTime = event.timestamp.toLocal();
    MedicationSchedule? closest;
    var closestDifference = const Duration(days: 2);
    for (final schedule in candidates) {
      for (var dayOffset = -1; dayOffset <= 1; dayOffset++) {
        final scheduledAt = DateTime(
          eventTime.year,
          eventTime.month,
          eventTime.day + dayOffset,
          schedule.hour,
          schedule.minute,
        );
        final difference = eventTime.difference(scheduledAt).abs();
        if (difference < closestDifference) {
          closestDifference = difference;
          closest = schedule;
        }
      }
    }
    return closest;
  }

  String _doseTimingStatusAt(MedicationSchedule schedule, DateTime localNow) {
    final scheduledAt = DateTime(
      localNow.year,
      localNow.month,
      localNow.day,
      schedule.hour,
      schedule.minute,
    );
    if (localNow.isBefore(scheduledAt)) return 'EARLY';
    if (!localNow.isAfter(
      scheduledAt.add(Duration(minutes: schedule.lateTolerance)),
    )) {
      return 'ON_TIME';
    }
    return 'LATE';
  }

  bool scheduleTimeReached(MedicationSchedule schedule, {DateTime? now}) {
    final localNow = (now ?? DateTime.now()).toLocal();
    final scheduledMinute = schedule.hour * 60 + schedule.minute;
    final currentMinute = localNow.hour * 60 + localNow.minute;
    return currentMinute >= scheduledMinute;
  }

  bool canConfirmScheduledDose(MedicationSchedule schedule, {DateTime? now}) {
    if (doseConfirmedToday(schedule.id) || doseMissedToday(schedule.id)) {
      return false;
    }
    return scheduleTimeReached(schedule, now: now) ||
        hasDoseRemovedTodayFor(schedule, now: now);
  }

  MedicationSchedule? nextSchedule({DateTime? now}) {
    unawaited(refreshMissedDoses(now: now));
    final localNow = (now ?? DateTime.now()).toLocal();
    final active = schedules.where((schedule) => schedule.enabled).toList()
      ..sort(
        (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
      );
    if (active.isEmpty) return null;

    // Prioritaskan jadwal hari ini yang sudah lewat tetapi belum dikonfirmasi.
    final pendingDue = active
        .where(
          (schedule) =>
              !doseConfirmedToday(schedule.id) &&
              !doseMissedToday(schedule.id) &&
              schedule.hour * 60 + schedule.minute <=
                  localNow.hour * 60 + localNow.minute,
        )
        .toList();
    if (pendingDue.isNotEmpty) return pendingDue.last;

    return active.firstWhere(
      (schedule) =>
          schedule.hour * 60 + schedule.minute >
          localNow.hour * 60 + localNow.minute,
      orElse: () => active.first,
    );
  }

  Future<void> setDoseConfirmed(
    MedicationSchedule schedule,
    bool confirmed,
  ) async {
    final now = DateTime.now();
    final status = confirmed
        ? doseTimingStatus(schedule, now: now)
        : 'DIBATALKAN';
    final recorded = await addEvent(
      DoseEvent(
        type: confirmed ? 'DOSE_CONFIRMED' : 'DOSE_CONFIRMATION_REVOKED',
        timestamp: now,
        scheduleId: schedule.id,
        sensorId: schedule.compartmentNumber,
        status: status,
      ),
    );
    if (confirmed && recorded) {
      unawaited(
        familyAlerts.report(
          kind: 'dose_status',
          title: l10n.medicationStatusTaken,
          details: l10n.medicationScheduledAsWasRecordedAsTaken(
            (schedule.label).toString(),
            (_timingLabel(status)).toString(),
          ),
        ),
      );
    }
  }

  String _timingLabel(String status) => switch (status) {
    'EARLY' => l10n.early2,
    'ON_TIME' => l10n.onTime,
    'LATE' => l10n.late,
    _ => l10n.recorded,
  };

  String doseTimingStatus(MedicationSchedule schedule, {DateTime? now}) {
    final localNow = (now ?? DateTime.now()).toLocal();
    final scheduledAt = DateTime(
      localNow.year,
      localNow.month,
      localNow.day,
      schedule.hour,
      schedule.minute,
    );
    if (localNow.isBefore(scheduledAt)) return 'EARLY';
    if (!localNow.isAfter(
      scheduledAt.add(Duration(minutes: schedule.lateTolerance)),
    )) {
      return 'ON_TIME';
    }
    return 'LATE';
  }

  bool doseMissedToday(int scheduleId, {DateTime? now}) {
    final localNow = (now ?? DateTime.now()).toLocal();
    return history.any((event) {
      final time = event.timestamp.toLocal();
      return event.type == 'DOSE_MISSED' &&
          event.scheduleId == scheduleId &&
          time.year == localNow.year &&
          time.month == localNow.month &&
          time.day == localNow.day;
    });
  }

  /// Catat jadwal yang melewati masa pengambilan dua jam. Proses ini aman
  /// dipanggil berulang karena satu jadwal hanya mendapat satu event missed
  /// per hari. Bila aplikasi benar-benar tertutup, pengecekan terjadi lagi
  /// saat aplikasi dibuka.
  Future<void> refreshMissedDoses({DateTime? now}) async {
    final localNow = (now ?? DateTime.now()).toLocal();
    for (final schedule in schedules.where((item) => item.enabled)) {
      final due = DateTime(
        localNow.year,
        localNow.month,
        localNow.day,
        schedule.hour,
        schedule.minute,
      );
      final effectiveDue =
          schedule.updatedAt != null &&
              due.isBefore(schedule.updatedAt!.toLocal())
          ? due.add(const Duration(days: 1))
          : due;
      if (localNow.isAfter(
            effectiveDue.add(const Duration(minutes: missedGraceMinutes)),
          ) &&
          !doseConfirmedToday(schedule.id) &&
          !hasDoseRemovedTodayFor(schedule, now: localNow) &&
          !doseMissedToday(schedule.id, now: localNow)) {
        await addEvent(
          DoseEvent(
            type: 'DOSE_MISSED',
            timestamp: localNow,
            scheduleId: schedule.id,
            status: 'MISSED',
          ),
        );
      }
    }
  }

  Future<void> clearHistory() async {
    history = [];
    await _database.clearEvents();
    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    required String family,
    int? age,
    String emergencyPhone = '',
    String emergencyEmail = '',
  }) async {
    patientName = name.trim().isEmpty ? patientName : name.trim();
    familyName = family.trim().isEmpty ? familyName : family.trim();
    patientAge = age;
    this.emergencyPhone = emergencyPhone.trim();
    this.emergencyEmail = emergencyEmail.trim();
    await _database.setSetting('patient_name', patientName);
    await _database.setSetting('family_name', familyName);
    await _database.setSetting(
      'patient_age',
      patientAge == null ? '' : '$patientAge',
    );
    await _database.setSetting('emergency_phone', this.emergencyPhone);
    await _database.setSetting('emergency_email', this.emergencyEmail);
    notifyListeners();
  }

  Future<void> setSeparationMinutes(int value) async {
    separationMinutes = value;
    await _database.setSetting('separation_minutes', '$separationMinutes');
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    if ((value != 'en' && value != 'id') || value == _languageCode) return;
    await _database.setSetting('language_code', value);
    _languageCode = value;
    notifications.languageCode = value;
    notifyListeners();
    // Replace pending reminders so they use the newly selected language.
    for (final schedule in schedules) {
      await _scheduleNotificationSafely(schedule);
    }
    await _scheduleMorningRefillSafely();
  }

  /// Hanya dipanggil setelah pengguna memilih perangkat dari hasil scan.
  /// Pilihan manual mengaktifkan kembali auto-connect perangkat tersebut.
  Future<void> saveManualPairing(String remoteId) async {
    pairedDeviceId = remoteId;
    autoReconnectEnabled = true;
    await _database.setSetting('paired_device_id', remoteId);
    await _database.setSetting('auto_reconnect_enabled', 'true');
    notifyListeners();
  }

  /// Disconnect manual harus tetap manual pada pembukaan aplikasi berikutnya.
  Future<void> disableAutoReconnect() async {
    autoReconnectEnabled = false;
    await _database.setSetting('auto_reconnect_enabled', 'false');
    notifyListeners();
  }

  @override
  void dispose() {
    _familyRetryTimer?.cancel();
    unawaited(_familyPushMessages?.cancel());
    familyAlerts.dispose();
    unawaited(_database.close());
    super.dispose();
  }
}
