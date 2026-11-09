import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/localization.dart';
import '../../models/dose_event.dart';
import '../../providers/app_provider.dart';
import '../../services/family_api.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    this.isActive = true,
    this.onOpenProfile,
    this.familyApi,
  });

  final bool isActive;
  final VoidCallback? onOpenProfile;
  final FamilyApi? familyApi;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with WidgetsBindingObserver {
  late final _familyApi =
      widget.familyApi ??
      FamilyApi(languageCode: () => context.read<AppProvider>().languageCode);
  StreamSubscription<String?>? _sessionSubscription;
  StreamSubscription<void>? _notificationSubscription;
  List<dynamic> _familyAlerts = [];
  final Set<String> _acknowledging = {};
  int _loadGeneration = 0;
  bool _loading = true;
  bool _signedIn = false;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sessionSubscription = _familyApi.sessionUserIds.distinct().listen((_) {
      unawaited(_loadFamilyAlerts(clear: true));
    });
    _notificationSubscription = _familyApi.foregroundNotifications.listen((_) {
      unawaited(_loadFamilyAlerts());
    });
    unawaited(_loadFamilyAlerts());
  }

  @override
  void didUpdateWidget(covariant HistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      unawaited(_loadFamilyAlerts());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.isActive) {
      unawaited(_loadFamilyAlerts());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_sessionSubscription?.cancel());
    unawaited(_notificationSubscription?.cancel());
    if (widget.familyApi == null) _familyApi.dispose();
    super.dispose();
  }

  Future<void> _loadFamilyAlerts({bool clear = false}) async {
    final generation = ++_loadGeneration;
    if (!mounted) return;
    setState(() {
      _loading = true;
      _loadFailed = false;
      if (clear) {
        _familyAlerts = [];
        _signedIn = false;
      }
    });
    try {
      final signedIn = await _familyApi.hasSession;
      final result = signedIn ? await _familyApi.inbox() : null;
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _signedIn = signedIn;
        _familyAlerts = result?['data'] as List? ?? [];
        _loading = false;
      });
    } catch (_) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _acknowledge(String alertId) async {
    if (!_acknowledging.add(alertId)) return;
    setState(() {});
    final generation = _loadGeneration;
    try {
      await _familyApi.acknowledge(alertId);
      if (!mounted || generation != _loadGeneration) return;
      // Show the acknowledged status immediately, then confirm server state.
      setState(() {
        _familyAlerts = [
          for (final raw in _familyAlerts)
            if ((raw as Map)['id']?.toString() == alertId)
              {...raw, 'acknowledged_at': DateTime.now().toIso8601String()}
            else
              raw,
        ];
      });
      await _loadFamilyAlerts();
    } catch (_) {
      if (mounted && generation == _loadGeneration) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.alertAcknowledgeFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _acknowledging.remove(alertId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final entries = <({DateTime time, DoseEvent? event, Map? alert})>[
      for (final event in app.history)
        (time: event.timestamp, event: event, alert: null),
      for (final raw in _familyAlerts)
        (
          time:
              DateTime.tryParse(
                (raw as Map)['occurred_at']?.toString() ?? '',
              ) ??
              DateTime.fromMillisecondsSinceEpoch(0),
          event: null,
          alert: raw,
        ),
    ]..sort((a, b) => b.time.compareTo(a.time));
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.activity),
        actions: [
          IconButton(
            tooltip: context.l10n.refreshFamilyNotifications,
            onPressed: _loading ? null : _loadFamilyAlerts,
            icon: const Icon(Icons.refresh),
          ),
          PopupMenuButton<String>(
            onSelected: (_) => _confirmClear(context, app),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'clear-history',
                enabled: app.history.isNotEmpty,
                child: Text(context.l10n.clearLocalHistory),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          if (_loadFailed)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.familyNotificationsLoadFailed,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(context.l10n.familyNotificationsRetryDescription),
                      TextButton.icon(
                        onPressed: _loading ? null : _loadFamilyAlerts,
                        icon: const Icon(Icons.refresh),
                        label: Text(context.l10n.retry),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadFamilyAlerts,
              child: entries.isEmpty
                  ? LayoutBuilder(
                      builder: (context, constraints) => ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: constraints.maxHeight,
                            child: _ActivityEmptyState(
                              icon: Icons.notifications_none_outlined,
                              title: context.l10n.noActivityYet,
                              description: _signedIn
                                  ? context.l10n.activityEmptyDescription
                                  : context.l10n.activityGuestDescription,
                              action:
                                  !_signedIn &&
                                      !_loading &&
                                      !_loadFailed &&
                                      widget.onOpenProfile != null
                                  ? FilledButton.tonalIcon(
                                      onPressed: widget.onOpenProfile,
                                      icon: const Icon(Icons.person_outline),
                                      label: Text(context.l10n.openProfile),
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      key: const PageStorageKey('activity-feed'),
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: entries.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = entries[index];
                        return item.event != null
                            ? _buildHistoryEvent(item.event!)
                            : _buildFamilyAlert(item.alert!);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryEvent(DoseEvent event) {
    final color = _eventColor(context, event.type);
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          foregroundColor: color,
          child: Icon(_eventIcon(event.type)),
        ),
        title: Text(
          _eventTitle(event.type, event.state, event.status),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${context.l10n.localActivity}\n'
          '${_formatTimestamp(context, event.timestamp)}'
          '${event.sensorId == null ? '' : context.l10n.compartment2('${event.sensorId}')}',
        ),
      ),
    );
  }

  Widget _buildFamilyAlert(Map item) {
    final alertId = item['id']?.toString();
    final pending = item['acknowledged_at'] == null;
    final busy = _acknowledging.contains(alertId);
    final scheme = Theme.of(context).colorScheme;
    final time = DateTime.tryParse(item['occurred_at']?.toString() ?? '');
    return Card(
      margin: EdgeInsets.zero,
      color: pending ? scheme.primaryContainer.withValues(alpha: 0.4) : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  pending
                      ? Icons.notifications_active_outlined
                      : Icons.task_alt,
                  color: pending ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item['title']?.toString() ?? context.l10n.familyAlert,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${context.l10n.family} · ${item['group_name'] ?? context.l10n.familyAlert}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (item['sender_email'] != null)
              Text(item['sender_email'].toString()),
            if (time != null) ...[
              const SizedBox(height: 4),
              Text(
                _formatTimestamp(context, time),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  pending
                      ? context.l10n.alertNeedsAttention
                      : context.l10n.alertHandled,
                  style: TextStyle(
                    color: pending ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                ),
                if (pending && alertId != null)
                  TextButton.icon(
                    onPressed: busy ? null : () => _acknowledge(alertId),
                    icon: busy
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.done),
                    label: Text(context.l10n.acknowledge),
                  ),
              ],
            ),
          ],
        ),
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

String _formatTimestamp(BuildContext context, DateTime value) {
  final time = value.toLocal();
  final localizations = MaterialLocalizations.of(context);
  return '${localizations.formatShortDate(time)} · '
      '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(time), alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context))}';
}

class _ActivityEmptyState extends StatelessWidget {
  const _ActivityEmptyState({
    required this.icon,
    required this.title,
    required this.description,
    this.action,
  });
  final IconData icon;
  final String title;
  final String description;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest,
            child: Icon(
              icon,
              size: 34,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    ),
  );
}
