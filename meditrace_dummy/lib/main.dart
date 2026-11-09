import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import 'simulator_state.dart';

enum _SignalPreset { actual, strong, weak }

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase is optional for BLE simulation and the network test panel.
    // Missing or invalid configuration must not prevent the dummy from opening.
  }
  runApp(const MeditraceDummyApp());
}

class MeditraceDummyApp extends StatelessWidget {
  const MeditraceDummyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'MEDITRACE Dummy',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00695C)),
      useMaterial3: true,
    ),
    home: const SimulatorScreen(),
  );
}

class SimulatorScreen extends StatefulWidget {
  const SimulatorScreen({super.key});

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> {
  static const _ble = MethodChannel('meditrace_dummy/ble');
  static const _workerUrl = 'https://meditrace.grownecro.tech';
  static const _googleWebClientId =
      '676550038130-7d0ssg76olenfpa8rlnkehpkh56r9aue.apps.googleusercontent.com';
  SimulatorState simulation = SimulatorState();
  bool advertising = false;
  bool connected = false;
  bool busy = false;
  String message = 'Belum menyiarkan BLE.';
  final List<String> events = [];
  final _emailController = TextEditingController();
  final _deviceNameController = TextEditingController(text: 'MEDITRACE-DUMMY');
  bool _notificationBusy = false;
  String? _notificationMessage;
  String? _workerMessage;
  String? _pushMessage;
  Future<void>? _googleInitialization;

  @override
  void initState() {
    super.initState();
    _ble.setMethodCallHandler((call) async {
      if (!mounted) return;
      setState(() {
        switch (call.method) {
          case 'advertising':
            advertising = call.arguments == true;
            message = advertising
                ? 'MEDITRACE Dummy dapat dicari sebagai MEDITRACE-DUMMY.'
                : 'Penyiaran berhenti.';
          case 'connection':
            connected = call.arguments == true;
          case 'log':
            events.insert(0, call.arguments.toString());
            if (events.length > 12) events.removeLast();
        }
      });
    });
  }

  @override
  void dispose() {
    _ble.setMethodCallHandler(null);
    _emailController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  bool get _firebaseReady => Firebase.apps.isNotEmpty;

  Future<String> _firebaseIdToken() async {
    if (!_firebaseReady) {
      throw StateError('Firebase belum siap. Pasang ulang APK dummy.');
    }
    final signIn = GoogleSignIn.instance;
    await (_googleInitialization ??= signIn.initialize(
      serverClientId: _googleWebClientId,
    ));
    if (FirebaseAuth.instance.currentUser == null) {
      final account = await signIn.authenticate();
      final googleIdToken = account.authentication.idToken;
      if (googleIdToken == null || googleIdToken.isEmpty) {
        throw StateError('Google tidak mengirim ID token.');
      }
      await FirebaseAuth.instance.signInWithCredential(
        GoogleAuthProvider.credential(idToken: googleIdToken),
      );
    }
    final idToken = await FirebaseAuth.instance.currentUser!.getIdToken(true);
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Token Firebase tidak tersedia.');
    }
    return idToken;
  }

  Future<Map<String, dynamic>> _postWorker(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final idToken = await _firebaseIdToken();
    final response = await http.post(
      Uri.parse('$_workerUrl$endpoint'),
      headers: {
        'authorization': 'Bearer $idToken',
        'content-type': 'application/json',
      },
      body: jsonEncode(data),
    );
    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        body['error']?.toString() ?? 'HTTP ${response.statusCode}',
      );
    }
    return body;
  }

  Future<void> _sendTestEmail() async {
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      setState(
        () => _notificationMessage = 'Masukkan alamat email tujuan yang valid.',
      );
      return;
    }
    setState(() {
      _notificationBusy = true;
      _notificationMessage = 'Menyiapkan login dan mengirim email…';
    });
    try {
      await _postWorker('/v1/testEmail', {'email': email});
      if (mounted) {
        setState(() => _notificationMessage = 'Email tes terkirim ke $email.');
      }
    } on GoogleSignInException catch (error) {
      if (mounted) {
        setState(
          () => _notificationMessage =
              'Login Google gagal: ${error.description ?? error.code.name}',
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(
          () => _notificationMessage =
              'Login Firebase gagal: ${error.message ?? error.code}',
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _notificationMessage = 'Tes email gagal: $error');
      }
    } finally {
      if (mounted) setState(() => _notificationBusy = false);
    }
  }

  Future<void> _checkWorker() async {
    setState(() => _workerMessage = 'Memeriksa Worker…');
    try {
      final response = await http.get(Uri.parse('$_workerUrl/healthz'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final ready = response.statusCode == 200 && body['ok'] == true;
      if (mounted) {
        setState(
          () => _workerMessage = ready
              ? 'Worker siap: Firebase ${body['credentialsConfigured'] == true ? 'OK' : 'belum siap'}, email ${body['emailConfigured'] == true ? 'OK' : 'belum siap'}.'
              : 'Worker tidak siap: HTTP ${response.statusCode}.',
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _workerMessage = 'Worker gagal diakses: $error');
      }
    }
  }

  Future<void> _sendTestPush() async {
    setState(() {
      _notificationBusy = true;
      _pushMessage = 'Meminta izin notifikasi dan token FCM…';
    });
    try {
      final messaging = FirebaseMessaging.instance;
      final permission = await messaging.requestPermission();
      if (permission.authorizationStatus == AuthorizationStatus.denied) {
        throw StateError('Izin notifikasi ditolak di HP dummy.');
      }
      final registered = messaging.onRegistered.first.timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw StateError('Pendaftaran FCM melebihi 15 detik.'),
      );
      await messaging.register();
      final token = await registered;
      if (token.length < 20) {
        throw StateError(
          'Token FCM belum tersedia. Periksa Google Play services.',
        );
      }
      await _postWorker('/v1/testPush', {'token': token});
      if (mounted) {
        setState(
          () => _pushMessage = 'Permintaan push berhasil dikirim. Notifikasi akan muncul di HP dummy.',
        );
      }
    } catch (error) {
      if (mounted) setState(() => _pushMessage = 'Tes push gagal: $error');
    } finally {
      if (mounted) setState(() => _notificationBusy = false);
    }
  }

  Future<void> _quickControl({bool? sensor, bool? door, int? battery}) async {
    var next = simulation;
    for (var index = 0; index < next.count; index++) {
      if (sensor != null) next = next.withSensor(index, sensor);
      if (door != null) next = next.withDoor(index, door);
    }
    if (battery != null) next = next.withBattery(battery);
    setState(() => simulation = next);
    await _publish();
    if (advertising) {
      for (var index = 0; index < next.count; index++) {
        if (sensor != null) await _event('DOSE_STATE_CHANGED', index, sensor);
        if (door != null) await _event('DOOR_STATE_CHANGED', index, door);
      }
    }
  }

  Future<void> _start() async {
    setState(() {
      busy = true;
      message = 'Menyiapkan GATT server…';
    });
    try {
      await _ble.invokeMethod<void>('start', {
        ...simulation.toNative(),
        'device_name': _deviceNameController.text.trim(),
      });
      if (mounted) setState(() => advertising = true);
    } on PlatformException catch (error) {
      if (mounted) setState(() => message = error.message ?? error.code);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _stop() async {
    setState(() => busy = true);
    try {
      await _ble.invokeMethod<void>('stop');
      if (mounted) {
        setState(() {
          advertising = false;
          connected = false;
        });
      }
    } on PlatformException catch (error) {
      if (mounted) setState(() => message = error.message ?? error.code);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _publish() async {
    if (!advertising) return;
    try {
      await _ble.invokeMethod<void>('update', simulation.toNative());
    } on PlatformException catch (error) {
      if (mounted) setState(() => message = error.message ?? error.code);
    }
  }

  Future<void> _event(String name, int index, bool value) async {
    if (!advertising) return;
    try {
      await _ble.invokeMethod<void>('event', {
        'event': name,
        'sensor_id': index + 1,
        'state': value,
      });
    } on PlatformException catch (error) {
      if (mounted) setState(() => message = error.message ?? error.code);
    }
  }

  Future<void> _triggerDoseAlarm(int index) async {
    if (!advertising) return;
    try {
      final present = simulation.sensors[index];
      await _ble.invokeMethod<void>('event', {
        'event': 'DOSE_ALARM',
        'sensor_id': index + 1,
        'schedule_id': 9000 + index + 1,
        'state': present,
        'status': present ? 'JADWAL_OBAT' : 'RUANG_KOSONG',
      });
      if (mounted) {
        setState(
          () => message = present
              ? 'Alarm jadwal ruang ${index + 1} dikirim.'
              : 'Alarm jadwal ruang ${index + 1}: ruang kosong.',
        );
      }
    } on PlatformException catch (error) {
      if (mounted) setState(() => message = error.message ?? error.code);
    }
  }

  Future<void> _changeSensor(int index, bool present) async {
    final wasPresent = simulation.sensors[index];
    setState(() => simulation = simulation.withSensor(index, present));
    await _publish();
    await _event(
      wasPresent && !present ? 'DOSE_REMOVED' : 'DOSE_STATE_CHANGED',
      index,
      present,
    );
  }

  Future<void> _changeDoor(int index, bool closed) async {
    setState(() => simulation = simulation.withDoor(index, closed));
    await _publish();
    await _event('DOOR_STATE_CHANGED', index, closed);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('MEDITRACE Dummy')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Simulator sensor BLE',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Jalankan di HP kedua. Di HP utama, cari nama BLE yang Anda atur di bawah. Nama Bluetooth HP ini berubah sementara selama penyiaran dan dikembalikan saat dihentikan.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _deviceNameController,
                  enabled: !advertising && !busy,
                  maxLength: 20,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[A-Za-z0-9 _-]'),
                    ),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Nama perangkat BLE',
                    hintText: 'MEDITRACE-DUMMY',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Text(message),
                Text(
                  'Koneksi HP utama: ${connected ? 'tersambung' : 'belum tersambung'}',
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: busy
                      ? null
                      : advertising
                      ? _stop
                      : _start,
                  icon: Icon(
                    advertising ? Icons.stop_circle_outlined : Icons.bluetooth,
                  ),
                  label: Text(
                    advertising
                        ? 'Hentikan MEDITRACE Dummy'
                        : 'Mulai siarkan MEDITRACE Dummy',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pemeriksaan sistem',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Gunakan urutan ini sebelum pengujian aplikasi utama: cek server, tes email/push, kemudian kontrol BLE di bawah.',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _checkWorker,
                  icon: const Icon(Icons.cloud_done_outlined),
                  label: const Text('Cek Worker & konfigurasi notifikasi'),
                ),
                if (_workerMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(_workerMessage!),
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _notificationBusy ? null : _sendTestPush,
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: const Text('Login Google & tes push di HP ini'),
                ),
                if (_pushMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(_pushMessage!),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tes notifikasi email',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Kartu ini login dengan Google lalu mengirim POST terautentikasi ke Worker MEDITRACE. Gunakan untuk menguji Resend tanpa aplikasi utama.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  enabled: !_notificationBusy,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Email tujuan',
                    hintText: 'nama@email.com',
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _notificationBusy ? null : _sendTestEmail,
                  icon: _notificationBusy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.mark_email_read_outlined),
                  label: Text(
                    _notificationBusy
                        ? 'Mengirim…'
                        : 'Login Google & kirim email tes',
                  ),
                ),
                if (_notificationMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(_notificationMessage!),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kontrol cepat alat dummy',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Perubahan dikirim ke aplikasi utama bila BLE sedang disiarkan. Tombol ini mengendalikan semua ruang sekaligus.',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () => _quickControl(sensor: true),
                      child: const Text('Isi semua obat'),
                    ),
                    OutlinedButton(
                      onPressed: () => _quickControl(sensor: false),
                      child: const Text('Kosongkan semua'),
                    ),
                    OutlinedButton(
                      onPressed: () => _quickControl(door: true),
                      child: const Text('Tutup semua pintu'),
                    ),
                    OutlinedButton(
                      onPressed: () => _quickControl(door: false),
                      child: const Text('Buka semua pintu'),
                    ),
                    OutlinedButton(
                      onPressed: () => _quickControl(battery: 15),
                      child: const Text('Baterai rendah 15%'),
                    ),
                    OutlinedButton(
                      onPressed: () => _quickControl(battery: 82),
                      child: const Text('Baterai normal 82%'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'ESP32-C3 · 5 kompartemen',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        Text(
          'Baterai simulasi: ${simulation.battery}%',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          'Estimasi durasi: ${simulation.estimatedRuntimeLabel}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const Text(
          'Perkiraan memakai baterai 1500 mAh dan arus rata-rata 150 mA. '
          'Durasi nyata bergantung pemancar IR, buzzer, koneksi BLE, dan beban lain.',
        ),
        Slider(
          value: simulation.battery.toDouble(),
          min: 0,
          max: 100,
          divisions: 20,
          label: '${simulation.battery}%',
          onChanged: (value) => setState(
            () => simulation = simulation.withBattery(value.round()),
          ),
          onChangeEnd: (_) => unawaited(_publish()),
        ),
        const SizedBox(height: 12),
        Text('Simulasi jarak', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        const Text(
          'Pilih Lemah untuk menguji peringatan dini di aplikasi utama. '
          'Nilai ini hanya dibaca jika perangkat bernama MEDITRACE-DUMMY.',
        ),
        const SizedBox(height: 8),
        SegmentedButton<_SignalPreset>(
          segments: const [
            ButtonSegment(
              value: _SignalPreset.actual,
              label: Text('RSSI asli'),
            ),
            ButtonSegment(value: _SignalPreset.strong, label: Text('Dekat')),
            ButtonSegment(value: _SignalPreset.weak, label: Text('Jauh')),
          ],
          selected: {
            switch (simulation.simulatedRssi) {
              -60 => _SignalPreset.strong,
              -90 => _SignalPreset.weak,
              _ => _SignalPreset.actual,
            },
          },
          onSelectionChanged: (values) {
            final strength = switch (values.first) {
              _SignalPreset.actual => null,
              _SignalPreset.strong => -60,
              _SignalPreset.weak => -90,
            };
            setState(() => simulation = simulation.withSimulatedRssi(strength));
            unawaited(_publish());
          },
        ),
        const SizedBox(height: 8),
        Text(
          simulation.simulatedRssi == -90
              ? 'Jauh: −90 dBm. Peringatan muncul setelah sekitar 45 detik.'
              : simulation.simulatedRssi == -60
              ? 'Dekat: −60 dBm. Status sinyal lemah akan pulih.'
              : 'Menggunakan RSSI Bluetooth asli dari kedua HP.',
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: busy || !advertising ? null : _stop,
          icon: const Icon(Icons.link_off),
          label: const Text('Simulasikan tertinggal (putus BLE)'),
        ),
        const Text(
          'Setelah putus, aplikasi utama memberi peringatan sesuai jeda di menu Lainnya. '
          'Tekan Mulai siarkan MEDITRACE Dummy untuk menyambungkan kembali.',
        ),
        const Divider(),
        Text('Kompartemen', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        for (var index = 0; index < simulation.count; index++)
          Card(
            key: ValueKey('compartment_${index + 1}'),
            margin: const EdgeInsets.only(bottom: 8),
            child: Column(
              children: [
                ListTile(
                  title: Text('Ruang ${index + 1}'),
                  subtitle: const Text('IR: isi obat · Reed: posisi pintu'),
                ),
                SwitchListTile(
                  key: ValueKey('sensor_${index + 1}'),
                  title: Text(
                    simulation.sensors[index] ? 'Obat ada' : 'Obat kosong',
                  ),
                  subtitle: const Text('Sensor IR'),
                  value: simulation.sensors[index],
                  onChanged: (value) => _changeSensor(index, value),
                ),
                SwitchListTile(
                  key: ValueKey('door_${index + 1}'),
                  title: Text(
                    simulation.doors[index]
                        ? 'Pintu tertutup'
                        : 'Pintu terbuka',
                  ),
                  subtitle: const Text('Reed switch'),
                  value: simulation.doors[index],
                  onChanged: (value) => _changeDoor(index, value),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: OutlinedButton.icon(
                    onPressed: advertising
                        ? () => _triggerDoseAlarm(index)
                        : null,
                    icon: const Icon(Icons.alarm),
                    label: const Text('Simulasikan alarm jadwal ruang ini'),
                  ),
                ),
              ],
            ),
          ),
        if (events.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Aktivitas BLE', style: Theme.of(context).textTheme.titleMedium),
          for (final event in events) Text('• $event'),
        ],
        const SizedBox(height: 24),
      ],
    ),
  );
}
