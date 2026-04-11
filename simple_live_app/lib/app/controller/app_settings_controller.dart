import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/constant.dart';
import 'package:simple_live_app/app/log.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/services/local_storage_service.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum SubtitleRecognitionMode {
  online,
  local,
}

enum SubtitleOnlineProvider {
  customWebSocket,
}

class AppSettingsController extends GetxController {
  static AppSettingsController get instance =>
      Get.find<AppSettingsController>();

  static const Set<String> _supportedWindowsVideoOutputDrivers = {
    "gpu",
    "gpu-next",
    "direct3d",
    "sdl",
    "null",
    "libmpv",
  };

  static const Set<String> _supportedWindowsAudioOutputDrivers = {
    "null",
    "directsound",
    "wasapi",
    "winmm",
    "pcm",
    "sdl",
    "openal",
    "libao",
    "auto",
  };

  static const Set<String> _supportedWindowsHardwareDecoders = {
    "no",
    "auto",
    "auto-safe",
    "yes",
    "auto-copy",
    "d3d11va",
    "d3d11va-copy",
    "nvdec",
    "nvdec-copy",
    "vulkan",
    "vulkan-copy",
    "dxva2",
    "dxva2-copy",
    "cuda",
    "cuda-copy",
    "crystalhd",
  };

  LocalStorageService get _storage => LocalStorageService.instance;

  T _readSetting<T>(String key, T defaultValue) {
    return _storage.getValue(key, defaultValue);
  }

  void _writeSetting(String key, dynamic value) {
    _storage.setValue(key, value);
  }

  void _syncSetting<T>(Rx<T> field, String key, T value) {
    field.value = value;
    _writeSetting(key, value);
  }

  void _syncIndexedEnumSetting<T extends Enum>(
    Rx<T> field,
    String key,
    T value,
  ) {
    field.value = value;
    _writeSetting(key, value.index);
  }

  void _syncStringListSetting(
    RxList<String> field,
    String key,
    List<String> value,
  ) {
    field.assignAll(value);
    _writeSetting(key, field.join(","));
  }

  void _syncMapListSetting(
    RxList<Map<String, dynamic>> field,
    String key,
    List<Map<String, dynamic>> value,
  ) {
    field.assignAll(value);
    _writeSetting(key, value);
  }

  List<Map<String, dynamic>> _readMapListSetting(String key) {
    final storedValues = _readSetting(key, <dynamic>[]);
    return storedValues
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  /// 缩放模式
  var scaleMode = 0.obs;

  var themeMode = 0.obs;

  var firstRun = false;

  @override
  void onInit() {
    final storage = _storage;
    final normalizedThemeMode = _readSetting(LocalStorageService.kThemeMode, 1);
    // Keep only light/dark for a simpler, more polished experience.
    final normalizedClamped = normalizedThemeMode.clamp(1, 2);
    themeMode.value = normalizedClamped;
    _writeSetting(LocalStorageService.kThemeMode, normalizedClamped);
    firstRun = _readSetting(LocalStorageService.kFirstRun, true);
    danmuSize.value = _readSetting(LocalStorageService.kDanmuSize, 16.0);
    danmuOpacity.value = _readSetting(LocalStorageService.kDanmuOpacity, 1.0);
    danmuArea.value = _readSetting(LocalStorageService.kDanmuArea, 0.8);
    danmuSpeed.value = _readSetting(LocalStorageService.kDanmuSpeed, 10.0);
    danmuEnable.value = _readSetting(LocalStorageService.kDanmuEnable, true);
    danmuStrokeWidth.value = _readSetting(
      LocalStorageService.kDanmuStrokeWidth,
      2.0,
    );
    danmuTopMargin.value =
        _readSetting(LocalStorageService.kDanmuTopMargin, 0.0);
    danmuBottomMargin.value = _readSetting(
      LocalStorageService.kDanmuBottomMargin,
      0.0,
    );
    danmuFontWeight.value =
        _readSetting(LocalStorageService.kDanmuFontWeight, 4);
    subtitleEnable.value =
        _readSetting(LocalStorageService.kSubtitleEnable, false);
    subtitleFontSize.value = _readSetting(
      LocalStorageService.kSubtitleFontSize,
      16.0,
    );
    subtitleBackgroundOpacity.value = _readSetting(
      LocalStorageService.kSubtitleBackgroundOpacity,
      0.7,
    );
    subtitleModelName.value = _readSetting(
      LocalStorageService.kSubtitleModelName,
      _defaultSubtitleModel,
    );
    final modeIndex = _readSetting(
      LocalStorageService.kSubtitleRecognitionMode,
      SubtitleRecognitionMode.local.index,
    );
    subtitleRecognitionMode.value = SubtitleRecognitionMode.values[
        modeIndex >= 0 && modeIndex < SubtitleRecognitionMode.values.length
            ? modeIndex
            : SubtitleRecognitionMode.local.index];
    final providerIndex = _readSetting(
      LocalStorageService.kSubtitleOnlineProvider,
      SubtitleOnlineProvider.customWebSocket.index,
    );
    subtitleOnlineProvider.value = SubtitleOnlineProvider.values[
        providerIndex >= 0 &&
                providerIndex < SubtitleOnlineProvider.values.length
            ? providerIndex
            : SubtitleOnlineProvider.customWebSocket.index];
    subtitleOnlineApiUrl.value = _readSetting(
      LocalStorageService.kSubtitleOnlineApiUrl,
      "",
    );
    subtitleOnlineApiKey.value = _readSetting(
      LocalStorageService.kSubtitleOnlineApiKey,
      "",
    );
    subtitleOnlineApiKeyHeader.value = _readSetting(
      LocalStorageService.kSubtitleOnlineApiKeyHeader,
      "Authorization",
    );
    subtitleDelay.value =
        _readSetting(LocalStorageService.kSubtitleDelay, 2000.0);
    hardwareDecode.value =
        _readSetting(LocalStorageService.kHardwareDecode, true);
    chatTextSize.value = _readSetting(LocalStorageService.kChatTextSize, 14.0);
    chatTextGap.value = _readSetting(LocalStorageService.kChatTextGap, 4.0);
    chatBubbleStyle.value = _readSetting(
      LocalStorageService.kChatBubbleStyle,
      false,
    );
    qualityLevel.value = _readSetting(LocalStorageService.kQualityLevel, 1);
    qualityLevelCellular.value = _readSetting(
      LocalStorageService.kQualityLevelCellular,
      1,
    );
    autoExitEnable.value =
        _readSetting(LocalStorageService.kAutoExitEnable, false);
    autoExitDuration.value =
        _readSetting(LocalStorageService.kAutoExitDuration, 60);
    roomAutoExitDuration.value = _readSetting(
      LocalStorageService.kRoomAutoExitDuration,
      60,
    );
    playerAutoPause.value = _readSetting(
      LocalStorageService.kPlayerAutoPause,
      false,
    );
    playerForceHttps.value = _readSetting(
      LocalStorageService.kPlayerForceHttps,
      false,
    );
    autoFullScreen.value = _readSetting(
      LocalStorageService.kAutoFullScreen,
      false,
    );

    // ignore: invalid_use_of_protected_member
    shieldList.value = storage.shieldBox.values.toSet();

    scaleMode.value = _readSetting(LocalStorageService.kPlayerScaleMode, 0);
    playerVolume.value = _readSetting(LocalStorageService.kPlayerVolume, 100.0);
    styleColor.value =
        _readSetting(LocalStorageService.kStyleColor, 0xff3498db);
    isDynamic.value = _readSetting(LocalStorageService.kIsDynamic, false);
    bilibiliLoginTip.value = _readSetting(
      LocalStorageService.kBilibiliLoginTip,
      true,
    );
    playerBufferSize.value =
        _readSetting(LocalStorageService.kPlayerBufferSize, 32);
    logEnable.value = _readSetting(LocalStorageService.kLogEnable, false);
    Log.verboseEnabled = logEnable.value;
    if (logEnable.value) {
      Log.initWriter();
    }

    customPlayerOutput.value = _readSetting(
      LocalStorageService.kCustomPlayerOutput,
      false,
    );
    final storedVideoOutputDriver = _readSetting(
      LocalStorageService.kVideoOutputDriver,
      "libmpv",
    );
    videoOutputDriver.value =
        _normalizeWindowsVideoOutputDriver(storedVideoOutputDriver);
    _writeSetting(
        LocalStorageService.kVideoOutputDriver, videoOutputDriver.value);

    final storedAudioOutputDriver = _readSetting(
      LocalStorageService.kAudioOutputDriver,
      "wasapi",
    );
    audioOutputDriver.value =
        _normalizeWindowsAudioOutputDriver(storedAudioOutputDriver);
    _writeSetting(
        LocalStorageService.kAudioOutputDriver, audioOutputDriver.value);

    final storedVideoHardwareDecoder = _readSetting(
      LocalStorageService.kVideoHardwareDecoder,
      "auto",
    );
    videoHardwareDecoder.value =
        _normalizeWindowsHardwareDecoder(storedVideoHardwareDecoder);
    _writeSetting(
      LocalStorageService.kVideoHardwareDecoder,
      videoHardwareDecoder.value,
    );

    autoUpdateFollowEnable.value = _readSetting(
      LocalStorageService.kAutoUpdateFollowEnable,
      true,
    );
    autoUpdateFollowDuration.value = _readSetting(
      LocalStorageService.kUpdateFollowDuration,
      10,
    );
    updateFollowThreadCount.value = _readSetting(
      LocalStorageService.kUpdateFollowThreadCount,
      0,
    ); // 默认 0 = 自动
    windowsTrayIntegration.value = _readSetting(
      LocalStorageService.kWindowsTrayIntegration,
      true,
    );
    ghostMode.value = _readSetting(LocalStorageService.kGhostMode, false);
    ghostPanelColor.value = _readSetting(
      LocalStorageService.kGhostPanelColor,
      themeMode.value == 2
          ? AppColors.ghostDarkPanel.toARGB32()
          : AppColors.ghostLightPanel.toARGB32(),
    );
    final disabledPackages = _readSetting(
      LocalStorageService.kEmoticonPackageDisabled,
      <String>[],
    );
    emoticonPackageDisabled
        .assignAll(disabledPackages.map((item) => item.toString()));
    autoSpamTextMsg.value =
        _readSetting(LocalStorageService.kAutoSpamTextMsg, "");
    autoSpamTextInterval.value = _readSetting(
      LocalStorageService.kAutoSpamTextInterval,
      5,
    );
    autoSpamTextChunkSize.value = _readSetting(
      LocalStorageService.kAutoSpamTextChunkSize,
      20,
    );
    autoSpamTextDuration.value = _readSetting(
      LocalStorageService.kAutoSpamTextDuration,
      0,
    );
    autoSpamEmotionInterval.value = _readSetting(
      LocalStorageService.kAutoSpamEmotionInterval,
      5,
    );
    autoSpamEmotionDuration.value = _readSetting(
      LocalStorageService.kAutoSpamEmotionDuration,
      0,
    );
    autoSpamEmotions.assignAll(
      _readMapListSetting(LocalStorageService.kAutoSpamEmotions),
    );
    autoSpamFavoritesInterval.value = _readSetting(
      LocalStorageService.kAutoSpamFavoritesInterval,
      5,
    );
    autoSpamFavoritesDuration.value = _readSetting(
      LocalStorageService.kAutoSpamFavoritesDuration,
      0,
    );
    autoSpamFavorites.assignAll(
      _readMapListSetting(LocalStorageService.kAutoSpamFavorites),
    );
    if (autoSpamFavorites.isEmpty) {
      autoSpamFavorites.add({'id': 1, 'name': '第1组', 'msg': ''});
    }
    autoSpamFavoritesIndex.value = _readSetting(
      LocalStorageService.kAutoSpamFavoritesIndex,
      0,
    );
    if (autoSpamFavoritesIndex.value >= autoSpamFavorites.length) {
      autoSpamFavoritesIndex.value = 0;
    }

    initSiteSort();
    initHomeSort();

    super.onInit();
  }

  void initSiteSort() {
    var sort = _readSetting(
      LocalStorageService.kSiteSort,
      Sites.allSites.keys.join(","),
    ).split(",");
    //如果数量与allSites的数量不一致，将缺失的添加上
    if (sort.length != Sites.allSites.length) {
      var keys = Sites.allSites.keys.toList();
      for (var i = 0; i < keys.length; i++) {
        if (!sort.contains(keys[i])) {
          sort.add(keys[i]);
        }
      }
    }

    siteSort.value = sort;
  }

  void initHomeSort() {
    final keys = Constant.allHomePages.keys.toList();
    final storedValue = _readSetting(
      LocalStorageService.kHomeSort,
      keys.join(","),
    );
    final sort = storedValue
        .split(",")
        .map((item) => item.trim())
        .where(
          (item) => item.isNotEmpty && Constant.allHomePages.containsKey(item),
        )
        .toList();
    for (final key in keys) {
      if (!sort.contains(key)) {
        sort.add(key);
      }
    }
    homeSort.value = sort;
    _writeSetting(LocalStorageService.kHomeSort, sort.join(","));
  }

  void setNoFirstRun() {
    _writeSetting(LocalStorageService.kFirstRun, false);
  }

  void changeTheme() {
    Get.dialog(
      RadioGroup(
        groupValue: themeMode.value,
        onChanged: (e) {
          Get.back();
          setTheme(e ?? 0);
        },
        child: const SimpleDialog(
          title: Text("设置主题"),
          children: [
            RadioListTile<int>(
              title: Text("跟随系统"),
              value: 0,
            ),
            RadioListTile<int>(
              title: Text("浅色模式"),
              value: 1,
            ),
            RadioListTile<int>(
              title: Text("深色模式"),
              value: 2,
            ),
          ],
        ),
      ),
    );
  }

  void setTheme(int i) {
    if (i <= 0) {
      i = 1;
    }
    if (i > 2) {
      i = 2;
    }
    themeMode.value = i;
    var mode = ThemeMode.values[i];

    _writeSetting(LocalStorageService.kThemeMode, i);
    Get.changeThemeMode(mode);
  }

  var hardwareDecode = true.obs;
  void setHardwareDecode(bool e) {
    _syncSetting(hardwareDecode, LocalStorageService.kHardwareDecode, e);
  }

  var chatTextSize = 14.0.obs;
  void setChatTextSize(double e) {
    _syncSetting(chatTextSize, LocalStorageService.kChatTextSize, e);
  }

  var chatTextGap = 4.0.obs;
  void setChatTextGap(double e) {
    _syncSetting(chatTextGap, LocalStorageService.kChatTextGap, e);
  }

  var chatBubbleStyle = false.obs;
  void setChatBubbleStyle(bool e) {
    _syncSetting(chatBubbleStyle, LocalStorageService.kChatBubbleStyle, e);
  }

  var danmuSize = 16.0.obs;
  void setDanmuSize(double e) {
    _syncSetting(danmuSize, LocalStorageService.kDanmuSize, e);
  }

  var danmuSpeed = 10.0.obs;
  void setDanmuSpeed(double e) {
    _syncSetting(danmuSpeed, LocalStorageService.kDanmuSpeed, e);
  }

  var danmuArea = 0.8.obs;
  void setDanmuArea(double e) {
    _syncSetting(danmuArea, LocalStorageService.kDanmuArea, e);
  }

  var danmuOpacity = 1.0.obs;
  void setDanmuOpacity(double e) {
    _syncSetting(danmuOpacity, LocalStorageService.kDanmuOpacity, e);
  }

  var danmuEnable = true.obs;
  void setDanmuEnable(bool e) {
    _syncSetting(danmuEnable, LocalStorageService.kDanmuEnable, e);
  }

  var danmuStrokeWidth = 2.0.obs;
  void setDanmuStrokeWidth(double e) {
    _syncSetting(danmuStrokeWidth, LocalStorageService.kDanmuStrokeWidth, e);
  }

  var danmuFontWeight = 4.obs;
  void setDanmuFontWeight(int e) {
    _syncSetting(danmuFontWeight, LocalStorageService.kDanmuFontWeight, e);
  }

  static const String _defaultSubtitleModel = "";
  var subtitleEnable = false.obs;
  void setSubtitleEnable(bool e) {
    _syncSetting(subtitleEnable, LocalStorageService.kSubtitleEnable, e);
  }

  var subtitleFontSize = 16.0.obs;
  void setSubtitleFontSize(double e) {
    _syncSetting(subtitleFontSize, LocalStorageService.kSubtitleFontSize, e);
  }

  var subtitleBackgroundOpacity = 0.7.obs;
  void setSubtitleBackgroundOpacity(double e) {
    _syncSetting(
      subtitleBackgroundOpacity,
      LocalStorageService.kSubtitleBackgroundOpacity,
      e,
    );
  }

  var subtitleModelName = _defaultSubtitleModel.obs;
  void setSubtitleModelName(String e) {
    _syncSetting(subtitleModelName, LocalStorageService.kSubtitleModelName, e);
  }

  var subtitleRecognitionMode = SubtitleRecognitionMode.local.obs;
  void setSubtitleRecognitionMode(SubtitleRecognitionMode mode) {
    _syncIndexedEnumSetting(
      subtitleRecognitionMode,
      LocalStorageService.kSubtitleRecognitionMode,
      mode,
    );
  }

  var subtitleOnlineProvider = SubtitleOnlineProvider.customWebSocket.obs;
  void setSubtitleOnlineProvider(SubtitleOnlineProvider provider) {
    _syncIndexedEnumSetting(
      subtitleOnlineProvider,
      LocalStorageService.kSubtitleOnlineProvider,
      provider,
    );
  }

  var subtitleOnlineApiUrl = "".obs;
  void setSubtitleOnlineApiUrl(String value) {
    _syncSetting(
      subtitleOnlineApiUrl,
      LocalStorageService.kSubtitleOnlineApiUrl,
      value,
    );
  }

  var subtitleOnlineApiKey = "".obs;
  void setSubtitleOnlineApiKey(String value) {
    _syncSetting(
      subtitleOnlineApiKey,
      LocalStorageService.kSubtitleOnlineApiKey,
      value,
    );
  }

  var subtitleOnlineApiKeyHeader = "Authorization".obs;
  void setSubtitleOnlineApiKeyHeader(String value) {
    _syncSetting(
      subtitleOnlineApiKeyHeader,
      LocalStorageService.kSubtitleOnlineApiKeyHeader,
      value,
    );
  }

  var subtitleDelay = 2000.0.obs;
  void setSubtitleDelay(double value) {
    _syncSetting(subtitleDelay, LocalStorageService.kSubtitleDelay, value);
  }

  var qualityLevel = 1.obs;
  void setQualityLevel(int level) {
    _syncSetting(qualityLevel, LocalStorageService.kQualityLevel, level);
  }

  var qualityLevelCellular = 1.obs;
  void setQualityLevelCellular(int level) {
    _syncSetting(
      qualityLevelCellular,
      LocalStorageService.kQualityLevelCellular,
      level,
    );
  }

  var autoExitEnable = false.obs;
  void setAutoExitEnable(bool e) {
    _syncSetting(autoExitEnable, LocalStorageService.kAutoExitEnable, e);
  }

  var autoExitDuration = 60.obs;
  void setAutoExitDuration(int e) {
    _syncSetting(autoExitDuration, LocalStorageService.kAutoExitDuration, e);
  }

  var roomAutoExitDuration = 60.obs;
  void setRoomAutoExitDuration(int e) {
    _syncSetting(
      roomAutoExitDuration,
      LocalStorageService.kRoomAutoExitDuration,
      e,
    );
  }

  var playerBufferSize = 32.obs;
  void setPlayerBufferSize(int e) {
    _syncSetting(playerBufferSize, LocalStorageService.kPlayerBufferSize, e);
  }

  var playerAutoPause = false.obs;
  void setPlayerAutoPause(bool e) {
    _syncSetting(playerAutoPause, LocalStorageService.kPlayerAutoPause, e);
  }

  var autoFullScreen = false.obs;
  void setAutoFullScreen(bool e) {
    _syncSetting(autoFullScreen, LocalStorageService.kAutoFullScreen, e);
  }

  var playershowSuperChat = true.obs;
  void setPlayerShowSuperChat(bool e) {
    _syncSetting(
        playershowSuperChat, LocalStorageService.kPlayerShowSuperChat, e);
  }

  RxSet<String> shieldList = <String>{}.obs;
  void addShieldList(String e) {
    shieldList.add(e);
    LocalStorageService.instance.shieldBox.put(e, e);
  }

  void removeShieldList(String e) {
    shieldList.remove(e);
    LocalStorageService.instance.shieldBox.delete(e);
  }

  Future clearShieldList() async {
    shieldList.clear();
    await LocalStorageService.instance.shieldBox.clear();
  }

  void setScaleMode(int value) {
    _syncSetting(scaleMode, LocalStorageService.kPlayerScaleMode, value);
  }

  RxList<String> siteSort = RxList<String>();
  void setSiteSort(List<String> e) {
    _syncStringListSetting(siteSort, LocalStorageService.kSiteSort, e);
  }

  RxList<String> homeSort = RxList<String>();
  void setHomeSort(List<String> e) {
    _syncStringListSetting(homeSort, LocalStorageService.kHomeSort, e);
  }

  Rx<double> playerVolume = 100.0.obs;
  void setPlayerVolume(double value) {
    _syncSetting(playerVolume, LocalStorageService.kPlayerVolume, value);
  }

  var styleColor = 0xff3498db.obs;
  void setStyleColor(int e) {
    _syncSetting(styleColor, LocalStorageService.kStyleColor, e);
  }

  var isDynamic = false.obs;
  void setIsDynamic(bool e) {
    _syncSetting(isDynamic, LocalStorageService.kIsDynamic, e);
  }

  var danmuTopMargin = 0.0.obs;
  void setDanmuTopMargin(double e) {
    _syncSetting(danmuTopMargin, LocalStorageService.kDanmuTopMargin, e);
  }

  var danmuBottomMargin = 0.0.obs;
  void setDanmuBottomMargin(double e) {
    _syncSetting(danmuBottomMargin, LocalStorageService.kDanmuBottomMargin, e);
  }

  var bilibiliLoginTip = true.obs;
  void setBiliBiliLoginTip(bool e) {
    _syncSetting(bilibiliLoginTip, LocalStorageService.kBilibiliLoginTip, e);
  }

  var logEnable = false.obs;
  void setLogEnable(bool e) {
    _syncSetting(logEnable, LocalStorageService.kLogEnable, e);
    Log.verboseEnabled = e;
  }

  var customPlayerOutput = false.obs;
  void setCustomPlayerOutput(bool e) {
    _syncSetting(
      customPlayerOutput,
      LocalStorageService.kCustomPlayerOutput,
      e,
    );
  }

  var videoOutputDriver = "".obs;
  void setVideoOutputDriver(String e) {
    _syncSetting(
      videoOutputDriver,
      LocalStorageService.kVideoOutputDriver,
      _normalizeWindowsVideoOutputDriver(e),
    );
  }

  var audioOutputDriver = "".obs;
  void setAudioOutputDriver(String e) {
    _syncSetting(
      audioOutputDriver,
      LocalStorageService.kAudioOutputDriver,
      _normalizeWindowsAudioOutputDriver(e),
    );
  }

  var videoHardwareDecoder = "".obs;
  void setVideoHardwareDecoder(String e) {
    _syncSetting(
      videoHardwareDecoder,
      LocalStorageService.kVideoHardwareDecoder,
      _normalizeWindowsHardwareDecoder(e),
    );
  }

  var autoUpdateFollowEnable = false.obs;
  void setAutoUpdateFollowEnable(bool e) {
    _syncSetting(
      autoUpdateFollowEnable,
      LocalStorageService.kAutoUpdateFollowEnable,
      e,
    );
  }

  var autoUpdateFollowDuration = 10.obs;
  void setAutoUpdateFollowDuration(int e) {
    _syncSetting(
      autoUpdateFollowDuration,
      LocalStorageService.kUpdateFollowDuration,
      e,
    );
  }

  var updateFollowThreadCount = 4.obs;
  void setUpdateFollowThreadCount(int e) {
    _syncSetting(
      updateFollowThreadCount,
      LocalStorageService.kUpdateFollowThreadCount,
      e,
    );
  }

  var playerForceHttps = false.obs;
  void setPlayerForceHttps(bool e) {
    _syncSetting(playerForceHttps, LocalStorageService.kPlayerForceHttps, e);
  }

  var windowsTrayIntegration = true.obs;
  void setWindowsTrayIntegration(bool e) {
    _syncSetting(
      windowsTrayIntegration,
      LocalStorageService.kWindowsTrayIntegration,
      e,
    );
  }

  var ghostMode = false.obs;
  void setGhostMode(bool e) {
    _syncSetting(ghostMode, LocalStorageService.kGhostMode, e);
  }

  var ghostPanelColor = AppColors.ghostLightPanel.toARGB32().obs;
  void setGhostPanelColor(int value) {
    _syncSetting(ghostPanelColor, LocalStorageService.kGhostPanelColor, value);
  }

  var autoSpamTextMsg = "".obs;
  void setAutoSpamTextMsg(String value) {
    _syncSetting(autoSpamTextMsg, LocalStorageService.kAutoSpamTextMsg, value);
  }

  var autoSpamTextInterval = 5.obs;
  void setAutoSpamTextInterval(int value) {
    _syncSetting(
      autoSpamTextInterval,
      LocalStorageService.kAutoSpamTextInterval,
      value,
    );
  }

  var autoSpamTextChunkSize = 20.obs;
  void setAutoSpamTextChunkSize(int value) {
    _syncSetting(
      autoSpamTextChunkSize,
      LocalStorageService.kAutoSpamTextChunkSize,
      value,
    );
  }

  var autoSpamTextDuration = 0.obs;
  void setAutoSpamTextDuration(int value) {
    _syncSetting(
      autoSpamTextDuration,
      LocalStorageService.kAutoSpamTextDuration,
      value,
    );
  }

  var autoSpamEmotionInterval = 5.obs;
  void setAutoSpamEmotionInterval(int value) {
    _syncSetting(
      autoSpamEmotionInterval,
      LocalStorageService.kAutoSpamEmotionInterval,
      value,
    );
  }

  var autoSpamEmotionDuration = 0.obs;
  void setAutoSpamEmotionDuration(int value) {
    _syncSetting(
      autoSpamEmotionDuration,
      LocalStorageService.kAutoSpamEmotionDuration,
      value,
    );
  }

  RxList<Map<String, dynamic>> autoSpamEmotions = <Map<String, dynamic>>[].obs;
  void setAutoSpamEmotions(List<Map<String, dynamic>> values) {
    _syncMapListSetting(
      autoSpamEmotions,
      LocalStorageService.kAutoSpamEmotions,
      values,
    );
  }

  void toggleAutoSpamEmotion(Map<String, dynamic> value) {
    final id = value['id']?.toString() ?? '';
    if (id.isEmpty) {
      return;
    }
    final list = List<Map<String, dynamic>>.from(autoSpamEmotions);
    final index = list.indexWhere((item) => item['id']?.toString() == id);
    if (index >= 0) {
      list.removeAt(index);
    } else {
      list.add(value);
    }
    setAutoSpamEmotions(list);
  }

  void clearAutoSpamEmotions() {
    setAutoSpamEmotions([]);
  }

  RxList<Map<String, dynamic>> autoSpamFavorites = <Map<String, dynamic>>[].obs;
  var autoSpamFavoritesIndex = 0.obs;
  var autoSpamFavoritesInterval = 5.obs;
  var autoSpamFavoritesDuration = 0.obs;

  void setAutoSpamFavorites(List<Map<String, dynamic>> values) {
    _syncMapListSetting(
      autoSpamFavorites,
      LocalStorageService.kAutoSpamFavorites,
      values,
    );
  }

  void setAutoSpamFavoritesIndex(int value) {
    _syncSetting(
      autoSpamFavoritesIndex,
      LocalStorageService.kAutoSpamFavoritesIndex,
      value,
    );
  }

  void setAutoSpamFavoritesInterval(int value) {
    _syncSetting(
      autoSpamFavoritesInterval,
      LocalStorageService.kAutoSpamFavoritesInterval,
      value,
    );
  }

  void setAutoSpamFavoritesDuration(int value) {
    _syncSetting(
      autoSpamFavoritesDuration,
      LocalStorageService.kAutoSpamFavoritesDuration,
      value,
    );
  }

  void addAutoSpamFavorite() {
    final list = List<Map<String, dynamic>>.from(autoSpamFavorites);
    final nextId = list.isEmpty
        ? 1
        : (list
                .map((e) => e['id'] as int? ?? 0)
                .reduce((a, b) => a > b ? a : b) +
            1);
    list.add({
      'id': nextId,
      'name': '第${list.length + 1}组',
      'msg': '',
    });
    setAutoSpamFavorites(list);
    setAutoSpamFavoritesIndex(list.length - 1);
  }

  void removeAutoSpamFavorite(int index) {
    final list = List<Map<String, dynamic>>.from(autoSpamFavorites);
    if (index < 0 || index >= list.length) {
      return;
    }
    list.removeAt(index);
    if (list.isEmpty) {
      list.add({'id': 1, 'name': '第1组', 'msg': ''});
      setAutoSpamFavorites(list);
      setAutoSpamFavoritesIndex(0);
      return;
    }
    setAutoSpamFavorites(list);
    if (autoSpamFavoritesIndex.value >= list.length) {
      setAutoSpamFavoritesIndex(list.length - 1);
    }
  }

  void updateAutoSpamFavoriteMessage(int index, String value) {
    final list = List<Map<String, dynamic>>.from(autoSpamFavorites);
    if (index < 0 || index >= list.length) {
      return;
    }
    list[index] = {
      ...list[index],
      'msg': value,
    };
    setAutoSpamFavorites(list);
  }

  RxSet<String> emoticonPackageDisabled = <String>{}.obs;
  bool isEmoticonPackageEnabled(String id) {
    if (id.isEmpty) {
      return true;
    }
    return !emoticonPackageDisabled.contains(id);
  }

  void setEmoticonPackageEnabled(String id, bool enabled) {
    if (id.isEmpty) {
      return;
    }
    if (enabled) {
      emoticonPackageDisabled.remove(id);
    } else {
      emoticonPackageDisabled.add(id);
    }
    _writeSetting(
      LocalStorageService.kEmoticonPackageDisabled,
      emoticonPackageDisabled.toList(),
    );
  }

  String _normalizeWindowsVideoOutputDriver(String value) {
    if (_supportedWindowsVideoOutputDrivers.contains(value)) {
      return value;
    }
    return "libmpv";
  }

  String _normalizeWindowsAudioOutputDriver(String value) {
    if (_supportedWindowsAudioOutputDrivers.contains(value)) {
      return value;
    }
    return "wasapi";
  }

  String _normalizeWindowsHardwareDecoder(String value) {
    if (_supportedWindowsHardwareDecoders.contains(value)) {
      return value;
    }
    return "auto";
  }
}
