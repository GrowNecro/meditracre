import '../l10n/localization.dart';

import 'dart:typed_data';

import 'package:http/http.dart' as http;

abstract final class FirmwareUpdateService {
  static const latestReleaseUrl =
      'https://github.com/GrowNecro/meditracre/releases/latest';
  static const latestEsp32C3Url =
      'https://github.com/GrowNecro/meditracre/releases/latest/download/'
      'meditrace-esp32-c3.bin';

  static Future<Uint8List> downloadLatestEsp32C3({
    String languageCode = 'en',
  }) async {
    final response = await http
        .get(Uri.parse(latestEsp32C3Url))
        .timeout(const Duration(seconds: 45));
    if (response.statusCode != 200) {
      throw FirmwareUpdateException(
        stringsForLanguage(languageCode)
            .firmwareUnavailable((response.statusCode).toString()),
      );
    }
    final bytes = response.bodyBytes;
    if (bytes.isEmpty) {
      throw FirmwareUpdateException(
        stringsForLanguage(languageCode).onlineFirmwareEmpty,
      );
    }
    if (bytes.first != 0xE9) {
      throw FirmwareUpdateException(
        stringsForLanguage(languageCode).invalidEsp32Firmware,
      );
    }
    return Uint8List.fromList(bytes);
  }
}

class FirmwareUpdateException implements Exception {
  const FirmwareUpdateException(this.message);

  final String message;

  @override
  String toString() => message;
}
