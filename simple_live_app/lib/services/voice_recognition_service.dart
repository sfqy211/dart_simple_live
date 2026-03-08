import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:vosk_flutter/vosk_flutter.dart';
import 'package:simple_live_app/services/voice_model_manager.dart';

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

class VoiceRecognitionService {
  VoiceRecognitionService({VoiceModelManager? modelManager})
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

  Future<void> startFromAudioStream({
    required String modelName,
    required Stream<Uint8List> audioStream,
    required void Function(VoiceRecognitionResult) onResult,
    Function? onError,
  }) async {
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
    final model = await _modelManager.resolveModelByName(modelName);
    final modelPath = await _modelManager.ensureModel(model);
    _currentModelName = model.name;
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
