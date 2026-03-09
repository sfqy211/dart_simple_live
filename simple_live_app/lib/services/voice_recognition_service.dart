import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/services/voice_model_manager.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

class VoiceRecognitionResult {
  final String text;
  final bool isFinal;
  final DateTime timestamp;

  VoiceRecognitionResult({
    required this.text,
    required this.isFinal,
    required this.timestamp,
  });
}

class SubtitleOnlineConfig {
  final SubtitleOnlineProvider provider;
  final String url;
  final String apiKey;
  final String apiKeyHeader;

  SubtitleOnlineConfig({
    required this.provider,
    required this.url,
    required this.apiKey,
    required this.apiKeyHeader,
  });
}

abstract class VoiceRecognitionEngine {
  bool get isRunning;

  Future<void> startFromAudioStream({
    required Stream<Uint8List> audioStream,
    required void Function(VoiceRecognitionResult) onResult,
    Function? onError,
    String? modelName,
    SubtitleOnlineConfig? onlineConfig,
  });

  Future<void> stop();

  Future<void> dispose();
}

class LocalSherpaOnnxRecognitionEngine implements VoiceRecognitionEngine {
  LocalSherpaOnnxRecognitionEngine({VoiceModelManager? modelManager})
      : _modelManager = modelManager ?? VoiceModelManager();

  final VoiceModelManager _modelManager;
  sherpa_onnx.OnlineRecognizer? _recognizer;
  sherpa_onnx.OnlineStream? _stream;
  StreamSubscription<Uint8List>? _audioSubscription;
  String? _currentModelName;
  bool _running = false;
  bool _bindingsReady = false;

  @override
  bool get isRunning => _running;

  @override
  Future<void> startFromAudioStream({
    required Stream<Uint8List> audioStream,
    required void Function(VoiceRecognitionResult) onResult,
    Function? onError,
    String? modelName,
    SubtitleOnlineConfig? onlineConfig,
  }) async {
    final resolvedModelName = await _resolveModelName(modelName);
    await _ensureInitialized(resolvedModelName);
    await _audioSubscription?.cancel();
    _audioSubscription = audioStream.listen(
      (chunk) async {
        if (chunk.isEmpty) {
          return;
        }
        try {
          final samples = _convertBytesToFloat32(chunk);
          _stream!.acceptWaveform(samples: samples, sampleRate: 16000);
          while (_recognizer!.isReady(_stream!)) {
            _recognizer!.decode(_stream!);
          }
          final result = _recognizer!.getResult(_stream!);
          if (result.text.isNotEmpty) {
            final isFinal = _recognizer!.isEndpoint(_stream!);
            onResult(
              VoiceRecognitionResult(
                text: result.text,
                isFinal: isFinal,
                timestamp: DateTime.now(),
              ),
            );
            if (isFinal) {
              _recognizer!.reset(_stream!);
            }
          }
        } catch (e) {
          if (onError != null) {
            onError(e);
          }
        }
      },
      onError: onError,
    );
    _running = true;
  }

  @override
  Future<void> stop() async {
    if (!_running) {
      return;
    }
    await _audioSubscription?.cancel();
    _audioSubscription = null;
    _running = false;
  }

  @override
  Future<void> dispose() async {
    await stop();
    _disposeRecognizer();
  }

  Future<String> _resolveModelName(String? modelName) async {
    if (modelName != null && modelName.isNotEmpty) {
      return modelName;
    }
    final models = await _modelManager.loadLocalModels();
    if (models.isEmpty) {
      throw Exception("未检测到本地模型");
    }
    return models.first.name;
  }

  void _ensureBindings() {
    if (_bindingsReady) {
      return;
    }
    sherpa_onnx.initBindings();
    _bindingsReady = true;
  }

  Future<void> _ensureInitialized(String modelName) async {
    if (_recognizer != null && _currentModelName == modelName) {
      return;
    }
    _disposeRecognizer();
    final modelPath = await _modelManager.resolveModelPath(modelName);
    final modelConfig = _buildModelConfig(modelPath);
    _ensureBindings();
    _recognizer = sherpa_onnx.OnlineRecognizer(
      sherpa_onnx.OnlineRecognizerConfig(
        model: modelConfig,
        feat: const sherpa_onnx.FeatureConfig(
          sampleRate: 16000,
          featureDim: 80,
        ),
      ),
    );
    _stream = _recognizer!.createStream();
    _currentModelName = modelName;
  }

  void _disposeRecognizer() {
    _stream?.free();
    _stream = null;
    _recognizer?.free();
    _recognizer = null;
  }

  sherpa_onnx.OnlineModelConfig _buildModelConfig(String modelPath) {
    final dir = Directory(modelPath);
    final files = dir
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .toList();
    final tokens = _findTokens(files);
    if (tokens == null) {
      throw Exception("未找到 tokens.txt 或 tokens.json");
    }
    final bpeVocab = _findBpeVocab(files);
    final encoder = _findModelFile(files, "encoder");
    final decoder = _findModelFile(files, "decoder");
    final joiner = _findModelFile(files, "joiner");
    final onnxFiles = files
        .where((file) => path.extension(file.path).toLowerCase() == ".onnx")
        .toList()
      ..sort((a, b) => a.path.length.compareTo(b.path.length));
    final modelType =
        _resolveModelType(onnxFiles, encoder, decoder, joiner, modelPath);
    if (encoder != null && decoder != null) {
      if (joiner != null) {
        return sherpa_onnx.OnlineModelConfig(
          transducer: sherpa_onnx.OnlineTransducerModelConfig(
            encoder: encoder,
            decoder: decoder,
            joiner: joiner,
          ),
          tokens: tokens,
          modelType: modelType,
          modelingUnit: bpeVocab == null ? "" : "bpe",
          bpeVocab: bpeVocab ?? "",
        );
      }
      return sherpa_onnx.OnlineModelConfig(
        paraformer: sherpa_onnx.OnlineParaformerModelConfig(
          encoder: encoder,
          decoder: decoder,
        ),
        tokens: tokens,
        modelType: modelType,
        modelingUnit: bpeVocab == null ? "" : "bpe",
        bpeVocab: bpeVocab ?? "",
      );
    }
    if (onnxFiles.isNotEmpty) {
      if (modelType != "zipformer" && modelType != "zipformer2") {
        throw Exception("当前模型结构不支持流式识别");
      }
      return sherpa_onnx.OnlineModelConfig(
        zipformer2Ctc: sherpa_onnx.OnlineZipformer2CtcModelConfig(
          model: onnxFiles.first.path,
        ),
        tokens: tokens,
        modelType: modelType,
        modelingUnit: bpeVocab == null ? "" : "bpe",
        bpeVocab: bpeVocab ?? "",
      );
    }
    throw Exception("未找到可用的模型文件");
  }

  String? _findTokens(List<File> files) {
    final tokens = files.where((file) {
      final name = path.basename(file.path).toLowerCase();
      return name == "tokens.txt" || name == "tokens.json";
    }).toList();
    if (tokens.isEmpty) {
      return null;
    }
    tokens.sort((a, b) => a.path.length.compareTo(b.path.length));
    return tokens.first.path;
  }

  String? _findBpeVocab(List<File> files) {
    final bpe = files.where((file) {
      final name = path.basename(file.path).toLowerCase();
      return name == "bpe.vocab" || name == "bpe.model";
    }).toList();
    if (bpe.isEmpty) {
      return null;
    }
    bpe.sort((a, b) => a.path.length.compareTo(b.path.length));
    return bpe.first.path;
  }

  String? _findModelFile(List<File> files, String keyword) {
    final matches = files.where((file) {
      final name = path.basename(file.path).toLowerCase();
      return name.contains(keyword) && name.endsWith(".onnx");
    }).toList();
    if (matches.isEmpty) {
      return null;
    }
    matches.sort((a, b) => a.path.length.compareTo(b.path.length));
    return matches.first.path;
  }

  String _resolveModelType(
    List<File> onnxFiles,
    String? encoder,
    String? decoder,
    String? joiner,
    String modelPath,
  ) {
    if (encoder != null && decoder != null && joiner != null) {
      return "transducer";
    }
    if (encoder != null && decoder != null) {
      return "paraformer";
    }
    // Check for single-file models (Zipformer2/Zipformer)
    final names =
        onnxFiles.map((file) => path.basename(file.path).toLowerCase());
    if (names.any((name) => name.contains("zipformer2"))) {
      return "zipformer2";
    }
    if (names.any((name) => name.contains("zipformer"))) {
      return "zipformer";
    }
    // Check directory name if file names are generic
    final dirName = path.basename(modelPath).toLowerCase();
    if (dirName.contains("zipformer2")) {
      return "zipformer2";
    }
    if (dirName.contains("zipformer")) {
      return "zipformer";
    }
    return "";
  }

  Float32List _convertBytesToFloat32(Uint8List bytes) {
    final values = Float32List(bytes.length ~/ 2);
    final data = ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.length);
    for (var i = 0; i < bytes.length; i += 2) {
      final sample = data.getInt16(i, Endian.little);
      values[i ~/ 2] = sample / 32768.0;
    }
    return values;
  }
}

class OnlineWebSocketRecognitionEngine implements VoiceRecognitionEngine {
  WebSocket? _socket;
  StreamSubscription<Uint8List>? _audioSubscription;
  StreamSubscription<dynamic>? _socketSubscription;
  bool _running = false;

  @override
  bool get isRunning => _running;

  @override
  Future<void> startFromAudioStream({
    required Stream<Uint8List> audioStream,
    required void Function(VoiceRecognitionResult) onResult,
    Function? onError,
    String? modelName,
    SubtitleOnlineConfig? onlineConfig,
  }) async {
    if (onlineConfig == null || onlineConfig.url.isEmpty) {
      throw Exception("未配置在线识别地址");
    }
    await stop();
    final headers = <String, dynamic>{};
    final apiKey = onlineConfig.apiKey.trim();
    if (apiKey.isNotEmpty) {
      final headerName = onlineConfig.apiKeyHeader.trim().isEmpty
          ? "Authorization"
          : onlineConfig.apiKeyHeader.trim();
      if (headerName == "Authorization" && !apiKey.startsWith("Bearer ")) {
        headers[headerName] = "Bearer $apiKey";
      } else {
        headers[headerName] = apiKey;
      }
    }
    _socket = await WebSocket.connect(
      onlineConfig.url,
      headers: headers.isEmpty ? null : headers,
    );
    _socketSubscription = _socket!.listen(
      (event) {
        final result = _parseMessage(event);
        if (result != null) {
          onResult(result);
        }
      },
      onError: onError,
      onDone: () {
        _running = false;
      },
    );
    _audioSubscription = audioStream.listen(
      (chunk) {
        if (chunk.isEmpty) {
          return;
        }
        _socket?.add(chunk);
      },
      onError: onError,
    );
    _running = true;
  }

  VoiceRecognitionResult? _parseMessage(dynamic event) {
    if (event is String) {
      try {
        final data = jsonDecode(event);
        if (data is Map<String, dynamic>) {
          final text = (data['text'] ?? data['partial'] ?? "").toString();
          if (text.isEmpty) {
            return null;
          }
          final isFinal = _parseFinalFlag(data);
          return VoiceRecognitionResult(
            text: text,
            isFinal: isFinal,
            timestamp: DateTime.now(),
          );
        }
      } catch (_) {
        if (event.trim().isEmpty) {
          return null;
        }
        return VoiceRecognitionResult(
          text: event,
          isFinal: true,
          timestamp: DateTime.now(),
        );
      }
    }
    return null;
  }

  bool _parseFinalFlag(Map<String, dynamic> data) {
    final candidates = [
      data['is_final'],
      data['final'],
      data['isFinal'],
      data['final_result'],
    ];
    for (final value in candidates) {
      if (value is bool) {
        return value;
      }
      if (value is num) {
        return value != 0;
      }
      if (value is String) {
        if (value == "true" || value == "1") {
          return true;
        }
        if (value == "false" || value == "0") {
          return false;
        }
      }
    }
    return data.containsKey('text');
  }

  @override
  Future<void> stop() async {
    if (!_running) {
      await _closeSocket();
      return;
    }
    await _audioSubscription?.cancel();
    await _socketSubscription?.cancel();
    _audioSubscription = null;
    _socketSubscription = null;
    await _closeSocket();
    _running = false;
  }

  Future<void> _closeSocket() async {
    try {
      await _socket?.close();
    } catch (_) {}
    _socket = null;
  }

  @override
  Future<void> dispose() async {
    await stop();
  }
}

class VoiceRecognitionService {
  VoiceRecognitionService({VoiceModelManager? modelManager})
      : _localEngine =
            LocalSherpaOnnxRecognitionEngine(modelManager: modelManager),
        _onlineEngine = OnlineWebSocketRecognitionEngine();

  final LocalSherpaOnnxRecognitionEngine _localEngine;
  final OnlineWebSocketRecognitionEngine _onlineEngine;
  VoiceRecognitionEngine? _activeEngine;

  bool get isRunning => _activeEngine?.isRunning ?? false;

  Future<void> startFromAudioStream({
    required String modelName,
    required Stream<Uint8List> audioStream,
    required void Function(VoiceRecognitionResult) onResult,
    Function? onError,
  }) async {
    final mode = AppSettingsController.instance.subtitleRecognitionMode.value;
    final engine =
        mode == SubtitleRecognitionMode.online ? _onlineEngine : _localEngine;
    if (_activeEngine != null && _activeEngine != engine) {
      await _activeEngine!.stop();
    }
    _activeEngine = engine;
    SubtitleOnlineConfig? onlineConfig;
    if (mode == SubtitleRecognitionMode.online) {
      onlineConfig = SubtitleOnlineConfig(
        provider: AppSettingsController.instance.subtitleOnlineProvider.value,
        url: AppSettingsController.instance.subtitleOnlineApiUrl.value,
        apiKey: AppSettingsController.instance.subtitleOnlineApiKey.value,
        apiKeyHeader:
            AppSettingsController.instance.subtitleOnlineApiKeyHeader.value,
      );
    }
    await engine.startFromAudioStream(
      audioStream: audioStream,
      onResult: onResult,
      onError: onError,
      modelName: modelName,
      onlineConfig: onlineConfig,
    );
  }

  Future<void> stop() async {
    await _activeEngine?.stop();
  }

  Future<void> dispose() async {
    await _localEngine.dispose();
    await _onlineEngine.dispose();
    _activeEngine = null;
  }
}
