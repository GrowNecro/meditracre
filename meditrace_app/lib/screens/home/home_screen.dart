import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/device_info.dart';
import '../../providers/app_provider.dart';
import '../../providers/ble_provider.dart';
import '../../services/ble_service.dart';
import '../device/device_screen.dart';
import '../device/scan_screen.dart';
import '../history/history_screen.dart';
import '../medication/medication_screen.dart';
import '../more/medication_guide_screen.dart';
import '../more/more_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('MEDITRACE'),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest,
            child: IconButton(
              icon: const Icon(Icons.help_outline, size: 28),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MedicationGuideScreen(),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    ),
    body: IndexedStack(
      index: _index,
      children: const [
        _Dashboard(),
        MedicationScreen(),
        HistoryScreen(),
        DeviceScreen(embedded: true),
        MoreScreen(),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _index,
      onDestinationSelected: (value) => setState(() => _index = value),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.medication_outlined),
          selectedIcon: Icon(Icons.medication),
          label: 'Jadwal',
        ),
        NavigationDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history),
          label: 'Riwayat',
        ),
        NavigationDestination(
          icon: Icon(Icons.developer_board_outlined),
          selectedIcon: Icon(Icons.developer_board),
          label: 'Perangkat',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
    ),
  );
}

class _Dashboard extends StatelessWidget {
  const _Dashboard();

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleProvider>();
    final app = context.watch<AppProvider>();
    final connected = ble.connectionState == MeditraceConnectionState.connected;
    final next = app.nextSchedule();
    final compartmentCount = ble.compartmentCount == 0
        ? DeviceInfo.c3CompartmentCount
        : ble.compartmentCount;
    final filledCount = ble.sensors
        .take(compartmentCount)
        .where((value) => value == 1)
        .length;
    final nextCompartmentEmpty =
        next?.compartmentNumber != null &&
        next!.compartmentNumber! <= ble.sensors.length &&
        ble.sensors[next.compartmentNumber! - 1] == 0;
    final scheme = Theme.of(context).colorScheme;
    final batteryColor = ble.battery == null
        ? scheme.outline
        : ble.battery! <= 20
        ? scheme.error
        : ble.battery! <= 40
        ? Colors.orange.shade700
        : Colors.green.shade700;
    final batteryIcon = ble.battery == null
        ? Icons.battery_unknown
        : ble.battery! <= 10
        ? Icons.battery_0_bar
        : ble.battery! <= 25
        ? Icons.battery_1_bar
        : ble.battery! <= 50
        ? Icons.battery_2_bar
        : ble.battery! <= 75
        ? Icons.battery_4_bar
        : Icons.battery_full;

    return RefreshIndicator(
      onRefresh: connected ? ble.refresh : () async {},
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Text(
            'Selamat datang!',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Pantau jadwal obatmu hari ini.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          Card(
            elevation: 2,
            color: connected
                ? scheme.surfaceContainerHighest
                : scheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        connected
                            ? Icons.medical_services
                            : Icons.medical_services_outlined,
                        color: connected ? Colors.teal.shade800 : scheme.error,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          connected ? 'MEDBOX aktif' : 'MEDBOX belum terhubung',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (connected)
                        IconButton(
                          tooltip: 'Detail perangkat',
                          onPressed: () => _showDeviceInfo(context, ble),
                          icon: const Icon(Icons.info_outline),
                        )
                      else
                        IconButton(
                          tooltip: 'Hubungkan perangkat',
                          onPressed: ble.isBusy
                              ? null
                              : () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => const ScanScreen(),
                                  ),
                                ),
                          icon: const Icon(Icons.bluetooth_searching),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(
                        batteryIcon,
                        color: batteryColor,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(child: Text('Baterai')),
                      Text(
                        ble.battery == null ? '--%' : '${ble.battery}%',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: ble.battery == null
                          ? 0
                          : (ble.battery!.clamp(0, 100)) / 100,
                      color: batteryColor,
                      backgroundColor: scheme.surface,
                    ),
                  ),
                  if (ble.batteryVoltage != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${ble.batteryVoltage!.toStringAsFixed(2)} V',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (ble.signalWeak)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Card(
                margin: EdgeInsets.zero,
                color: scheme.errorContainer,
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.warning_amber, color: scheme.error),
                  title: Text(
                    'Sinyal lemah',
                    style: TextStyle(
                      color: scheme.onErrorContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Pastikan MEDBOX tetap dekat.',
                    style: TextStyle(color: scheme.onErrorContainer),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 14),
          Card(
            elevation: 2,
            color: scheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jadwal berikutnya',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    next?.timeText ?? '--:--',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: scheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    next == null
                        ? 'Belum ada jadwal obat'
                        : 'Tunggu jadwal obat berikutnya',
                    style: TextStyle(color: scheme.onSecondaryContainer),
                  ),
                  if (nextCompartmentEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        'Obat belum tersedia di kompartemen ini.',
                        style: TextStyle(
                          color: scheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const MedicationScreen(),
                        ),
                      ),
                      child: const Text('Lihat jadwal obat'),
                    ),
                  ),
                  if (next != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.tonalIcon(
                        onPressed: app.canConfirmScheduledDose(next)
                            ? () => app.setDoseConfirmed(next, true)
                            : null,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Sudah minum'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Kotak obat',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const DeviceScreen()),
                ),
                child: const Text('Lihat semua'),
              ),
            ],
          ),
          _MedicationBoxSummary(
            connected: connected,
            sensors: ble.sensors,
            compartmentCount: compartmentCount,
            filledCount: filledCount,
          ),
          if (ble.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                ble.errorMessage!,
                style: TextStyle(color: scheme.error),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showDeviceInfo(BuildContext context, BleProvider ble) =>
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('MEDITRACE terhubung'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Baterai'),
              Text('${ble.battery ?? ble.deviceInfo?.battery ?? '--'}%'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
}

class _MedicationBoxSummary extends StatelessWidget {
  const _MedicationBoxSummary({
    required this.connected,
    required this.sensors,
    required this.compartmentCount,
    required this.filledCount,
  });

  final bool connected;
  final List<int> sensors;
  final int compartmentCount;
  final int filledCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Status kompartemen',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Chip(
                  label: Text(
                    connected && filledCount == compartmentCount
                        ? 'Lengkap'
                        : 'Perlu diisi',
                  ),
                ),
              ],
            ),
            Text(
              connected
                  ? '$filledCount dari $compartmentCount kompartemen terisi'
                  : 'Hubungkan MEDBOX untuk melihat isi',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(compartmentCount, (index) {
                final filled = connected && index < sensors.length
                    ? sensors[index] == 1
                    : false;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index == compartmentCount - 1 ? 0 : 6,
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: filled
                                ? scheme.primaryContainer
                                : scheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.medication_outlined,
                              size: 18,
                              color: filled ? scheme.primary : scheme.tertiary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('${index + 1}'),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            Text(
              connected && filledCount == compartmentCount
                  ? 'Semua kompartemen sudah terisi.'
                  : 'Isi obat sebelum jadwal berikutnya.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
