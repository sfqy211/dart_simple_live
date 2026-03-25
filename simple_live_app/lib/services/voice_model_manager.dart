import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

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

    final models = <LocalVoiceModel>[];
    final searchDirectories = await _resolveSearchDirectories();
    for (final dir in searchDirectories) {
      if (!await dir.exists()) {
        continue;
      }
      final entities = await dir.list(followLinks: false).toList();
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

  Future<String> resolveModelsDirectoryLabel() async {
    return (await _resolvePrimaryModelsDirectory()).path;
  }

  Future<List<String>> resolveSearchDirectoryLabels() async {
    final directories = await _resolveSearchDirectories();
    return directories.map((directory) => directory.path).toList();
  }

  Future<LocalVoiceModel> importModelDirectory(
    String sourcePath, {
    bool overwrite = true,
  }) async {
    final models = await importModelDirectories(
      sourcePath,
      overwrite: overwrite,
    );
    return models.first;
  }

  Future<List<LocalVoiceModel>> importModelDirectories(
    String sourcePath, {
    bool overwrite = true,
  }) async {
    final sourceDir = Directory(sourcePath);
    if (!await sourceDir.exists()) {
      throw Exception("所选目录不存在");
    }

    final sourceCandidates = <Directory>[];
    if (_isValidModelDirectory(sourceDir)) {
      sourceCandidates.add(sourceDir);
    } else {
      final entities = await sourceDir.list(followLinks: false).toList();
      for (final entity in entities) {
        if (entity is Directory && _isValidModelDirectory(entity)) {
          sourceCandidates.add(entity);
        }
      }
    }

    if (sourceCandidates.isEmpty) {
      throw Exception("所选目录及其一级子目录中都没有可用的 sherpa-onnx 模型");
    }

    final targetRoot = await _resolvePrimaryModelsDirectory();
    await targetRoot.create(recursive: true);

    for (final sourceCandidate in sourceCandidates) {
      final targetDir = Directory(
        path.join(targetRoot.path, path.basename(sourceCandidate.path)),
      );
      final sameDirectory = path.normalize(sourceCandidate.path) ==
          path.normalize(targetDir.path);

      if (await targetDir.exists() && !sameDirectory) {
        if (!overwrite) {
          throw Exception("目标目录已存在同名模型");
        }
        await targetDir.delete(recursive: true);
      }

      if (!sameDirectory) {
        await _copyDirectory(sourceCandidate, targetDir);
      }
    }

    _cachedModels = null;
    final importedModels = await loadLocalModels(refresh: true);
    final sourceNames = sourceCandidates
        .map((directory) => path.basename(directory.path))
        .toSet();
    final matched = importedModels
        .where((model) => sourceNames.contains(path.basename(model.modelPath)))
        .toList();

    if (matched.isEmpty) {
      throw Exception("模型导入完成，但重新扫描时未找到可用模型");
    }
    return matched;
  }

  String buildOfficialDownloadUrl(String modelName) {
    if (modelName.startsWith("sherpa-onnx-")) {
      return "https://k2-fsa.github.io/sherpa/onnx/pretrained_models/";
    }
    return "https://k2-fsa.github.io/sherpa/onnx/pretrained_models/";
  }

  Future<List<Directory>> _resolveSearchDirectories() async {
    final uniquePaths = <String>{};

    void addPath(String? value) {
      if (value == null || value.trim().isEmpty) {
        return;
      }
      uniquePaths.add(path.normalize(value));
    }

    if (Platform.isAndroid) {
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        addPath(path.join(externalDir.path, "models"));
      }
      final docsDir = await getApplicationDocumentsDirectory();
      addPath(path.join(docsDir.path, "models"));
    } else if (Platform.isIOS) {
      final docsDir = await getApplicationDocumentsDirectory();
      addPath(path.join(docsDir.path, "models"));
    } else {
      final cwd = Directory.current.path;
      if (path.basename(cwd) == "simple_live_app") {
        addPath(path.join(cwd, "models"));
      } else {
        addPath(path.join(cwd, "simple_live_app", "models"));
      }
    }

    return uniquePaths.map(Directory.new).toList();
  }

  Future<Directory> _resolvePrimaryModelsDirectory() async {
    if (Platform.isAndroid) {
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        return Directory(path.join(externalDir.path, "models"));
      }
      final docsDir = await getApplicationDocumentsDirectory();
      return Directory(path.join(docsDir.path, "models"));
    }
    if (Platform.isIOS) {
      final docsDir = await getApplicationDocumentsDirectory();
      return Directory(path.join(docsDir.path, "models"));
    }

    final cwd = Directory.current.path;
    if (path.basename(cwd) == "simple_live_app") {
      return Directory(path.join(cwd, "models"));
    }
    return Directory(path.join(cwd, "simple_live_app", "models"));
  }

  bool _isValidModelDirectory(Directory dir) {
    final entries = dir.listSync(recursive: true, followLinks: false);
    final files = entries.whereType<File>().toList();
    final hasTokens = files.any((file) {
      final name = path.basename(file.path).toLowerCase();
      return name == "tokens.txt" || name == "tokens.json";
    });
    if (!hasTokens) {
      return false;
    }
    return _hasSupportedOnnxModel(files, dir.path);
  }

  bool _hasSupportedOnnxModel(List<File> files, String dirPath) {
    final onnxFiles = files.where((file) {
      return path.extension(file.path).toLowerCase() == ".onnx";
    }).toList();
    if (onnxFiles.isEmpty) {
      return false;
    }
    final lowerNames =
        onnxFiles.map((file) => path.basename(file.path).toLowerCase());
    if (lowerNames.any((name) => name.contains("zipformer2"))) {
      return true;
    }
    if (lowerNames.any((name) => name.contains("zipformer"))) {
      return true;
    }
    final hasEncoder = onnxFiles.any(
      (file) => path.basename(file.path).toLowerCase().contains("encoder"),
    );
    final hasDecoder = onnxFiles.any(
      (file) => path.basename(file.path).toLowerCase().contains("decoder"),
    );
    if (hasEncoder && hasDecoder) {
      return true;
    }

    final dirName = path.basename(dirPath).toLowerCase();
    if (dirName.contains("zipformer")) {
      return true;
    }
    return false;
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

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await destination.create(recursive: true);
    await for (final entity
        in source.list(recursive: false, followLinks: false)) {
      final nextPath = path.join(destination.path, path.basename(entity.path));
      if (entity is Directory) {
        await _copyDirectory(entity, Directory(nextPath));
      } else if (entity is File) {
        await entity.copy(nextPath);
      }
    }
  }
}
