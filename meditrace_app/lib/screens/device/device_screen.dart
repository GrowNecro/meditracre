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
    final content = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: connected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.errorContainer,
          child: ListTile(
            leading: Icon(
              connected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
            ),
            title: Text(
              connected ? 'MEDITRACE terhubung' : 'MEDITRACE belum terhubung',
            ),
            subtitle: Text(ble.deviceInfo?.deviceName ?? 'Tidak ada MEDITRACE'),
          ),
        ),
        const SizedBox(height: 12),
        CompartmentStatusSection(ble: ble),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: connected && !ble.isBusy ? ble.refresh : null,
          icon: const Icon(Icons.refresh),
          label: const Text('Perbarui kondisi MEDITRACE'),
        ),
        const SizedBox(height: 16),
        Card(
          child: ExpansionTile(
            title: const Text('Detail perangkat'),
            subtitle: const Text('Baterai, sinyal, dan informasi teknis'),
            children: [
              _Info(
                label: 'Baterai',
                value: '${ble.battery ?? ble.deviceInfo?.battery ?? 0}%',
              ),
              _Info(
                label: 'Estimasi durasi',
                value: BatteryEstimate.label(
                  ble.battery ?? ble.deviceInfo?.battery,
                ),
              ),
              _Info(
                label: 'Kuat sinyal',
                value: connected ? '${ble.rssi ?? '-'} dBm' : '-',
              ),
              _Info(
                label: 'ID perangkat',
                value: ble.deviceInfo?.deviceId ?? '-',
              ),
              _Info(label: 'Firmware', value: ble.deviceInfo?.firmware ?? '-'),
              const _Info(label: 'Sumber jadwal', value: 'Aplikasi/ponsel'),
              _Info(
                label: 'Event belum dikirim',
                value: '${ble.pendingEvents}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (connected) ...[
          OutlinedButton.icon(
            onPressed: ble.isBusy
                ? null
                : () => _downloadAndUpdateFirmware(context, ble),
            icon: const Icon(Icons.cloud_download_outlined),
            label: const Text('Update firmware terbaru'),
          ),
          OutlinedButton.icon(
            onPressed: ble.isBusy
                ? null
                : () => _selectAndUpdateFirmware(context, ble),
            icon: const Icon(Icons.folder_open_outlined),
            label: const Text('Pilih firmware dari perangkat'),
          ),
        ],
        if (ble.firmwareProgress > 0 && ble.firmwareProgress < 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(value: ble.firmwareProgress),
          ),
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
            label: const Text('Cari MEDITRACE'),
          )
        else ...[
          TextButton.icon(
            onPressed: ble.isBusy
                ? null
                : () => _confirmDisconnect(context, ble),
            icon: const Icon(Icons.link_off),
            label: const Text('Putuskan koneksi'),
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
        title: Text(ble.deviceInfo?.deviceName ?? 'Perangkat MEDITRACE'),
      ),
      body: content,
    );
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
      final bytes = await FirmwareUpdateService.downloadLatestEsp32C3();
      if (!context.mounted) return;
      await _confirmAndUpdate(context, ble, bytes);
    } on FirmwareUpdateException catch (error) {
      if (context.mounted) {
        _showMessage(context, error.message);
      }
    } on Exception catch (error) {
      if (context.mounted) {
        _showMessage(context, 'Gagal mengunduh firmware: $error');
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
        title: const Text('Update firmware?'),
        content: Text(
          'Perangkat akan restart setelah update selesai. '
          '${bytes.length} byte akan dikirim melalui BLE.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
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
          ? 'Firmware selesai dikirim. Perangkat sedang restart.'
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
        title: const Text('Putuskan MEDITRACE?'),
        content: const Text(
          'Setelah diputus, MEDITRACE tidak akan tersambung otomatis. '
          'Anda perlu menghubungkannya kembali secara manual.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
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
