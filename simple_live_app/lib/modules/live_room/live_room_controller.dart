import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:share_plus/share_plus.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/constant.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/app/event_bus.dart';
import 'package:simple_live_app/app/log.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/models/db/follow_user.dart';
import 'package:simple_live_app/models/db/history.dart';
import 'package:simple_live_app/modules/live_room/player/player_controller.dart';
import 'package:simple_live_app/modules/settings/danmu_settings_page.dart';
import 'package:simple_live_app/services/bilibili_account_service.dart';
import 'package:simple_live_app/services/db_service.dart';
import 'package:simple_live_app/services/follow_service.dart';
import 'package:simple_live_app/services/voice_recognition_service.dart';
import 'package:simple_live_app/widgets/desktop_refresh_button.dart';
import 'package:simple_live_app/widgets/follow_user_item.dart';
import 'package:simple_live_app/widgets/net_image.dart';
import 'package:simple_live_app/widgets/settings/settings_card.dart';
import 'package:simple_live_app/widgets/settings/settings_number.dart';
import 'package:simple_live_app/widgets/settings/settings_switch.dart';
import 'package:simple_live_core/simple_live_core.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

class LiveRoomController extends PlayerController
    with WidgetsBindingObserver, WindowListener {
  final Site pSite;
  final String pRoomId;
  late LiveDanmaku liveDanmaku;
  LiveRoomController({
    required this.pSite,
    required this.pRoomId,
  }) {
    rxSite = pSite.obs;
    rxRoomId = pRoomId.obs;
    liveDanmaku = site.liveSite.getDanmaku();
  }

  late Rx<Site> rxSite;
  Site get site => rxSite.value;
  late Rx<String> rxRoomId;
  String get roomId => rxRoomId.value;

  Rx<LiveRoomDetail?> detail = Rx<LiveRoomDetail?>(null);
  var online = 0.obs;
  var followed = false.obs;
  var liveStatus = false.obs;
  RxList<LiveSuperChatMessage> superChats = RxList<LiveSuperChatMessage>();
  final VoiceRecognitionService _voiceRecognitionService =
      VoiceRecognitionService();
  final RxString subtitleText = "".obs;
  final RxBool subtitleIsPartial = false.obs;
  final RxBool subtitleEnabled = false.obs;
  final Rx<Offset?> subtitlePosition = Rx<Offset?>(null);
  Timer? _subtitleClearTimer;
  Timer? _subtitleDelayTimer;
  VoiceRecognitionResult? _pendingSubtitleResult;
  final List<Worker> _subtitleWorkers = [];
  final Player _subtitleAudioPlayer = Player();
  StreamController<Uint8List>? _subtitleAudioStreamController;
  RandomAccessFile? _subtitleAudioReader;
  Timer? _subtitleAudioReadTimer;
  File? _subtitleAudioDumpFile;
  int _subtitleAudioOffset = 0;
  bool _subtitleAudioHeaderSkipped = false;
  bool _subtitleAudioStopping = false;
  Future<void>? _subtitleAudioStopTask;

  /// 滚动控制
  final ScrollController scrollController = ScrollController();

  /// 聊天信息
  RxList<LiveMessage> messages = RxList<LiveMessage>();

  /// 清晰度数据
  RxList<LivePlayQuality> qualites = RxList<LivePlayQuality>();

  /// 当前清晰度
  var currentQuality = -1;
  var currentQualityInfo = "".obs;

  /// 线路数据
  RxList<String> playUrls = RxList<String>();

  Map<String, String>? playHeaders;

  /// 当前线路
  var currentLineIndex = -1;
  var currentLineInfo = "".obs;

  /// 退出倒计时
  var countdown = 60.obs;

  Timer? autoExitTimer;

  /// 设置的自动关闭时间（分钟）
  var autoExitMinutes = 60.obs;

  ///是否延迟自动关闭
  var delayAutoExit = false.obs;

  /// 是否启用自动关闭
  var autoExitEnable = false.obs;

  /// 是否禁用自动滚动聊天栏
  /// - 当用户向上滚动聊天栏时，不再自动滚动
  var disableAutoScroll = false.obs;

  /// 是否处于后台
  var isBackground = false;

  /// 直播间加载失败
  var loadError = false.obs;
  Object? error;
  StackTrace? errorStackTrace;

  // 开播时长状态变量
  var liveDuration = "00:00:00".obs;
  Timer? _liveDurationTimer;

  /// 弹幕输入控制器
  final TextEditingController chatInputController = TextEditingController();

  final RxBool autoSpamTextRunning = false.obs;
  final RxBool autoSpamEmotionRunning = false.obs;
  final RxBool autoSpamFavoritesRunning = false.obs;
  Timer? _autoSpamTextTimer;
  Timer? _autoSpamTextLimitTimer;
  Timer? _autoSpamEmotionTimer;
  Timer? _autoSpamEmotionLimitTimer;
  Timer? _autoSpamFavoritesTimer;
  Timer? _autoSpamFavoritesLimitTimer;
  int _autoSpamTextIndex = 0;
  int _autoSpamEmotionIndex = 0;
  int _autoSpamFavoritesIndex = 0;
  int _autoSpamTextFailCount = 0;
  int _autoSpamEmotionFailCount = 0;
  int _autoSpamFavoritesFailCount = 0;
  static const int _autoSpamFailLimit = 3;

  /// 发送弹幕
  Future<void> sendChatMessage(String message) async {
    if (message.isEmpty) return;

    // 检查是否为 B 站直播间
    if (site.id != Constant.kBiliBili) {
      SmartDialog.showToast("当前平台暂不支持发送弹幕");
      return;
    }

    // 调用发送弹幕方法
    var success = await BiliBiliAccountService.instance.sendMsg(
      detail.value?.roomId ?? roomId,
      message,
    );

    if (success) {
      // 清空输入框
      chatInputController.clear();
    }
  }

  /// 发送表情包
  Future<void> sendEmotionMessage(String emotion,
      {Map<String, dynamic>? emoticonOptions}) async {
    if (emotion.isEmpty) return;

    // 检查是否为 B 站直播间
    if (site.id != Constant.kBiliBili) {
      SmartDialog.showToast("当前平台暂不支持发送表情包");
      return;
    }

    // 调用发送表情包方法
    var success = await BiliBiliAccountService.instance.sendEmotion(
      detail.value?.roomId ?? roomId,
      emotion,
      emoticonOptions: emoticonOptions,
    );

    if (success) {
      // 清空输入框
      chatInputController.clear();
    }
  }

  bool get _isBiliRoom => site.id == Constant.kBiliBili;

  List<String> _splitAutoSpamText(String message, int chunkSize) {
    final cleaned = message.replaceAll('\n', '');
    if (cleaned.isEmpty) {
      return [];
    }
    if (chunkSize <= 0 || cleaned.length <= chunkSize) {
      return [cleaned];
    }
    final reg = RegExp('.{1,$chunkSize}');
    return reg.allMatches(cleaned).map((e) => e.group(0) ?? '').toList();
  }

  Future<bool> _sendAutoText(String message) {
    return BiliBiliAccountService.instance
        .sendMsg(detail.value?.roomId ?? roomId, message);
  }

  Future<bool> _sendAutoEmotion(String message,
      {Map<String, dynamic>? emoticonOptions}) {
    return BiliBiliAccountService.instance.sendEmotion(
      detail.value?.roomId ?? roomId,
      message,
      emoticonOptions: emoticonOptions,
    );
  }

  void _stopAutoSpamTimer(Timer? timer) {
    timer?.cancel();
  }

  void stopAutoSpamText() {
    autoSpamTextRunning.value = false;
    _autoSpamTextIndex = 0;
    _autoSpamTextFailCount = 0;
    _stopAutoSpamTimer(_autoSpamTextTimer);
    _autoSpamTextTimer = null;
    _stopAutoSpamTimer(_autoSpamTextLimitTimer);
    _autoSpamTextLimitTimer = null;
  }

  void stopAutoSpamEmotion() {
    autoSpamEmotionRunning.value = false;
    _autoSpamEmotionIndex = 0;
    _autoSpamEmotionFailCount = 0;
    _stopAutoSpamTimer(_autoSpamEmotionTimer);
    _autoSpamEmotionTimer = null;
    _stopAutoSpamTimer(_autoSpamEmotionLimitTimer);
    _autoSpamEmotionLimitTimer = null;
  }

  void stopAutoSpamFavorites() {
    autoSpamFavoritesRunning.value = false;
    _autoSpamFavoritesIndex = 0;
    _autoSpamFavoritesFailCount = 0;
    _stopAutoSpamTimer(_autoSpamFavoritesTimer);
    _autoSpamFavoritesTimer = null;
    _stopAutoSpamTimer(_autoSpamFavoritesLimitTimer);
    _autoSpamFavoritesLimitTimer = null;
  }

  void stopAllAutoSpam() {
    stopAutoSpamText();
    stopAutoSpamEmotion();
    stopAutoSpamFavorites();
  }

  Future<void> startAutoSpamText() async {
    if (!_isBiliRoom) {
      SmartDialog.showToast("当前平台暂不支持自动发送");
      return;
    }
    final settings = AppSettingsController.instance;
    final message = settings.autoSpamTextMsg.value.trim();
    if (message.isEmpty) {
      SmartDialog.showToast("请输入自动发送内容");
      return;
    }
    final interval = settings.autoSpamTextInterval.value;
    if (interval <= 0) {
      SmartDialog.showToast("发送间隔需大于 0 秒");
      return;
    }
    final chunkSize = settings.autoSpamTextChunkSize.value;
    final messages = _splitAutoSpamText(message, chunkSize);
    if (messages.isEmpty) {
      SmartDialog.showToast("自动发送内容为空");
      return;
    }
    stopAutoSpamText();
    autoSpamTextRunning.value = true;
    _autoSpamTextIndex = 0;
    _autoSpamTextFailCount = 0;
    final duration = settings.autoSpamTextDuration.value;
    Future<void> sendNext() async {
      if (!autoSpamTextRunning.value) {
        return;
      }
      final text = messages[_autoSpamTextIndex];
      final success = await _sendAutoText(text);
      if (!success) {
        _autoSpamTextFailCount += 1;
        if (_autoSpamTextFailCount >= _autoSpamFailLimit) {
          stopAutoSpamText();
          SmartDialog.showToast("自动发送失败次数过多，已停止");
          return;
        }
      } else {
        _autoSpamTextFailCount = 0;
      }
      _autoSpamTextIndex = (_autoSpamTextIndex + 1) % messages.length;
    }

    await sendNext();
    _autoSpamTextTimer =
        Timer.periodic(Duration(seconds: interval), (_) => sendNext());
    if (duration > 0) {
      _autoSpamTextLimitTimer = Timer(
        Duration(seconds: duration),
        () {
          stopAutoSpamText();
        },
      );
    }
  }

  Future<void> startAutoSpamEmotion() async {
    if (!_isBiliRoom) {
      SmartDialog.showToast("当前平台暂不支持自动发送");
      return;
    }
    final settings = AppSettingsController.instance;
    final emotions = settings.autoSpamEmotions;
    if (emotions.isEmpty) {
      SmartDialog.showToast("请先选择表情包");
      return;
    }
    final interval = settings.autoSpamEmotionInterval.value;
    if (interval <= 0) {
      SmartDialog.showToast("发送间隔需大于 0 秒");
      return;
    }
    stopAutoSpamEmotion();
    autoSpamEmotionRunning.value = true;
    _autoSpamEmotionIndex = 0;
    _autoSpamEmotionFailCount = 0;
    final duration = settings.autoSpamEmotionDuration.value;
    Future<void> sendNext() async {
      if (!autoSpamEmotionRunning.value) {
        return;
      }
      final item = emotions[_autoSpamEmotionIndex];
      final text = item['text']?.toString() ?? '';
      final options = item['emoticonOptions'] is Map
          ? Map<String, dynamic>.from(item['emoticonOptions'])
          : null;
      if (text.isEmpty) {
        _autoSpamEmotionIndex = (_autoSpamEmotionIndex + 1) % emotions.length;
        return;
      }
      final success = await _sendAutoEmotion(text, emoticonOptions: options);
      if (!success) {
        _autoSpamEmotionFailCount += 1;
        if (_autoSpamEmotionFailCount >= _autoSpamFailLimit) {
          stopAutoSpamEmotion();
          SmartDialog.showToast("自动发送失败次数过多，已停止");
          return;
        }
      } else {
        _autoSpamEmotionFailCount = 0;
      }
      _autoSpamEmotionIndex = (_autoSpamEmotionIndex + 1) % emotions.length;
    }

    await sendNext();
    _autoSpamEmotionTimer =
        Timer.periodic(Duration(seconds: interval), (_) => sendNext());
    if (duration > 0) {
      _autoSpamEmotionLimitTimer = Timer(
        Duration(seconds: duration),
        () {
          stopAutoSpamEmotion();
        },
      );
    }
  }

  Future<void> startAutoSpamFavorites() async {
    if (!_isBiliRoom) {
      SmartDialog.showToast("当前平台暂不支持自动发送");
      return;
    }
    final settings = AppSettingsController.instance;
    final favorites = settings.autoSpamFavorites;
    if (favorites.isEmpty) {
      SmartDialog.showToast("请先添加收藏夹弹幕");
      return;
    }
    final interval = settings.autoSpamFavoritesInterval.value;
    if (interval <= 0) {
      SmartDialog.showToast("发送间隔需大于 0 秒");
      return;
    }
    final chunkSize = settings.autoSpamTextChunkSize.value;
    final messages = <String>[];
    for (final item in favorites) {
      final msg = item['msg']?.toString() ?? '';
      if (msg.trim().isEmpty) {
        continue;
      }
      messages.addAll(_splitAutoSpamText(msg, chunkSize));
    }
    if (messages.isEmpty) {
      SmartDialog.showToast("收藏夹弹幕为空");
      return;
    }
    stopAutoSpamFavorites();
    autoSpamFavoritesRunning.value = true;
    _autoSpamFavoritesIndex = 0;
    _autoSpamFavoritesFailCount = 0;
    final duration = settings.autoSpamFavoritesDuration.value;
    Future<void> sendNext() async {
      if (!autoSpamFavoritesRunning.value) {
        return;
      }
      final text = messages[_autoSpamFavoritesIndex];
      final success = await _sendAutoText(text);
      if (!success) {
        _autoSpamFavoritesFailCount += 1;
        if (_autoSpamFavoritesFailCount >= _autoSpamFailLimit) {
          stopAutoSpamFavorites();
          SmartDialog.showToast("自动发送失败次数过多，已停止");
          return;
        }
      } else {
        _autoSpamFavoritesFailCount = 0;
      }
      _autoSpamFavoritesIndex = (_autoSpamFavoritesIndex + 1) % messages.length;
    }

    await sendNext();
    _autoSpamFavoritesTimer =
        Timer.periodic(Duration(seconds: interval), (_) => sendNext());
    if (duration > 0) {
      _autoSpamFavoritesLimitTimer = Timer(
        Duration(seconds: duration),
        () {
          stopAutoSpamFavorites();
        },
      );
    }
  }

  String _getEmoticonPackageId(dynamic pkg, int index) {
    if (pkg is Map) {
      final id = pkg['pkg_id'] ?? pkg['pkg_name'] ?? '';
      final value = id.toString();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return "index_$index";
  }

  String _getEmoticonPackageName(dynamic pkg) {
    if (pkg is Map) {
      final name = pkg['pkg_name'];
      if (name != null) {
        return name.toString();
      }
    }
    return "未知";
  }

  String _getEmoticonPackageCover(dynamic pkg) {
    if (pkg is Map) {
      final cover = pkg['current_cover'];
      if (cover != null) {
        return cover.toString();
      }
    }
    return "";
  }

  String _getEmoticonId(dynamic emoticon, int index) {
    if (emoticon is Map) {
      final id =
          emoticon['emoticon_unique'] ?? emoticon['text'] ?? emoticon['id'];
      final value = id?.toString() ?? '';
      if (value.isNotEmpty) {
        return value;
      }
    }
    return "index_$index";
  }

  String _getEmoticonText(dynamic emoticon) {
    if (emoticon is Map) {
      final text = emoticon['emoticon_unique'] ?? emoticon['text'] ?? '';
      return text.toString();
    }
    return "";
  }

  String _getEmoticonUrl(dynamic emoticon) {
    if (emoticon is Map) {
      final url = emoticon['url'] ?? '';
      return url.toString();
    }
    return "";
  }

  Map<String, dynamic>? _getEmoticonOptions(dynamic emoticon) {
    if (emoticon is Map && emoticon['emoticon_options'] is Map) {
      return Map<String, dynamic>.from(emoticon['emoticon_options']);
    }
    return null;
  }

  List<dynamic> _filterEmoticonPackages(List<dynamic> packages) {
    final filtered = <dynamic>[];
    for (var i = 0; i < packages.length; i++) {
      final pkg = packages[i];
      final id = _getEmoticonPackageId(pkg, i);
      if (AppSettingsController.instance.isEmoticonPackageEnabled(id)) {
        filtered.add(pkg);
      }
    }
    return filtered;
  }

  Future<List<dynamic>?> getEmoticons({bool applyFilter = true}) async {
    if (site.id != Constant.kBiliBili) {
      SmartDialog.showToast("当前平台暂不支持发送表情包");
      return null;
    }

    // 获取表情包列表
    var emoticons = await BiliBiliAccountService.instance.getEmoticons(
      detail.value?.roomId ?? roomId,
    );

    if (emoticons == null) {
      SmartDialog.showToast("获取表情包列表失败");
      return null;
    }

    // 确保 emoticons 是列表
    if (emoticons is! List) {
      SmartDialog.showToast("获取表情包列表失败");
      return null;
    }

    if (emoticons.isEmpty) {
      SmartDialog.showToast("暂无可用表情包");
      return null;
    }

    final packages =
        applyFilter ? _filterEmoticonPackages(emoticons) : emoticons;
    if (packages.isEmpty) {
      SmartDialog.showToast("暂无可用表情包");
      return null;
    }

    return packages;
  }

  Future<void> showEmotionPanel() async {
    var emoticonPackages = await getEmoticons();
    if (emoticonPackages == null) {
      return;
    }

    if (emoticonPackages.isEmpty) {
      return;
    }

    Utils.showBottomSheet(
      title: "选择表情包",
      child: DefaultTabController(
        length: emoticonPackages.length,
        child: Column(
          children: [
            TabBar(
              isScrollable: true,
              tabs: emoticonPackages.map((pkg) {
                var cover = _getEmoticonPackageCover(pkg);
                return Tab(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: cover.isNotEmpty
                        ? NetImage(
                            cover,
                            width: 32,
                            height: 32,
                            borderRadius: 4,
                          )
                        : Text(_getEmoticonPackageName(pkg)),
                  ),
                );
              }).toList(),
            ),
            Expanded(
              child: TabBarView(
                children: emoticonPackages.map((pkg) {
                  dynamic emoticons;
                  if (pkg is Map) {
                    emoticons = pkg['emoticons'];
                  }
                  final emoticonList =
                      emoticons is List ? emoticons : <dynamic>[];

                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    padding: AppStyle.edgeInsetsA12,
                    itemCount: emoticonList.length,
                    itemBuilder: (context, index) {
                      var emoticon = emoticonList[index];
                      var url = '';
                      var text = '';
                      if (emoticon is Map) {
                        url = emoticon['url'] ?? '';
                        text = emoticon['emoticon_unique'] ??
                            emoticon['text'] ??
                            '';
                      }

                      return GestureDetector(
                        onTap: () {
                          Get.back();
                          sendEmotionMessage(text);
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          child: NetImage(
                            url,
                            width: 48,
                            height: 48,
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmoticonPackageSettingsContent(List<dynamic> emoticonPackages) {
    return ListView.builder(
      padding: AppStyle.edgeInsetsV12,
      itemCount: emoticonPackages.length,
      itemBuilder: (context, index) {
        final pkg = emoticonPackages[index];
        final id = _getEmoticonPackageId(pkg, index);
        final title = _getEmoticonPackageName(pkg);
        final subtitle = id == title ? null : "ID: $id";
        return Obx(
          () => SettingsSwitch(
            value: AppSettingsController.instance.isEmoticonPackageEnabled(id),
            title: title,
            subtitle: subtitle,
            onChanged: (value) {
              AppSettingsController.instance
                  .setEmoticonPackageEnabled(id, value);
            },
          ),
        );
      },
    );
  }

  Future<void> showEmoticonPackageSettingsSheet() async {
    var emoticonPackages = await getEmoticons(applyFilter: false);
    if (emoticonPackages == null) {
      return;
    }

    if (emoticonPackages.isEmpty) {
      SmartDialog.showToast("暂无可用表情包");
      return;
    }

    final child = _buildEmoticonPackageSettingsContent(emoticonPackages);
    if (_shouldUseDesktopWorkspace()) {
      Utils.showRightDialog(
        title: "表情包筛选",
        width: 420,
        useSystem: true,
        child: child,
      );
      return;
    }
    Utils.showBottomSheet(title: "表情包筛选", child: child);
  }

  Future<void> showAutoSpamEmotionsSheet() async {
    var emoticonPackages = await getEmoticons();
    if (emoticonPackages == null || emoticonPackages.isEmpty) {
      SmartDialog.showToast("暂无可用表情包");
      return;
    }
    Utils.showBottomSheet(
      title: "选择自动发送表情",
      child: DefaultTabController(
        length: emoticonPackages.length,
        child: Column(
          children: [
            TabBar(
              isScrollable: true,
              tabs: emoticonPackages.map((pkg) {
                var cover = _getEmoticonPackageCover(pkg);
                return Tab(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: cover.isNotEmpty
                        ? NetImage(
                            cover,
                            width: 32,
                            height: 32,
                            borderRadius: 4,
                          )
                        : Text(_getEmoticonPackageName(pkg)),
                  ),
                );
              }).toList(),
            ),
            Padding(
              padding: AppStyle.edgeInsetsA12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Obx(
                    () => Text(
                      "已选 ${AppSettingsController.instance.autoSpamEmotions.length} 个",
                      style: Get.textTheme.bodySmall,
                    ),
                  ),
                  TextButton(
                    onPressed:
                        AppSettingsController.instance.clearAutoSpamEmotions,
                    child: const Text("清空"),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: emoticonPackages.map((pkg) {
                  dynamic emoticons;
                  if (pkg is Map) {
                    emoticons = pkg['emoticons'];
                  }
                  final emoticonList =
                      emoticons is List ? emoticons : <dynamic>[];
                  return Obx(
                    () {
                      final selectedIds = AppSettingsController
                          .instance.autoSpamEmotions
                          .map((e) => e['id']?.toString() ?? '')
                          .where((e) => e.isNotEmpty)
                          .toSet();
                      return GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                        ),
                        padding: AppStyle.edgeInsetsA12,
                        itemCount: emoticonList.length,
                        itemBuilder: (context, index) {
                          final emoticon = emoticonList[index];
                          final id = _getEmoticonId(emoticon, index);
                          final text = _getEmoticonText(emoticon);
                          final url = _getEmoticonUrl(emoticon);
                          final options = _getEmoticonOptions(emoticon);
                          final selected = selectedIds.contains(id);
                          return GestureDetector(
                            onTap: () {
                              AppSettingsController.instance
                                  .toggleAutoSpamEmotion(
                                {
                                  'id': id,
                                  'text': text,
                                  'url': url,
                                  if (options != null)
                                    'emoticonOptions': options,
                                },
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: AppStyle.radius8,
                                border: Border.all(
                                  color: selected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey.withAlpha(60),
                                ),
                                color: selected
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withAlpha(24)
                                    : Colors.transparent,
                              ),
                              padding: AppStyle.edgeInsetsA4,
                              child: Stack(
                                children: [
                                  Align(
                                    child: NetImage(
                                      url,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  if (selected)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Icon(
                                        Icons.check_circle,
                                        size: 16,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAutoSpamBottomSheet({
    required String title,
    required Widget child,
  }) async {
    final shouldRestoreGhost = ghostModeState.value;
    if (shouldRestoreGhost) {
      await allowMainWindowInteractionForGhost();
    }
    await Utils.showBottomSheet(
      title: title,
      child: child,
    );
    if (shouldRestoreGhost) {
      await restoreGhostInteractionAfterMainWindow();
    }
  }

  Widget _buildAutoSpamEntry({
    required IconData icon,
    required String title,
    required RxBool running,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: AppStyle.edgeInsetsV12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon),
              AppStyle.vGap8,
              Text(title),
              AppStyle.vGap4,
              Obx(
                () => Text(
                  running.value ? "运行中" : "已停止",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> showAutoSpamSheet() async {
    await _showAutoSpamBottomSheet(
      title: "自动发送",
      child: ListView(
        padding: AppStyle.edgeInsetsA12,
        children: [
          SettingsCard(
            child: Row(
              children: [
                _buildAutoSpamEntry(
                  icon: Icons.message_outlined,
                  title: "文字弹幕",
                  running: autoSpamTextRunning,
                  onTap: () {
                    Get.back();
                    showAutoSpamTextSheet();
                  },
                ),
                Container(
                  width: 1,
                  height: 52,
                  color: Colors.grey.withAlpha(40),
                ),
                _buildAutoSpamEntry(
                  icon: Icons.emoji_emotions_outlined,
                  title: "表情包",
                  running: autoSpamEmotionRunning,
                  onTap: () {
                    Get.back();
                    showAutoSpamEmotionSheet();
                  },
                ),
                Container(
                  width: 1,
                  height: 52,
                  color: Colors.grey.withAlpha(40),
                ),
                _buildAutoSpamEntry(
                  icon: Icons.bookmarks_outlined,
                  title: "收藏夹",
                  running: autoSpamFavoritesRunning,
                  onTap: () {
                    Get.back();
                    showAutoSpamFavoritesSheet();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> showAutoSpamTextSheet() async {
    final settings = AppSettingsController.instance;
    final textController =
        TextEditingController(text: settings.autoSpamTextMsg.value);
    await _showAutoSpamBottomSheet(
      title: "文字弹幕",
      child: ListView(
        padding: AppStyle.edgeInsetsA12,
        children: [
          SettingsCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Obx(
                  () => ListTile(
                    title: const Text("文字弹幕"),
                    subtitle: Text(
                      autoSpamTextRunning.value ? "运行中" : "已停止",
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: autoSpamTextRunning.value
                              ? null
                              : startAutoSpamText,
                          child: const Text("开始"),
                        ),
                        TextButton(
                          onPressed: autoSpamTextRunning.value
                              ? stopAutoSpamText
                              : null,
                          child: const Text("停止"),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: AppStyle.edgeInsetsH12,
                  child: TextField(
                    controller: textController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "输入自动发送弹幕内容",
                      border: OutlineInputBorder(
                        borderRadius: AppStyle.radius12,
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.withAlpha(25),
                      contentPadding: AppStyle.edgeInsetsH12,
                    ),
                    onChanged: settings.setAutoSpamTextMsg,
                  ),
                ),
                AppStyle.vGap8,
                Obx(
                  () => SettingsNumber(
                    title: "发送间隔",
                    value: settings.autoSpamTextInterval.value,
                    min: 1,
                    max: 300,
                    unit: "秒",
                    onChanged: settings.setAutoSpamTextInterval,
                  ),
                ),
                AppStyle.divider,
                Obx(
                  () => SettingsNumber(
                    title: "单条长度",
                    value: settings.autoSpamTextChunkSize.value,
                    min: 5,
                    max: 60,
                    onChanged: settings.setAutoSpamTextChunkSize,
                  ),
                ),
                AppStyle.divider,
                Obx(
                  () => SettingsNumber(
                    title: "持续时长",
                    value: settings.autoSpamTextDuration.value,
                    min: 0,
                    max: 3600,
                    unit: "秒",
                    onChanged: settings.setAutoSpamTextDuration,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> showAutoSpamEmotionSheet() async {
    final settings = AppSettingsController.instance;
    await _showAutoSpamBottomSheet(
      title: "表情包",
      child: ListView(
        padding: AppStyle.edgeInsetsA12,
        children: [
          SettingsCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Obx(
                  () => ListTile(
                    title: const Text("表情包"),
                    subtitle: Text(
                      autoSpamEmotionRunning.value ? "运行中" : "已停止",
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: autoSpamEmotionRunning.value
                              ? null
                              : startAutoSpamEmotion,
                          child: const Text("开始"),
                        ),
                        TextButton(
                          onPressed: autoSpamEmotionRunning.value
                              ? stopAutoSpamEmotion
                              : null,
                          child: const Text("停止"),
                        ),
                      ],
                    ),
                  ),
                ),
                ListTile(
                  title: const Text("选择表情"),
                  subtitle: Obx(
                    () => Text(
                      "已选 ${settings.autoSpamEmotions.length} 个",
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: showAutoSpamEmotionsSheet,
                ),
                AppStyle.divider,
                Obx(
                  () => SettingsNumber(
                    title: "发送间隔",
                    value: settings.autoSpamEmotionInterval.value,
                    min: 1,
                    max: 300,
                    unit: "秒",
                    onChanged: settings.setAutoSpamEmotionInterval,
                  ),
                ),
                AppStyle.divider,
                Obx(
                  () => SettingsNumber(
                    title: "持续时长",
                    value: settings.autoSpamEmotionDuration.value,
                    min: 0,
                    max: 3600,
                    unit: "秒",
                    onChanged: settings.setAutoSpamEmotionDuration,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> showAutoSpamFavoritesSheet() async {
    final settings = AppSettingsController.instance;
    final favoriteController = TextEditingController(
      text: settings.autoSpamFavorites.isNotEmpty
          ? settings.autoSpamFavorites[settings.autoSpamFavoritesIndex.value]
                      ['msg']
                  ?.toString() ??
              ''
          : '',
    );
    await _showAutoSpamBottomSheet(
      title: "收藏夹",
      child: ListView(
        padding: AppStyle.edgeInsetsA12,
        children: [
          SettingsCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Obx(
                  () => ListTile(
                    title: const Text("收藏夹"),
                    subtitle: Text(
                      autoSpamFavoritesRunning.value ? "运行中" : "已停止",
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: autoSpamFavoritesRunning.value
                              ? null
                              : startAutoSpamFavorites,
                          child: const Text("开始"),
                        ),
                        TextButton(
                          onPressed: autoSpamFavoritesRunning.value
                              ? stopAutoSpamFavorites
                              : null,
                          child: const Text("停止"),
                        ),
                      ],
                    ),
                  ),
                ),
                ListTile(
                  title: const Text("分组管理"),
                  trailing: TextButton(
                    onPressed: settings.addAutoSpamFavorite,
                    child: const Text("新增"),
                  ),
                ),
                Obx(
                  () => Column(
                    children: List.generate(
                      settings.autoSpamFavorites.length,
                      (index) {
                        final item = settings.autoSpamFavorites[index];
                        final name =
                            item['name']?.toString() ?? "分组${index + 1}";
                        final selected =
                            settings.autoSpamFavoritesIndex.value == index;
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: selected
                                ? Theme.of(Get.context!).colorScheme.primary
                                : null,
                          ),
                          title: Text(name),
                          onTap: () {
                            settings.setAutoSpamFavoritesIndex(index);
                            final msg = settings.autoSpamFavorites[index]['msg']
                                    ?.toString() ??
                                '';
                            if (favoriteController.text != msg) {
                              favoriteController.text = msg;
                            }
                          },
                          trailing: IconButton(
                            onPressed: () {
                              settings.removeAutoSpamFavorite(index);
                              final currentIndex =
                                  settings.autoSpamFavoritesIndex.value;
                              final msg = settings
                                      .autoSpamFavorites[currentIndex]['msg']
                                      ?.toString() ??
                                  '';
                              if (favoriteController.text != msg) {
                                favoriteController.text = msg;
                              }
                            },
                            icon: const Icon(Icons.delete_outline),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: AppStyle.edgeInsetsH12,
                  child: Obx(
                    () {
                      final currentIndex =
                          settings.autoSpamFavoritesIndex.value;
                      final currentMsg = settings
                              .autoSpamFavorites[currentIndex]['msg']
                              ?.toString() ??
                          '';
                      if (favoriteController.text != currentMsg) {
                        favoriteController.text = currentMsg;
                      }
                      return TextField(
                        controller: favoriteController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: "输入当前分组弹幕内容",
                          border: OutlineInputBorder(
                            borderRadius: AppStyle.radius12,
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.withAlpha(25),
                          contentPadding: AppStyle.edgeInsetsH12,
                        ),
                        onChanged: (value) {
                          settings.updateAutoSpamFavoriteMessage(
                            currentIndex,
                            value,
                          );
                        },
                      );
                    },
                  ),
                ),
                AppStyle.vGap8,
                Obx(
                  () => SettingsNumber(
                    title: "发送间隔",
                    value: settings.autoSpamFavoritesInterval.value,
                    min: 1,
                    max: 300,
                    unit: "秒",
                    onChanged: settings.setAutoSpamFavoritesInterval,
                  ),
                ),
                AppStyle.divider,
                Obx(
                  () => SettingsNumber(
                    title: "持续时长",
                    value: settings.autoSpamFavoritesDuration.value,
                    min: 0,
                    max: 3600,
                    unit: "秒",
                    onChanged: settings.setAutoSpamFavoritesDuration,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void onInit() {
    WidgetsBinding.instance.addObserver(this);
    if (FollowService.instance.followList.isEmpty) {
      FollowService.instance.loadData();
    }
    initAutoExit();
    showDanmakuState.value = AppSettingsController.instance.danmuEnable.value;
    subtitleEnabled.value = AppSettingsController.instance.subtitleEnable.value;
    followed.value = DBService.instance.getFollowExist("${site.id}_$roomId");
    loadData();

    scrollController.addListener(scrollListener);
    if (!Platform.isAndroid) {
      WindowManagerPlus.current.addListener(this);
    }
    _subtitleWorkers.add(
      ever(AppSettingsController.instance.subtitleEnable, (value) {
        subtitleEnabled.value = value;
        if (value) {
          startVoiceRecognition();
        } else {
          stopVoiceRecognition();
        }
        sendGhostConfig();
      }),
    );
    _subtitleWorkers.add(
      ever(AppSettingsController.instance.subtitleModelName, (value) {
        if (subtitleEnabled.value &&
            AppSettingsController.instance.subtitleRecognitionMode.value ==
                SubtitleRecognitionMode.local) {
          restartVoiceRecognition();
        }
      }),
    );
    _subtitleWorkers.add(
      ever(AppSettingsController.instance.subtitleRecognitionMode, (value) {
        if (subtitleEnabled.value) {
          restartVoiceRecognition();
        }
      }),
    );
    _subtitleWorkers.add(
      ever(AppSettingsController.instance.subtitleOnlineProvider, (value) {
        if (subtitleEnabled.value &&
            AppSettingsController.instance.subtitleRecognitionMode.value ==
                SubtitleRecognitionMode.online) {
          restartVoiceRecognition();
        }
      }),
    );
    _subtitleWorkers.add(
      ever(AppSettingsController.instance.subtitleOnlineApiUrl, (value) {
        if (subtitleEnabled.value &&
            AppSettingsController.instance.subtitleRecognitionMode.value ==
                SubtitleRecognitionMode.online) {
          restartVoiceRecognition();
        }
      }),
    );
    _subtitleWorkers.add(
      ever(AppSettingsController.instance.subtitleOnlineApiKey, (value) {
        if (subtitleEnabled.value &&
            AppSettingsController.instance.subtitleRecognitionMode.value ==
                SubtitleRecognitionMode.online) {
          restartVoiceRecognition();
        }
      }),
    );
    _subtitleWorkers.add(
      ever(AppSettingsController.instance.subtitleOnlineApiKeyHeader, (value) {
        if (subtitleEnabled.value &&
            AppSettingsController.instance.subtitleRecognitionMode.value ==
                SubtitleRecognitionMode.online) {
          restartVoiceRecognition();
        }
      }),
    );
    _subtitleWorkers.add(
      ever(liveStatus, (value) {
        if (!value) {
          stopVoiceRecognition();
        } else if (subtitleEnabled.value) {
          startVoiceRecognition();
        }
      }),
    );
    if (subtitleEnabled.value) {
      startVoiceRecognition();
    }

    super.onInit();
  }

  String? _resolveSubtitlePlayUrl() {
    if (currentLineIndex < 0 || currentLineIndex >= playUrls.length) {
      return null;
    }
    var url = playUrls[currentLineIndex];
    if (AppSettingsController.instance.playerForceHttps.value) {
      url = url.replaceAll("http://", "https://");
    }
    return url;
  }

  Future<void> _readSubtitleAudioDump() async {
    if (_subtitleAudioStopping) {
      return;
    }
    if (_subtitleAudioReader == null ||
        _subtitleAudioStreamController == null) {
      return;
    }
    try {
      final length = await _subtitleAudioReader!.length();
      if (length <= _subtitleAudioOffset) {
        return;
      }
      await _subtitleAudioReader!.setPosition(_subtitleAudioOffset);
      final bytes =
          await _subtitleAudioReader!.read(length - _subtitleAudioOffset);
      _subtitleAudioOffset = length;
      if (bytes.isEmpty) {
        return;
      }
      var data = bytes;
      if (!_subtitleAudioHeaderSkipped && data.length >= 12) {
        if (data[0] == 0x52 &&
            data[1] == 0x49 &&
            data[2] == 0x46 &&
            data[3] == 0x46 &&
            data[8] == 0x57 &&
            data[9] == 0x41 &&
            data[10] == 0x56 &&
            data[11] == 0x45) {
          if (data.length <= 44) {
            _subtitleAudioHeaderSkipped = true;
            return;
          }
          data = data.sublist(44);
          _subtitleAudioHeaderSkipped = true;
        }
      }
      if (_subtitleAudioStopping) {
        return;
      }
      _subtitleAudioStreamController?.add(Uint8List.fromList(data));
    } catch (_) {
      return;
    }
  }

  Future<Stream<Uint8List>?> _startSubtitleAudioCapture() async {
    final url = _resolveSubtitlePlayUrl();
    if (url == null) {
      return null;
    }
    await _stopSubtitleAudioCapture();
    _subtitleAudioStopping = false;
    final tempPath = Directory.systemTemp.path;
    final cacheDir = Directory(
      "$tempPath${Platform.pathSeparator}simple_live_cache",
    );
    if (!cacheDir.existsSync()) {
      cacheDir.createSync(recursive: true);
    }
    final dumpFile = File(
      "$tempPath${Platform.pathSeparator}simple_live_subtitle_audio.pcm",
    );
    if (await dumpFile.exists()) {
      await dumpFile.writeAsBytes(const [], flush: true);
    } else {
      await dumpFile.create(recursive: true);
    }
    _subtitleAudioDumpFile = dumpFile;
    _subtitleAudioOffset = 0;
    _subtitleAudioHeaderSkipped = false;
    _subtitleAudioReader = await dumpFile.open(mode: FileMode.read);
    _subtitleAudioStreamController = StreamController<Uint8List>();
    _subtitleAudioReadTimer = Timer.periodic(
      const Duration(milliseconds: 80),
      (_) => _readSubtitleAudioDump(),
    );
    final native = _subtitleAudioPlayer.platform as NativePlayer;
    await native.setProperty('vid', 'no');
    await native.setProperty('sid', 'no');
    await native.setProperty('audio-format', 's16');
    await native.setProperty('audio-samplerate', '16000');
    await native.setProperty('audio-channels', 'mono');
    await native.setProperty('ao', 'pcm');
    await native.setProperty('ao-pcm-file', dumpFile.path);
    await native.setProperty('ao-pcm-waveheader', 'no');
    await native.setProperty('cache', 'no');
    await native.setProperty('cache-dir', cacheDir.path);
    await _subtitleAudioPlayer.open(
      Media(url, httpHeaders: playHeaders),
    );
    return _subtitleAudioStreamController!.stream;
  }

  Future<void> _stopSubtitleAudioCapture() async {
    if (_subtitleAudioStopTask != null) {
      await _subtitleAudioStopTask;
      return;
    }
    _subtitleAudioStopTask = _doStopSubtitleAudioCapture();
    await _subtitleAudioStopTask;
    _subtitleAudioStopTask = null;
  }

  Future<void> _doStopSubtitleAudioCapture() async {
    _subtitleAudioStopping = true;
    _subtitleAudioReadTimer?.cancel();
    _subtitleAudioReadTimer = null;
    try {
      await _subtitleAudioStreamController?.close();
    } catch (_) {}
    _subtitleAudioStreamController = null;
    try {
      await _subtitleAudioReader?.close();
    } catch (_) {}
    _subtitleAudioReader = null;
    _subtitleAudioOffset = 0;
    _subtitleAudioHeaderSkipped = false;
    try {
      await _subtitleAudioPlayer.stop();
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 80));
    if (_subtitleAudioDumpFile != null) {
      try {
        if (await _subtitleAudioDumpFile!.exists()) {
          await _subtitleAudioDumpFile!.delete();
        }
      } catch (_) {}
    }
    _subtitleAudioDumpFile = null;
  }

  Future<void> startVoiceRecognition() async {
    if (!liveStatus.value) {
      return;
    }
    if (_voiceRecognitionService.isRunning) {
      return;
    }
    final audioStream = await _startSubtitleAudioCapture();
    if (audioStream == null) {
      return;
    }
    try {
      await _voiceRecognitionService.startFromAudioStream(
        modelName: AppSettingsController.instance.subtitleModelName.value,
        audioStream: audioStream,
        onResult: _handleSubtitleResult,
        onError: (error) {
          SmartDialog.showToast("语音识别错误: $error");
        },
      );
    } catch (e) {
      SmartDialog.showToast("启动语音识别失败: $e");
    }
  }

  Future<void> stopVoiceRecognition() async {
    _subtitleDelayTimer?.cancel();
    _subtitleDelayTimer = null;
    _pendingSubtitleResult = null;
    _subtitleClearTimer?.cancel();
    subtitleText.value = "";
    subtitleIsPartial.value = false;
    _sendGhostSubtitle("", false);
    await _stopSubtitleAudioCapture();
    await _voiceRecognitionService.stop();
  }

  Future<void> restartVoiceRecognition() async {
    await stopVoiceRecognition();
    await startVoiceRecognition();
  }

  void _handleSubtitleResult(VoiceRecognitionResult result) {
    final delayMs = AppSettingsController.instance.subtitleDelay.value.toInt();
    if (delayMs <= 0) {
      _applySubtitleResult(result);
      return;
    }
    _pendingSubtitleResult = result;
    if (_subtitleDelayTimer != null) {
      return;
    }
    _subtitleDelayTimer = Timer(Duration(milliseconds: delayMs), () {
      _subtitleDelayTimer = null;
      final pending = _pendingSubtitleResult;
      if (pending == null) {
        return;
      }
      _pendingSubtitleResult = null;
      _applySubtitleResult(pending);
    });
  }

  void _applySubtitleResult(VoiceRecognitionResult result) {
    subtitleText.value = result.text;
    subtitleIsPartial.value = !result.isFinal;
    _sendGhostSubtitle(result.text, !result.isFinal);
    if (result.isFinal) {
      _subtitleClearTimer?.cancel();
      _subtitleClearTimer = Timer(
        const Duration(seconds: 4),
        () {
          if (!subtitleIsPartial.value) {
            subtitleText.value = "";
            _sendGhostSubtitle("", false);
          }
        },
      );
    }
  }

  void _sendGhostSubtitle(String text, bool partial) {
    if (!ghostModeState.value || ghostWindowId == null) {
      return;
    }
    try {
      WindowManagerPlus.current.invokeMethodToWindow(
        ghostWindowId!,
        'subtitle',
        {
          'text': text,
          'partial': partial,
        },
      );
    } catch (_) {}
  }

  void scrollListener() {
    if (scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      disableAutoScroll.value = true;
    }
  }

  /// 初始化自动关闭倒计时
  void initAutoExit() {
    if (AppSettingsController.instance.autoExitEnable.value) {
      autoExitEnable.value = true;
      autoExitMinutes.value =
          AppSettingsController.instance.autoExitDuration.value;
      setAutoExit();
    } else {
      autoExitMinutes.value =
          AppSettingsController.instance.roomAutoExitDuration.value;
    }
  }

  void setAutoExit() {
    if (!autoExitEnable.value) {
      autoExitTimer?.cancel();
      return;
    }
    autoExitTimer?.cancel();
    countdown.value = autoExitMinutes.value * 60;
    autoExitTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      countdown.value -= 1;
      if (countdown.value <= 0) {
        timer = Timer(const Duration(seconds: 10), () async {
          await WakelockPlus.disable();
          exit(0);
        });
        autoExitTimer?.cancel();
        var delay = await Utils.showAlertDialog("定时关闭已到时,是否延迟关闭?",
            title: "延迟关闭", confirm: "延迟", cancel: "关闭", selectable: true);
        if (delay) {
          timer.cancel();
          delayAutoExit.value = true;
          showAutoExitSheet();
          setAutoExit();
        } else {
          delayAutoExit.value = false;
          await WakelockPlus.disable();
          exit(0);
        }
      }
    });
  }
  // 弹窗逻辑

  void refreshRoom() {
    //messages.clear();
    superChats.clear();
    liveDanmaku.stop();

    loadData();
  }

  /// 聊天栏始终滚动到底部
  void chatScrollToBottom() {
    if (scrollController.hasClients) {
      // 如果手动上拉过，就不自动滚动到底部
      if (disableAutoScroll.value) {
        return;
      }
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
    }
  }

  /// 初始化弹幕接收事件
  void initDanmau() {
    liveDanmaku.onMessage = onWSMessage;
    liveDanmaku.onClose = onWSClose;
    liveDanmaku.onReady = onWSReady;
  }

  /// 接收到WebSocket信息
  void onWSMessage(LiveMessage msg) {
    if (msg.type == LiveMessageType.chat) {
      if (messages.length > 200 && !disableAutoScroll.value) {
        messages.removeAt(0);
      }

      // 关键词屏蔽检查
      for (var keyword in AppSettingsController.instance.shieldList) {
        Pattern? pattern;
        if (Utils.isRegexFormat(keyword)) {
          String removedSlash = Utils.removeRegexFormat(keyword);
          try {
            pattern = RegExp(removedSlash);
          } catch (e) {
            // should avoid this during add keyword
            Log.d("关键词：$keyword 正则格式错误");
          }
        } else {
          pattern = keyword;
        }
        if (pattern != null && msg.message.contains(pattern)) {
          Log.d("关键词：$keyword\n已屏蔽消息内容：${msg.message}");
          return;
        }
      }

      messages.add(msg);

      WidgetsBinding.instance.addPostFrameCallback(
        (_) => chatScrollToBottom(),
      );
      if (!liveStatus.value || isBackground) {
        return;
      }

      final item = DanmakuContentItem(
        msg.message,
        color: Color.fromARGB(
          255,
          msg.color.r,
          msg.color.g,
          msg.color.b,
        ),
      );
      sendDanmakuToGhostWindow(item, userName: msg.userName);
      addDanmaku([item]);
    } else if (msg.type == LiveMessageType.online) {
      online.value = msg.data;
    } else if (msg.type == LiveMessageType.superChat) {
      superChats.add(msg.data);
    }
  }

  /// 添加一条系统消息
  void addSysMsg(String msg) {
    messages.add(
      LiveMessage(
        type: LiveMessageType.chat,
        userName: "LiveSysMessage",
        message: msg,
        color: LiveMessageColor.white,
      ),
    );
  }

  /// 接收到WebSocket关闭信息
  void onWSClose(String msg) {
    addSysMsg(msg);
  }

  /// WebSocket准备就绪
  void onWSReady() {
    addSysMsg("弹幕服务器连接正常");
  }

  /// 加载直播间信息
  void loadData() async {
    try {
      SmartDialog.showLoading(msg: "");
      loadError.value = false;
      error = null;
      errorStackTrace = null;
      update();
      addSysMsg("正在读取直播间信息");
      detail.value = await site.liveSite.getRoomDetail(roomId: roomId);

      getSuperChatMessage();

      addHistory();
      // 确认房间关注状态
      followed.value = DBService.instance.getFollowExist("${site.id}_$roomId");
      online.value = detail.value!.online;
      liveStatus.value = detail.value!.status || detail.value!.isRecord;
      if (liveStatus.value) {
        getPlayQualites();
      }
      if (detail.value!.isRecord) {
        addSysMsg("当前主播未开播，正在轮播录像");
      }
      addSysMsg("开始连接弹幕服务器");
      initDanmau();
      liveDanmaku.start(detail.value?.danmakuData);
      startLiveDurationTimer(); // 启动开播时长定时器
    } catch (e, stackTrace) {
      Log.logPrint(e);
      //SmartDialog.showToast(e.toString());
      loadError.value = true;
      error = e;
      errorStackTrace = stackTrace;
    } finally {
      SmartDialog.dismiss(status: SmartStatus.loading);
    }
  }

  /// 初始化播放器
  void getPlayQualites() async {
    qualites.clear();
    currentQuality = -1;

    try {
      var playQualites =
          await site.liveSite.getPlayQualites(detail: detail.value!);

      if (playQualites.isEmpty) {
        SmartDialog.showToast("无法读取播放清晰度");
        return;
      }
      qualites.value = playQualites;
      var qualityLevel = await getQualityLevel();
      if (qualityLevel == 2) {
        //最高
        currentQuality = 0;
      } else if (qualityLevel == 0) {
        //最低
        currentQuality = playQualites.length - 1;
      } else {
        //中间值
        int middle = (playQualites.length / 2).floor();
        currentQuality = middle;
      }

      getPlayUrl();
    } catch (e) {
      Log.logPrint(e);
      SmartDialog.showToast("无法读取播放清晰度");
    }
  }

  Future<int> getQualityLevel() async {
    var qualityLevel = AppSettingsController.instance.qualityLevel.value;
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult.first == ConnectivityResult.mobile) {
        qualityLevel =
            AppSettingsController.instance.qualityLevelCellular.value;
      }
    } catch (e) {
      Log.logPrint(e);
    }
    return qualityLevel;
  }

  void getPlayUrl() async {
    playUrls.clear();
    currentQualityInfo.value = qualites[currentQuality].quality;
    currentLineInfo.value = "";
    currentLineIndex = -1;
    var playUrl = await site.liveSite
        .getPlayUrls(detail: detail.value!, quality: qualites[currentQuality]);
    if (playUrl.urls.isEmpty) {
      SmartDialog.showToast("无法读取播放地址");
      return;
    }
    playUrls.value = playUrl.urls;
    playHeaders = playUrl.headers;
    currentLineIndex = 0;
    currentLineInfo.value = "线路${currentLineIndex + 1}";
    //重置错误次数
    mediaErrorRetryCount = 0;
    initPlaylist();
  }

  void changePlayLine(int index) {
    currentLineIndex = index;
    //重置错误次数
    mediaErrorRetryCount = 0;
    setPlayer();
  }

  void initPlaylist() async {
    currentLineInfo.value = "线路${currentLineIndex + 1}";
    errorMsg.value = "";

    final mediaList = playUrls.map((url) {
      var finalUrl = url;
      if (AppSettingsController.instance.playerForceHttps.value) {
        finalUrl = finalUrl.replaceAll("http://", "https://");
      }
      return Media(finalUrl, httpHeaders: playHeaders);
    }).toList();

    // 初始化播放器并设置 ao 参数
    await initializePlayer();
    if (Platform.isAndroid) {
      if (audioOnlyMode.value) {
        await applyAudioMode();
      }
    }

    await player.open(Playlist(mediaList));
    if (subtitleEnabled.value && liveStatus.value) {
      restartVoiceRecognition();
    }
  }

  void setPlayer() async {
    currentLineInfo.value = "线路${currentLineIndex + 1}";
    errorMsg.value = "";

    await player.jump(currentLineIndex);
    if (subtitleEnabled.value && liveStatus.value) {
      restartVoiceRecognition();
    }
  }

  @override
  void mediaEnd() async {
    super.mediaEnd();
    if (mediaErrorRetryCount < 2) {
      Log.d("播放结束，尝试第${mediaErrorRetryCount + 1}次刷新");
      if (mediaErrorRetryCount == 1) {
        //延迟一秒再刷新
        await Future.delayed(const Duration(seconds: 1));
      }
      mediaErrorRetryCount += 1;
      //刷新一次
      setPlayer();
      return;
    }

    Log.d("播放结束");
    // 遍历线路，如果全部链接都断开就是直播结束了
    if (playUrls.length - 1 == currentLineIndex) {
      liveStatus.value = false;
    } else {
      changePlayLine(currentLineIndex + 1);

      //setPlayer();
    }
  }

  int mediaErrorRetryCount = 0;
  @override
  void mediaError(String error) async {
    super.mediaEnd();
    if (mediaErrorRetryCount < 2) {
      Log.d("播放失败，尝试第${mediaErrorRetryCount + 1}次刷新");
      if (mediaErrorRetryCount == 1) {
        //延迟一秒再刷新
        await Future.delayed(const Duration(seconds: 1));
      }
      mediaErrorRetryCount += 1;
      //刷新一次
      setPlayer();
      return;
    }

    if (playUrls.length - 1 == currentLineIndex) {
      errorMsg.value = "播放失败";
      SmartDialog.showToast("播放失败:$error");
    } else {
      //currentLineIndex += 1;
      //setPlayer();
      changePlayLine(currentLineIndex + 1);
    }
  }

  /// 读取SC
  void getSuperChatMessage() async {
    try {
      var sc =
          await site.liveSite.getSuperChatMessage(roomId: detail.value!.roomId);
      superChats.addAll(sc);
    } catch (e) {
      Log.logPrint(e);
      addSysMsg("SC读取失败");
    }
  }

  /// 移除掉已到期的SC
  void removeSuperChats() async {
    var now = DateTime.now().millisecondsSinceEpoch;
    superChats.value = superChats
        .where((x) => x.endTime.millisecondsSinceEpoch > now)
        .toList();
  }

  /// 添加历史记录
  void addHistory() {
    if (detail.value == null) {
      return;
    }
    var id = "${site.id}_$roomId";
    var history = DBService.instance.getHistory(id);
    if (history != null) {
      history.updateTime = DateTime.now();
    }
    history ??= History(
      id: id,
      roomId: roomId,
      siteId: site.id,
      userName: detail.value?.userName ?? "",
      face: detail.value?.userAvatar ?? "",
      updateTime: DateTime.now(),
    );

    DBService.instance.addOrUpdateHistory(history);
  }

  /// 关注用户
  void followUser() {
    if (detail.value == null) {
      return;
    }
    var id = "${site.id}_$roomId";
    DBService.instance.addFollow(
      FollowUser(
        id: id,
        roomId: roomId,
        siteId: site.id,
        userName: detail.value?.userName ?? "",
        face: detail.value?.userAvatar ?? "",
        addTime: DateTime.now(),
      ),
    );
    followed.value = true;
    EventBus.instance.emit(Constant.kUpdateFollow, id);
  }

  /// 取消关注用户
  void removeFollowUser() async {
    if (detail.value == null) {
      return;
    }
    if (!await Utils.showAlertDialog("确定要取消关注该用户吗？", title: "取消关注")) {
      return;
    }

    var id = "${site.id}_$roomId";
    DBService.instance.deleteFollow(id);
    followed.value = false;
    EventBus.instance.emit(Constant.kUpdateFollow, id);
  }

  void share() {
    if (detail.value == null) {
      return;
    }
    SharePlus.instance.share(ShareParams(uri: Uri.parse(detail.value!.url)));
  }

  void copyUrl() {
    if (detail.value == null) {
      return;
    }
    Utils.copyToClipboard(detail.value!.url);
    SmartDialog.showToast("已复制直播间链接");
  }

  /// 复制新生成的直播流
  void copyPlayUrl() async {
    // 未开播不复制
    if (!liveStatus.value) {
      return;
    }
    var playUrl = await site.liveSite
        .getPlayUrls(detail: detail.value!, quality: qualites[currentQuality]);
    if (playUrl.urls.isEmpty) {
      SmartDialog.showToast("无法读取播放地址");
      return;
    }
    Utils.copyToClipboard(playUrl.urls.first);
    SmartDialog.showToast("已复制播放直链");
  }

  /// 底部打开播放器设置
  void showDanmuSettingsSheet() {
    Utils.showBottomSheet(
      title: "弹幕设置",
      child: ListView(
        padding: AppStyle.edgeInsetsA12,
        children: [
          DanmuSettingsView(
            danmakuController: danmakuController,
            onTapDanmuShield: () {
              Get.back();
              showDanmuShield();
            },
          ),
        ],
      ),
    );
  }

  void showVolumeSlider(BuildContext targetContext) {
    SmartDialog.showAttach(
      targetContext: targetContext,
      alignment: Alignment.topCenter,
      displayTime: const Duration(seconds: 3),
      maskColor: const Color(0x00000000),
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: AppStyle.radius12,
            color: Theme.of(context).cardColor,
          ),
          padding: AppStyle.edgeInsetsA4,
          child: Obx(
            () => SizedBox(
              width: 200,
              child: Slider(
                min: 0,
                max: 100,
                value: AppSettingsController.instance.playerVolume.value,
                onChanged: (newValue) {
                  player.setVolume(newValue);
                  AppSettingsController.instance.setPlayerVolume(newValue);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  bool _shouldUseDesktopWorkspace() {
    final context = Get.context;
    if (context == null) {
      return false;
    }
    return AppStyle.isDesktopLayout(context) && !isVertical.value;
  }

  Widget _buildQualitySelector({required VoidCallback onClose}) {
    return RadioGroup(
      groupValue: currentQuality,
      onChanged: (e) {
        onClose();
        currentQuality = e ?? 0;
        getPlayUrl();
      },
      child: ListView.builder(
        itemCount: qualites.length,
        itemBuilder: (_, i) {
          final item = qualites[i];
          return RadioListTile(
            value: i,
            title: Text(item.quality),
          );
        },
      ),
    );
  }

  Widget _buildPlayLineSelector({required VoidCallback onClose}) {
    return RadioGroup(
      groupValue: currentLineIndex,
      onChanged: (e) {
        onClose();
        changePlayLine(e ?? 0);
      },
      child: ListView.builder(
        itemCount: playUrls.length,
        itemBuilder: (_, i) {
          return RadioListTile(
            value: i,
            title: Text("线路${i + 1}"),
            secondary: Text(
              playUrls[i].contains(".flv") ? "FLV" : "HLS",
            ),
          );
        },
      ),
    );
  }

  Widget _buildScaleModeSelector() {
    return Obx(
      () => RadioGroup(
        groupValue: AppSettingsController.instance.scaleMode.value,
        onChanged: (e) {
          AppSettingsController.instance.setScaleMode(e ?? 0);
          updateScaleMode();
        },
        child: ListView(
          padding: AppStyle.edgeInsetsV12,
          children: const [
            RadioListTile(
              value: 0,
              title: Text("适应"),
              visualDensity: VisualDensity.compact,
            ),
            RadioListTile(
              value: 1,
              title: Text("拉伸"),
              visualDensity: VisualDensity.compact,
            ),
            RadioListTile(
              value: 2,
              title: Text("铺满"),
              visualDensity: VisualDensity.compact,
            ),
            RadioListTile(
              value: 3,
              title: Text("16:9"),
              visualDensity: VisualDensity.compact,
            ),
            RadioListTile(
              value: 4,
              title: Text("4:3"),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  void showQualitySheet() {
    if (_shouldUseDesktopWorkspace()) {
      Utils.showRightDialog(
        title: "清晰度",
        width: 320,
        useSystem: true,
        child: _buildQualitySelector(onClose: Utils.hideRightDialog),
      );
      return;
    }

    Utils.showBottomSheet(
      title: "切换清晰度",
      child: _buildQualitySelector(
        onClose: () {
          Get.back();
        },
      ),
    );
  }

  void showPlayUrlsSheet() {
    if (_shouldUseDesktopWorkspace()) {
      Utils.showRightDialog(
        title: "线路",
        width: 320,
        useSystem: true,
        child: _buildPlayLineSelector(onClose: Utils.hideRightDialog),
      );
      return;
    }

    Utils.showBottomSheet(
      title: "切换线路",
      child: _buildPlayLineSelector(
        onClose: () {
          Get.back();
        },
      ),
    );
  }

  void showPlayerSettingsSheet() {
    if (_shouldUseDesktopWorkspace()) {
      Utils.showRightDialog(
        title: "画面尺寸",
        width: 320,
        useSystem: true,
        child: _buildScaleModeSelector(),
      );
      return;
    }

    Utils.showBottomSheet(
      title: "画面尺寸",
      child: _buildScaleModeSelector(),
    );
  }

  Future<void> toggleGhostModeQuick() async {
    if (!Platform.isWindows) {
      return;
    }
    toggleGhostMode();
  }

  void showDanmuShield() {
    TextEditingController keywordController = TextEditingController();

    void addKeyword() {
      if (keywordController.text.isEmpty) {
        SmartDialog.showToast("请输入关键词");
        return;
      }

      AppSettingsController.instance
          .addShieldList(keywordController.text.trim());
      keywordController.text = "";
    }

    Utils.showBottomSheet(
      title: "关键词屏蔽",
      child: ListView(
        padding: AppStyle.edgeInsetsA12,
        children: [
          TextField(
            controller: keywordController,
            decoration: InputDecoration(
              contentPadding: AppStyle.edgeInsetsH12,
              border: const OutlineInputBorder(),
              hintText: "请输入关键词",
              suffixIcon: TextButton.icon(
                onPressed: addKeyword,
                icon: const Icon(Icons.add),
                label: const Text("添加"),
              ),
            ),
            onSubmitted: (e) {
              addKeyword();
            },
          ),
          AppStyle.vGap12,
          Obx(
            () => Text(
              "已添加${AppSettingsController.instance.shieldList.length}个关键词（点击移除）",
              style: Get.textTheme.titleSmall,
            ),
          ),
          AppStyle.vGap12,
          Obx(
            () => Wrap(
              runSpacing: 12,
              spacing: 12,
              children: AppSettingsController.instance.shieldList
                  .map(
                    (item) => InkWell(
                      borderRadius: AppStyle.radius24,
                      onTap: () {
                        AppSettingsController.instance.removeShieldList(item);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: AppStyle.radius24,
                        ),
                        padding: AppStyle.edgeInsetsH12.copyWith(
                          top: 4,
                          bottom: 4,
                        ),
                        child: Text(
                          item,
                          style: Get.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  void showFollowUserSheet() {
    Utils.showBottomSheet(
      title: "关注列表",
      child: Obx(
        () => Stack(
          children: [
            RefreshIndicator(
              onRefresh: FollowService.instance.loadData,
              child: ListView.builder(
                itemCount: FollowService.instance.liveList.length,
                itemBuilder: (_, i) {
                  var item = FollowService.instance.liveList[i];
                  return Obx(
                    () => FollowUserItem(
                      item: item,
                      playing: rxSite.value.id == item.siteId &&
                          rxRoomId.value == item.roomId,
                      onTap: () {
                        Get.back();
                        resetRoom(
                          Sites.allSites[item.siteId]!,
                          item.roomId,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            if (Platform.isWindows)
              Positioned(
                right: 12,
                bottom: 12,
                child: Obx(
                  () => DesktopRefreshButton(
                    refreshing: FollowService.instance.updating.value,
                    onPressed: FollowService.instance.loadData,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void showAutoExitSheet() {
    if (AppSettingsController.instance.autoExitEnable.value &&
        !delayAutoExit.value) {
      SmartDialog.showToast("已设置了全局定时关闭");
      return;
    }
    Utils.showBottomSheet(
      title: "定时关闭",
      child: ListView(
        children: [
          Obx(
            () => SwitchListTile(
              title: Text(
                "启用定时关闭",
                style: Get.textTheme.titleMedium,
              ),
              value: autoExitEnable.value,
              onChanged: (e) {
                autoExitEnable.value = e;

                setAutoExit();
                //controller.setAutoExitEnable(e);
              },
            ),
          ),
          Obx(
            () => ListTile(
              enabled: autoExitEnable.value,
              title: Text(
                "自动关闭时间：${autoExitMinutes.value ~/ 60}小时${autoExitMinutes.value % 60}分钟",
                style: Get.textTheme.titleMedium,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                var value = await showTimePicker(
                  context: Get.context!,
                  initialTime: TimeOfDay(
                    hour: autoExitMinutes.value ~/ 60,
                    minute: autoExitMinutes.value % 60,
                  ),
                  initialEntryMode: TimePickerEntryMode.inputOnly,
                  builder: (_, child) {
                    return MediaQuery(
                      data: Get.mediaQuery.copyWith(
                        alwaysUse24HourFormat: true,
                      ),
                      child: child!,
                    );
                  },
                );
                if (value == null || (value.hour == 0 && value.minute == 0)) {
                  return;
                }
                var duration =
                    Duration(hours: value.hour, minutes: value.minute);
                autoExitMinutes.value = duration.inMinutes;
                AppSettingsController.instance
                    .setRoomAutoExitDuration(autoExitMinutes.value);
                //setAutoExitDuration(duration.inMinutes);
                setAutoExit();
              },
            ),
          ),
        ],
      ),
    );
  }

  void openNaviteAPP() async {
    var naviteUrl = "bilibili://live/${detail.value?.roomId}";
    var webUrl = "https://live.bilibili.com/${detail.value?.roomId}";
    try {
      await launchUrlString(naviteUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      Log.logPrint(e);
      SmartDialog.showToast("无法打开APP，将使用浏览器打开");
      await launchUrlString(webUrl, mode: LaunchMode.externalApplication);
    }
  }

  void resetRoom(Site site, String roomId) async {
    if (this.site == site && this.roomId == roomId) {
      return;
    }

    stopAllAutoSpam();
    rxSite.value = site;
    rxRoomId.value = roomId;

    // 清除全部消息
    liveDanmaku.stop();
    messages.clear();
    superChats.clear();
    danmakuController?.clear();

    // 重新设置LiveDanmaku
    liveDanmaku = site.liveSite.getDanmaku();

    // 停止播放
    await player.stop();

    // 刷新信息
    loadData();
  }

  void copyErrorDetail() {
    Utils.copyToClipboard('''直播平台：${rxSite.value.name}
房间号：${rxRoomId.value}
错误信息：
${error?.toString()}
----------------
${errorStackTrace?.toString()}''');
    SmartDialog.showToast("已复制错误信息");
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      Log.d("进入后台");
      //进入后台，关闭弹幕
      danmakuController?.clear();
      isBackground = true;
      stopAllAutoSpam();
      stopVoiceRecognition();
    } else
    //返回前台
    if (state == AppLifecycleState.resumed) {
      Log.d("返回前台");
      isBackground = false;
      if (subtitleEnabled.value) {
        startVoiceRecognition();
      }
    }
  }

  // 用于启动开播时长计算和更新的函数
  void startLiveDurationTimer() {
    // 如果不是直播状态或者 showTime 为空，则不启动定时器
    if (!(detail.value?.status ?? false) || detail.value?.showTime == null) {
      liveDuration.value = "00:00:00"; // 未开播时显示 00:00:00
      _liveDurationTimer?.cancel();
      return;
    }

    try {
      int startTimeStamp = int.parse(detail.value!.showTime!);
      // 取消之前的定时器
      _liveDurationTimer?.cancel();
      // 创建新的定时器，每秒更新一次
      _liveDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        int currentTimeStamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        int durationInSeconds = currentTimeStamp - startTimeStamp;

        int hours = durationInSeconds ~/ 3600;
        int minutes = (durationInSeconds % 3600) ~/ 60;
        int seconds = durationInSeconds % 60;

        String formattedDuration =
            '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
        liveDuration.value = formattedDuration;
      });
    } catch (e) {
      liveDuration.value = "--:--:--"; // 错误时显示 --:--:--
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    scrollController.removeListener(scrollListener);
    scrollController.dispose();
    chatInputController.dispose();
    if (!Platform.isAndroid) {
      WindowManagerPlus.current.removeListener(this);
    }
    autoExitTimer?.cancel();
    _subtitleClearTimer?.cancel();
    for (final worker in _subtitleWorkers) {
      worker.dispose();
    }

    stopAllAutoSpam();
    liveDanmaku.stop();
    danmakuController = null;
    _liveDurationTimer?.cancel(); // 页面关闭时取消定时器
    _stopSubtitleAudioCapture();
    _subtitleAudioPlayer.dispose();
    _voiceRecognitionService.dispose();
    super.onClose();
  }

  @override
  Future<dynamic> onEventFromWindow(
      String eventName, int fromWindowId, dynamic arguments) async {
    if (eventName == 'send_chat') {
      String text = '';
      if (arguments is Map) {
        text = arguments['text']?.toString() ?? '';
      } else if (arguments is String) {
        text = arguments;
      }
      final message = text.trim();
      if (message.isNotEmpty) {
        await sendChatMessage(message);
      }
    } else if (eventName == 'send_emotion') {
      String text = '';
      Map<String, dynamic>? emoticonOptions;
      if (arguments is Map) {
        text = arguments['text']?.toString() ?? '';
        final options = arguments['emoticonOptions'];
        if (options is Map) {
          emoticonOptions = Map<String, dynamic>.from(options);
        }
      } else if (arguments is String) {
        text = arguments;
      }
      final message = text.trim();
      if (message.isNotEmpty) {
        await sendEmotionMessage(message, emoticonOptions: emoticonOptions);
      }
    } else if (eventName == 'get_emoticons') {
      final emoticonPackages = await getEmoticons();
      if (emoticonPackages is List && ghostWindowId != null) {
        WindowManagerPlus.current.invokeMethodToWindow(
          ghostWindowId!,
          'emoticons',
          {'packages': emoticonPackages},
        );
      }
    } else if (eventName == 'show_emotions') {
      await showEmotionPanel();
    } else if (eventName == 'show_auto_spam') {
      await showAutoSpamSheet();
    } else if (eventName == 'get_auto_spam_state') {
      if (ghostWindowId != null) {
        final settings = AppSettingsController.instance;
        WindowManagerPlus.current.invokeMethodToWindow(
          ghostWindowId!,
          'auto_spam_state',
          {
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
            'textRunning': autoSpamTextRunning.value,
            'emotionRunning': autoSpamEmotionRunning.value,
            'favoritesRunning': autoSpamFavoritesRunning.value,
          },
        );
      }
    } else if (eventName == 'set_auto_spam_state') {
      if (arguments is Map) {
        final message = Map<String, dynamic>.from(arguments);
        final settings = AppSettingsController.instance;
        if (message.containsKey('textMsg')) {
          settings.setAutoSpamTextMsg(message['textMsg']?.toString() ?? '');
        }
        if (message['textInterval'] is num) {
          settings.setAutoSpamTextInterval(
              (message['textInterval'] as num).toInt());
        }
        if (message['textChunkSize'] is num) {
          settings.setAutoSpamTextChunkSize(
              (message['textChunkSize'] as num).toInt());
        }
        if (message['textDuration'] is num) {
          settings.setAutoSpamTextDuration(
              (message['textDuration'] as num).toInt());
        }
        if (message['emotionInterval'] is num) {
          settings.setAutoSpamEmotionInterval(
              (message['emotionInterval'] as num).toInt());
        }
        if (message['emotionDuration'] is num) {
          settings.setAutoSpamEmotionDuration(
              (message['emotionDuration'] as num).toInt());
        }
        if (message['favoritesInterval'] is num) {
          settings.setAutoSpamFavoritesInterval(
              (message['favoritesInterval'] as num).toInt());
        }
        if (message['favoritesDuration'] is num) {
          settings.setAutoSpamFavoritesDuration(
              (message['favoritesDuration'] as num).toInt());
        }
        if (message['favoritesIndex'] is num) {
          settings.setAutoSpamFavoritesIndex(
              (message['favoritesIndex'] as num).toInt());
        }
        if (message['emotions'] is List) {
          settings.setAutoSpamEmotions(
            (message['emotions'] as List)
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList(),
          );
        }
        if (message['favorites'] is List) {
          settings.setAutoSpamFavorites(
            (message['favorites'] as List)
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList(),
          );
        }
      }
    } else if (eventName == 'auto_spam_action') {
      if (arguments is Map) {
        final message = Map<String, dynamic>.from(arguments);
        final type = message['type']?.toString() ?? '';
        final start = message['start'] == true;
        if (type == 'text') {
          if (start) {
            await startAutoSpamText();
          } else {
            stopAutoSpamText();
          }
        } else if (type == 'emotion') {
          if (start) {
            await startAutoSpamEmotion();
          } else {
            stopAutoSpamEmotion();
          }
        } else if (type == 'favorites') {
          if (start) {
            await startAutoSpamFavorites();
          } else {
            stopAutoSpamFavorites();
          }
        }
      }
    } else if (eventName == 'ghost_settings') {
      if (arguments is Map) {
        final message = Map<String, dynamic>.from(arguments);
        if (message.containsKey('opacity')) {
          final value = message['opacity'];
          if (value is num) {
            setGhostModeOpacity(value.toDouble());
          }
        }
        if (message.containsKey('locked')) {
          final value = message['locked'];
          if (value is bool) {
            setGhostModeLocked(value);
          }
        }
        if (message.containsKey('panelColor')) {
          final value = message['panelColor'];
          if (value is int) {
            AppSettingsController.instance.setGhostPanelColor(value);
            sendGhostConfig();
          }
        }
        if (message.containsKey('subtitleEnable')) {
          final value = message['subtitleEnable'];
          if (value is bool) {
            AppSettingsController.instance.setSubtitleEnable(value);
          }
        }
      }
    } else if (eventName == 'ghost_volume') {
      if (arguments is Map) {
        final value = arguments['value'];
        if (value is num) {
          player.setVolume(value.toDouble());
          AppSettingsController.instance.setPlayerVolume(value.toDouble());
        }
      }
    } else if (eventName == 'ghost_exit' || eventName == 'ghost_closed') {
      stopAllAutoSpam();
      if (ghostModeState.value) {
        exitGhostMode();
      }
    }
    return null;
  }
}
