import '../models/device_info.dart';
import '../models/meditrace_device.dart';

import 'dart:typed_data';

enum MeditraceConnectionState { disconnected, connecting, connected }

abstract interface class BleService {
  Stream<List<MeditraceDevice>> get scanResults;
  Stream<bool> get scanning;
  Stream<MeditraceConnectionState> get connectionState;
  Stream<String> get statusMessages;
  Stream<String> get deviceEvents;

  DeviceInfo? get deviceInfo;
  MeditraceDevice? get connectedDevice;
  int? get rssi;

  Future<void> startScan();
  Future<void> stopScan();
  Future<void> connect(String remoteId);
  Future<void> disconnect();
  Future<void> writeCommand(String command);
  Future<String> readConfig();
  Future<void> writeConfig(String config);
  Future<void> writeFirmwareChunk(Uint8List chunk);
  Future<void> refreshStatus();
  Future<int?> readSignalStrength();
  Future<void> dispose();
}

class BleException implements Exception {
  const BleException(this.message);
  final String message;

  @override
  String toString() => message;
}
