import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/constants/ble_constants.dart';
import '../models/device_info.dart';
import '../models/meditrace_device.dart';
import 'ble_service.dart';

class FlutterBlueBleService implements BleService {
  final _scanController = StreamController<List<MeditraceDevice>>.broadcast();
  final _scanningController = StreamController<bool>.broadcast();
  final _connectionController =
      StreamController<MeditraceConnectionState>.broadcast();
  final _statusController = StreamController<String>.broadcast();
  final _eventController = StreamController<String>.broadcast();

  final Map<String, BluetoothDevice> _devices = {};
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<bool>? _scanningSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _statusSubscription;
  StreamSubscription<List<int>>? _eventSubscription;

  BluetoothDevice? _connected;
  BluetoothCharacteristic? _commandCharacteristic;
  BluetoothCharacteristic? _statusCharacteristic;
  BluetoothCharacteristic? _configCharacteristic;
  BluetoothCharacteristic? _otaCharacteristic;
  DeviceInfo? _deviceInfo;
  MeditraceDevice? _connectedDevice;
  int? _rssi;

  FlutterBlueBleService() {
    _scanSubscription = FlutterBluePlus.onScanResults.listen(
      _handleScanResults,
      onError: (Object error) => _statusController.add('Scan gagal: $error'),
    );
    _scanningSubscription = FlutterBluePlus.isScanning.listen(
      _scanningController.add,
    );
  }

  @override
  Stream<List<MeditraceDevice>> get scanResults => _scanController.stream;
  @override
  Stream<bool> get scanning => _scanningController.stream;
  @override
  Stream<MeditraceConnectionState> get connectionState =>
      _connectionController.stream;
  @override
  Stream<String> get statusMessages => _statusController.stream;
  @override
  Stream<String> get deviceEvents => _eventController.stream;
  @override
  DeviceInfo? get deviceInfo => _deviceInfo;
  @override
  MeditraceDevice? get connectedDevice => _connectedDevice;
  @override
  int? get rssi => _rssi;

  Future<void> _requestPermissions() async {
    final result = await <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
    final scanDenied = !(result[Permission.bluetoothScan]?.isGranted ?? false);
    final connectDenied =
        !(result[Permission.bluetoothConnect]?.isGranted ?? false);
    if (scanDenied || connectDenied) {
      throw const BleException(
        'Izin Bluetooth diperlukan untuk mencari MEDITRACE.',
      );
    }
  }

  @override
  Future<void> startScan() async {
    await _requestPermissions();
    if (!await FlutterBluePlus.isSupported) {
      throw const BleException('Perangkat ini tidak mendukung Bluetooth LE.');
    }
    await _ensureBluetoothIsOn();
    _devices.clear();
    _scanController.add(const []);
    await FlutterBluePlus.startScan(timeout: BleConstants.scanDuration);
  }

  Future<void> _ensureBluetoothIsOn() async {
    var state = FlutterBluePlus.adapterStateNow;
    if (state == BluetoothAdapterState.unknown) {
      try {
        state = await FlutterBluePlus.adapterState
            .where((value) => value != BluetoothAdapterState.unknown)
            .first
            .timeout(const Duration(seconds: 5));
      } on TimeoutException {
        state = FlutterBluePlus.adapterStateNow;
      }
    }
    if (state == BluetoothAdapterState.on) {
      return;
    }

    try {
      await FlutterBluePlus.turnOn(timeout: 15);
      await FlutterBluePlus.adapterState
          .where((value) => value == BluetoothAdapterState.on)
          .first
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw const BleException(
        'Bluetooth belum aktif. Izinkan aplikasi menyalakan Bluetooth, lalu scan ulang.',
      );
    }
  }

  void _handleScanResults(List<ScanResult> results) {
    final meditraceDevices = <MeditraceDevice>[];
    for (final result in results) {
      final name = result.advertisementData.advName.isNotEmpty
          ? result.advertisementData.advName
          : result.device.platformName;
      final upperName = name.toUpperCase();
      final hasMeditraceName =
          upperName.startsWith('MEDBOX-') || upperName.startsWith('MEDITRACE-');
      final hasMeditraceService = result.advertisementData.serviceUuids.any(
        (uuid) => uuid.str.toLowerCase() == BleConstants.serviceUuid,
      );
      if (!hasMeditraceName && !hasMeditraceService) {
        continue;
      }
      final id = result.device.remoteId.str;
      _devices[id] = result.device;
      meditraceDevices.add(
        MeditraceDevice(
          remoteId: id,
          name: name.isEmpty ? 'MEDITRACE ($id)' : name,
          rssi: result.rssi,
        ),
      );
    }
    meditraceDevices.sort((a, b) => b.rssi.compareTo(a.rssi));
    _scanController.add(meditraceDevices);
  }

  @override
  Future<void> stopScan() => FlutterBluePlus.stopScan();

  @override
  Future<void> connect(String remoteId) async {
    await _requestPermissions();
    await stopScan();
    // Jangan pernah memakai characteristic dari koneksi sebelumnya jika
    // discovery koneksi baru gagal atau perangkat reboot di tengah proses.
    _clearConnection();
    final device = _devices[remoteId] ?? BluetoothDevice.fromId(remoteId);
    _connectionController.add(MeditraceConnectionState.connecting);

    await _connectionSubscription?.cancel();
    _connectionSubscription = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _clearConnection();
        _connectionController.add(MeditraceConnectionState.disconnected);
      }
    });
    device.cancelWhenDisconnected(
      _connectionSubscription!,
      delayed: true,
      next: true,
    );

    try {
      await device.connect(
        license: License.nonprofit,
        timeout: BleConstants.connectionTimeout,
      );
      _connected = device;
      _rssi = await device.readRssi();
      await _discoverMeditraceService(device);
      _connectedDevice = MeditraceDevice(
        remoteId: remoteId,
        name: _deviceInfo?.deviceName ?? device.advName,
        rssi: _rssi ?? 0,
      );
      _connectionController.add(MeditraceConnectionState.connected);
    } catch (error) {
      await device.disconnect();
      _clearConnection();
      _connectionController.add(MeditraceConnectionState.disconnected);
      throw BleException('Tidak dapat terhubung ke MEDITRACE: $error');
    }
  }

  Future<void> _discoverMeditraceService(BluetoothDevice device) async {
    final services = await device.discoverServices();
    BluetoothCharacteristic? info;
    BluetoothCharacteristic? event;
    _commandCharacteristic = null;
    _statusCharacteristic = null;
    _configCharacteristic = null;
    _otaCharacteristic = null;

    for (final service in services) {
      if (service.serviceUuid.str.toLowerCase() != BleConstants.serviceUuid) {
        continue;
      }
      for (final characteristic in service.characteristics) {
        switch (characteristic.characteristicUuid.str.toLowerCase()) {
          case BleConstants.deviceInfoUuid:
            info = characteristic;
          case BleConstants.commandUuid:
            _commandCharacteristic = characteristic;
          case BleConstants.statusUuid:
            _statusCharacteristic = characteristic;
          case BleConstants.configUuid:
            _configCharacteristic = characteristic;
          case BleConstants.otaUuid:
            _otaCharacteristic = characteristic;
          case BleConstants.eventUuid:
            event = characteristic;
        }
      }
    }

    if (info == null ||
        _commandCharacteristic == null ||
        _statusCharacteristic == null) {
      throw const BleException('Service BLE MEDITRACE tidak lengkap.');
    }

    final infoPayload = utf8.decode(await info.read());
    _deviceInfo = DeviceInfo.fromJson(
      jsonDecode(infoPayload) as Map<String, dynamic>,
    );

    await _statusSubscription?.cancel();
    _statusSubscription = _statusCharacteristic!.onValueReceived.listen(
      (value) => _statusController.add(utf8.decode(value)),
    );
    device.cancelWhenDisconnected(_statusSubscription!);
    await _statusCharacteristic!.setNotifyValue(true);

    if (event != null) {
      await _eventSubscription?.cancel();
      _eventSubscription = event.onValueReceived.listen(
        (value) => _eventController.add(utf8.decode(value)),
      );
      device.cancelWhenDisconnected(_eventSubscription!);
      await event.setNotifyValue(true);
    }
  }

  @override
  Future<void> writeCommand(String command) async {
    final characteristic = _commandCharacteristic;
    if (characteristic == null) {
      throw const BleException('MEDITRACE belum terhubung.');
    }
    await characteristic.write(utf8.encode(command), withoutResponse: false);
  }

  @override
  Future<String> readConfig() async {
    final characteristic = _configCharacteristic;
    if (characteristic == null) {
      throw const BleException('Konfigurasi MEDITRACE tidak tersedia.');
    }
    return utf8.decode(await characteristic.read());
  }

  @override
  Future<void> writeConfig(String config) async {
    final characteristic = _configCharacteristic;
    if (characteristic == null) {
      throw const BleException('Konfigurasi MEDITRACE tidak tersedia.');
    }

    await characteristic.write(utf8.encode(config), withoutResponse: false);
  }

  @override
  Future<void> writeFirmwareChunk(Uint8List chunk) async {
    final characteristic = _otaCharacteristic;
    if (characteristic == null) {
      throw const BleException('Fitur update firmware tidak tersedia.');
    }
    await characteristic.write(chunk.toList(), withoutResponse: true);
  }

  @override
  Future<void> refreshStatus() async {
    await writeCommand('GET_STATUS');
    await readSignalStrength();
  }

  @override
  Future<int?> readSignalStrength() async {
    final device = _connected;
    if (device == null) return null;
    _rssi = await device.readRssi();
    return _rssi;
  }

  @override
  Future<void> disconnect() async {
    await _connected?.disconnect();
    _clearConnection();
    _connectionController.add(MeditraceConnectionState.disconnected);
  }

  void _clearConnection() {
    _connected = null;
    _commandCharacteristic = null;
    _statusCharacteristic = null;
    _configCharacteristic = null;
    _otaCharacteristic = null;
    _connectedDevice = null;
    _deviceInfo = null;
    _rssi = null;
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _scanSubscription?.cancel();
    await _scanningSubscription?.cancel();
    await _connectionSubscription?.cancel();
    await _statusSubscription?.cancel();
    await _eventSubscription?.cancel();
    await _scanController.close();
    await _scanningController.close();
    await _connectionController.close();
    await _statusController.close();
    await _eventController.close();
  }
}
