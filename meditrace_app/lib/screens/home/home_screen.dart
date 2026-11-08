import '../../l10n/localization.dart';

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
  const HomeScreen({
    super.key,
    this.selectedIndex = 0,
    this.inviteCode,
    this.onInviteConsumed,
  });

  final int selectedIndex;
  final String? inviteCode;
  final VoidCallback? onInviteConsumed;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.selectedIndex;
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      setState(() => _index = widget.selectedIndex);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: _index == 0
        ? AppBar(
            titleSpacing: 12,
            title: Row(
              spacing: 6,
              children: [
                Image.asset(
                  'assets/images/meditrace_logo_transparent.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                  semanticLabel: context.l10n.meditraceLogo,
                ),
                const SizedBox(width: 6),
                const Flexible(
                  child: Text('MEDITRACE', overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
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
          )
        : null,
    body: Stack(
      fit: StackFit.expand,
      children: [
        _buildTabContent(0, const _Dashboard()),
        _buildTabContent(1, const MedicationScreen()),
        _buildTabContent(2, const HistoryScreen()),
        _buildTabContent(3, const DeviceScreen(embedded: true)),
        _buildTabContent(
          4,
          MoreScreen(
            inviteCode: widget.inviteCode,
            onInviteConsumed: widget.onInviteConsumed,
          ),
        ),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _index,
      onDestinationSelected: (value) => setState(() => _index = value),
      destinations: [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: context.l10n.home,
        ),
        NavigationDestination(
          icon: Icon(Icons.medication_outlined),
          selectedIcon: Icon(Icons.medication),
          label: context.l10n.schedule,
        ),
        NavigationDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history),
          label: context.l10n.history,
        ),
        NavigationDestination(
          icon: Icon(Icons.developer_board_outlined),
          selectedIcon: Icon(Icons.developer_board),
          label: context.l10n.device,
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: context.l10n.profile,
        ),
      ],
    ),
  );

  Widget _buildTabContent(int index, Widget child) {
    final selected = _index == index;
    return Offstage(
      offstage: !selected,
      child: IgnorePointer(
        ignoring: !selected,
        child: AnimatedOpacity(
          opacity: selected ? 1 : 0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          child: AnimatedSlide(
            offset: selected
                ? Offset.zero
                : Offset(index > _index ? 0.04 : -0.04, 0),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            child: child,
          ),
        ),
      ),
    );
  }
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
      onRefresh: connected
          ? ble.refresh
          : () async {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    context.l10n.connectMeditraceToRefreshItsStatus,
                  ),
                ),
              );
            },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Text(
            context.l10n.welcome,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.keepTrackOfYourMedicationScheduleToday,
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
                          connected
                              ? context.l10n.meditraceActive
                              : context.l10n.meditraceNotConnected,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (connected)
                        IconButton(
                          tooltip: context.l10n.deviceDetails,
                          onPressed: () => _showDeviceInfo(context, ble),
                          icon: const Icon(Icons.info_outline),
                        )
                      else
                        IconButton(
                          tooltip: context.l10n.connectDevice,
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
                      Icon(batteryIcon, color: batteryColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          ble.batteryEstimated
                              ? context.l10n.estimatedBattery
                              : context.l10n.battery,
                        ),
                      ),
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
                  if (ble.batteryEstimated) ...[
                    const SizedBox(height: 6),
                    Text(
                      context
                          .l10n
                          .estimatedFromUsageTimeRatherThanVoltageMeasurement,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (!ble.batteryEstimated && ble.batteryVoltage != null) ...[
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
                    context.l10n.weakSignal,
                    style: TextStyle(
                      color: scheme.onErrorContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    context.l10n.keepMeditraceNearby,
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
                    context.l10n.nextSchedule,
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
                        ? context.l10n.noMedicationSchedulesYet
                        : context.l10n.waitForTheNextMedicationSchedule,
                    style: TextStyle(color: scheme.onSecondaryContainer),
                  ),
                  if (nextCompartmentEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        context
                            .l10n
                            .medicationIsNotAvailableInThisCompartmentYet,
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
                      child: Text(context.l10n.viewMedicationSchedule),
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
                        label: Text(context.l10n.taken),
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
                  context.l10n.medicationBox,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const DeviceScreen()),
                ),
                child: Text(context.l10n.viewAll),
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
          title: Text(context.l10n.meditraceConnected),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ble.batteryEstimated
                    ? context.l10n.estimatedBattery
                    : context.l10n.battery,
              ),
              Text('${ble.battery ?? ble.deviceInfo?.battery ?? '--'}%'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.close),
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
            Wrap(
              spacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  context.l10n.compartmentStatus,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Chip(
                  label: Text(
                    connected && filledCount == compartmentCount
                        ? context.l10n.complete
                        : context.l10n.needsRefill,
                  ),
                ),
              ],
            ),
            Text(
              connected
                  ? context.l10n.ofCompartmentsFilled(
                      (filledCount).toString(),
                      (compartmentCount).toString(),
                    )
                  : context.l10n.connectMeditraceToSeeContents,
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
                  ? context.l10n.allCompartmentsAreFilled
                  : context.l10n.refillMedicationBeforeTheNextSchedule,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
