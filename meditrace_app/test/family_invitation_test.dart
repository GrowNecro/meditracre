import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meditrace_app/l10n/localization.dart';
import 'package:meditrace_app/providers/app_provider.dart';
import 'package:meditrace_app/screens/more/family_screen.dart';
import 'package:meditrace_app/services/family_api.dart';
import 'package:provider/provider.dart';

void main() {
  const code = '0123456789ABCDEF01234567';
  late AppProvider app;
  late _InvitationApi api;
  late int consumed;
  setUp(() {
    app = AppProvider();
    api = _InvitationApi();
    consumed = 0;
  });
  tearDown(() {
    app.dispose();
    api.dispose();
  });

  Future<void> showInvitation(
    WidgetTester tester, {
    String invitation = code,
  }) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: FamilyScreen(
            familyApi: api,
            initialInviteCode: invitation,
            onInviteConsumed: () => consumed++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'guest invitation survives login and is consumed only after confirmation',
    (tester) async {
      api.signedIn = false;
      await showInvitation(tester);
      expect(find.text(code), findsOneWidget);
      expect(api.joinedCodes, isEmpty);
      final join = find.widgetWithText(FilledButton, 'Join now');
      expect(tester.widget<FilledButton>(join).onPressed, isNull);
      api.signedIn = true;
      api.sessions.add('user');
      await tester.pumpAndSettle();
      expect(find.text(code), findsOneWidget);
      expect(api.joinedCodes, isEmpty);
      await tester.tap(join);
      await tester.pumpAndSettle();
      expect(api.joinedCodes, [code]);
      expect(consumed, 1);
      expect(find.text(code), findsNothing);
      expect(find.text('You have joined the family group.'), findsOneWidget);
    },
  );

  testWidgets('new links update an already mounted invitation screen', (
    tester,
  ) async {
    await showInvitation(tester);
    const second = 'ABCDEF0123456789ABCDEF01';
    await showInvitation(tester, invitation: second);
    expect(find.text(second), findsOneWidget);
    expect(find.text(code), findsNothing);
    expect(api.joinedCodes, isEmpty);
  });

  testWidgets('failed acceptance keeps the code available to retry', (
    tester,
  ) async {
    api.failJoin = true;
    await showInvitation(tester);
    await tester.tap(find.text('Join now'));
    await tester.pumpAndSettle();
    expect(find.text(code), findsOneWidget);
    expect(consumed, 0);
    api.failJoin = false;
    await tester.tap(find.text('Join now'));
    await tester.pumpAndSettle();
    expect(api.joinedCodes, [code, code]);
    expect(consumed, 1);
  });

  testWidgets(
    'successful acceptance is not retried when the following group refresh fails',
    (tester) async {
      api.failRefreshAfterJoin = true;
      await showInvitation(tester);
      await tester.tap(find.text('Join now'));
      await tester.pumpAndSettle();
      expect(consumed, 1);
      expect(find.text(code), findsNothing);
      expect(find.text('Could not refresh groups'), findsOneWidget);
      api.sessions.add('user');
      await tester.pumpAndSettle();
      expect(api.joinedCodes, [code]);
      expect(find.text(code), findsNothing);
    },
  );
}

class _InvitationApi extends FamilyApi {
  bool signedIn = true;
  bool failJoin = false;
  bool failRefreshAfterJoin = false;
  final joinedCodes = <String>[];
  final sessions = StreamController<String?>.broadcast();

  @override
  bool get backendConfigured => true;
  @override
  Future<bool> get hasSession async => signedIn;
  @override
  Stream<String?> get sessionUserIds => sessions.stream;
  @override
  Future<Map<String, dynamic>> me() async => {
    'user': {'id': 'user', 'name': 'Family User'},
  };
  @override
  Future<void> refreshPushRegistration() async {}
  @override
  Future<Map<String, dynamic>> families() async {
    if (failRefreshAfterJoin && joinedCodes.isNotEmpty) {
      throw const FamilyApiException('Could not refresh groups');
    }
    return {'groups': []};
  }

  @override
  Future<Map<String, dynamic>> joinFamily(String code) async {
    joinedCodes.add(code);
    if (failJoin) throw const FamilyApiException('Invitation unavailable');
    return {'id': 123};
  }

  @override
  void dispose() => unawaited(sessions.close());
}
