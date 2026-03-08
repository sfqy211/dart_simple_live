import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:vosk_flutter/vosk_flutter.dart';

class VoiceModelManager {
  List<LanguageModelDescription>? _cachedModels;

  Future<List<LanguageModelDescription>> loadPreferredModels({
    bool refresh = false,
  }) async {
    if (!refresh && _cachedModels != null) {
      return _cachedModels!;
    }
    try {
      final models = await ModelLoader().loadModelsList();
      _cachedModels = models
          .where((model) => !model.obsolete && model.type == "small")
          .toList();
      return _cachedModels!;
    } catch (_) {
      _cachedModels = _fallbackModels();
      return _cachedModels!;
    }
  }

  Future<LanguageModelDescription> resolveModelByName(String name) async {
    final models = await loadPreferredModels();
    return models.firstWhere(
      (model) => model.name == name,
      orElse: () => models.first,
    );
  }

  Future<bool> isModelAvailable(String modelName) async {
    final loader = await _resolveLoader();
    return loader.isModelAlreadyLoaded(modelName);
  }

  Future<String> ensureModel(LanguageModelDescription model) async {
    final loader = await _resolveLoader();
    if (await loader.isModelAlreadyLoaded(model.name)) {
      return loader.modelPath(model.name);
    }
    return loader.loadFromNetwork(model.url);
  }

  Future<ModelLoader> _resolveLoader() async {
    final storage = await _resolveModelStorage();
    if (storage == null) {
      return ModelLoader();
    }
    return ModelLoader(modelStorage: storage);
  }

  Future<String?> _resolveModelStorage() async {
    final candidates = <String>[];
    final cwd = Directory.current.path;
    candidates.add(path.join(cwd, "models"));
    candidates.add(path.join(cwd, "model"));
    final documents = await getApplicationDocumentsDirectory();
    candidates.add(path.join(documents.path, "models"));
    candidates.add(path.join(documents.path, "model"));
    for (final candidate in candidates) {
      if (Directory(candidate).existsSync()) {
        return candidate;
      }
    }
    return null;
  }

  List<LanguageModelDescription> _fallbackModels() {
    return [
      LanguageModelDescription(
        lang: "en-us",
        langText: "English (US)",
        md5: "",
        name: "vosk-model-small-en-us-0.15",
        obsolete: false,
        size: 0,
        sizeText: "unknown",
        type: "small",
        url: "https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip",
        version: "0.15",
      ),
      LanguageModelDescription(
        lang: "zh-cn",
        langText: "中文",
        md5: "",
        name: "vosk-model-small-cn-0.22",
        obsolete: false,
        size: 0,
        sizeText: "unknown",
        type: "small",
        url: "https://alphacephei.com/vosk/models/vosk-model-small-cn-0.22.zip",
        version: "0.22",
      ),
    ];
  }
}
