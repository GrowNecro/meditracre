import '../../l10n/localization.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/medication_schedule.dart';
import '../../providers/app_provider.dart';

class MedicationScreen extends StatelessWidget {
  const MedicationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.medicationSchedule)),
      body: app.schedules.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.alarm_add_outlined,
                      size: 56,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.noMedicationSchedulesYet,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.addAReminderToAvoidMissingMedication,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => _addSchedule(context),
                      icon: const Icon(Icons.alarm_add_outlined),
                      label: Text(context.l10n.addSchedule),
                    ),
                  ],
                ),
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: app.schedules.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final schedule = app.schedules[index];
                    final confirmed = app.doseConfirmedToday(schedule.id);
                    final canConfirm = app.canConfirmScheduledDose(schedule);
                    final scheme = Theme.of(context).colorScheme;
                    return Card(
                      elevation: 2,
                      color: scheme.primaryContainer.withValues(alpha: 0.45),
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.fromLTRB(
                              16,
                              8,
                              8,
                              0,
                            ),
                            onTap: () => _editSchedule(context, schedule),
                            leading: CircleAvatar(
                              backgroundColor: scheme.primaryContainer,
                              child: Icon(
                                Icons.alarm,
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                            title: Text(
                              schedule.timeText,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: scheme.onPrimaryContainer,
                                  ),
                            ),
                            subtitle: Text(
                              context.l10n.everyDay,
                              style: TextStyle(
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                PopupMenuButton<String>(
                                  tooltip: context.l10n.scheduleActions,
                                  onSelected: (action) {
                                    if (action == 'delete') {
                                      _confirmRemove(context, schedule);
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: Icon(
                                          Icons.delete_outline,
                                          color: scheme.error,
                                        ),
                                        title: Text(
                                          context.l10n.deleteSchedule,
                                        ),
                                      ),
                                    ),
                                  ],
                                  icon: const Icon(Icons.more_vert),
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (confirmed)
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        _confirmDose(context, schedule, false),
                                    icon: const Icon(Icons.check_circle),
                                    label: Text(context.l10n.takenTodayUndo),
                                  )
                                else
                                  FilledButton.icon(
                                    onPressed: canConfirm
                                        ? () => _confirmDose(
                                            context,
                                            schedule,
                                            true,
                                          )
                                        : null,
                                    icon: const Icon(Icons.check),
                                    label: Text(context.l10n.taken),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addSchedule(context),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.addSchedule),
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    MedicationSchedule schedule,
  ) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.deleteMedicationSchedule),
        content: Text(
          context.l10n.scheduleAtWillBeDeleted(
            (schedule.label).toString(),
            (schedule.timeText).toString(),
          ),
        ),
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
    if (remove == true && context.mounted) {
      await context.read<AppProvider>().removeSchedule(schedule.id);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.scheduleDeleted)));
      }
    }
  }

  Future<void> _confirmDose(
    BuildContext context,
    MedicationSchedule schedule,
    bool confirmed,
  ) async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          confirmed
              ? context.l10n.haveYouTakenTheMedication
              : context.l10n.revokeConfirmation,
        ),
        content: Text(
          confirmed
              ? context.l10n.confirmOnlyIfTheMedicationFromThisCompartment
              : context.l10n.todaySTakenStatusWillBeRevoked,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.back),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              confirmed ? context.l10n.yesTaken : context.l10n.revokeStatus,
            ),
          ),
        ],
      ),
    );
    if (proceed == true && context.mounted) {
      await context.read<AppProvider>().setDoseConfirmed(schedule, confirmed);
    }
  }

  Future<void> _addSchedule(BuildContext context) async {
    final app = context.read<AppProvider>();

    await app.requestNotificationPermission();
    if (!context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null || !context.mounted) return;
    await app.saveSchedule(
      MedicationSchedule(
        id: app.createScheduleId(),
        label: context.l10n.medicationSchedule2,
        hour: time.hour,
        minute: time.minute,
      ),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.scheduleAdded)));
    }
  }

  Future<void> _editSchedule(
    BuildContext context,
    MedicationSchedule schedule,
  ) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: schedule.hour, minute: schedule.minute),
    );
    if (time == null || !context.mounted) return;
    await context.read<AppProvider>().saveSchedule(
      schedule.copyWith(hour: time.hour, minute: time.minute),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.scheduleUpdated)));
    }
  }
}
