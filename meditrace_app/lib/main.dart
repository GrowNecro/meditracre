import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'providers/ble_provider.dart';
import 'screens/home/home_screen.dart';
import 'services/ble_service.dart';
import 'services/flutter_blue_ble_service.dart';
import 'services/local_database.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase bersifat pelengkap untuk fitur keluarga. Jangan menahan runApp()
  // karena kegagalan konfigurasi Firebase tidak boleh membuat aplikasi berhenti
  // di splash screen Flutter.
  unawaited(_initializeFirebase());
  runApp(const MeditraceApp());
}

Future<void> _initializeFirebase() async {
  try {
    if (Firebase.apps.isEmpty) await Firebase.initializeApp();
  } catch (_) {
    // BLE, jadwal lokal, dan riwayat tetap dapat dipakai tanpa Firebase.
  }
}

class MeditraceApp extends StatefulWidget {
  const MeditraceApp({super.key, this.bleService, this.database});

  final BleService? bleService;
  final LocalDatabase? database;

  @override
  State<MeditraceApp> createState() => _MeditraceAppState();
}

class _MeditraceAppState extends State<MeditraceApp>
    with WidgetsBindingObserver {
  late final AppProvider _app;
  late final BleProvider _ble;
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  String? _inviteCode;
  int _homeTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _app = AppProvider(database: widget.database);
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
    final segments = uri.pathSegments;
    if (uri.host != 'meditrace.grownecro.tech' ||
        segments.length != 2 ||
        segments.first != 'invite' ||
        !RegExp(r'^[0-9A-Fa-f]{24}$').hasMatch(segments.last)) {
      return;
    }
    if (mounted) {
      setState(() {
        _inviteCode = segments.last.toUpperCase();
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
    await _app.initialize();
    await _ble.reconnectSavedDevice();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_linkSubscription?.cancel());
    _ble.dispose();
    _app.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider<AppProvider>.value(value: _app),
      ChangeNotifierProvider<BleProvider>.value(value: _ble),
    ],
    child: MaterialApp(
      title: 'MEDITRACE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF397A80),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: HomeScreen(
        selectedIndex: _homeTab,
        inviteCode: _inviteCode,
        onInviteConsumed: () => setState(() => _inviteCode = null),
      ),
    ),
  );
}
