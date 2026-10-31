class MedicationSchedule {
  const MedicationSchedule({
    required this.id,
    required this.label,
    required this.hour,
    required this.minute,
    this.compartmentNumber,
    this.enabled = true,
    this.earlyTolerance = 15,
    this.lateTolerance = 15,
    this.updatedAt,
  });

  final int id;
  final String label;
  final int hour;
  final int minute;
  final int? compartmentNumber;
  final bool enabled;
  final int earlyTolerance;
  final int lateTolerance;
  final DateTime? updatedAt;

  String get timeText =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  MedicationSchedule copyWith({
    String? label,
    int? hour,
    int? minute,
    int? compartmentNumber,
    bool? enabled,
    DateTime? updatedAt,
  }) => MedicationSchedule(
    id: id,
    label: label ?? this.label,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    compartmentNumber: compartmentNumber ?? this.compartmentNumber,
    enabled: enabled ?? this.enabled,
    earlyTolerance: earlyTolerance,
    lateTolerance: lateTolerance,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'hour': hour,
    'minute': minute,
    'compartment_number': compartmentNumber,
    'enabled': enabled,
    'early_tolerance': earlyTolerance,
    'late_tolerance': lateTolerance,
    'updated_at': updatedAt?.toIso8601String(),
  };

  factory MedicationSchedule.fromJson(Map<String, dynamic> json) =>
      MedicationSchedule(
        id: (json['id'] as num).toInt(),
        label: json['label'] as String? ?? 'Obat',
        hour: (json['hour'] as num).toInt(),
        minute: (json['minute'] as num).toInt(),
        compartmentNumber: (json['compartment_number'] as num?)?.toInt(),
        enabled: json['enabled'] as bool? ?? true,
        earlyTolerance: (json['early_tolerance'] as num?)?.toInt() ?? 15,
        lateTolerance: (json['late_tolerance'] as num?)?.toInt() ?? 15,
        updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
      );
}
