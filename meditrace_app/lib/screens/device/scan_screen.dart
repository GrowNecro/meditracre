import '../../l10n/localization.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/ble_provider.dart';
import 'device_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BleProvider>().scan();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.findMeditrace),
        actions: [
          IconButton(
            tooltip: ble.isScanning
                ? context.l10n.stopScanning
                : context.l10n.scanAgain,
            onPressed: ble.isBusy
                ? null
                : ble.isScanning
                ? ble.stopScan
                : ble.scan,
            icon: Icon(ble.isScanning ? Icons.stop : Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          if (ble.isScanning) const LinearProgressIndicator(),
          if (ble.errorMessage != null)
            MaterialBanner(
              content: Text(ble.errorMessage!),
              actions: [
                TextButton(
                  onPressed: ble.clearError,
                  child: Text(context.l10n.close),
                ),
              ],
            ),
          Expanded(
            child: ble.devices.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        context.l10n.noMeditraceFoundYetMakeSureTheMedication,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: ble.devices.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final device = ble.devices[index];
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.medication),
                          ),
                          title: Text(device.name),
                          subtitle: Text(context.l10n.tapToConnect),
                          trailing: const Icon(Icons.chevron_right),
                          enabled: !ble.isBusy,
                          onTap: () async {
                            await ble.connect(device.remoteId);
                            if (!context.mounted || ble.errorMessage != null) {
                              return;
                            }
                            await Navigator.of(context).pushReplacement(
                              MaterialPageRoute<void>(
                                builder: (_) => const DeviceScreen(),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
