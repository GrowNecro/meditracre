abstract final class InvitationLink {
  static String? codeFromUri(Uri uri) {
    if (uri.scheme != 'https' ||
        uri.host.toLowerCase() != 'meditrace.grownecro.tech' ||
        uri.userInfo.isNotEmpty ||
        (uri.hasPort && uri.port != 443)) {
      return null;
    }
    final segments = [...uri.pathSegments];
    if (segments.isNotEmpty && segments.last.isEmpty) segments.removeLast();
    if (segments.length != 2 ||
        segments.first != 'invite' ||
        !RegExp(r'^(?:[0-9A-Fa-f]{24}|[0-9A-Za-z]{9})$')
            .hasMatch(segments.last)) {
      return null;
    }
    return segments.last.toUpperCase();
  }
}
