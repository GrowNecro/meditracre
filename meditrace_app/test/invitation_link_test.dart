import 'package:flutter_test/flutter_test.dart';
import 'package:meditrace_app/services/invitation_link.dart';

void main() {
  const code = '0123456789ABCDEF01234567';
  test('existing nine-character backend invitation links remain supported', () {
    expect(
      InvitationLink.codeFromUri(
        Uri.parse('https://meditrace.grownecro.tech/invite/z9x8w7v6u'),
      ),
      'Z9X8W7V6U',
    );
  });
  test(
    'accepts invitation links and normalizes case, trailing slash and tracking',
    () {
      for (final path in [
        '/invite/$code',
        '/invite/${code.toLowerCase()}/?utm_source=email',
      ]) {
        expect(
          InvitationLink.codeFromUri(
            Uri.parse('https://meditrace.grownecro.tech$path'),
          ),
          code,
        );
      }
    },
  );

  test('rejects malformed codes, lookalike domains and non-HTTPS links', () {
    for (final link in [
      'http://meditrace.grownecro.tech/invite/$code',
      'https://meditrace.grownecro.tech.other.example/invite/$code',
      'https://other.example/invite/$code',
      'https://user@meditrace.grownecro.tech/invite/$code',
      'https://meditrace.grownecro.tech:8443/invite/$code',
      'https://meditrace.grownecro.tech/invite/short',
      'https://meditrace.grownecro.tech/invite/ZZZZZZZZZZZZZZZZZZZZZZZZ',
      'https://meditrace.grownecro.tech/invite/$code/extra',
    ]) {
      expect(InvitationLink.codeFromUri(Uri.parse(link)), isNull, reason: link);
    }
  });
}
