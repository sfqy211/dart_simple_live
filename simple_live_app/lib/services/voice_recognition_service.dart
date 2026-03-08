import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/services/voice_model_manager.dart';
import 'package:vosk_flutter/vosk_flutter.dart';

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

class LocalVoskRecognitionEngine implements VoiceRecognitionEngine {
  LocalVoskRecognitionEngine({VoiceModelManager? modelManager})
      : _modelManager = modelManager ?? VoiceModelManager();

  final VoiceModelManager _modelManager;
  final VoskFlutterPlugin _vosk = VoskFlutterPlugin.instance();
  Recognizer? _recognizer;
  SpeechService? _speechService;
  StreamSubscription<String>? _resultSubscription;
  StreamSubscription<String>? _partialSubscription;
  StreamSubscription<Uint8List>? _audioSubscription;
  String? _currentModelName;
  bool _running = false;

  @override
  bool get isRunning => _running;

  Future<void> start({
    required String modelName,
    required void Function(VoiceRecognitionResult) onResult,
    Function? onError,
  }) async {
    await _ensureInitialized(modelName);
    await _audioSubscription?.cancel();
    _audioSubscription = null;
    _speechService = await _vosk.initSpeechService(_recognizer!);
    await _speechService!.start(onRecognitionError: onError);
    await _resultSubscription?.cancel();
    await _partialSubscription?.cancel();
    _resultSubscription = _speechService!.onResult().listen((data) {
      final parsed = _parseResult(data, true);
      if (parsed != null) {
        onResult(parsed);
      }
    });
    _partialSubscription = _speechService!.onPartial().listen((data) {
      final parsed = _parseResult(data, false);
      if (parsed != null) {
        onResult(parsed);
      }
    });
    _running = true;
  }

  @override
  Future<void> startFromAudioStream({
    required Stream<Uint8List> audioStream,
    required void Function(VoiceRecognitionResult) onResult,
    Function? onError,
    String? modelName,
    SubtitleOnlineConfig? onlineConfig,
  }) async {
    if (modelName == null || modelName.isEmpty) {
      throw Exception("未指定本地模型");
    }
    await _ensureInitialized(modelName);
    await _resultSubscription?.cancel();
    await _partialSubscription?.cancel();
    await _speechService?.stop();
    await _audioSubscription?.cancel();
    _audioSubscription = audioStream.listen(
      (chunk) async {
        if (chunk.isEmpty) {
          return;
        }
        try {
          final hasResult = await _recognizer!.acceptWaveformBytes(chunk);
          final raw = hasResult
              ? await _recognizer!.getResult()
              : await _recognizer!.getPartialResult();
          final parsed = _parseResult(raw, hasResult);
          if (parsed != null) {
            onResult(parsed);
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
    await _resultSubscription?.cancel();
    await _partialSubscription?.cancel();
    await _audioSubscription?.cancel();
    await _speechService?.stop();
    _audioSubscription = null;
    _running = false;
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _speechService?.dispose();
    await _recognizer?.dispose();
    _recognizer = null;
  }

  Future<void> _ensureInitialized(String modelName) async {
    if (_recognizer != null && _currentModelName == modelName) {
      return;
    }
    final modelPath = await _modelManager.resolveModelPath(modelName);
    final model = await _modelManager.resolveModelByName(modelName);
    _currentModelName = model?.name ?? modelName;
    final voskModel = await _vosk.createModel(modelPath);
    _recognizer = await _vosk.createRecognizer(
      model: voskModel,
      sampleRate: 16000,
    );
    await _recognizer!.setMaxAlternatives(1);
    await _recognizer!.setWords(words: true);
    await _recognizer!.setPartialWords(partialWords: true);
  }

  VoiceRecognitionResult? _parseResult(String raw, bool isFinal) {
    try {
      final data = jsonDecode(raw);
      if (data is! Map<String, dynamic>) {
        return null;
      }
      final text = (data['text'] ?? data['partial'])?.toString() ?? "";
      if (text.isEmpty) {
        return null;
      }
      return VoiceRecognitionResult(
        text: text,
        isFinal: isFinal && data.containsKey('text'),
        timestamp: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
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
      : _localEngine = LocalVoskRecognitionEngine(modelManager: modelManager),
        _onlineEngine = OnlineWebSocketRecognitionEngine();

  final LocalVoskRecognitionEngine _localEngine;
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
    final engine = mode == SubtitleRecognitionMode.online
        ? _onlineEngine
        : _localEngine;
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
