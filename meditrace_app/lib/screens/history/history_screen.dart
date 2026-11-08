import '../../l10n/localization.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../services/family_api.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final _familyApi = FamilyApi(
    languageCode: () => context.read<AppProvider>().languageCode,
  );
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
    final events = app.history;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.history),
        actions: [
          IconButton(
            tooltip: context.l10n.clearLocalHistory,
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
          if (preview)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.history_toggle_off,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.noHistoryYet,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.medicationAndDeviceActivityWillAppearHere,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          if (!preview)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: events.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final event = events[index];
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
                      '${event.sensorId == null ? '' : context.l10n.compartment2((event.sensorId).toString())}',
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, AppProvider app) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.clearAllHistory),
        content: Text(context.l10n.allLocalActivityWillBeDeletedAndCannot),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.delete),
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
    'DOSE_REMOVED' => context.l10n.medicationRemoved,
    'DOSE_STATE_CHANGED' =>
      state == true
          ? context.l10n.compartmentFilled
          : context.l10n.compartmentEmpty,
    'DOOR_STATE_CHANGED' =>
      state == true
          ? context.l10n.compartmentClosed
          : context.l10n.compartmentOpened,
    'DOSE_ALARM' => context.l10n.medicationReminder,
    'DOSE_CONFIRMED' => context.l10n.medicationTaken2(
      (_timingText(status)).toString(),
    ),
    'DOSE_CONFIRMATION_REVOKED' => context.l10n.medicationConfirmationRevoked,
    'DOSE_MISSED' => context.l10n.medicationScheduleMissed,
    'BLE_CONNECTED' =>
      status == 'RECONNECTED'
          ? context.l10n.meditracePoweredBackOnAndConnected
          : context.l10n.meditracePoweredOnAndConnected,
    'BLE_DISCONNECTED' => context.l10n.meditraceConnectionLost,
    'SEPARATION_PATIENT_WARNED' => context.l10n.warningMeditraceNotDetected,
    'SEPARATION_CAREGIVER_ESCALATED' => context.l10n.alertSentToFamily,
    'SEPARATION_FALSE_ALARM' => context.l10n.meditraceReconnected,
    'MEDBOX_LEFT_BEHIND' => context.l10n.meditraceReportedLeftBehind,
    _ => context.l10n.deviceActivity,
  };

  String _timingText(String status) => switch (status) {
    'EARLY' => context.l10n.early2,
    'ON_TIME' => context.l10n.onTime,
    'LATE' => context.l10n.late,
    _ => context.l10n.recorded,
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
        ListTile(
          leading: Icon(Icons.notifications_active_outlined),
          title: Text(context.l10n.familyNotifications),
          subtitle: Text(context.l10n.alertsForCaregiversAndFamilyMembers),
        ),
        if (alerts.isEmpty)
          ListTile(
            title: Text(context.l10n.noFamilyNotificationsYet),
            contentPadding: EdgeInsets.fromLTRB(16, 0, 16, 12),
          ),
        for (final rawAlert in alerts)
          Builder(
            builder: (context) {
              final item = rawAlert as Map;
              final alertId = item['id']?.toString();
              return ListTile(
                title: Text(
                  item['title']?.toString() ?? context.l10n.familyAlert,
                ),
                subtitle: Text(
                  '${item['group_name'] ?? context.l10n.family} · '
                  '${item['sender_email'] ?? context.l10n.senderEmailUnavailable} · '
                  '${item['occurred_at'] ?? '-'}',
                ),
                trailing: item['acknowledged_at'] == null && alertId != null
                    ? TextButton(
                        onPressed: () => onAcknowledge(alertId),
                        child: Text(context.l10n.acknowledge),
                      )
                    : const Icon(Icons.check_circle_outline),
              );
            },
          ),
      ],
    ),
  );
}
