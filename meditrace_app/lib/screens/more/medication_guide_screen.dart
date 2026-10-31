import 'package:flutter/material.dart';

class MedicationGuideScreen extends StatelessWidget {
  const MedicationGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Panduan penggunaan obat')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: scheme.primaryContainer,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline),
                      SizedBox(width: 8),
                      Text(
                        'Catatan penting',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Informasi ini bersifat umum dan tidak menggantikan '
                    'instruksi dokter, apoteker, maupun etiket obat Anda.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const _GuideCard(
            icon: Icons.schedule_outlined,
            title: 'Mengapa jadwal penting?',
            body:
                'Minum obat secara teratur sesuai rencana terapi membantu '
                'obat bekerja sebagaimana yang diharapkan. Gunakan pengingat '
                'MEDITRACE sebagai pendamping, lalu ikuti aturan pada resep.',
          ),
          const _GuideCard(
            icon: Icons.warning_amber_outlined,
            title: 'Jangan mengubah dosis sendiri',
            body:
                'Melewatkan, menunda, atau meminum dosis terlalu berdekatan '
                'dapat mengurangi manfaat obat atau meningkatkan risiko efek '
                'samping. Jangan menghentikan, menambah, atau menggandakan '
                'dosis tanpa arahan dokter atau apoteker.',
          ),
          const _GuideCard(
            icon: Icons.help_outline,
            title: 'Kalau lupa minum obat',
            body:
                'Aturannya tidak sama untuk semua obat. Periksa etiket atau '
                'leaflet obat dan hubungi dokter atau apoteker bila ragu. '
                'Jangan langsung menggandakan dosis untuk mengganti yang lupa.',
          ),
          const _GuideCard(
            icon: Icons.checklist_outlined,
            title: 'Panduan praktis',
            body:
                '• Isi kompartemen sesuai resep dan label asli obat.\n'
                '• Tekan “Sudah minum” setelah obat benar-benar diminum atau '
                'digunakan sesuai instruksi.\n'
                '• Catat atau tanyakan bila ada efek yang mengganggu.\n'
                '• Jangan menghancurkan atau membuka kapsul tanpa petunjuk '
                'tenaga kesehatan.',
          ),
          const _GuideCard(
            icon: Icons.emergency_outlined,
            title: 'Kapan perlu bantuan segera?',
            body:
                'Segera hubungi layanan gawat darurat setempat bila setelah '
                'obat muncul sulit bernapas atau bengkak pada wajah, bibir, '
                'mulut, atau tenggorokan. Untuk keluhan lain yang mengkhawatirkan, '
                'hubungi dokter atau apoteker.',
            isAlert: true,
          ),
          const SizedBox(height: 8),
          Text(
            'Rujukan: panduan layanan NHS tentang keterlambatan dosis, '
            'pengelolaan obat, dan penggunaan obat oleh pendamping.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.icon,
    required this.title,
    required this.body,
    this.isAlert = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool isAlert;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: isAlert ? scheme.errorContainer : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: isAlert ? scheme.onErrorContainer : null),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(body),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
