import '../l10n/localization.dart';

import 'package:flutter/material.dart';

import '../models/device_info.dart';
import '../providers/ble_provider.dart';
import '../services/ble_service.dart';

class CompartmentStatusSection extends StatelessWidget {
  const CompartmentStatusSection({
    super.key,
    required this.ble,
    this.compact = false,
  });

  final BleProvider ble;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final connected = ble.connectionState == MeditraceConnectionState.connected;
    final cards = List.generate(ble.compartmentCount, (index) {
      return _CompartmentStatus(
        number: index + 1,
        connected: connected,
        occupied: connected && index < ble.sensors.length
            ? ble.sensors[index] == 1
            : null,
        doorClosed: connected && index < ble.doors.length
            ? ble.doors[index] == 1
            : null,
        hasDoorSensor:
            index <
            (ble.deviceInfo?.board == 'ESP32-C3'
                ? DeviceInfo.c3CompartmentCount
                : 1),
        compact: compact,
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          compact
              ? context.l10n.medicationInTheBox
              : context.l10n.compartmentStatus,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (!connected)
          Text(context.l10n.connectMeditraceToSeeEachCompartmentSStatus)
        else if (ble.sensorValid == false)
          Text(context.l10n.theSensorsCouldNotBeReadCheckThe)
        else if (ble.lastSensorUpdate == null)
          Text(context.l10n.gettingSensorStatusFromMeditrace),
        if (compact)
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 560 ? 2 : 1;
              final width =
                  (constraints.maxWidth - (columns - 1) * 8) / columns;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final card in cards) SizedBox(width: width, child: card),
                ],
              );
            },
          )
        else
          ...cards,
      ],
    );
  }
}

class _CompartmentStatus extends StatelessWidget {
  const _CompartmentStatus({
    required this.number,
    required this.connected,
    required this.occupied,
    required this.doorClosed,
    required this.hasDoorSensor,
    required this.compact,
  });

  final int number;
  final bool connected;
  final bool? occupied;
  final bool? doorClosed;
  final bool hasDoorSensor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      final status = occupied == null
          ? context.l10n.notReadYet
          : occupied!
          ? context.l10n.medicationAvailable
          : context.l10n.noMedication;
      final colorScheme = Theme.of(context).colorScheme;
      return Card(
        margin: EdgeInsets.zero,
        color: connected && occupied == false
            ? colorScheme.errorContainer
            : connected && occupied == true
            ? colorScheme.primaryContainer
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: colorScheme.surface,
                child: Icon(
                  occupied == null
                      ? Icons.help_outline
                      : occupied!
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_rounded,
                  color: occupied == false
                      ? colorScheme.error
                      : colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.compartment3((number).toString()),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(status, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final doseText = occupied == null
        ? context.l10n.notReadYet
        : occupied!
        ? context.l10n.filled
        : context.l10n.empty;
    final doorText = !hasDoorSensor
        ? context.l10n.doorSensorUnavailable
        : doorClosed == null
        ? context.l10n.notReadYet
        : doorClosed!
        ? context.l10n.closed
        : context.l10n.open;
    final needsAttention =
        connected &&
        (occupied == false || (hasDoorSensor && doorClosed == false));

    return Card(
      color: needsAttention
          ? Theme.of(context).colorScheme.errorContainer
          : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.compartment4((number).toString()),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _StatusLine(
              icon: Icons.medication_outlined,
              text: context.l10n.medication((doseText).toString()),
            ),
            const SizedBox(height: 4),
            _StatusLine(
              icon: Icons.door_front_door_outlined,
              text: context.l10n.door((doorText).toString()),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.icon, required this.text});

  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 20),
      const SizedBox(width: 8),
      Expanded(child: Text(text)),
    ],
  );
}
