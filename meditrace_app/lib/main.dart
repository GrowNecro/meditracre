import 'l10n/localization.dart';

import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'providers/ble_provider.dart';
import 'screens/home/home_screen.dart';
import 'services/ble_service.dart';
import 'services/family_api.dart';
import 'services/invitation_link.dart';
import 'services/flutter_blue_ble_service.dart';
import 'services/local_database.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _firebaseInitialization = _initializeFirebase();
  runApp(const MeditraceApp(showStartupSplash: true));
}

Future<void>? _firebaseInitialization;

Future<void> _initializeFirebase() async {
  if (Firebase.apps.isNotEmpty) return;
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // BLE, jadwal lokal, dan riwayat tetap dapat dipakai tanpa Firebase.
  }
}

class MeditraceApp extends StatefulWidget {
  const MeditraceApp({
    super.key,
    this.bleService,
    this.database,
    this.familyApi,
    this.showStartupSplash = false,
  });

  final BleService? bleService;
  final LocalDatabase? database;
  final FamilyApi? familyApi;
  final bool showStartupSplash;

  @override
  State<MeditraceApp> createState() => _MeditraceAppState();
}

class _MeditraceAppState extends State<MeditraceApp>
    with WidgetsBindingObserver {
  late final AppProvider _app;
  late final BleProvider _ble;
  late final FamilyApi _familyApi;
  final _appLinks = AppLinks();
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<Uri>? _linkSubscription;
  String? _inviteCode;
  int _inviteRequestId = 0;
  int _homeTab = 0;
  bool _isReady = false;
  bool _entryPromptShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _app = AppProvider(database: widget.database);
    _familyApi =
        widget.familyApi ?? FamilyApi(languageCode: () => _app.languageCode);
    _ble = BleProvider(widget.bleService ?? FlutterBlueBleService(), _app);
    _linkSubscription = _appLinks.uriLinkStream.listen(_handleLink);
    unawaited(_readInitialLink());
    unawaited(_start());
  }

  Future<void> _readInitialLink() async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) _handleLink(uri);
    } catch (_) {
      // Link handling is optional; the normal app flow remains available.
    }
  }

  void _handleLink(Uri uri) {
    final code = InvitationLink.codeFromUri(uri);
    if (code == null) return;
    if (mounted) {
      setState(() {
        _inviteCode = code;
        _inviteRequestId++;
        _homeTab = 4;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (_ble.connectionState == MeditraceConnectionState.connected) {
      unawaited(_ble.refresh());
    } else {
      unawaited(_ble.reconnectSavedDevice());
    }
  }

  Future<void> _start() async {
    final firebaseInitialization = _firebaseInitialization;
    if (firebaseInitialization != null) await firebaseInitialization;
    await _app.initialize();
    if (mounted) {
      setState(() => _isReady = true);
    }
    if (widget.showStartupSplash) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_showEntryChoice());
      });
    }
    unawaited(_ble.reconnectSavedDevice());
  }

  Future<void> _showEntryChoice() async {
    final api = _familyApi;
    if (_entryPromptShown || !mounted || await api.hasSession) return;
    if (!mounted) return;
    final navigatorContext = _navigatorKey.currentContext;
    if (navigatorContext == null || !navigatorContext.mounted) return;
    _entryPromptShown = true;
    await showDialog<void>(
      context: navigatorContext,
      barrierDismissible: false,
      builder: (dialogContext) => _EntryChoiceDialog(
        onLogin: () async {
          try {
            await api.loginWithGoogle();
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          } catch (error) {
            if (dialogContext.mounted) {
              ScaffoldMessenger.of(dialogContext)
                  .showSnackBar(SnackBar(content: Text(error.toString())));
            }
          }
        },
        onGuest: () => Navigator.pop(dialogContext),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_linkSubscription?.cancel());
    _ble.dispose();
    _app.dispose();
    if (widget.familyApi == null) _familyApi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider<AppProvider>.value(value: _app),
      ChangeNotifierProvider<BleProvider>.value(value: _ble),
    ],
    child: ListenableBuilder(
      listenable: _app,
      builder: (context, _) => MaterialApp(
        navigatorKey: _navigatorKey,
        locale: Locale(_app.languageCode),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        title: 'MEDITRACE',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF16B8C0),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF2FFFE),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFE7FFFD),
            foregroundColor: Color(0xFF075E63),
            surfaceTintColor: Colors.transparent,
          ),
          navigationBarTheme: const NavigationBarThemeData(
            backgroundColor: Color(0xFFE7FFFD),
            indicatorColor: Color(0xFF9DEBE8),
            surfaceTintColor: Colors.transparent,
          ),
          cardTheme: const CardThemeData(surfaceTintColor: Color(0xFFB9F4F0)),
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: _FadeSlidePageTransitionsBuilder(),
              TargetPlatform.iOS: _FadeSlidePageTransitionsBuilder(),
              TargetPlatform.windows: _FadeSlidePageTransitionsBuilder(),
              TargetPlatform.macOS: _FadeSlidePageTransitionsBuilder(),
              TargetPlatform.linux: _FadeSlidePageTransitionsBuilder(),
            },
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF16B8C0),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF071F20),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0B2D2E),
            surfaceTintColor: Colors.transparent,
          ),
          navigationBarTheme: const NavigationBarThemeData(
            backgroundColor: Color(0xFF0B2D2E),
            surfaceTintColor: Colors.transparent,
          ),
          cardTheme: const CardThemeData(surfaceTintColor: Color(0xFF164849)),
        ),
        themeMode: ThemeMode.system,
        home: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: !widget.showStartupSplash || _isReady
              ? HomeScreen(
                  key: const ValueKey('home'),
                  selectedIndex: _homeTab,
                  familyApi: _familyApi,
                  inviteCode: _inviteCode,
                  inviteRequestId: _inviteRequestId,
                  onInviteConsumed: () => setState(() => _inviteCode = null),
                )
              : const _SplashScreen(key: ValueKey('splash')),
        ),
      ),
    ),
  );
}

class _FadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const _FadeSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final slide = Tween<Offset>(
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation);
    final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: const SizedBox.expand(
      child: Image(
        image: AssetImage('assets/images/splash_screen.jpg'),
        fit: BoxFit.cover,
      ),
    ),
  );
}

class _EntryChoiceDialog extends StatefulWidget {
  const _EntryChoiceDialog({required this.onLogin, required this.onGuest});

  final Future<void> Function() onLogin;
  final VoidCallback onGuest;

  @override
  State<_EntryChoiceDialog> createState() => _EntryChoiceDialogState();
}

class _EntryChoiceDialogState extends State<_EntryChoiceDialog> {
  bool _loading = false;

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      await widget.onLogin();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l10n.welcomeToMeditrace),
    content: Text(context.l10n.signInToUseFamilyFeaturesAndAccount),
    actions: [
      TextButton(
        onPressed: _loading ? null : widget.onGuest,
        child: Text(context.l10n.continueAsGuest),
      ),
      FilledButton.icon(
        onPressed: _loading ? null : _login,
        icon: _loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.login),
        label: Text(context.l10n.signIn),
      ),
    ],
  );
}
