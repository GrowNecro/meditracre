import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meditrace_dummy/main.dart';
import 'package:meditrace_dummy/simulator_state.dart';

void main() {
  test('payload lima sensor mengikuti format MEDITRACE', () {
    final state = SimulatorState()
        .withSensor(0, false)
        .withDoor(1, false)
        .withBattery(55);
    expect(state.toNative()['count'], 5);
    expect(state.toNative()['sensors'], [0, 1, 1, 1, 1]);
    expect(state.toNative()['doors'], [1, 0, 1, 1, 1]);
    expect(state.toNative()['battery'], 55);
    expect(() => state.withCount(2), throwsArgumentError);
    expect(state.withSimulatedRssi(-90).toNative()['simulated_rssi'], -90);
    expect(state.withSimulatedRssi(-60).toNative()['simulated_rssi'], -60);
    expect(state.withBattery(82).estimatedRuntimeLabel, '8 jam 12 menit');
    expect(state.withBattery(0).estimatedRuntimeLabel, 'Belum tersedia');
  });

  testWidgets('kontrol sensor dapat diubah tanpa BLE aktif', (tester) async {
    await tester.pumpWidget(const MeditraceDummyApp());
    expect(find.text('MEDITRACE Dummy'), findsOneWidget);
    expect(find.text('Mulai siarkan MEDITRACE Dummy'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('sensor_1')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Obat ada'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('sensor_1')));
    await tester.pump();
    expect(find.text('Obat kosong'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('menyediakan pemicu alarm jadwal untuk setiap ruang', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MeditraceDummyApp());
    expect(
      find.text('Simulasikan alarm jadwal ruang ini', skipOffstage: false),
      findsNWidgets(5),
    );
  });

  testWidgets('menyediakan panel uji server dan kontrol cepat', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MeditraceDummyApp());
    expect(
      find.text('Pemeriksaan sistem', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.text('Tes notifikasi email', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.text('Kontrol cepat alat dummy', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('Isi semua obat', skipOffstage: false), findsOneWidget);
    expect(
      find.text('Baterai rendah 15%', skipOffstage: false),
      findsOneWidget,
    );
  });
}
