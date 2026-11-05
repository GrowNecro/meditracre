class DeviceInfo {
  static const int c3CompartmentCount = 5;

  const DeviceInfo({
    required this.deviceId,
    required this.deviceName,
    required this.firmware,
    required this.battery,
    this.board,
    this.batteryEstimated = false,
  });

  final String deviceId;
  final String deviceName;
  final String firmware;
  final int battery;
  final String? board;
  final bool batteryEstimated;

  int get compartmentCount => board == 'ESP32-C3' ? c3CompartmentCount : 2;

  factory DeviceInfo.fromJson(Map<String, dynamic> json) => DeviceInfo(
    deviceId: json['device_id'] as String? ?? 'Unknown',
    deviceName:
        json['device_name'] as String? ??
        json['device_id'] as String? ??
        'MEDITRACE',
    firmware: json['firmware'] as String? ?? '-',
    battery: (json['battery'] as num?)?.toInt() ?? 0,
    board: json['board'] as String?,
    batteryEstimated: json['battery_estimated'] == true,
  );
}
