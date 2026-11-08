import '../l10n/localization.dart';

import 'package:url_launcher/url_launcher.dart';

abstract final class AppUpdateService {
  static final latestApkUri = Uri.parse(
    'https://github.com/GrowNecro/meditracre/releases/latest/download/'
    'meditrace.apk',
  );
  static final latestReleaseUri = Uri.parse(
    'https://github.com/GrowNecro/meditracre/releases/latest',
  );

  static Future<void> downloadLatestApk({String languageCode = 'en'}) async {
    final opened = await launchUrl(
      latestApkUri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened) {
      throw AppUpdateException(
        stringsForLanguage(languageCode).apkDownloadFailed,
      );
    }
  }

  static Future<void> openLatestRelease({String languageCode = 'en'}) async {
    final opened = await launchUrl(
      latestReleaseUri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened) {
      throw AppUpdateException(
        stringsForLanguage(languageCode).appUpdatePageFailed,
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
