import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/app/log.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

class GhostBridge {
  static const mainWindowId = 0;
  static const eventUpdate = 'update';
  static const eventConfig = 'config';
  static const eventDanmaku = 'danmaku';
  static const eventSubtitle = 'subtitle';
  static const eventEmoticons = 'emoticons';
  static const eventGhostClosed = 'ghost_closed';
  static const eventGhostSettings = 'ghost_settings';
  static const eventGetAutoSpamState = 'get_auto_spam_state';
  static const eventAutoSpamState = 'auto_spam_state';
  static const eventSetAutoSpamState = 'set_auto_spam_state';
  static const eventAutoSpamAction = 'auto_spam_action';
  static const eventGhostVolume = 'ghost_volume';
  static const eventGhostExit = 'ghost_exit';
  static const eventSendChat = 'send_chat';
  static const eventSendEmotion = 'send_emotion';
  static const eventGetEmoticons = 'get_emoticons';
  static const eventShowEmotions = 'show_emotions';
  static const eventShowAutoSpam = 'show_auto_spam';

  static bool get hasGhostWindow =>
      WindowManagerPlus.current.id != mainWindowId;

  static bool canSendToGhost(int? windowId) => windowId != null;

  static void sendToGhost(
    int? windowId,
    String eventName,
    dynamic arguments, {
    String? errorMessage,
  }) {
    if (windowId == null) {
      return;
    }
    try {
      WindowManagerPlus.current.invokeMethodToWindow(
        windowId,
        eventName,
        arguments,
      );
    } catch (e) {
      if (errorMessage != null && errorMessage.isNotEmpty) {
        Log.logPrint('$errorMessage: $e');
      }
    }
  }

  static void sendToMain(
    String eventName,
    dynamic arguments, {
    String? errorMessage,
  }) {
    try {
      WindowManagerPlus.current.invokeMethodToWindow(
        mainWindowId,
        eventName,
        arguments,
      );
    } catch (e) {
      if (errorMessage != null && errorMessage.isNotEmpty) {
        Log.logPrint('$errorMessage: $e');
      }
    }
  }

  static Map<String, dynamic> buildDanmakuPayload(
    DanmakuContentItem item, {
    String? userName,
  }) {
    return {
      'text': item.text,
      'user': userName,
      'color': item.color.toARGB32(),
      'type': item.type.index,
      'selfSend': item.selfSend,
    };
  }

  static Map<String, dynamic> buildSubtitlePayload(
    String text,
    bool partial,
  ) {
    return {
      'text': text,
      'partial': partial,
    };
  }

  static Map<String, dynamic> buildUpdatePayload({
    double? opacity,
    bool? locked,
  }) {
    return {
      if (opacity != null) 'opacity': opacity,
      if (locked != null) 'locked': locked,
    };
  }

  static Map<String, dynamic> buildConfigPayload({
    required AppSettingsController settings,
    required double opacity,
    required bool locked,
  }) {
    return {
      'opacity': opacity,
      'locked': locked,
      'danmaku': {
        'fontSize': settings.danmuSize.value,
        'opacity': settings.danmuOpacity.value,
        'fontWeight': settings.danmuFontWeight.value,
      },
      'panelColor': settings.ghostPanelColor.value,
      'volume': settings.playerVolume.value,
      'subtitleEnable': settings.subtitleEnable.value,
    };
  }

  static Map<String, dynamic> buildAutoSpamStatePayload({
    required AppSettingsController settings,
    required bool textRunning,
    required bool emotionRunning,
    required bool favoritesRunning,
  }) {
    return {
      'textMsg': settings.autoSpamTextMsg.value,
      'textInterval': settings.autoSpamTextInterval.value,
      'textChunkSize': settings.autoSpamTextChunkSize.value,
      'textDuration': settings.autoSpamTextDuration.value,
      'emotionInterval': settings.autoSpamEmotionInterval.value,
      'emotionDuration': settings.autoSpamEmotionDuration.value,
      'favoritesInterval': settings.autoSpamFavoritesInterval.value,
      'favoritesDuration': settings.autoSpamFavoritesDuration.value,
      'favoritesIndex': settings.autoSpamFavoritesIndex.value,
      'emotions': settings.autoSpamEmotions.toList(),
      'favorites': settings.autoSpamFavorites.toList(),
      'textRunning': textRunning,
      'emotionRunning': emotionRunning,
      'favoritesRunning': favoritesRunning,
    };
  }

  static List<Map<String, dynamic>> normalizeMapList(dynamic values) {
    if (values is! List) {
      return const [];
    }
    return values
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
