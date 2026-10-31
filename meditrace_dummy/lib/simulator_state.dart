class SimulatorState {
  static const batteryCapacityMah = 1500.0;
  static const averageCurrentMa = 150.0;

  SimulatorState({
    this.count = 5,
    this.battery = 82,
    this.simulatedRssi,
    List<bool>? sensors,
    List<bool>? doors,
  }) : sensors = List.unmodifiable(sensors ?? List.filled(count, true)),
       doors = List.unmodifiable(doors ?? List.filled(count, true)) {
    if (count != 5) throw ArgumentError.value(count, 'count');
    if (this.sensors.length != count || this.doors.length != count) {
      throw ArgumentError('Jumlah sensor dan pintu harus sesuai mode.');
    }
  }

  final int count;
  final int battery;
  final int? simulatedRssi;
  final List<bool> sensors;
  final List<bool> doors;

  Duration? get estimatedRuntime {
    if (battery <= 0) return null;
    final hours = batteryCapacityMah * (battery / 100) / averageCurrentMa;
    return Duration(minutes: (hours * 60).round());
  }

  String get estimatedRuntimeLabel {
    final duration = estimatedRuntime;
    if (duration == null) return 'Belum tersedia';
    return '${duration.inHours} jam '
        '${duration.inMinutes.remainder(60)} menit';
  }

  SimulatorState withCount(int next) => SimulatorState(
    count: next,
    battery: battery,
    simulatedRssi: simulatedRssi,
    sensors: List.generate(next, (i) => i < count ? sensors[i] : true),
    doors: List.generate(next, (i) => i < count ? doors[i] : true),
  );

  SimulatorState withBattery(int next) => SimulatorState(
    count: count,
    battery: next.clamp(0, 100),
    simulatedRssi: simulatedRssi,
    sensors: sensors,
    doors: doors,
  );

  SimulatorState withSensor(int index, bool value) => SimulatorState(
    count: count,
    battery: battery,
    simulatedRssi: simulatedRssi,
    sensors: [...sensors]..[index] = value,
    doors: doors,
  );

  SimulatorState withDoor(int index, bool value) => SimulatorState(
    count: count,
    battery: battery,
    simulatedRssi: simulatedRssi,
    sensors: sensors,
    doors: [...doors]..[index] = value,
  );

  SimulatorState withSimulatedRssi(int? value) => SimulatorState(
    count: count,
    battery: battery,
    simulatedRssi: value,
    sensors: sensors,
    doors: doors,
  );

  Map<String, Object?> toNative() => {
    'count': count,
    'battery': battery,
    'simulated_rssi': simulatedRssi,
    'sensors': sensors.map((value) => value ? 1 : 0).toList(),
    'doors': doors.map((value) => value ? 1 : 0).toList(),
  };
}
