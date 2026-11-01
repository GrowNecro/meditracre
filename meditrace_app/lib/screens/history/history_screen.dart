import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/dose_event.dart';
import '../../providers/app_provider.dart';
import '../../services/family_api.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _familyApi = FamilyApi();
  List<dynamic> _familyAlerts = [];

  @override
  void initState() {
    super.initState();
    _loadFamilyAlerts();
  }

  @override
  void dispose() {
    _familyApi.dispose();
    super.dispose();
  }

  Future<void> _loadFamilyAlerts() async {
    try {
      if (!await _familyApi.hasSession || !_familyApi.backendConfigured) return;
      final result = await _familyApi.inbox();
      if (mounted) {
        setState(() => _familyAlerts = result['data'] as List? ?? []);
      }
    } catch (_) {
      // Riwayat lokal tetap tersedia jika inbox keluarga belum dapat dibaca.
    }
  }

  Future<void> _acknowledge(String alertId) async {
    try {
      await _familyApi.acknowledge(alertId);
      await _loadFamilyAlerts();
    } catch (_) {
      // The alert remains visible and can be acknowledged again later.
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final preview = app.history.isEmpty;
    final events = preview ? _previewEvents() : app.history;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat'),
        actions: [
          IconButton(
            tooltip: 'Hapus riwayat lokal',
            onPressed: app.history.isEmpty
                ? null
                : () => _confirmClear(context, app),
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: ListView(
        children: [
          if (_familyAlerts.isNotEmpty || _familyApi.backendConfigured)
            _FamilyAlertsSection(
              alerts: _familyAlerts,
              onAcknowledge: _acknowledge,
            ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: events.length + (preview ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (preview && index == 0) {
                return Card(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: const ListTile(
                    leading: Icon(Icons.visibility_outlined),
                    title: Text('Contoh tampilan riwayat'),
                    subtitle: Text(
                      'Aktivitas di bawah hanya contoh dan tidak tersimpan.',
                    ),
                  ),
                );
              }
              final event = events[index - (preview ? 1 : 0)];
              final time = event.timestamp.toLocal();
              final color = _eventColor(context, event.type);
              return Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.14),
                    foregroundColor: color,
                    child: Icon(_eventIcon(event.type)),
                  ),
                  title: Text(
                    _eventTitle(event.type, event.state, event.status),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year} '
                    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
                    '${event.sensorId == null ? '' : ' · Ruang ${event.sensorId}'}',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<DoseEvent> _previewEvents() {
    final now = DateTime.now();
    return [
      DoseEvent(
        type: 'DOSE_CONFIRMED',
        status: 'ON_TIME',
        timestamp: now.subtract(const Duration(minutes: 18)),
        sensorId: 2,
      ),
      DoseEvent(
        type: 'DOSE_REMOVED',
        timestamp: now.subtract(const Duration(hours: 2)),
        sensorId: 2,
      ),
      DoseEvent(
        type: 'DOSE_ALARM',
        timestamp: now.subtract(const Duration(hours: 2, minutes: 5)),
      ),
      DoseEvent(
        type: 'DOOR_STATE_CHANGED',
        state: false,
        timestamp: now.subtract(const Duration(hours: 2, minutes: 6)),
        sensorId: 2,
      ),
      DoseEvent(
        type: 'BLE_DISCONNECTED',
        timestamp: now.subtract(const Duration(days: 1)),
      ),
      DoseEvent(
        type: 'BLE_CONNECTED',
        timestamp: now.subtract(const Duration(days: 1, minutes: 3)),
        status: 'RECONNECTED',
      ),
    ];
  }

  Future<void> _confirmClear(BuildContext context, AppProvider app) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus semua riwayat?'),
        content: const Text(
          'Semua aktivitas lokal akan dihapus dan tidak dapat dipulihkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true) await app.clearHistory();
  }

  IconData _eventIcon(String type) => switch (type) {
    'DOSE_REMOVED' => Icons.medication,
    'DOSE_STATE_CHANGED' => Icons.inventory_2_outlined,
    'DOOR_STATE_CHANGED' => Icons.inventory_2_outlined,
    'DOSE_ALARM' => Icons.alarm,
    'DOSE_CONFIRMED' => Icons.task_alt,
    'DOSE_CONFIRMATION_REVOKED' => Icons.undo,
    'DOSE_MISSED' => Icons.alarm_off,
    'BLE_CONNECTED' => Icons.bluetooth_connected,
    'BLE_DISCONNECTED' ||
    'SEPARATION_PATIENT_WARNED' ||
    'SEPARATION_CAREGIVER_ESCALATED' ||
    'MEDBOX_LEFT_BEHIND' => Icons.warning_amber,
    'SEPARATION_FALSE_ALARM' => Icons.bluetooth_connected,
    _ => Icons.check_circle_outline,
  };

  Color _eventColor(BuildContext context, String type) {
    final scheme = Theme.of(context).colorScheme;
    return switch (type) {
      'BLE_DISCONNECTED' ||
      'SEPARATION_PATIENT_WARNED' ||
      'SEPARATION_CAREGIVER_ESCALATED' ||
      'MEDBOX_LEFT_BEHIND' => scheme.error,
      'BLE_CONNECTED' ||
      'DOSE_CONFIRMED' ||
      'SEPARATION_FALSE_ALARM' => Colors.green.shade700,
      'DOSE_MISSED' || 'DOSE_CONFIRMATION_REVOKED' => Colors.orange.shade800,
      'DOSE_ALARM' => scheme.secondary,
      _ => scheme.primary,
    };
  }

  String _eventTitle(String type, bool? state, String status) => switch (type) {
    'DOSE_REMOVED' => 'Obat diambil',
    'DOSE_STATE_CHANGED' =>
      state == true ? 'Kompartemen terisi' : 'Kompartemen kosong',
    'DOOR_STATE_CHANGED' =>
      state == true ? 'Kompartemen ditutup' : 'Kompartemen dibuka',
    'DOSE_ALARM' => 'Pengingat obat',
    'DOSE_CONFIRMED' => 'Obat diminum · ${_timingText(status)}',
    'DOSE_CONFIRMATION_REVOKED' => 'Konfirmasi minum dibatalkan',
    'DOSE_MISSED' => 'Jadwal obat terlewat',
    'BLE_CONNECTED' =>
      status == 'RECONNECTED'
          ? 'MEDITRACE hidup kembali dan terhubung'
          : 'MEDITRACE hidup dan terhubung',
    'BLE_DISCONNECTED' => 'Koneksi MEDITRACE terputus',
    'SEPARATION_PATIENT_WARNED' => 'Peringatan: MEDITRACE tidak terdeteksi',
    'SEPARATION_CAREGIVER_ESCALATED' => 'Peringatan dikirim ke keluarga',
    'SEPARATION_FALSE_ALARM' => 'MEDITRACE terhubung kembali',
    'MEDBOX_LEFT_BEHIND' => 'MEDITRACE dilaporkan tertinggal',
    _ => 'Aktivitas perangkat',
  };

  String _timingText(String status) => switch (status) {
    'EARLY' => 'lebih cepat',
    'ON_TIME' => 'tepat waktu',
    'LATE' => 'terlambat',
    _ => 'tercatat',
  };
}

class _FamilyAlertsSection extends StatelessWidget {
  const _FamilyAlertsSection({
    required this.alerts,
    required this.onAcknowledge,
  });

  final List<dynamic> alerts;
  final Future<void> Function(String) onAcknowledge;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
    child: Column(
      children: [
        const ListTile(
          leading: Icon(Icons.notifications_active_outlined),
          title: Text('Pemberitahuan keluarga'),
          subtitle: Text('Peringatan caregiver dan anggota keluarga'),
        ),
        if (alerts.isEmpty)
          const ListTile(
            title: Text('Belum ada pemberitahuan keluarga'),
            contentPadding: EdgeInsets.fromLTRB(16, 0, 16, 12),
          ),
        for (final rawAlert in alerts)
          Builder(
            builder: (context) {
              final item = rawAlert as Map;
              final alertId = item['id']?.toString();
              return ListTile(
                title: Text(item['title']?.toString() ?? 'Peringatan keluarga'),
                subtitle: Text(
                  '${item['group_name'] ?? 'Keluarga'} · '
                  '${item['sender_email'] ?? 'Email pengirim tidak tersedia'} · '
                  '${item['occurred_at'] ?? '-'}',
                ),
                trailing: item['acknowledged_at'] == null && alertId != null
                    ? TextButton(
                        onPressed: () => onAcknowledge(alertId),
                        child: const Text('Tangani'),
                      )
                    : const Icon(Icons.check_circle_outline),
              );
            },
          ),
      ],
    ),
  );
}
