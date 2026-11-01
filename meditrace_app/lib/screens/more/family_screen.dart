import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../services/family_api.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({
    super.key,
    this.embedded = false,
    this.initialInviteCode,
  });

  final bool embedded;
  final String? initialInviteCode;

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
  int? _activeGroupId;

  @override
  void initState() {
    super.initState();
    _refresh();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final code = widget.initialInviteCode;
      if (code != null) _joinWithCode(code);
    });
  }

  Future<void> _joinWithCode(String code) async {
    if (!mounted) return;
    await _run(() => _api.joinFamily(code));
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _refresh({bool showLoading = true}) async {
    final relay = context.read<AppProvider>().familyAlerts;
    setState(() {
      if (showLoading) _busy = true;
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
          });
        }
        return;
      }
      await _api.refreshPushRegistration();
      final families = await _api.families();
      final ownerId = (me['user'] as Map)['id'] as String;
      final ownedGroups = (families['groups'] as List? ?? [])
          .where((item) => (item as Map)['owner_id'] == ownerId)
          .toList();
      if (relay.groupId == null && ownedGroups.isNotEmpty) {
        await relay.selectGroup(_groupId(ownedGroups.first));
      }
      if (!mounted) return;
      setState(() {
        _signedIn = true;
        _name = (me['user'] as Map)['name'].toString();
        _userId = ownerId;
        _families = families['groups'] as List? ?? [];
        _activeGroupId = relay.groupId;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
        });
      }
    } finally {
      if (mounted && showLoading) setState(() => _busy = false);
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
      await _refresh(showLoading: false);
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _invite(int groupId, String groupName) async {
    await _run(() async {
      final result = await _api.invite(groupId, 'caregiver');
      if (!mounted) return;
      final code = result['code']?.toString() ?? '';
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Kode undangan caregiver'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SelectableText(
                code,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(letterSpacing: 2, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text('Berlaku 7 hari dan hanya bisa dipakai sekali.'),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: code));
                  if (!dialogContext.mounted) return;
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Kode berhasil disalin')),
                  );
                },
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Salin kode'),
              ),
              FilledButton.icon(
                onPressed: () => _emailInvitation(groupId, groupName, code),
                icon: const Icon(Icons.email_outlined),
                label: const Text('Kirim via email'),
              ),
            ],
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

  Future<void> _emailInvitation(
    int groupId,
    String groupName,
    String code,
  ) async {
    var email = '';
    final submit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kirim undangan via email'),
        content: TextField(
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email penerima',
            hintText: 'keluarga@email.com',
          ),
          onChanged: (value) => email = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Kirim email'),
          ),
        ],
      ),
    );
    if (submit != true || !mounted) return;
    final recipient = email.trim();
    if (!recipient.contains('@') || recipient.contains(' ')) {
      setState(() => _error = 'Masukkan alamat email yang valid.');
      return;
    }
    await _run(
      () => _api.sendInvitationEmail(
        groupId: groupId,
        email: recipient,
        code: code,
        groupName: groupName,
      ),
    );
  }

  Future<void> _editFamily(int groupId, String currentName) async {
    var name = currentName;
    final submit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit nama keluarga'),
        content: TextField(
          autofocus: true,
          controller: TextEditingController(text: currentName),
          decoration: const InputDecoration(labelText: 'Nama keluarga'),
          onChanged: (value) => name = value,
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
    if (submit != true || !mounted) return;
    await _run(() => _api.updateFamily(groupId, name.trim()));
  }

  Future<void> _deleteFamily(int groupId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus grup keluarga?'),
        content: Text(
          'Grup "$name" akan dihapus dan anggota tidak dapat lagi '
          'mengaksesnya. Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(() => _api.deleteFamily(groupId));
  }

  Future<void> _logout() async {
    final relay = context.read<AppProvider>().familyAlerts;
    await _api.logout();
    await relay.clearOnLogout();
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();
    if (widget.embedded) return content;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keluarga'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildContent() {
    return ListView(
      shrinkWrap: widget.embedded,
      physics: widget.embedded ? const NeverScrollableScrollPhysics() : null,
      padding: const EdgeInsets.all(16),
      children: [
        if (_busy && !widget.embedded) const LinearProgressIndicator(),
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
            'Masuk dari kartu Profil di atas untuk mengatur grup dan berbagi peringatan dengan keluarga.',
          ),
          if (!widget.embedded) ...[
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
          ],
        ] else ...[
          if (!widget.embedded)
            ListTile(
              title: Text(_name),
              subtitle: const Text('Akun sudah terhubung'),
              trailing: TextButton(
                onPressed: _busy ? null : () => _run(_logout),
                child: const Text('Keluar'),
              ),
            ),
          if (!_api.backendConfigured)
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Pengaturan grup belum aktif'),
              subtitle: Text(
                'Fitur lokal tetap berjalan. Hubungkan backend untuk mengatur keluarga.',
              ),
            )
          else ...[
            const Divider(),
            const Text('Grup keluarga'),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Peringatan ruang obat kosong dan MEDITRACE terputus dikirim ke grup yang Anda miliki. Koneksi manual yang diputus tidak mengirim peringatan.',
              ),
            ),
            if (_activeGroupId != null)
              const ListTile(
                leading: Icon(Icons.notifications_active_outlined),
                title: Text('Peringatan keluarga aktif'),
                subtitle: Text(
                  'MEDITRACE akan mengirim peringatan ke grup keluarga Anda.',
                ),
                contentPadding: EdgeInsets.zero,
              ),
            for (final item in _families)
              Card(
                child: ListTile(
                  title: Text((item as Map)['name'].toString()),
                  subtitle: Text('${item['members_count']} anggota'),
                  trailing: item['owner_id'] != _userId
                      ? null
                      : PopupMenuButton<String>(
                          onSelected: (action) {
                            final id = _groupId(item);
                            final name = item['name'].toString();
                            if (action == 'invite') {
                              _invite(id, name);
                            } else if (action == 'edit') {
                              _editFamily(id, name);
                            } else {
                              _deleteFamily(id, name);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'invite',
                              child: Text('Undang caregiver'),
                            ),
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit nama'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Hapus grup'),
                            ),
                          ],
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
          ],
        ],
      ],
    );
  }

  int _groupId(Object? item) {
    final value = item is Map ? item['id'] : null;
    final id = switch (value) {
      int value => value,
      num value => value.toInt(),
      String value => int.tryParse(value),
      _ => null,
    };
    if (id == null || id < 1) {
      throw StateError('ID grup keluarga tidak valid.');
    }
    return id;
  }
}
