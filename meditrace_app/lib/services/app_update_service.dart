import 'package:url_launcher/url_launcher.dart';

abstract final class AppUpdateService {
  static final latestApkUri = Uri.parse(
    'https://github.com/GrowNecro/meditracre/releases/latest/download/'
    'meditrace.apk',
  );
  static final latestReleaseUri = Uri.parse(
    'https://github.com/GrowNecro/meditracre/releases/latest',
  );

  static Future<void> downloadLatestApk() async {
    final opened = await launchUrl(
      latestApkUri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened) {
      throw const AppUpdateException('APK terbaru tidak dapat diunduh.');
    }
  }

  static Future<void> openLatestRelease() async {
    final opened = await launchUrl(
      latestReleaseUri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened) {
      throw const AppUpdateException(
        'Halaman update aplikasi tidak dapat dibuka.',
      );
    }
  }
}

class AppUpdateException implements Exception {
  const AppUpdateException(this.message);

  final String message;

  @override
  String toString() => message;
}
