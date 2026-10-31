import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../providers/ble_provider.dart';
import 'family_screen.dart';
import 'medication_guide_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Keluarga & Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(app.patientName),
              subtitle: const Text('Profil yang tersimpan di HP ini'),
              trailing: IconButton(
                onPressed: () => _editProfile(context, app),
                icon: const Icon(Icons.edit_outlined),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: const Text('Panduan penggunaan obat'),
              subtitle: const Text(
                'Jadwal, dosis, obat terlupa, dan panduan umum',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MedicationGuideScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.family_restroom),
                  title: Text(app.familyName),
                  subtitle: const Text('Nama keluarga di HP ini'),
                ),
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: const Text('Akun & keluarga'),
                  subtitle: const Text(
                    'Hubungkan keluarga dan lihat pemberitahuan',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FamilyScreen()),
                  ),
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
                    title: Text('Peringatan MEDITRACE tertinggal'),
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
                        label: const Text('Saya meninggalkan MEDBOX'),
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
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profil lokal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: name,
              decoration: const InputDecoration(labelText: 'Nama'),
              onChanged: (value) => name = value,
            ),
            TextFormField(
              initialValue: family,
              decoration: const InputDecoration(labelText: 'Keluarga'),
              onChanged: (value) => family = value,
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
      await app.updateProfile(name: name, family: family);
    }
  }
}
