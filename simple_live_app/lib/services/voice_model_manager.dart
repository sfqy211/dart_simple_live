import 'dart:io';

import 'package:path/path.dart' as path;

class LocalVoiceModel {
  final String name;
  final String version;
  final int sizeBytes;
  final String sizeText;
  final String modelPath;
  final DateTime lastModified;
  final String downloadUrl;

  LocalVoiceModel({
    required this.name,
    required this.version,
    required this.sizeBytes,
    required this.sizeText,
    required this.modelPath,
    required this.lastModified,
    required this.downloadUrl,
  });
}

class VoiceModelManager {
  List<LocalVoiceModel>? _cachedModels;

  Future<List<LocalVoiceModel>> loadLocalModels({bool refresh = false}) async {
    if (!refresh && _cachedModels != null) {
      return _cachedModels!;
    }
    final modelsPath = _resolveModelsDirectory();
    final dir = Directory(modelsPath);
    if (!await dir.exists()) {
      _cachedModels = [];
      return _cachedModels!;
    }
    final entities = await dir.list(followLinks: false).toList();
    final models = <LocalVoiceModel>[];
    for (final entity in entities) {
      if (entity is! Directory) {
        continue;
      }
      final name = path.basename(entity.path);
      if (!_isValidModelDirectory(entity)) {
        continue;
      }
      final sizeBytes = await _calculateDirectorySize(entity);
      final stat = await entity.stat();
      final version = _extractVersion(name);
      models.add(
        LocalVoiceModel(
          name: name,
          version: version,
          sizeBytes: sizeBytes,
          sizeText: _formatBytes(sizeBytes),
          modelPath: entity.path,
          lastModified: stat.modified,
          downloadUrl: buildOfficialDownloadUrl(name),
        ),
      );
    }
    models.sort((a, b) => a.name.compareTo(b.name));
    _cachedModels = models;
    return _cachedModels!;
  }

  Future<LocalVoiceModel?> resolveModelByName(String name) async {
    final models = await loadLocalModels();
    if (models.isEmpty) {
      return null;
    }
    return models.firstWhere(
      (model) => model.name == name,
      orElse: () => models.first,
    );
  }

  Future<String> resolveModelPath(String modelName) async {
    final model = await resolveModelByName(modelName);
    if (model == null) {
      throw Exception("未检测到本地模型");
    }
    return model.modelPath;
  }

  String resolveModelsDirectoryLabel() {
    return path.join("simple_live_app", "models");
  }

  String buildOfficialDownloadUrl(String modelName) {
    if (modelName.startsWith("sherpa-onnx-")) {
      return "https://k2-fsa.github.io/sherpa/onnx/pretrained_models/";
    }
    return "https://k2-fsa.github.io/sherpa/onnx/pretrained_models/";
  }

  String _resolveModelsDirectory() {
    final cwd = Directory.current.path;
    if (path.basename(cwd) == "simple_live_app") {
      return path.join(cwd, "models");
    }
    return path.join(cwd, "simple_live_app", "models");
  }

  bool _isValidModelDirectory(Directory dir) {
    final tokensTxt = File(path.join(dir.path, "tokens.txt"));
    final tokensJson = File(path.join(dir.path, "tokens.json"));
    if (!tokensTxt.existsSync() && !tokensJson.existsSync()) {
      return false;
    }
    final entries = dir.listSync(followLinks: false);
    final hasOnnx = entries.whereType<File>().any(
          (file) => path.extension(file.path).toLowerCase() == ".onnx",
        );
    return hasOnnx;
  }

  String _extractVersion(String name) {
    final match = RegExp(r'(\d+(?:\.\d+)+)$').firstMatch(name);
    return match?.group(1) ?? "unknown";
  }

  Future<int> _calculateDirectorySize(Directory dir) async {
    var total = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        try {
          total += await entity.length();
        } catch (_) {}
      }
    }
    return total;
  }

  String _formatBytes(int bytes) {
    const units = ["B", "KB", "MB", "GB", "TB"];
    var size = bytes.toDouble();
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    return "${size.toStringAsFixed(size >= 100 ? 0 : 1)} ${units[unitIndex]}";
  }
}
