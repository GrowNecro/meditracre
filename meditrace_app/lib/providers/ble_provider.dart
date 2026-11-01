import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/device_info.dart';
import '../models/dose_event.dart';
import '../models/meditrace_device.dart';
import '../services/ble_service.dart';
import 'app_provider.dart';

class BleProvider extends ChangeNotifier {
  BleProvider(this._service, this._app) {
    _subscriptions.add(
      _service.scanResults.listen((value) {
        devices = value;
        _connectIfSavedDeviceFound(value);
        notifyListeners();
      }),
    );
    _subscriptions.add(
      _service.scanning.listen((value) {
        isScanning = value;
        if (!value && _pendingAutoReconnectId != null) {
          _scheduleReconnect();
        }

        notifyListeners();
      }),
    );
    _subscriptions.add(
      _service.connectionState.listen((value) {
        final wasConnected =
            connectionState == MeditraceConnectionState.connected;
        connectionState = value;
        if (value == MeditraceConnectionState.connected) {
          if (!wasConnected) {
            unawaited(
              _recordConnectionEvent(
                'BLE_CONNECTED',
                _disconnectedAt == null ? 'CONNECTED' : 'RECONNECTED',
              ),
            );
          }
          _manualDisconnect = false;
          _recordFalseAlarmIfNeeded();
          _patientSeparationTimer?.cancel();
          _separationRelayTimer?.cancel();
          _startSignalMonitoring();
          unawaited(_syncDeviceClock());
          unawaited(_cancelSeparationAlertSafely());
          unawaited(_app.familyAlerts.flush());
          unawaited(refresh());
        } else if (wasConnected &&
            value == MeditraceConnectionState.disconnected) {
          _stopSignalMonitoring();
          _deviceClockSynced = false;
          sensors = const [];
          doors = const [];
          _dummySignalOverride = null;
          sensorValid = null;
          lastSensorUpdate = null;
          _disconnectedAt = DateTime.now();
          unawaited(
            _recordConnectionEvent(
              'BLE_DISCONNECTED',
              _manualDisconnect ? 'MANUAL_DISCONNECT' : 'MONITORING_STARTED',
            ),
          );
          if (!_manualDisconnect) {
            _schedulePatientSeparationAlert();
            _scheduleFamilySeparationAlert();
            unawaited(
              _scheduleSeparationAlertSafely(
                const Duration(seconds: _patientWarningSeconds),
              ),
            );
          }

          if (!_manualDisconnect && _app.autoReconnectEnabled) {
            _scheduleReconnect(const Duration(seconds: 2));
          }
        }
        notifyListeners();
      }),
    );
    _subscriptions.add(
      _service.statusMessages.listen((value) {
        lastStatus = value;
        _parseStatus(value);
        notifyListeners();
      }),
    );
    _subscriptions.add(
      _service.deviceEvents.listen((value) {
        lastEvent = value;
        _parseEvent(value);
        notifyListeners();
      }),
    );
  }

  Future<void> _syncDeviceClock() async {
    final epoch = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    await _run(() => _service.writeCommand('SYNC_TIME:$epoch'));
    if (connectionState == MeditraceConnectionState.connected &&
        errorMessage == null) {
      _deviceClockSynced = true;
      _startScheduleMonitoring();
      notifyListeners();
    }
  }

  final BleService _service;
  final AppProvider _app;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Timer? _reconnectTimer;
  Timer? _signalTimer;
  Timer? _scheduleTimer;
  bool _deviceClockSynced = false;
  double firmwareProgress = 0;
  Timer? _patientSeparationTimer;
  Timer? _separationRelayTimer;
  DateTime? _disconnectedAt;
  bool _patientWarningSent = false;
  final Set<String> _triggeredScheduleKeys = <String>{};
  static const int _patientWarningSeconds = 30;
  static const int _caregiverDelayMinutes = 5;
  Set<int> _emptyCompartments = {};
  bool _readingSignal = false;
  bool _manualDisconnect = false;
  int _weakSignalSamples = 0;
  int _strongSignalSamples = 0;
  int _signalGeneration = 0;
  bool signalWeak = false;
  int? _dummySignalOverride;
  String? _pendingAutoReconnectId;
  List<MeditraceDevice> devices = const [];
  bool isScanning = false;
  bool isBusy = false;
  MeditraceConnectionState connectionState =
      MeditraceConnectionState.disconnected;
  String? lastStatus;
  String? lastEvent;
  String? errorMessage;
  int? battery;
  double? batteryVoltage;
  bool alarmActive = false;
  int pendingEvents = 0;
  List<int> sensors = const [];
  List<int> doors = const [];
  bool? sensorValid;
  DateTime? lastSensorUpdate;

  // Stream untuk memantau status koneksi dari luar provider
  Stream<MeditraceConnectionState> get connectionStateStream =>
      _service.connectionState;

  int get compartmentCount {
    if (deviceInfo?.board == 'ESP32-C3') {
      return DeviceInfo.c3CompartmentCount;
    }
    final reported = sensors.length > doors.length
        ? sensors.length
        : doors.length;
    final expected = deviceInfo?.compartmentCount ?? 0;
    return reported > expected ? reported : expected;
  }

  DeviceInfo? get deviceInfo => _service.deviceInfo;
  MeditraceDevice? get connectedDevice => _service.connectedDevice;
  int? get rssi => _service.rssi;

  Future<void> scan() => _run(_service.startScan);
  Future<void> stopScan() => _run(_service.stopScan);
  Future<void> connect(String remoteId) async {
    _manualDisconnect = false;
    _reconnectTimer?.cancel();
    _pendingAutoReconnectId = null;
    await _run(() => _service.connect(remoteId));
    // _run menangkap error agar UI tetap stabil. Bila tidak ada error,
    // koneksi manual ini adalah persetujuan pengguna untuk menyimpan pairing.
    // Jangan bergantung pada urutan event Stream connectionState di sini.
    if (errorMessage == null) {
      await _app.saveManualPairing(remoteId);
    }
  }

  Future<void> disconnect() async {
    _manualDisconnect = true;
    _patientSeparationTimer?.cancel();
    _separationRelayTimer?.cancel();
    _stopSignalMonitoring();
    _reconnectTimer?.cancel();
    _pendingAutoReconnectId = null;
    await _app.disableAutoReconnect();
    await _run(_service.disconnect);
  }

  /// Mencari perangkat terakhir yang dipilih pengguna dan menghubungkannya
  /// kembali jika mode auto-connect masih aktif.
  Future<void> reconnectSavedDevice() async {
    final remoteId = _app.pairedDeviceId;
    if (!_app.autoReconnectEnabled ||
        remoteId == null ||
        isBusy ||
        connectionState == MeditraceConnectionState.connected ||
        connectionState == MeditraceConnectionState.connecting) {
      return;
    }
    _pendingAutoReconnectId = remoteId;
    await _run(_service.startScan);
  }

  Future<void> sendCommand(String command) =>
      _run(() => _service.writeCommand(command));

  Future<void> updateFirmware(Uint8List firmware) async {
    if (firmware.isEmpty) throw const BleException('File firmware kosong.');
    firmwareProgress = 0;
    notifyListeners();
    final crc = _crc32(firmware);
    await _run(
      () => _service.writeCommand(
        'OTA_BEGIN:${firmware.length}:${crc.toRadixString(16)}',
      ),
    );
    if (errorMessage != null) return;
    const chunkSize = 180;
    for (var offset = 0; offset < firmware.length; offset += chunkSize) {
      final end = (offset + chunkSize).clamp(0, firmware.length);
      await _run(
        () => _service.writeFirmwareChunk(
          Uint8List.sublistView(firmware, offset, end),
        ),
      );
      if (errorMessage != null) return;
      firmwareProgress = end / firmware.length;
      notifyListeners();
    }
    await _run(() => _service.writeCommand('OTA_END'));
    if (errorMessage == null) {
      firmwareProgress = 1;
      notifyListeners();
    }
  }

  int _crc32(Uint8List data) {
    var crc = 0xFFFFFFFF;
    for (final byte in data) {
      crc ^= byte;
      for (var bit = 0; bit < 8; bit++) {
        crc = (crc >> 1) ^ ((crc & 1) == 1 ? 0xEDB88320 : 0);
      }
    }
    return (crc ^ 0xFFFFFFFF) >>> 0;
  }

  Future<void> refresh() => _run(() async {
    await _service.refreshStatus();
    await _service.writeCommand('GET_SENSOR');
    await _service.writeCommand('GET_PENDING_EVENTS');
  });

  void _startSignalMonitoring() {
    _stopSignalMonitoring();
    _signalTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(_checkSignal()),
    );
  }

  /// Tanpa RTC, buzzer dijalankan oleh aplikasi selama aplikasi dan BLE aktif.
  /// Notifikasi jadwal tetap dijadwalkan Android agar pasien tetap diingatkan
  /// bila aplikasi berada di background.
  void _startScheduleMonitoring() {
    _scheduleTimer?.cancel();
    _checkDueSchedules();
    _scheduleTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _checkDueSchedules(),
    );
  }

  void _checkDueSchedules() {
    if (connectionState != MeditraceConnectionState.connected ||
        !_deviceClockSynced) {
      return;
    }
    final now = DateTime.now();
    final day = '${now.year}-${now.month}-${now.day}';
    for (final schedule in _app.schedules.where((item) => item.enabled)) {
      if (schedule.hour != now.hour || schedule.minute != now.minute) continue;
      final key = '$day-${schedule.id}';
      if (!_triggeredScheduleKeys.add(key)) continue;
      unawaited(_run(() => _service.writeCommand('ALARM_1000')));
      unawaited(
        _app.addEvent(
          DoseEvent(
            type: 'DOSE_ALARM',
            timestamp: now,
            scheduleId: schedule.id,
            status: 'APP_BLE_SCHEDULE',
          ),
        ),
      );
    }
    _triggeredScheduleKeys.removeWhere((key) => !key.startsWith(day));
    unawaited(_app.refreshMissedDoses(now: now));
  }

  void _stopSignalMonitoring() {
    _signalGeneration++;
    _signalTimer?.cancel();
    _signalTimer = null;
    _weakSignalSamples = 0;
    _strongSignalSamples = 0;
    signalWeak = false;
  }

  Future<void> _checkSignal() async {
    if (_readingSignal ||
        connectionState != MeditraceConnectionState.connected) {
      return;
    }
    _readingSignal = true;
    final generation = _signalGeneration;
    try {
      final strength =
          _dummySignalOverride ?? await _service.readSignalStrength();
      if (strength == null ||
          generation != _signalGeneration ||
          connectionState != MeditraceConnectionState.connected) {
        return;
      }
      if (strength <= -85) {
        _weakSignalSamples++;
        _strongSignalSamples = 0;
        if (!signalWeak && _weakSignalSamples >= 3) {
          signalWeak = true;
          unawaited(_showWeakSignalAlertSafely());
        }
      } else {
        _weakSignalSamples = 0;
        if (strength >= -75) {
          _strongSignalSamples++;
          if (_strongSignalSamples >= 2) signalWeak = false;
        } else {
          _strongSignalSamples = 0;
        }
      }
      notifyListeners();
    } catch (_) {
      // Satu sampel RSSI gagal dibaca; tunggu sampel berikutnya.
    } finally {
      _readingSignal = false;
    }
  }

  void _connectIfSavedDeviceFound(List<MeditraceDevice> foundDevices) {
    final targetId = _pendingAutoReconnectId;
    if (targetId == null || !_app.autoReconnectEnabled) return;
    if (!foundDevices.any((device) => device.remoteId == targetId)) return;

    _pendingAutoReconnectId = null;
    unawaited(_connectAutomatically(targetId));
  }

  Future<void> _connectAutomatically(String remoteId) async {
    _manualDisconnect = false;
    await _run(() async {
      await _service.stopScan();
      await _service.connect(remoteId);
    });
    if (connectionState != MeditraceConnectionState.connected &&
        _app.autoReconnectEnabled) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect([Duration delay = const Duration(seconds: 5)]) {
    if (!_app.autoReconnectEnabled ||
        connectionState == MeditraceConnectionState.connected ||
        connectionState == MeditraceConnectionState.connecting) {
      return;
    }
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      unawaited(reconnectSavedDevice());
    });
  }

  void _parseStatus(String payload) {
    try {
      final json = jsonDecode(payload) as Map<String, dynamic>;
      if ((deviceInfo?.deviceId == 'MEDITRACE-DUMMY' ||
              deviceInfo?.deviceId == 'MEDBOX-DUMMY') &&
          json.containsKey('simulated_rssi')) {
        _dummySignalOverride = (json['simulated_rssi'] as num?)?.toInt();
      }
      battery = (json['battery'] as num?)?.toInt() ?? battery;
      batteryVoltage =
          (json['battery_voltage'] as num?)?.toDouble() ?? batteryVoltage;
      alarmActive = json['alarm'] as bool? ?? alarmActive;
      pendingEvents = (json['pending'] as num?)?.toInt() ?? pendingEvents;
      if (json.containsKey('sensors') || json.containsKey('doors')) {
        final valid = json['sensor_valid'] != false;
        sensorValid = valid;
        final maxCount = deviceInfo?.compartmentCount;
        sensors = valid
            ? (json['sensors'] as List<dynamic>?)
                      ?.map((e) => _normalizeSensorValue((e as num).toInt()))
                      .take(maxCount ?? 16)
                      .toList() ??
                  const []
            : const [];
        doors = valid
            ? (json['doors'] as List<dynamic>?)
                      ?.map((e) => (e as num).toInt())
                      .take(maxCount ?? 16)
                      .toList() ??
                  const []
            : const [];
        lastSensorUpdate = valid ? DateTime.now() : null;
        final emptyNow = <int>{};
        if (valid) {
          for (var i = 0; i < sensors.length; i++) {
            if (sensors[i] == 0) emptyNow.add(i + 1);
          }
        }
        final newlyEmpty = emptyNow.difference(_emptyCompartments);
        if (valid) _emptyCompartments = emptyNow;
        if (newlyEmpty.isNotEmpty) {
          unawaited(_showRefillAlertSafely());
          unawaited(_reportLowSupply(newlyEmpty));
        }
      }
    } catch (_) {
      // Balasan command non-JSON tetap tersedia melalui lastStatus.
    }
  }

  /// Firmware ESP32-C3 mengirim nilai semantik: 1 = beam terhalang/obat ada,
  /// 0 = beam bebas/kompartemen kosong. Dummy memakai kontrak yang sama.
  int _normalizeSensorValue(int rawValue) {
    return rawValue == 0 ? 0 : 1;
  }

  Future<void> _reportLowSupply(Set<int> compartments) async {
    try {
      final numbers = (compartments.toList()..sort()).join(', ');
      await _app.familyAlerts.report(
        kind: 'low_supply',
        title: 'Obat di kompartemen $numbers kosong',
        details:
            'Sensor MEDITRACE mendeteksi kompartemen $numbers kosong. Periksa dan isi ulang obat.',
      );
    } catch (_) {
      // Status sensor dan notifikasi lokal tidak bergantung pada internet.
    }
  }

  void _scheduleFamilySeparationAlert() {
    _separationRelayTimer?.cancel();
    _separationRelayTimer = Timer(
      const Duration(
        seconds: _patientWarningSeconds + _caregiverDelayMinutes * 60,
      ),
      () {
        if (_manualDisconnect ||
            connectionState == MeditraceConnectionState.connected) {
          return;
        }
        unawaited(_reportDisconnected());
      },
    );
  }

  void _schedulePatientSeparationAlert() {
    _patientWarningSent = false;
    _patientSeparationTimer?.cancel();
    _patientSeparationTimer = Timer(
      const Duration(seconds: _patientWarningSeconds),
      () {
        if (_manualDisconnect ||
            connectionState == MeditraceConnectionState.connected) {
          return;
        }
        _patientWarningSent = true;
        final now = DateTime.now();
        final latency = _disconnectedAt == null
            ? 0
            : now.difference(_disconnectedAt!).inMilliseconds;
        unawaited(
          _app.addEvent(
            DoseEvent(
              type: 'SEPARATION_PATIENT_WARNED',
              timestamp: now,
              status: 'LATENCY_${latency}MS',
            ),
          ),
        );
      },
    );
  }

  Future<void> _reportDisconnected() async {
    try {
      final now = DateTime.now();
      final latency = _disconnectedAt == null
          ? 0
          : now.difference(_disconnectedAt!).inMilliseconds;
      await _app.familyAlerts.report(
        kind: 'separation_escalation',
        title: 'MEDITRACE terputus dari HP',
        details: 'Pasien telah diperingatkan setelah 30 detik. MEDITRACE belum terhubung kembali 5 menit kemudian. Periksa jarak dan daya perangkat.',
      );
      await _app.addEvent(
        DoseEvent(
          type: 'SEPARATION_CAREGIVER_ESCALATED',
          timestamp: now,
          status: 'LATENCY_${latency}MS',
        ),
      );
    } catch (_) {
      // Alert lokal tetap berjalan tanpa backend.
    }
  }

  Future<void> _recordConnectionEvent(String type, String status) async {
    try {
      await _app.addEvent(
        DoseEvent(type: type, timestamp: DateTime.now(), status: status),
      );
    } catch (_) {
      // Koneksi tetap berjalan jika penyimpanan riwayat belum siap.
    }
  }

  Future<Map<String, dynamic>?> reportMedboxLeftBehind() async {
    final now = DateTime.now();
    try {
      final result = await _app.familyAlerts.report(
        kind: 'medbox_left_behind',
        title: 'Pasien melaporkan MEDITRACE tertinggal',
        details: 'Pasien mengonfirmasi bahwa kotak obat MEDITRACE tertinggal.',
      );
      await _app.addEvent(
        DoseEvent(
          type: 'MEDBOX_LEFT_BEHIND',
          timestamp: now,
          status: 'ESCALATED_IMMEDIATELY',
        ),
      );
      return result;
    } catch (_) {
      // Relay akan mencoba ulang ketika koneksi internet tersedia.
      return {
        'ok': false,
        'error': 'Peringatan gagal dikirim. Periksa login dan grup keluarga.',
      };
    }
  }

  void _recordFalseAlarmIfNeeded() {
    final disconnectedAt = _disconnectedAt;
    if (disconnectedAt == null) return;
    final reconnectedAt = DateTime.now();
    final latency = reconnectedAt.difference(disconnectedAt).inMilliseconds;
    if (_patientWarningSent) {
      unawaited(
        _app.addEvent(
          DoseEvent(
            type: 'SEPARATION_FALSE_ALARM',
            timestamp: reconnectedAt,
            status: 'RECONNECTED_AFTER_${latency}MS',
          ),
        ),
      );
    }
    _disconnectedAt = null;
    _patientWarningSent = false;
  }

  Future<void> _cancelSeparationAlertSafely() async {
    try {
      await _app.notifications.cancelSeparationAlert();
    } catch (_) {
      // Koneksi dan status sensor tetap dapat digunakan tanpa plugin notifikasi.
    }
  }

  Future<void> _scheduleSeparationAlertSafely(Duration delay) async {
    try {
      await _app.notifications.scheduleSeparationAlert(delay);
    } catch (_) {
      // Notifikasi bukan syarat untuk memperbarui status koneksi.
    }
  }

  Future<void> _showRefillAlertSafely() async {
    try {
      await _app.notifications.showRefillAlert();
    } catch (_) {
      // Status kosong tetap muncul di aplikasi.
    }
  }

  Future<void> _showWeakSignalAlertSafely() async {
    try {
      await _app.notifications.showWeakSignalAlert();
    } catch (_) {
      // Status sinyal lemah tetap terlihat di aplikasi.
    }
  }

  void _parseEvent(String payload) {
    try {
      final json = jsonDecode(payload) as Map<String, dynamic>;
      final event = DoseEvent.fromJson(json);
      if (deviceInfo?.board == 'ESP32-C3' &&
          event.sensorId != null &&
          (event.sensorId! < 1 ||
              event.sensorId! > DeviceInfo.c3CompartmentCount)) {
        return;
      }
      if (event.type == 'DOSE_ALARM') {
        unawaited(_app.addEvent(event));
        unawaited(_showScheduledDoseAlertSafely(event));
      } else if (event.type == 'DOSE_REMOVED') {
        final taken = _app.doseTakenFromRemoval(event);
        unawaited(_app.addEvent(taken));
        unawaited(_showDoseTakenAlertSafely(taken));
        unawaited(_reportDoseConfirmed(taken));
      } else {
        unawaited(_app.addEvent(event));
      }
    } catch (_) {
      unawaited(
        _app.addEvent(DoseEvent(type: payload, timestamp: DateTime.now())),
      );
    }
  }

  Future<void> _reportDoseConfirmed(DoseEvent event) async {
    try {
      await _app.familyAlerts.report(
        kind: 'dose_status',
        title: 'Status obat: sudah diminum',
        details:
            'Obat pada ruang ${event.sensorId ?? '-'} tercatat sudah diminum (${event.status}).',
      );
    } catch (_) {
      // Riwayat lokal tetap tersimpan jika relay keluarga belum tersedia.
    }
  }

  Future<void> _showDoseTakenAlertSafely(DoseEvent event) async {
    try {
      await _app.notifications.showDoseTakenAlert(
        _app.doseRemovalNotificationText(event),
      );
    } catch (_) {
      // Riwayat pengambilan tetap tersimpan jika notifikasi Android gagal.
    }
  }

  Future<void> _showScheduledDoseAlertSafely(DoseEvent event) async {
    try {
      final room = event.sensorId == null ? '' : ' ruang ${event.sensorId}';
      await _app.notifications.showScheduledDoseAlert(
        event.state == false
            ? 'Jadwal obat$room: ruang kosong, isi ulang dulu.'
            : 'Waktunya minum obat$room.',
      );
    } catch (_) {
      // Catatan event tetap tersimpan jika notifikasi Android gagal.
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  Future<void> _run(Future<void> Function() operation) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await operation();
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _scheduleTimer?.cancel();
    _patientSeparationTimer?.cancel();
    _separationRelayTimer?.cancel();
    _stopSignalMonitoring();
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(_service.dispose());
    super.dispose();
  }
}
