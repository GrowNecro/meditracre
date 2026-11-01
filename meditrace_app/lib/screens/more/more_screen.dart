import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../providers/ble_provider.dart';
import '../../services/family_api.dart';
import 'family_screen.dart';
import 'medication_guide_screen.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key, this.inviteCode, this.onInviteConsumed});

  final String? inviteCode;
  final VoidCallback? onInviteConsumed;

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  final _api = FamilyApi();
  bool _checkingAccount = true;
  bool _signedIn = false;
  String? _accountEmail;
  String? _accountName;
  String? _accountError;

  @override
  void initState() {
    super.initState();
    _loadAccount();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final code = widget.inviteCode;
      if (code != null) {
        _showInvite(code);
      }
    });
  }

  Future<void> _showInvite(String code) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Undangan keluarga'),
        content: Text('Kode undangan $code sudah siap digunakan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Nanti'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _showFamilyJoin(code);
            },
            child: const Text('Gabung sekarang'),
          ),
        ],
      ),
    );
    widget.onInviteConsumed?.call();
  }

  void _showFamilyJoin(String code) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Masukkan kode $code di bagian Keluarga')),
    );
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _loadAccount() async {
    final app = context.read<AppProvider>();
    try {
      if (await _api.hasSession) {
        final result = await _api.me();
        final user = result['user'] as Map;
        final accountName = user['name']?.toString();
        if (accountName != null && accountName.isNotEmpty) {
          await app.updateProfile(name: accountName, family: app.familyName);
        }
        if (mounted) {
          setState(() {
            _signedIn = true;
            _accountName = accountName;
            _accountEmail = user['email']?.toString();
          });
        }
      }
    } catch (error) {
      if (mounted) setState(() => _accountError = error.toString());
    } finally {
      if (mounted) setState(() => _checkingAccount = false);
    }
  }

  Future<void> _signIn(AppProvider app) async {
    setState(() {
      _checkingAccount = true;
      _accountError = null;
    });
    try {
      final result = await _api.loginWithGoogle();
      final user = result['user'] as Map;
      final name = user['name']?.toString();
      if (name != null && name.isNotEmpty) {
        await app.updateProfile(name: name, family: app.familyName);
      }

      if (mounted) {
        setState(() {
          _signedIn = true;
          _accountName = name;
          _accountEmail = user['email']?.toString();
        });
      }
    } catch (error) {
      if (mounted) setState(() => _accountError = error.toString());
    } finally {
      if (mounted) setState(() => _checkingAccount = false);
    }
  }

  Future<void> _signOut(AppProvider app) async {
    setState(() {
      _checkingAccount = true;
      _accountError = null;
    });
    try {
      await _api.logout();
      await app.familyAlerts.clearOnLogout();
      if (mounted) {
        setState(() {
          _signedIn = false;
          _accountName = null;
          _accountEmail = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _accountError = error.toString());
    } finally {
      if (mounted) setState(() => _checkingAccount = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            tooltip: 'Panduan obat',
            icon: const Icon(Icons.help_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MedicationGuideScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 26,
                        child: Icon(Icons.person_outline),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _accountName ?? app.patientName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              _signedIn
                                  ? (_accountEmail ??
                                        'Email akun tidak tersedia')
                                  : 'Belum masuk',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Lengkapi profil',
                        onPressed: () => _editProfile(context, app),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_accountError != null)
                    Text(
                      _accountError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  if (!_signedIn)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _checkingAccount ? null : () => _signIn(app),
                        icon: const Icon(Icons.login),
                        label: const Text('Masuk dengan Google'),
                      ),
                    )
                  else
                    TextButton(
                      onPressed: _checkingAccount ? null : () => _signOut(app),
                      child: const Text('Keluar dari akun'),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.health_and_safety_outlined),
                  title: Text('Data kesehatan'),
                  subtitle: Text('Informasi pasien dan kontak darurat'),
                ),
                ListTile(
                  title: Text(
                    app.patientAge == null
                        ? 'Umur belum diisi'
                        : 'Umur ${app.patientAge} tahun',
                  ),
                  subtitle: Text(
                    app.emergencyPhone.isEmpty && app.emergencyEmail.isEmpty
                        ? 'Kontak darurat belum diisi'
                        : 'Kontak darurat sudah tersimpan',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _editProfile(context, app),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.family_restroom),
                  title: const Text('Keluarga'),
                  subtitle: Text(
                    _signedIn
                        ? 'Atur grup, caregiver, dan pemberitahuan'
                        : 'Masuk untuk menghubungkan keluarga',
                  ),
                ),
                FamilyScreen(
                  key: ValueKey('${_signedIn}_${widget.inviteCode}'),
                  embedded: true,
                  initialInviteCode: widget.inviteCode,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Consumer<BleProvider>(
              builder: (context, ble, _) => Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.bluetooth_disabled),
                    title: Text('Pengingat saat MEDITRACE tertinggal'),
                    subtitle: Text(
                      'Pasien diperingatkan 30 detik setelah terputus. Jika belum reconnect 5 menit kemudian, caregiver diberi tahu.',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: ble.reportMedboxLeftBehind,
                        icon: const Icon(Icons.warning_amber_rounded),
                        label: const Text('Saya meninggalkan MEDITRACE'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editProfile(BuildContext context, AppProvider app) async {
    var name = app.patientName;
    var family = app.familyName;
    var ageText = app.patientAge?.toString() ?? '';
    var emergencyPhone = app.emergencyPhone;
    var emergencyEmail = app.emergencyEmail;
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: name,
              decoration: const InputDecoration(
                labelText: 'Nama pengguna',
                hintText: 'Contoh: Budi',
              ),
              onChanged: (value) => name = value,
            ),
            TextFormField(
              initialValue: family,
              decoration: const InputDecoration(
                labelText: 'Nama keluarga',
                hintText: 'Contoh: Keluarga Budi',
              ),
              onChanged: (value) => family = value,
            ),
            TextFormField(
              initialValue: ageText,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Umur'),
              onChanged: (value) => ageText = value,
            ),
            TextFormField(
              initialValue: emergencyPhone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Nomor darurat',
                hintText: 'Contoh: 08123456789',
              ),
              onChanged: (value) => emergencyPhone = value,
            ),
            TextFormField(
              initialValue: emergencyEmail,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email darurat',
                hintText: 'keluarga@email.com',
              ),
              onChanged: (value) => emergencyEmail = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (save == true && context.mounted) {
      await app.updateProfile(
        name: name,
        family: family,
        age: int.tryParse(ageText.trim()),
        emergencyPhone: emergencyPhone,
        emergencyEmail: emergencyEmail,
      );
    }
  }
}
