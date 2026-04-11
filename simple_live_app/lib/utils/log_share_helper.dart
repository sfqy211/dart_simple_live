import 'dart:io';

Future<bool> revealFileInExplorer(String path) async {
  if (!Platform.isWindows) {
    return false;
  }

  final normalizedPath = path.replaceAll('/', '\\').replaceAll('"', r'\"');
  final argument = '/select,"$normalizedPath"';
  try {
    await Process.start('explorer.exe', [argument]);
    return true;
  } catch (_) {
    return false;
  }
}
