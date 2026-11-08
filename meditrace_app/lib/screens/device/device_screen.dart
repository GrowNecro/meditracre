import '../../l10n/localization.dart';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'dart:typed_data';

import 'package:provider/provider.dart';

import '../../providers/ble_provider.dart';
import '../../services/ble_service.dart';
import '../../services/battery_estimate.dart';
import '../../services/firmware_update_service.dart';
import '../../widgets/compartment_status_section.dart';
import 'scan_screen.dart';

class DeviceScreen extends StatelessWidget {
  const DeviceScreen({super.key, this.embedded = false});
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleProvider>();
    final connected = ble.connectionState == MeditraceConnectionState.connected;
    final connecting =
        ble.connectionState == MeditraceConnectionState.connecting;
    final content = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: connected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.errorContainer,
          child: ListTile(
            leading: Icon(
              connected
                  ? Icons.bluetooth_connected
                  : connecting
                  ? Icons.bluetooth_searching
                  : Icons.bluetooth_disabled,
            ),
            title: Text(
              connected
                  ? context.l10n.meditraceConnected
                  : connecting
                  ? context.l10n.connectingToMeditrace
                  : context.l10n.meditraceNotConnected,
            ),
            subtitle: Text(
              connecting
                  ? context.l10n.pleaseWait
                  : ble.deviceInfo?.deviceName ?? context.l10n.noMeditrace,
            ),
          ),
        ),
        const SizedBox(height: 12),
        CompartmentStatusSection(ble: ble),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: connected && !ble.isBusy ? ble.refresh : null,
          icon: const Icon(Icons.refresh),
          label: Text(context.l10n.refreshMeditraceStatus),
        ),
        const SizedBox(height: 16),
        Card(
          child: ExpansionTile(
            title: Text(context.l10n.deviceDetails),
            subtitle: Text(context.l10n.batterySignalAndTechnicalInformation),
            children: [
              _Info(
                label: ble.batteryEstimated
                    ? context.l10n.estimatedBattery
                    : context.l10n.battery,
                value: '${ble.battery ?? ble.deviceInfo?.battery ?? 0}%',
              ),
              _Info(
                label: context.l10n.estimatedRuntime,
                value: BatteryEstimate.label(
                  ble.battery ?? ble.deviceInfo?.battery,
                  languageCode: Localizations.localeOf(context).languageCode,
                ),
              ),
              if (ble.batteryEstimated) ...[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    context.l10n.estimatedFromAMahBatteryAndAnAverage,
                  ),
                ),
                TextButton.icon(
                  onPressed: connected && !ble.isBusy
                      ? () => _markBatteryFull(context, ble)
                      : null,
                  icon: const Icon(Icons.battery_charging_full),
                  label: Text(context.l10n.markBatteryAsFull),
                ),
              ],
              _Info(
                label: context.l10n.signalStrength,
                value: connected ? '${ble.rssi ?? '-'} dBm' : '-',
              ),
              _Info(
                label: context.l10n.deviceId,
                value: ble.deviceInfo?.deviceId ?? '-',
              ),
              _Info(label: 'Firmware', value: ble.deviceInfo?.firmware ?? '-'),
              _Info(
                label: context.l10n.scheduleSource,
                value: context.l10n.appPhone,
              ),
              _Info(
                label: context.l10n.unsentEvents,
                value: '${ble.pendingEvents}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (connected) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.espCFirmware,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.theLatestUpdateIsDownloadedFromGithubReleases,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: ble.isBusy
                        ? null
                        : () => _downloadAndUpdateFirmware(context, ble),
                    icon: const Icon(Icons.cloud_download_outlined),
                    label: Text(context.l10n.updateToLatestFirmware),
                  ),
                  OutlinedButton.icon(
                    onPressed: ble.isBusy
                        ? null
                        : () => _selectAndUpdateFirmware(context, ble),
                    icon: const Icon(Icons.folder_open_outlined),
                    label: Text(context.l10n.chooseLocalBinFile),
                  ),
                  if (ble.firmwareProgress > 0) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: ble.firmwareProgress < 1
                          ? ble.firmwareProgress
                          : 1,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ble.firmwareProgress < 1
                          ? context.l10n.sendingFirmware(
                              ((ble.firmwareProgress * 100).round()).toString(),
                            )
                          : context.l10n.firmwareSentTheDeviceIsRestarting,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (!connected)
          FilledButton.icon(
            onPressed: ble.isBusy
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => const ScanScreen()),
                  ),
            icon: const Icon(Icons.bluetooth_searching),
            label: Text(context.l10n.findMeditrace),
          )
        else ...[
          TextButton.icon(
            onPressed: ble.isBusy
                ? null
                : () => _confirmDisconnect(context, ble),
            icon: const Icon(Icons.link_off),
            label: Text(context.l10n.disconnect),
          ),
        ],
        if (ble.errorMessage != null)
          Text(
            ble.errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(ble.deviceInfo?.deviceName ?? context.l10n.meditraceDevice),
      ),
      body: content,
    );
  }

  Future<void> _markBatteryFull(BuildContext context, BleProvider ble) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.isTheBatteryFullyCharged),
        content: Text(context.l10n.theEstimateWillRestartFromUseThisOnly),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.markAsFull),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ble.markBatteryFull();
    if (context.mounted && ble.errorMessage != null) {
      _showMessage(context, ble.errorMessage!);
    }
  }

  Future<void> _selectAndUpdateFirmware(
    BuildContext context,
    BleProvider ble,
  ) async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['bin'],
    );
    final bytes = await _readFirmwareBytes(file);
    if (bytes == null || bytes.isEmpty || !context.mounted) {
      return;
    }
    await _confirmAndUpdate(context, ble, bytes);
  }

  Future<void> _downloadAndUpdateFirmware(
    BuildContext context,
    BleProvider ble,
  ) async {
    try {
      final bytes = await FirmwareUpdateService.downloadLatestEsp32C3(
        languageCode: Localizations.localeOf(context).languageCode,
      );
      if (!context.mounted) return;
      await _confirmAndUpdate(context, ble, bytes);
    } on FirmwareUpdateException catch (error) {
      if (context.mounted) {
        _showMessage(context, error.message);
      }
    } on Exception catch (error) {
      if (context.mounted) {
        _showMessage(
          context,
          context.l10n.couldNotDownloadFirmware((error).toString()),
        );
      }
    }
  }

  Future<void> _confirmAndUpdate(
    BuildContext context,
    BleProvider ble,
    Uint8List bytes,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.updateFirmware),
        content: Text(
          context.l10n.theDeviceWillRestartAfterTheUpdateBytes(
            (bytes.length).toString(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Update'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ble.updateFirmware(bytes);
    if (!context.mounted) return;
    _showMessage(
      context,
      ble.errorMessage == null
          ? context.l10n.firmwareSentTheDeviceIsRestarting
          : ble.errorMessage!,
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<Uint8List?> _readFirmwareBytes(PlatformFile? file) async {
    if (file == null) return null;
    return file.readAsBytes();
  }

  Future<void> _confirmDisconnect(BuildContext context, BleProvider ble) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.disconnectMeditrace),
        content: Text(
          context
              .l10n
              .afterDisconnectingMeditraceWillNotReconnectAutomaticallyYou,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Putuskan'),
          ),
        ],
      ),
    );
    if (confirmed == true) await ble.disconnect();
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) =>
      ListTile(title: Text(label), trailing: Text(value));
}
