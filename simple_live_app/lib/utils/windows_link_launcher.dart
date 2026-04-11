import 'dart:io';

/// Opens [url] in the user's default browser on Windows.
///
/// Throws a [FormatException] if [url] is empty or malformed and
/// an [UnsupportedError] when running on non-Windows platforms.
Future<void> openExternalLink(String url) async {
  final trimmed = url.trim();
  if (trimmed.isEmpty) {
    throw const FormatException('URL cannot be empty.');
  }

  final uri = Uri.tryParse(trimmed);
  if (uri == null || uri.scheme.isEmpty) {
    throw FormatException('Invalid URL: $url');
  }

  if (!Platform.isWindows) {
    throw UnsupportedError(
      'External link launching is only supported on Windows.',
    );
  }

  await Process.start('explorer', [uri.toString()]);
}
