import 'dart:typed_data';

import 'package:http/http.dart' as http;

abstract final class FirmwareUpdateService {
  static const latestReleaseUrl =
      'https://github.com/GrowNecro/medbox/releases/latest';
  static const latestEsp32C3Url =
      'https://github.com/GrowNecro/medbox/releases/latest/download/'
      'meditrace-esp32-c3.bin';

  static Future<Uint8List> downloadLatestEsp32C3() async {
    final response = await http
        .get(Uri.parse(latestEsp32C3Url))
        .timeout(const Duration(seconds: 45));
    if (response.statusCode != 200) {
      throw FirmwareUpdateException(
        'Firmware online tidak tersedia (${response.statusCode}).',
      );
    }
    final bytes = response.bodyBytes;
    if (bytes.isEmpty) {
      throw const FirmwareUpdateException('File firmware online kosong.');
    }
    if (bytes.first != 0xE9) {
      throw const FirmwareUpdateException(
        'File bukan firmware ESP32 yang valid; update dibatalkan.',
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
