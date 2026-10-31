class DoseEvent {
  const DoseEvent({
    required this.type,
    required this.timestamp,
    this.sensorId,
    this.scheduleId,
    this.state,
    this.status = 'TERCATAT',
  });

  final String type;
  final DateTime timestamp;
  final int? sensorId;
  final int? scheduleId;
  final bool? state;
  final String status;

  Map<String, dynamic> toJson() => {
    'type': type,
    'timestamp': timestamp.toIso8601String(),
    'sensor_id': sensorId,
    'schedule_id': scheduleId,
    'state': state,
    'status': status,
  };

  factory DoseEvent.fromJson(Map<String, dynamic> json) => DoseEvent(
    type: json['type'] as String? ?? json['event'] as String? ?? 'EVENT',
    timestamp:
        DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
    sensorId: (json['sensor_id'] as num?)?.toInt(),
    scheduleId: (json['schedule_id'] as num?)?.toInt(),
    state: json['state'] as bool?,
    status: json['status'] as String? ?? 'TERCATAT',
  );
}
