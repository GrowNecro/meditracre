import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meditrace_app/main.dart';
import 'package:meditrace_app/models/device_info.dart';
import 'package:meditrace_app/models/dose_event.dart';
import 'package:meditrace_app/models/meditrace_device.dart';
import 'package:meditrace_app/models/medication_schedule.dart';
import 'package:meditrace_app/providers/app_provider.dart';
import 'package:meditrace_app/services/ble_service.dart';
import 'package:meditrace_app/services/battery_estimate.dart';
import 'package:meditrace_app/services/local_database.dart';

void main() {
  testWidgets('menampilkan kondisi awal disconnected', (tester) async {
    await tester.pumpWidget(MeditraceApp(bleService: _FakeBleService()));

    expect(find.text('MEDBOX belum terhubung'), findsOneWidget);
    expect(find.text('Belum terhubung'), findsNothing);
    expect(find.byIcon(Icons.bluetooth_searching), findsOneWidget);
  });

  testWidgets('pembatalan tambah jadwal tidak merusak navigator', (
    tester,
  ) async {
    await tester.pumpWidget(
      MeditraceApp(
        bleService: _FakeBleService(),
        database: _MemoryLocalDatabase(),
      ),
    );
    await tester.tap(find.text('Jadwal').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
    await tester.tapAt(const Offset(1, 1));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Jadwal Obat'), findsOneWidget);
  });

  testWidgets('jadwal baru tidak meminta pemilihan ruang obat', (tester) async {
    await tester.pumpWidget(
      MeditraceApp(
        bleService: _FakeBleService(),
        database: _MemoryLocalDatabase(),
      ),
    );
    await tester.tap(find.text('Jadwal').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih ruang obat'), findsNothing);
    expect(find.text('Setiap hari'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(find.text('Jadwal Obat'), findsOneWidget);
  });

  testWidgets('menutup dialog profil tidak memakai field yang sudah dibuang', (
    tester,
  ) async {
    await tester.pumpWidget(MeditraceApp(bleService: _FakeBleService()));
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Profil lokal'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Keluarga & Profil'), findsOneWidget);
  });

  test('parsing device info aman untuk payload minimum', () {
    final info = DeviceInfo.fromJson({
      'device_id': 'MEDITRACE-A13F',
      'firmware': '0.1.0',
      'battery': 82,
    });

    expect(info.deviceName, 'MEDITRACE-A13F');
    expect(info.battery, 82);
    expect(info.compartmentCount, 2);
    expect(
      DeviceInfo.fromJson({
        'device_id': 'MEDITRACE-C3-1234',
        'board': 'ESP32-C3',
      }).compartmentCount,
      5,
    );
  });

  test('jadwal lama tetap terbaca dan jadwal baru menyimpan nomor ruang', () {
    final legacy = MedicationSchedule.fromJson({
      'id': 1,
      'label': 'Vitamin',
      'hour': 8,
      'minute': 30,
    });
    expect(legacy.compartmentNumber, isNull);
    final updated = legacy.copyWith(compartmentNumber: 3);
    expect(updated.toJson()['compartment_number'], 3);
    expect(MedicationSchedule.fromJson(updated.toJson()).compartmentNumber, 3);
    expect(legacy.copyWith(label: 'Vitamin pagi').label, 'Vitamin pagi');
  });

  test('jadwal tetap dikelola aplikasi tanpa RTC perangkat', () {
    final app = AppProvider(database: _MemoryLocalDatabase());
    app.schedules = const [
      MedicationSchedule(
        id: 91,
        label: 'Vitamin',
        hour: 8,
        minute: 30,
        compartmentNumber: 3,
      ),
      MedicationSchedule(id: 92, label: 'Jadwal lama', hour: 9, minute: 0),
    ];
    expect(app.schedules, hasLength(2));
    expect(app.schedules.first.timeText, '08:30');
    expect(app.schedules.last.timeText, '09:00');
    app.dispose();
  });

  test('estimasi baterai memakai kapasitas dan arus rata-rata C3', () {
    expect(BatteryEstimate.label(100), '10 jam 0 menit');
    expect(BatteryEstimate.label(82), '8 jam 12 menit');
    expect(BatteryEstimate.label(15), '1 jam 30 menit');
    expect(BatteryEstimate.label(0), 'Belum tersedia');
  });

  test('konfirmasi minum obat bisa dicatat dan dibatalkan', () async {
    final database = _MemoryLocalDatabase();
    final app = AppProvider(database: database);
    const schedule = MedicationSchedule(
      id: 12,
      label: 'Vitamin',
      hour: 8,
      minute: 0,
      compartmentNumber: 2,
    );
    expect(app.doseConfirmedToday(schedule.id), isFalse);
    await app.setDoseConfirmed(schedule, true);
    expect(app.doseConfirmedToday(schedule.id), isTrue);
    expect(database.events.single.scheduleId, 12);
    expect(database.events.single.sensorId, 2);
    await app.setDoseConfirmed(schedule, false);
    expect(app.doseConfirmedToday(schedule.id), isFalse);
    expect(database.events.last.type, 'DOSE_CONFIRMATION_REVOKED');
    app.dispose();
  });

  testWidgets(
    'status C3 hanya menampilkan lima kompartemen dari payload lama',
    (tester) async {
      final service = _FakeBleService();
      await tester.pumpWidget(MeditraceApp(bleService: service));
      service.info = const DeviceInfo(
        deviceId: 'MEDITRACE-C3-1234',
        deviceName: 'MEDITRACE-C3-1234',
        firmware: '0.4.0',
        battery: 80,
        board: 'ESP32-C3',
      );
      service.emitConnected();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Perangkat'));
      await tester.pump();
      await tester.pumpAndSettle();

      service.emitStatus(
        '{"sensors":[1,0,0,0,0,0],"doors":[0,1,1,1,1,1],"sensor_valid":true}',
      );
      await tester.pump();
      service.emitStatus(
        '{"sensors":[1,0,0,0,0,0],"doors":[0,1,1,1,1,1],"sensor_valid":true}',
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Kompartemen 1'), 200);
      expect(find.text('Obat: Terisi'), findsOneWidget);
      expect(find.text('Pintu: Terbuka'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Kompartemen 5'), 250);
      expect(find.text('Kompartemen 5'), findsOneWidget);
      expect(find.text('Kompartemen 6', skipOffstage: false), findsNothing);

      service.emitStatus('{"sensors":[],"doors":[],"sensor_valid":false}');
      await tester.pump();
      expect(find.text('Obat: Belum terbaca'), findsWidgets);
      expect(find.text('Obat: Kosong'), findsNothing);
    },
  );

  testWidgets('Home langsung menampilkan status kompartemen C3', (
    tester,
  ) async {
    final service = _FakeBleService();
    await tester.pumpWidget(MeditraceApp(bleService: service));
    service.info = const DeviceInfo(
      deviceId: 'MEDITRACE-C3-1234',
      deviceName: 'MEDITRACE-C3-1234',
      firmware: '0.4.0',
      battery: 80,
      board: 'ESP32-C3',
    );
    service.emitConnected();
    await tester.pumpAndSettle();

    expect(find.text('Kotak obat'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Status kompartemen'), 250);
    expect(find.text('Status kompartemen'), findsOneWidget);
    expect(find.text('Perlu diisi'), findsOneWidget);
    expect(find.text('Pintu: Terbuka'), findsNothing);
    expect(find.text('RTC'), findsNothing);
    expect(find.text('Ruang 6', skipOffstage: false), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sinyal lemah berulang menampilkan peringatan dini', (
    tester,
  ) async {
    final service = _FakeBleService()..signal = -88;
    await tester.pumpWidget(MeditraceApp(bleService: service));
    service.emitConnected();
    await tester.pump();
    await tester.pump();
    final warning = find.textContaining('Sinyal lemah');

    await tester.pump(const Duration(seconds: 30));
    await tester.pump(const Duration(seconds: 30));
    await tester.pump();
    expect(warning, findsNothing);
    await tester.pump(const Duration(seconds: 30));
    await tester.pump();
    expect(warning, findsOneWidget);

    service.signal = -65;
    await tester.pump(const Duration(seconds: 30));
    await tester.pump(const Duration(seconds: 30));
    expect(warning, findsNothing);
  });

  testWidgets('RSSI buatan hanya dipakai untuk MEDITRACE-DUMMY', (
    tester,
  ) async {
    final service = _FakeBleService()..signal = -60;
    await tester.pumpWidget(MeditraceApp(bleService: service));
    service.info = const DeviceInfo(
      deviceId: 'MEDITRACE-DUMMY',
      deviceName: 'MEDITRACE-DUMMY',
      firmware: 'dummy-1.0',
      battery: 82,
      board: 'ESP32-C3',
    );
    service.emitConnected();
    await tester.pump();
    service.emitStatus('{"simulated_rssi":-90}');
    await tester.pump();
    await tester.pump(const Duration(seconds: 30));
    await tester.pump(const Duration(seconds: 30));
    await tester.pump(const Duration(seconds: 30));
    await tester.pump();
    expect(find.textContaining('Sinyal lemah'), findsOneWidget);

    service.emitStatus('{"simulated_rssi":-60}');
    await tester.pump();
    await tester.pump(const Duration(seconds: 30));
    await tester.pump(const Duration(seconds: 30));
    await tester.pump();
    expect(find.textContaining('Sinyal lemah'), findsNothing);
  });

  testWidgets('Home tetap terbaca di layar kecil dengan teks diperbesar', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final service = _FakeBleService();
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
        child: MeditraceApp(bleService: service),
      ),
    );
    service.info = const DeviceInfo(
      deviceId: 'MEDITRACE-C3-1234',
      deviceName: 'MEDITRACE-C3-1234',
      firmware: '0.4.0',
      battery: 80,
      board: 'ESP32-C3',
    );
    service.emitConnected();
    service.emitStatus(
      '{"sensors":[0,0,0,0,1],"doors":[1,1,1,1,1],"sensor_valid":true}',
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Isi obat sebelum jadwal berikutnya.'),
      200,
    );
    expect(find.text('1 dari 5 kompartemen terisi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('status dosis membedakan early, on-time, late, dan missed', () async {
    final database = _MemoryLocalDatabase();
    final app = AppProvider(database: database);
    const schedule = MedicationSchedule(
      id: 91,
      label: 'Vitamin pagi',
      hour: 8,
      minute: 0,
      lateTolerance: 15,
    );
    app.schedules = [schedule];

    expect(
      app.doseTimingStatus(schedule, now: DateTime(2026, 10, 24, 7, 55)),
      'EARLY',
    );
    expect(
      app.doseTimingStatus(schedule, now: DateTime(2026, 10, 24, 8, 15)),
      'ON_TIME',
    );
    expect(
      app.doseTimingStatus(schedule, now: DateTime(2026, 10, 24, 8, 16)),
      'LATE',
    );

    await app.refreshMissedDoses(now: DateTime(2026, 10, 24, 10, 1));
    expect(
      app.doseMissedToday(schedule.id, now: DateTime(2026, 10, 24)),
      isTrue,
    );
    expect(database.events.single.type, 'DOSE_MISSED');
  });

  test('jadwal baru setelah tengah malam menunggu hari berikutnya', () async {
    final database = _MemoryLocalDatabase();
    final app = AppProvider(database: database);
    final createdAt = DateTime(2026, 11, 1, 23, 58);
    final schedule = MedicationSchedule(
      id: 101,
      label: 'Jadwal obat',
      hour: 0,
      minute: 5,
      updatedAt: createdAt,
    );
    app.schedules = [schedule];

    await app.refreshMissedDoses(now: DateTime(2026, 11, 1, 23, 59));
    expect(database.events, isEmpty);

    await app.refreshMissedDoses(now: DateTime(2026, 11, 2, 2, 6));
    expect(database.events.single.type, 'DOSE_MISSED');
    app.dispose();
  });

  test('notifikasi pengambilan menggabungkan status minum obat', () {
    final app = AppProvider(database: _MemoryLocalDatabase());
    final schedule = MedicationSchedule(
      id: 102,
      label: 'Jadwal obat',
      hour: 8,
      minute: 0,
    );
    app.schedules = [schedule];

    expect(
      app.doseRemovalNotificationText(
        DoseEvent(
          type: 'DOSE_REMOVED',
          timestamp: DateTime(2026, 11, 1, 8, 10),
        ),
      ),
      'Obat diminum tepat waktu.',
    );
    expect(
      app
          .doseTakenFromRemoval(
            DoseEvent(
              type: 'DOSE_REMOVED',
              timestamp: DateTime(2026, 11, 1, 8, 10),
            ),
          )
          .type,
      'DOSE_CONFIRMED',
    );
    app.dispose();
  });
}

class _FakeBleService implements BleService {
  final _connection = StreamController<MeditraceConnectionState>.broadcast();
  final _status = StreamController<String>.broadcast();
  DeviceInfo? info;
  int signal = -60;

  void emitConnected() => _connection.add(MeditraceConnectionState.connected);
  void emitStatus(String value) => _status.add(value);

  @override
  Stream<MeditraceConnectionState> get connectionState => _connection.stream;
  @override
  DeviceInfo? get deviceInfo => info;
  @override
  Stream<String> get deviceEvents => const Stream.empty();
  @override
  MeditraceDevice? get connectedDevice => null;
  @override
  int? get rssi => null;
  @override
  Stream<List<MeditraceDevice>> get scanResults => const Stream.empty();
  @override
  Stream<bool> get scanning => const Stream.empty();
  @override
  Stream<String> get statusMessages => _status.stream;
  @override
  Future<void> connect(String remoteId) async {}
  @override
  Future<void> disconnect() async {}
  @override
  Future<void> dispose() async {
    await _connection.close();
    await _status.close();
  }

  @override
  Future<void> refreshStatus() async {}
  @override
  Future<int?> readSignalStrength() async => signal;
  @override
  Future<void> startScan() async {}
  @override
  Future<void> stopScan() async {}
  @override
  Future<void> writeCommand(String command) async {}
  @override
  Future<String> readConfig() async => '{}';
  @override
  Future<void> writeConfig(String config) async {}
  @override
  Future<void> writeFirmwareChunk(Uint8List chunk) async {}
}

class _MemoryLocalDatabase extends LocalDatabase {
  final List<DoseEvent> events = [];
  final List<MedicationSchedule> schedules = [];
  final Map<String, String> settings = {};

  @override
  Future<void> addEvent(DoseEvent event) async => events.add(event);

  @override
  Future<List<MedicationSchedule>> loadSchedules() async =>
      List<MedicationSchedule>.of(schedules);

  @override
  Future<void> saveSchedule(MedicationSchedule schedule) async {
    schedules.removeWhere((item) => item.id == schedule.id);
    schedules.add(schedule);
  }

  @override
  Future<void> deleteSchedule(int id) async =>
      schedules.removeWhere((item) => item.id == id);

  @override
  Future<List<DoseEvent>> loadEvents({int limit = 100}) async =>
      List<DoseEvent>.of(events);

  @override
  Future<String?> getSetting(String key) async => settings[key];

  @override
  Future<void> setSetting(String key, String value) async =>
      settings[key] = value;

  @override
  Future<void> clearEvents() async => events.clear();
}
