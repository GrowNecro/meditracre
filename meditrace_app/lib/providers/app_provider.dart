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
  String patientName = 'Pengguna MEDITRACE';
  String familyName = 'Keluarga Saya';
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
      patientName = await _database.getSetting('patient_name') ?? patientName;
      familyName = await _database.getSetting('family_name') ?? familyName;
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

  Future<void> addEvent(DoseEvent event) async {
    await _database.addEvent(event);
    history = [event, ...history].take(100).toList();
    notifyListeners();
  }

  bool doseConfirmedToday(int scheduleId) {
    final now = DateTime.now();
    for (final event in history) {
      if (event.scheduleId != scheduleId ||
          (event.type != 'DOSE_CONFIRMED' &&
              event.type != 'DOSE_CONFIRMATION_REVOKED')) {
        continue;
      }
      final time = event.timestamp.toLocal();
      if (time.year == now.year &&
          time.month == now.month &&
          time.day == now.day) {
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
      return 'Obat diminum berdasarkan pengambilan.';
    }
    final status = _doseTimingStatusAt(schedule, event.timestamp.toLocal());
    final timing = switch (status) {
      'EARLY' => 'lebih awal',
      'ON_TIME' => 'tepat waktu',
      _ => 'terlambat',
    };
    return 'Obat diminum $timing.';
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

  Future<void> setDoseConfirmed(MedicationSchedule schedule, bool confirmed) =>
      addEvent(
        DoseEvent(
          type: confirmed ? 'DOSE_CONFIRMED' : 'DOSE_CONFIRMATION_REVOKED',
          timestamp: DateTime.now(),
          scheduleId: schedule.id,
          sensorId: schedule.compartmentNumber,
          status: confirmed
              ? doseTimingStatus(schedule, now: DateTime.now())
              : 'DIBATALKAN',
        ),
      );

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
