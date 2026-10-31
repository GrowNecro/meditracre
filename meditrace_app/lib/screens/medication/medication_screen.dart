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
      appBar: AppBar(title: const Text('Jadwal Obat')),
      body: app.schedules.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Belum ada jadwal obat.\nKetuk Tambah jadwal untuk mulai.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
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
                        contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                        onTap: () => _editSchedule(context, schedule),
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                          child: Icon(
                            Icons.alarm,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                        title: Text(
                          schedule.timeText,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: scheme.onPrimaryContainer,
                              ),
                        ),
                        subtitle: Text(
                          'Setiap hari',
                          style: TextStyle(color: scheme.onPrimaryContainer),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Hapus jadwal',
                              onPressed: () =>
                                  _confirmRemove(context, schedule),
                              icon: Icon(
                                Icons.delete_outline,
                                color: scheme.error,
                              ),
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
                                label: const Text(
                                  'Sudah diminum hari ini · batalkan',
                                ),
                              )
                            else
                              FilledButton.icon(
                                onPressed: canConfirm
                                    ? () =>
                                          _confirmDose(context, schedule, true)
                                    : null,
                                icon: const Icon(Icons.check),
                                label: const Text('Sudah minum'),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addSchedule(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah jadwal'),
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
        title: const Text('Hapus jadwal obat?'),
        content: Text(
          'Jadwal ${schedule.label} pukul ${schedule.timeText} akan dihapus.',
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
    if (remove == true && context.mounted) {
      await context.read<AppProvider>().removeSchedule(schedule.id);
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
        title: Text(confirmed ? 'Obat sudah diminum?' : 'Batalkan konfirmasi?'),
        content: Text(
          confirmed
              ? 'Konfirmasi hanya jika obat dari ruang ini benar-benar sudah diminum, bukan sekadar diambil dari kotak.'
              : 'Status diminum hari ini akan dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Kembali'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmed ? 'Ya, sudah diminum' : 'Batalkan status'),
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
        label: 'Jadwal obat',
        hour: time.hour,
        minute: time.minute,
      ),
    );
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
  }
}
