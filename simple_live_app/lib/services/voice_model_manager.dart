import 'package:vosk_flutter/vosk_flutter.dart';

class VoiceModelManager {
  final ModelLoader _modelLoader = ModelLoader();
  List<LanguageModelDescription>? _cachedModels;

  Future<List<LanguageModelDescription>> loadPreferredModels({
    bool refresh = false,
  }) async {
    if (!refresh && _cachedModels != null) {
      return _cachedModels!;
    }
    try {
      final models = await _modelLoader.loadModelsList();
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
    return _modelLoader.isModelAlreadyLoaded(modelName);
  }

  Future<String> ensureModel(LanguageModelDescription model) async {
    if (await isModelAvailable(model.name)) {
      return _modelLoader.modelPath(model.name);
    }
    return _modelLoader.loadFromNetwork(model.url);
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
