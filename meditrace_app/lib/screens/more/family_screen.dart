import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../services/family_api.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  final _api = FamilyApi();
  bool _busy = true;
  bool _signedIn = false;
  String? _error;
  String _name = '';
  String? _userId;
  List<dynamic> _families = [];
  List<dynamic> _alerts = [];
  int? _activeGroupId;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final relay = context.read<AppProvider>().familyAlerts;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!await _api.hasSession) {
        if (mounted) setState(() => _signedIn = false);
        return;
      }
      if (mounted) setState(() => _signedIn = true);
      final me = await _api.me();
      if (!_api.backendConfigured) {
        if (mounted) {
          setState(() {
            _name = (me['user'] as Map)['name'].toString();
            _userId = (me['user'] as Map)['id'] as String;
            _families = [];
            _alerts = [];
          });
        }
        return;
      }
      await _api.refreshPushRegistration();
      final families = await _api.families();
      final alerts = await _api.inbox();
      final ownerId = (me['user'] as Map)['id'] as String;
      final ownedGroups = (families['groups'] as List? ?? [])
          .where((item) => (item as Map)['owner_id'] == ownerId)
          .toList();
      if (relay.groupId == null && ownedGroups.length == 1) {
        await relay.selectGroup((ownedGroups.single as Map)['id'] as int);
      }
      if (!mounted) return;
      setState(() {
        _signedIn = true;
        _name = (me['user'] as Map)['name'].toString();
        _userId = ownerId;
        _families = families['groups'] as List? ?? [];
        _alerts = alerts['data'] as List? ?? [];
        _activeGroupId = relay.groupId;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _textAction(
    String title,
    String label,
    Future<Map<String, dynamic>> Function(String) action,
  ) async {
    var input = '';
    final submit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextFormField(
          decoration: InputDecoration(labelText: label),
          onChanged: (value) => input = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (submit == true && mounted) {
      await _run(() => action(input.trim()));
    }
  }

  Future<void> _run(Future<dynamic> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      await _refresh();
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _busy = false;
        });
      }
    }
  }

  Future<void> _invite(int groupId) async {
    await _run(() async {
      final result = await _api.invite(groupId, 'caregiver');
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Kode undangan caregiver'),
          content: SelectableText(
            '${result['code']}\n\nBerlaku 7 hari, sekali pakai. Kirim langsung ke orang yang dipercaya.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _logout() async {
    final relay = context.read<AppProvider>().familyAlerts;
    await _api.logout();
    await relay.clearOnLogout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Akun & Grup Keluarga'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_busy) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (!_signedIn) ...[
            const Text(
              'Masuk dengan Google untuk menghubungkan keluarga. Jika belum punya akun MEDITRACE, akun akan dibuat otomatis. Jadwal obat di HP ini tetap bisa dipakai tanpa login.',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy
                  ? null
                  : () {
                      final relay = context.read<AppProvider>().familyAlerts;
                      _run(() async {
                        await _api.loginWithGoogle();
                        await relay.flush();
                      });
                    },
              icon: const Icon(Icons.account_circle),
              label: const Text('Masuk dengan Google'),
            ),
          ] else ...[
            ListTile(
              title: Text(_name),
              subtitle: const Text('Akun MEDITRACE'),
              trailing: TextButton(
                onPressed: _busy ? null : () => _run(_logout),
                child: const Text('Keluar'),
              ),
            ),
            if (!_api.backendConfigured)
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Login Google berhasil'),
                subtitle: Text(
                  'Backend grup keluarga belum aktif. Jadwal dan pengingat lokal tetap berjalan.',
                ),
              )
            else ...[
              const Divider(),
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => _textAction(
                        'Kirim email uji',
                        'Alamat email penerima',
                        _api.testEmail,
                      ),
                icon: const Icon(Icons.mark_email_read_outlined),
                label: const Text('Kirim email notifikasi uji'),
              ),
              const SizedBox(height: 8),
              const Text('Grup keluarga'),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Peringatan ruang obat kosong dan MEDITRACE terputus dikirim ke grup yang Anda miliki. Koneksi manual yang diputus tidak mengirim peringatan.',
                ),
              ),
              if (_families.any((item) => (item as Map)['owner_id'] == _userId))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: DropdownButtonFormField<int>(
                    initialValue:
                        _families.any(
                          (item) =>
                              (item as Map)['owner_id'] == _userId &&
                              item['id'] == _activeGroupId,
                        )
                        ? _activeGroupId
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Grup penerima peringatan MEDITRACE',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final item in _families)
                        if ((item as Map)['owner_id'] == _userId)
                          DropdownMenuItem<int>(
                            value: item['id'] as int,
                            child: Text(item['name'].toString()),
                          ),
                    ],
                    onChanged: _busy
                        ? null
                        : (id) => _run(
                            () => context
                                .read<AppProvider>()
                                .familyAlerts
                                .selectGroup(id),
                          ),
                  ),
                ),
              for (final item in _families)
                Card(
                  child: ListTile(
                    title: Text((item as Map)['name'].toString()),
                    subtitle: Text('${item['members_count']} anggota'),
                    trailing: item['owner_id'] != _userId
                        ? null
                        : IconButton(
                            tooltip: 'Undang caregiver',
                            icon: const Icon(Icons.person_add_alt_1),
                            onPressed: () => _invite(item['id'] as int),
                          ),
                  ),
                ),
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () => _textAction(
                        'Buat grup',
                        'Nama keluarga',
                        _api.createFamily,
                      ),
                child: const Text('Buat grup keluarga'),
              ),
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () => _textAction(
                        'Gabung grup',
                        'Kode undangan',
                        _api.joinFamily,
                      ),
                child: const Text('Masukkan kode undangan'),
              ),
              const Divider(),
              const Text('Pemberitahuan untuk Anda'),
              if (_alerts.isEmpty)
                const ListTile(title: Text('Belum ada pemberitahuan')),
              for (final item in _alerts)
                Card(
                  child: ListTile(
                    title: Text((item as Map)['title'].toString()),
                    subtitle: Text(
                      '${item['group_name']} · ${item['occurred_at']}',
                    ),
                    trailing: item['acknowledged_at'] == null
                        ? TextButton(
                            onPressed: () => _run(
                              () => _api.acknowledge(item['id'] as String),
                            ),
                            child: const Text('Tangani'),
                          )
                        : const Icon(Icons.check_circle_outline),
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }
}
