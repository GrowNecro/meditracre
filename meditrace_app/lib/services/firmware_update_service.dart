import 'dart:typed_data';

import 'package:http/http.dart' as http;

abstract final class FirmwareUpdateService {
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
    if (response.bodyBytes.isEmpty) {
      throw const FirmwareUpdateException('File firmware online kosong.');
    }
    return Uint8List.fromList(response.bodyBytes);
  }
}

class FirmwareUpdateException implements Exception {
  const FirmwareUpdateException(this.message);

  final String message;

  @override
  String toString() => message;
}
