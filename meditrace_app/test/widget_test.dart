import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meditrace_app/main.dart';
import 'package:meditrace_app/models/device_info.dart';
import 'package:meditrace_app/models/dose_event.dart';
import 'package:meditrace_app/models/meditrace_device.dart';
import 'package:meditrace_app/models/medication_schedule.dart';
import 'package:meditrace_app/providers/app_provider.dart';
import 'package:meditrace_app/providers/ble_provider.dart';
import 'package:meditrace_app/services/ble_service.dart';
import 'package:meditrace_app/services/battery_estimate.dart';
import 'package:meditrace_app/services/local_database.dart';
import 'package:meditrace_app/services/family_api.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets(
    'initial and repeated invitation links open Profile with the pending code',
    (tester) async {
      const code = '0123456789ABCDEF01234567';
      const uri = 'https://meditrace.grownecro.tech/invite/$code';
      const messages = MethodChannel('com.llfbandit.app_links/messages');
      const events = MethodChannel('com.llfbandit.app_links/events');
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        messages,
        (call) async => call.method == 'getInitialLink' ? uri : null,
      );
      messenger.setMockMethodCallHandler(events, (_) async => null);
      addTearDown(() {
        messenger.setMockMethodCallHandler(messages, null);
        messenger.setMockMethodCallHandler(events, null);
      });
      final api = _SessionFamilyApi();
      addTearDown(api.dispose);
      await tester.pumpWidget(
        MeditraceApp(
          bleService: _FakeBleService(),
          database: _MemoryLocalDatabase(),
          familyApi: api,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        4,
      );
      await tester.scrollUntilVisible(
        find.text(code),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(code), findsOneWidget);
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0,
      );
      tester.binding.channelBuffers.push(
        events.name,
        const StandardMethodCodec().encodeSuccessEnvelope(uri),
        (_) {},
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        4,
      );
      expect(find.text(code), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'startup Google sign-in immediately updates the already mounted profile',
    (tester) async {
      final api = _SessionFamilyApi();
      addTearDown(api.dispose);
      await tester.pumpWidget(
        MeditraceApp(
          showStartupSplash: true,
          bleService: _FakeBleService(),
          database: _MemoryLocalDatabase(),
          familyApi: api,
        ),
      );
      await tester.pumpAndSettle();
      final app = tester
          .element(find.byType(NavigationBar))
          .read<AppProvider>();
      app.patientAge = 52;
      app.emergencyPhone = '08123456789';
      app.emergencyEmail = 'emergency@example.com';
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome to MEDITRACE'), findsNothing);
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('account@example.com'), findsOneWidget);
      expect(find.text('Sign out of account'), findsOneWidget);
      expect(find.text('Not signed in'), findsNothing);
      expect(app.patientAge, 52);
      expect(app.emergencyPhone, '08123456789');
      expect(app.emergencyEmail, 'emergency@example.com');
    },
  );

  testWidgets(
    'external login and logout synchronize profile and family without restarting',
    (tester) async {
      final api = _SessionFamilyApi();
      addTearDown(api.dispose);
      await tester.pumpWidget(
        MeditraceApp(
          bleService: _FakeBleService(),
          database: _MemoryLocalDatabase(),
          familyApi: api,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Not signed in'), findsOneWidget);
      api.setSignedIn(true);
      await tester.pumpAndSettle();
      expect(find.text('account@example.com'), findsOneWidget);
      expect(find.text('Not signed in'), findsNothing);
      expect(
        find.text(
          'Sign in using the Profile card above to manage groups and share alerts with your family.',
        ),
        findsNothing,
      );
      api.setSignedIn(false);
      await tester.pumpAndSettle();
      expect(find.text('Not signed in'), findsOneWidget);
      expect(find.text('account@example.com'), findsNothing);
      expect(find.text('Sign out of account'), findsNothing);
    },
  );

  testWidgets(
    'a delayed account response cannot restore signed-in UI after logout',
    (tester) async {
      final api = _SessionFamilyApi();
      addTearDown(api.dispose);
      await tester.pumpWidget(
        MeditraceApp(
          bleService: _FakeBleService(),
          database: _MemoryLocalDatabase(),
          familyApi: api,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      final pending = Completer<Map<String, dynamic>>();
      api.pendingProfile = pending.future;
      api.setSignedIn(true);
      await tester.pump();
      await tester.pump();
      api.setSignedIn(false);
      await tester.pumpAndSettle();
      pending.complete(_SessionFamilyApi.profile);
      await tester.pumpAndSettle();
      expect(find.text('Not signed in'), findsOneWidget);
      expect(find.text('account@example.com'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'local storage failure does not hide a successful Google sign-in',
    (tester) async {
      final api = _SessionFamilyApi();
      addTearDown(api.dispose);
      await tester.pumpWidget(
        MeditraceApp(
          bleService: _FakeBleService(),
          database: _FailingProfileDatabase(),
          familyApi: api,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      api.setSignedIn(true);
      await tester.pumpAndSettle();
      expect(find.text('account@example.com'), findsOneWidget);
      expect(find.text('Sign out of account'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('startup welcome uses default English', (tester) async {
    await tester.pumpWidget(
      MeditraceApp(
        showStartupSplash: true,
        bleService: _FakeBleService(),
        database: _MemoryLocalDatabase(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Welcome to MEDITRACE'), findsOneWidget);
    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('language changes immediately and survives app restart', (
    tester,
  ) async {
    final database = _MemoryLocalDatabase();
    await tester.pumpWidget(
      MeditraceApp(bleService: _FakeBleService(), database: database),
    );
    await tester.pumpAndSettle();
    expect(find.text('Welcome!'), findsOneWidget);
    expect(
      Localizations.localeOf(tester.element(find.byType(NavigationBar))),
      const Locale('en'),
    );

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('language-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bahasa Indonesia').last);
    await tester.pumpAndSettle();
    expect(find.text('Bahasa'), findsOneWidget);
    expect(find.text('Profil'), findsWidgets);
    expect(database.settings['language_code'], 'id');
    expect(
      Localizations.localeOf(tester.element(find.byType(NavigationBar))),
      const Locale('id'),
    );

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MeditraceApp(bleService: _FakeBleService(), database: database),
    );
    await tester.pumpAndSettle();
    expect(find.text('Selamat datang!'), findsOneWidget);
    await tester.tap(find.text('Jadwal'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('Batal'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('language-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();
    expect(find.text('Language'), findsOneWidget);
    expect(database.settings['language_code'], 'en');
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome!'), findsOneWidget);
  });

  testWidgets('unsupported saved language falls back to English', (
    tester,
  ) async {
    final database = _MemoryLocalDatabase()..settings['language_code'] = 'fr';
    await tester.pumpWidget(
      MeditraceApp(bleService: _FakeBleService(), database: database),
    );
    await tester.pumpAndSettle();
    expect(find.text('Welcome!'), findsOneWidget);
    expect(
      Localizations.localeOf(tester.element(find.byType(NavigationBar))),
      const Locale('en'),
    );
  });

  testWidgets('mode estimasi menghapus tegangan ADC lama', (tester) async {
    final service = _FakeBleService();
    final app = AppProvider(database: _MemoryLocalDatabase());
    final ble = BleProvider(service, app);
    service.emitStatus('{"battery":100,"battery_voltage":5.7}');
    await tester.pump();
    expect(ble.batteryVoltage, 5.7);
    service.emitStatus(
      '{"battery":50,"battery_estimated":true,"battery_voltage":null}',
    );
    await tester.pump();
    expect(ble.battery, 50);
    expect(ble.batteryEstimated, isTrue);
    expect(ble.batteryVoltage, isNull);
    ble.dispose();
    app.dispose();
  });

  testWidgets('estimasi baterai ditandai dan reset perlu konfirmasi', (
    tester,
  ) async {
    final service = _FakeBleService()
      ..info = const DeviceInfo(
        deviceId: 'MEDITRACE-C3-1234',
        deviceName: 'MEDITRACE-C3-1234',
        firmware: '0.9.7',
        battery: 50,
        batteryEstimated: true,
        board: 'ESP32-C3',
      );
    await tester.pumpWidget(MeditraceApp(bleService: service));
    service.emitConnected();
    service.emitStatus(
      '{"battery":50,"battery_estimated":true,"battery_voltage":null}',
    );
    await tester.pumpAndSettle();
    expect(find.text('Estimated battery'), findsOneWidget);
    expect(find.text('5.70 V'), findsNothing);
    await tester.tap(find.text('Device'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Device details'), 200);
    await tester.tap(find.text('Device details'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Mark battery as full'), 200);
    await tester.tap(find.text('Mark battery as full'));
    await tester.pumpAndSettle();
    expect(find.text('Is the battery fully charged?'), findsOneWidget);
    expect(service.commands, isNot(contains('BATTERY_FULL')));
    await tester.tap(find.text('Mark as full'));
    await tester.pumpAndSettle();
    expect(
      service.commands.where((value) => value == 'BATTERY_FULL'),
      hasLength(1),
    );
  });

  testWidgets('reconnect mulai 500 ms setelah koneksi terputus', (
    tester,
  ) async {
    final service = _FakeBleService();
    final app = AppProvider(database: _MemoryLocalDatabase())
      ..pairedDeviceId = 'saved-device'
      ..autoReconnectEnabled = true;
    final ble = BleProvider(service, app)
      ..connectionState = MeditraceConnectionState.connected;

    service.emitDisconnected();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 499));
    expect(service.scanCount, 0);
    await tester.pump(const Duration(milliseconds: 1));
    expect(service.scanCount, 1);
    ble.dispose();
    app.dispose();
  });

  testWidgets('reconnect yang tertunda saat sibuk tetap dicoba', (
    tester,
  ) async {
    final service = _FakeBleService();
    final app = AppProvider(database: _MemoryLocalDatabase())
      ..pairedDeviceId = 'saved-device'
      ..autoReconnectEnabled = true;
    final ble = BleProvider(service, app)..isBusy = true;

    await ble.reconnectSavedDevice();
    await tester.pump(const Duration(milliseconds: 500));
    expect(service.scanCount, 0);
    ble.isBusy = false;
    await tester.pump(const Duration(milliseconds: 500));
    expect(service.scanCount, 1);
    ble.dispose();
    app.dispose();
  });

  testWidgets('reconnect mencoba lagi setelah scan gagal', (tester) async {
    final service = _FakeBleService()..scanFails = true;
    final app = AppProvider(database: _MemoryLocalDatabase())
      ..pairedDeviceId = 'saved-device'
      ..autoReconnectEnabled = true;
    final ble = BleProvider(service, app);

    await ble.reconnectSavedDevice();
    expect(service.scanCount, 1);
    service.scanFails = false;
    await tester.pump(const Duration(seconds: 2));
    expect(service.scanCount, 2);
    ble.dispose();
    app.dispose();
  });

  testWidgets('reconnect memakai hasil scan aktif tanpa scan ulang', (
    tester,
  ) async {
    final service = _FakeBleService();
    final app = AppProvider(database: _MemoryLocalDatabase())
      ..pairedDeviceId = 'saved-device'
      ..autoReconnectEnabled = true;
    final ble = BleProvider(service, app)
      ..isScanning = true
      ..devices = [
        MeditraceDevice(
          remoteId: 'saved-device',
          name: 'MEDITRACE-1234',
          rssi: -50,
        ),
      ];

    await ble.reconnectSavedDevice();
    await tester.pump();
    expect(service.scanCount, 0);
    expect(service.connectCount, 1);
    ble.dispose();
    app.dispose();
  });

  testWidgets('putus manual tetap menonaktifkan reconnect', (tester) async {
    final service = _FakeBleService();
    final app = AppProvider(database: _MemoryLocalDatabase())
      ..pairedDeviceId = 'saved-device'
      ..autoReconnectEnabled = true;
    final ble = BleProvider(service, app);

    await ble.disconnect();
    await ble.reconnectSavedDevice();
    await tester.pump(const Duration(seconds: 3));
    expect(app.autoReconnectEnabled, isFalse);
    expect(service.scanCount, 0);
    ble.dispose();
    app.dispose();
  });

  testWidgets('menampilkan kondisi awal disconnected', (tester) async {
    await tester.pumpWidget(MeditraceApp(bleService: _FakeBleService()));

    expect(find.text('MEDITRACE not connected'), findsOneWidget);
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
    await tester.tap(find.text('Schedule').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
    await tester.tapAt(const Offset(1, 1));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Medication Schedule'), findsOneWidget);
  });

  testWidgets('jadwal baru tidak meminta pemilihan ruang obat', (tester) async {
    await tester.pumpWidget(
      MeditraceApp(
        bleService: _FakeBleService(),
        database: _MemoryLocalDatabase(),
      ),
    );
    await tester.tap(find.text('Schedule').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih ruang obat'), findsNothing);
    expect(find.text('Every day'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(find.text('Medication Schedule'), findsOneWidget);
  });

  testWidgets('menutup dialog profil tidak memakai field yang sudah dibuang', (
    tester,
  ) async {
    await tester.pumpWidget(MeditraceApp(bleService: _FakeBleService()));
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Edit profile'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Profile'), findsWidgets);
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
    expect(BatteryEstimate.label(100), '10 hr 0 min');
    expect(BatteryEstimate.label(82), '8 hr 12 min');
    expect(BatteryEstimate.label(15), '1 hr 30 min');
    expect(BatteryEstimate.label(0), 'Not available yet');
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
      await tester.tap(find.text('Device'));
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
      await tester.scrollUntilVisible(find.text('Compartment 1'), 200);
      expect(find.text('Medication: Filled'), findsOneWidget);
      expect(find.text('Door: Open'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Compartment 5'), 250);
      expect(find.text('Compartment 5'), findsOneWidget);
      expect(find.text('Compartment 6', skipOffstage: false), findsNothing);

      service.emitStatus('{"sensors":[],"doors":[],"sensor_valid":false}');
      await tester.pump();
      expect(find.text('Medication: Not read yet'), findsWidgets);
      expect(find.text('Medication: Empty'), findsNothing);
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

    expect(find.text('Medication box'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Compartment status'), 250);
    expect(find.text('Compartment status'), findsOneWidget);
    expect(find.text('Needs refill'), findsOneWidget);
    expect(find.text('Door: Open'), findsNothing);
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
    final warning = find.textContaining('Weak signal');

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
    expect(find.textContaining('Weak signal'), findsOneWidget);

    service.emitStatus('{"simulated_rssi":-60}');
    await tester.pump();
    await tester.pump(const Duration(seconds: 30));
    await tester.pump(const Duration(seconds: 30));
    await tester.pump();
    expect(find.textContaining('Weak signal'), findsNothing);
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
      find.text('Refill medication before the next schedule.'),
      200,
    );
    expect(find.text('1 of 5 compartments filled'), findsOneWidget);
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

  test('satu jadwal tidak mencatat konfirmasi atau email ganda', () async {
    final database = _MemoryLocalDatabase();
    final app = AppProvider(database: database);
    final schedule = MedicationSchedule(
      id: 93,
      label: 'Vitamin malam',
      hour: DateTime.now().hour,
      minute: DateTime.now().minute,
      compartmentNumber: 1,
    );
    app.schedules = [schedule];
    final event = DoseEvent(
      type: 'DOSE_CONFIRMED',
      timestamp: DateTime.now(),
      scheduleId: schedule.id,
      sensorId: 1,
      status: 'ON_TIME',
    );

    expect(await app.addEvent(event), isTrue);
    expect(await app.addEvent(event), isFalse);
    expect(
      database.events.where((item) => item.type == 'DOSE_CONFIRMED'),
      hasLength(1),
    );
    app.dispose();
  });

  test('obat dikembalikan dalam 15 menit membatalkan konfirmasi', () async {
    final database = _MemoryLocalDatabase();
    final app = AppProvider(database: database);
    final nowForTest = DateTime.now();
    final timestamp = DateTime(
      nowForTest.year,
      nowForTest.month,
      nowForTest.day,
      17,
      0,
    );
    await app.addEvent(
      DoseEvent(
        type: 'DOSE_CONFIRMED',
        timestamp: timestamp,
        scheduleId: 94,
        sensorId: 1,
        status: 'ON_TIME',
      ),
    );

    final revoked = await app.handleCompartmentRefilled(
      1,
      timestamp.add(const Duration(minutes: 15)),
    );

    expect(revoked, isTrue);
    expect(app.doseConfirmedToday(94), isFalse);
    expect(database.events.last.type, 'DOSE_CONFIRMATION_REVOKED');
  });

  test('pengisian setelah 15 menit mempertahankan konfirmasi lama', () async {
    final database = _MemoryLocalDatabase();
    final app = AppProvider(database: database);
    final nowForTest = DateTime.now();
    final timestamp = DateTime(
      nowForTest.year,
      nowForTest.month,
      nowForTest.day,
      17,
      0,
    );
    await app.addEvent(
      DoseEvent(
        type: 'DOSE_CONFIRMED',
        timestamp: timestamp,
        scheduleId: 95,
        sensorId: 1,
        status: 'ON_TIME',
      ),
    );

    final revoked = await app.handleCompartmentRefilled(
      1,
      timestamp.add(const Duration(minutes: 16)),
    );

    expect(revoked, isFalse);
    expect(app.doseConfirmedToday(95), isTrue);
    expect(database.events, hasLength(1));
  });

  test(
    'pengambilan sensor mencegah status missed saat isi ulang terlambat',
    () async {
      final database = _MemoryLocalDatabase();
      final app = AppProvider(database: database);
      const schedule = MedicationSchedule(
        id: 92,
        label: 'Vitamin siang',
        hour: 8,
        minute: 0,
        compartmentNumber: 2,
      );
      app.schedules = [schedule];
      await app.addEvent(
        DoseEvent(
          type: 'DOSE_REMOVED',
          timestamp: DateTime(2026, 10, 24, 8, 5),
          sensorId: 2,
        ),
      );

      await app.refreshMissedDoses(now: DateTime(2026, 10, 24, 10, 1));

      expect(
        app.doseMissedToday(schedule.id, now: DateTime(2026, 10, 24)),
        isFalse,
      );
      expect(database.events, hasLength(1));
    },
  );

  test('jadwal baru setelah tengah malam menunggu hari berikutnya', () async {
    final database = _MemoryLocalDatabase();
    final app = AppProvider(database: database);
    final createdAt = DateTime(2026, 11, 1, 23, 58);
    final schedule = MedicationSchedule(
      id: 101,
      label: 'Medication schedule',
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
      label: 'Medication schedule',
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
      'Medication taken on time.',
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
  int scanCount = 0;
  int connectCount = 0;
  bool scanFails = false;
  final List<String> commands = [];

  void emitConnected() => _connection.add(MeditraceConnectionState.connected);
  void emitDisconnected() =>
      _connection.add(MeditraceConnectionState.disconnected);
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
  Future<void> connect(String remoteId) async {
    connectCount++;
  }

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
  Future<void> startScan() async {
    scanCount++;
    if (scanFails) throw const BleException('Scan gagal');
  }

  @override
  Future<void> stopScan() async {}
  @override
  Future<void> writeCommand(String command) async {
    commands.add(command);
  }

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

class _FailingProfileDatabase extends _MemoryLocalDatabase {
  @override
  Future<void> setSetting(String key, String value) async {
    throw StateError('Local storage is unavailable');
  }
}

class _SessionFamilyApi extends FamilyApi {
  static const profile = <String, dynamic>{
    'user': {
      'id': 'account-user',
      'name': 'Account User',
      'email': 'account@example.com',
    },
  };
  final _sessions = StreamController<String?>.broadcast();
  bool _signedIn = false;
  Future<Map<String, dynamic>>? pendingProfile;

  void setSignedIn(bool value) {
    _signedIn = value;
    _sessions.add(value ? 'account-user' : null);
  }

  @override
  Future<bool> get hasSession async => _signedIn;
  @override
  bool get backendConfigured => false;
  @override
  Stream<String?> get sessionUserIds => _sessions.stream;
  @override
  Stream<void> get foregroundNotifications => const Stream.empty();
  @override
  Future<Map<String, dynamic>> loginWithGoogle() async {
    setSignedIn(true);
    return profile;
  }

  @override
  Future<Map<String, dynamic>> me() async =>
      pendingProfile == null ? profile : await pendingProfile!;
  @override
  Future<Map<String, dynamic>> inbox() async => {'data': []};
  @override
  void dispose() => unawaited(_sessions.close());
}
