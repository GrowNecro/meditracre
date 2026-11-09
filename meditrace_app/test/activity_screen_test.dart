import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meditrace_app/l10n/localization.dart';
import 'package:meditrace_app/models/dose_event.dart';
import 'package:meditrace_app/providers/app_provider.dart';
import 'package:meditrace_app/screens/history/history_screen.dart';
import 'package:meditrace_app/services/family_api.dart';
import 'package:meditrace_app/services/local_database.dart';
import 'package:provider/provider.dart';

void main() {
  late AppProvider app;
  late _InboxApi api;

  setUp(() {
    app = AppProvider(database: _MemoryStorage())
      ..history = [
        DoseEvent(
          type: 'MEDBOX_LEFT_BEHIND',
          timestamp: DateTime(2026, 11, 9, 10),
        ),
      ];
    api = _InboxApi();
  });

  tearDown(() {
    app.dispose();
    api.dispose();
  });

  Future<void> showActivity(
    WidgetTester tester, {
    String language = 'en',
  }) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: MaterialApp(
          locale: Locale(language),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: HistoryScreen(familyApi: api, onOpenProfile: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'one feed mixes family and local events in time order without tabs',
    (tester) async {
      api.alerts = [
        _alert('older', 'Older family alert', 9),
        _alert('newer', 'New family alert', 11),
      ];
      await showActivity(tester);
      expect(find.text('Activity'), findsOneWidget);
      expect(find.byType(TabBar), findsNothing);
      expect(find.text('No family notifications yet'), findsNothing);
      final latest = tester.getTopLeft(find.text('New family alert')).dy;
      final local = tester
          .getTopLeft(find.text('MEDITRACE reported left behind'))
          .dy;
      final oldest = tester.getTopLeft(find.text('Older family alert')).dy;
      expect(latest, lessThan(local));
      expect(local, lessThan(oldest));
      expect(find.text('Family · My Family'), findsNWidgets(2));
    },
  );

  testWidgets(
    'empty family inbox adds no extra empty card above local activity',
    (tester) async {
      await showActivity(tester);
      expect(find.text('MEDITRACE reported left behind'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Family notifications'), findsNothing);
      expect(find.text('No activity yet'), findsNothing);
    },
  );

  testWidgets('failed family refresh keeps local activity and supports retry', (
    tester,
  ) async {
    api.failLoad = true;
    await showActivity(tester);
    expect(find.text('Could not load family notifications'), findsOneWidget);
    expect(find.text('MEDITRACE reported left behind'), findsOneWidget);
    api.failLoad = false;
    api.alerts = [_alert('new', 'Recovered family alert', 11)];
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Recovered family alert'), findsOneWidget);
    expect(find.text('Could not load family notifications'), findsNothing);
  });

  testWidgets(
    'acknowledgement failure can be retried and success marks the alert handled',
    (tester) async {
      api.alerts = [_alert('new', 'Family warning', 11)];
      api.failAcknowledge = true;
      await showActivity(tester);
      await tester.tap(find.text('Acknowledge'));
      await tester.pumpAndSettle();
      expect(find.text('Needs attention'), findsOneWidget);
      expect(
        find.text('Could not acknowledge this alert. Please try again.'),
        findsOneWidget,
      );
      api.failAcknowledge = false;
      await tester.tap(find.text('Acknowledge'));
      await tester.pumpAndSettle();
      expect(find.text('Handled'), findsOneWidget);
      expect(find.text('Acknowledge'), findsNothing);
    },
  );

  testWidgets('clearing local history preserves family notifications', (
    tester,
  ) async {
    api.alerts = [_alert('new', 'Family warning', 11)];
    await showActivity(tester);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear local history'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('MEDITRACE reported left behind'), findsNothing);
    expect(find.text('Family warning'), findsOneWidget);
    expect(api.alerts, hasLength(1));
  });

  testWidgets('deleting a cloud notification preserves local activity', (
    tester,
  ) async {
    api.alerts = [_alert('cloud-one', 'Family warning', 11)];
    await showActivity(tester);
    await tester.tap(find.byTooltip('Delete family notification'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Family warning'), findsNothing);
    expect(find.text('MEDITRACE reported left behind'), findsOneWidget);
    expect(api.deletedAlertIds, ['cloud-one']);
  });

  testWidgets('clearing cloud notifications removes inbox alerts only', (
    tester,
  ) async {
    api.alerts = [
      _alert('cloud-one', 'Family warning one', 11),
      _alert('cloud-two', 'Family warning two', 12),
    ];
    await showActivity(tester);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear family notifications'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Family warning one'), findsNothing);
    expect(find.text('Family warning two'), findsNothing);
    expect(find.text('MEDITRACE reported left behind'), findsOneWidget);
    expect(api.clearCalls, 1);
    expect(api.alerts, isEmpty);
  });

  testWidgets('partial cloud clear refreshes the remaining inbox entries', (
    tester,
  ) async {
    api.alerts = [
      _alert('cloud-one', 'Family warning one', 11),
      _alert('cloud-two', 'Family warning two', 12),
    ];
    api.failClearAfterRemovingOne = true;
    await showActivity(tester);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear family notifications'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not delete the notification. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Family warning one'), findsNothing);
    expect(find.text('Family warning two'), findsOneWidget);
  });

  testWidgets('known cloud alert titles follow the selected language', (
    tester,
  ) async {
    api.alerts = [_alert('cloud-one', 'Medication status: taken', 11)];
    await showActivity(tester, language: 'id');
    expect(find.text('Status obat: sudah diminum'), findsOneWidget);
    expect(find.text('Medication status: taken'), findsNothing);
  });

  testWidgets('localized compartment alert keeps its compartment number', (
    tester,
  ) async {
    api.alerts = [_alert('cloud-empty', 'Compartment 3 is empty', 11)];
    await showActivity(tester, language: 'id');
    expect(find.text('Obat di kompartemen 3 kosong'), findsOneWidget);
  });

  testWidgets(
    'foreground messages refresh the feed and logout clears family data',
    (tester) async {
      await showActivity(tester);
      api.alerts = [_alert('new', 'Incoming family alert', 11)];
      api.messages.add(null);
      await tester.pumpAndSettle();
      expect(find.text('Incoming family alert'), findsOneWidget);
      api.signedIn = false;
      api.sessions.add(null);
      await tester.pumpAndSettle();
      expect(find.text('Incoming family alert'), findsNothing);
      expect(find.text('MEDITRACE reported left behind'), findsOneWidget);
    },
  );

  testWidgets(
    'Indonesian empty activity works with large text on a small screen',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      app.history = [];
      api.signedIn = false;
      await showActivity(tester, language: 'id');
      expect(find.text('Aktivitas'), findsOneWidget);
      expect(find.text('Belum ada aktivitas'), findsOneWidget);
      await tester.ensureVisible(find.text('Buka profil'));
      expect(tester.takeException(), isNull);
    },
  );
}

Map<String, Object?> _alert(String id, String title, int hour) => {
  'id': id,
  'title': title,
  'group_name': 'My Family',
  'sender_email': 'family@example.com',
  'occurred_at': DateTime(2026, 11, 9, hour).toIso8601String(),
  'acknowledged_at': null,
};

class _InboxApi extends FamilyApi {
  bool signedIn = true;
  bool failLoad = false;
  bool failAcknowledge = false;
  bool failClearAfterRemovingOne = false;
  int clearCalls = 0;
  final deletedAlertIds = <String>[];
  List<Map<String, Object?>> alerts = [];
  final sessions = StreamController<String?>.broadcast();
  final messages = StreamController<void>.broadcast();

  @override
  Future<bool> get hasSession async => signedIn;
  @override
  Stream<String?> get sessionUserIds => sessions.stream;
  @override
  Stream<void> get foregroundNotifications => messages.stream;
  @override
  Future<Map<String, dynamic>> inbox() async {
    if (failLoad) throw const FamilyApiException('Offline');
    return {
      'data': [for (final item in alerts) Map.of(item)],
    };
  }

  @override
  Future<Map<String, dynamic>> acknowledge(String alertId) async {
    if (failAcknowledge) throw const FamilyApiException('Offline');
    alerts = [
      for (final item in alerts)
        if (item['id'] == alertId)
          {...item, 'acknowledged_at': '2026-11-09T12:00:00'}
        else
          item,
    ];
    return {'ok': true};
  }

  @override
  Future<Map<String, dynamic>> deleteAlert(String alertId) async {
    deletedAlertIds.add(alertId);
    alerts = [
      for (final item in alerts)
        if (item['id'] != alertId) item,
    ];
    return {'ok': true};
  }

  @override
  Future<Map<String, dynamic>> clearAlerts() async {
    clearCalls++;
    if (failClearAfterRemovingOne) {
      alerts = alerts.skip(1).toList();
      throw const FamilyApiException('Partial failure');
    }
    alerts.clear();
    return {'ok': true, 'deletedCount': 2};
  }

  @override
  void dispose() {
    unawaited(sessions.close());
    unawaited(messages.close());
  }
}

class _MemoryStorage extends LocalDatabase {
  @override
  Future<void> clearEvents() async {}
}
