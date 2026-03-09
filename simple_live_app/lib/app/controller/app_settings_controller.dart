import 'dart:io';

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

  /// 缩放模式
  var scaleMode = 0.obs;

  var themeMode = 0.obs;

  var firstRun = false;

  @override
  void onInit() {
    themeMode.value = LocalStorageService.instance
        .getValue(LocalStorageService.kThemeMode, 0);
    firstRun = LocalStorageService.instance
        .getValue(LocalStorageService.kFirstRun, true);
    danmuSize.value = LocalStorageService.instance
        .getValue(LocalStorageService.kDanmuSize, 16.0);
    danmuOpacity.value = LocalStorageService.instance
        .getValue(LocalStorageService.kDanmuOpacity, 1.0);
    danmuArea.value = LocalStorageService.instance
        .getValue(LocalStorageService.kDanmuArea, 0.8);
    danmuSpeed.value = LocalStorageService.instance
        .getValue(LocalStorageService.kDanmuSpeed, 10.0);
    danmuEnable.value = LocalStorageService.instance
        .getValue(LocalStorageService.kDanmuEnable, true);
    danmuStrokeWidth.value = LocalStorageService.instance
        .getValue(LocalStorageService.kDanmuStrokeWidth, 2.0);
    danmuTopMargin.value = LocalStorageService.instance
        .getValue(LocalStorageService.kDanmuTopMargin, 0.0);
    danmuBottomMargin.value = LocalStorageService.instance
        .getValue(LocalStorageService.kDanmuBottomMargin, 0.0);
    danmuFontWeight.value = LocalStorageService.instance
        .getValue(LocalStorageService.kDanmuFontWeight, 4);
    subtitleEnable.value = LocalStorageService.instance
        .getValue(LocalStorageService.kSubtitleEnable, false);
    subtitleFontSize.value = LocalStorageService.instance
        .getValue(LocalStorageService.kSubtitleFontSize, 16.0);
    subtitleBackgroundOpacity.value = LocalStorageService.instance
        .getValue(LocalStorageService.kSubtitleBackgroundOpacity, 0.7);
    subtitleModelName.value = LocalStorageService.instance.getValue(
        LocalStorageService.kSubtitleModelName, _defaultSubtitleModel);
    final modeIndex = LocalStorageService.instance.getValue(
      LocalStorageService.kSubtitleRecognitionMode,
      SubtitleRecognitionMode.local.index,
    );
    subtitleRecognitionMode.value = SubtitleRecognitionMode.values[
        modeIndex >= 0 && modeIndex < SubtitleRecognitionMode.values.length
            ? modeIndex
            : SubtitleRecognitionMode.local.index];
    final providerIndex = LocalStorageService.instance.getValue(
      LocalStorageService.kSubtitleOnlineProvider,
      SubtitleOnlineProvider.customWebSocket.index,
    );
    subtitleOnlineProvider.value = SubtitleOnlineProvider.values[
        providerIndex >= 0 &&
                providerIndex < SubtitleOnlineProvider.values.length
            ? providerIndex
            : SubtitleOnlineProvider.customWebSocket.index];
    subtitleOnlineApiUrl.value = LocalStorageService.instance
        .getValue(LocalStorageService.kSubtitleOnlineApiUrl, "");
    subtitleOnlineApiKey.value = LocalStorageService.instance
        .getValue(LocalStorageService.kSubtitleOnlineApiKey, "");
    subtitleOnlineApiKeyHeader.value = LocalStorageService.instance.getValue(
        LocalStorageService.kSubtitleOnlineApiKeyHeader, "Authorization");

    hardwareDecode.value = LocalStorageService.instance
        .getValue(LocalStorageService.kHardwareDecode, true);
    chatTextSize.value = LocalStorageService.instance
        .getValue(LocalStorageService.kChatTextSize, 14.0);

    chatTextGap.value = LocalStorageService.instance
        .getValue(LocalStorageService.kChatTextGap, 4.0);

    chatBubbleStyle.value = LocalStorageService.instance.getValue(
      LocalStorageService.kChatBubbleStyle,
      false,
    );

    qualityLevel.value = LocalStorageService.instance
        .getValue(LocalStorageService.kQualityLevel, 1);
    qualityLevelCellular.value = LocalStorageService.instance
        .getValue(LocalStorageService.kQualityLevelCellular, 1);

    autoExitEnable.value = LocalStorageService.instance
        .getValue(LocalStorageService.kAutoExitEnable, false);

    autoExitDuration.value = LocalStorageService.instance
        .getValue(LocalStorageService.kAutoExitDuration, 60);

    roomAutoExitDuration.value = LocalStorageService.instance
        .getValue(LocalStorageService.kRoomAutoExitDuration, 60);

    playerCompatMode.value = LocalStorageService.instance
        .getValue(LocalStorageService.kPlayerCompatMode, false);

    playerAutoPause.value = LocalStorageService.instance
        .getValue(LocalStorageService.kPlayerAutoPause, false);

    playerForceHttps.value = LocalStorageService.instance
        .getValue(LocalStorageService.kPlayerForceHttps, false);

    autoFullScreen.value = LocalStorageService.instance
        .getValue(LocalStorageService.kAutoFullScreen, false);

    // ignore: invalid_use_of_protected_member
    shieldList.value = LocalStorageService.instance.shieldBox.values.toSet();

    scaleMode.value = LocalStorageService.instance.getValue(
      LocalStorageService.kPlayerScaleMode,
      0,
    );

    playerVolume.value = LocalStorageService.instance.getValue(
      LocalStorageService.kPlayerVolume,
      100.0,
    );
    pipHideDanmu.value = LocalStorageService.instance
        .getValue(LocalStorageService.kPIPHideDanmu, true);

    styleColor.value = LocalStorageService.instance
        .getValue(LocalStorageService.kStyleColor, 0xff3498db);

    isDynamic.value = LocalStorageService.instance
        .getValue(LocalStorageService.kIsDynamic, false);

    bilibiliLoginTip.value = LocalStorageService.instance
        .getValue(LocalStorageService.kBilibiliLoginTip, true);

    playerBufferSize.value = LocalStorageService.instance
        .getValue(LocalStorageService.kPlayerBufferSize, 32);

    logEnable.value = LocalStorageService.instance
        .getValue(LocalStorageService.kLogEnable, false);
    if (logEnable.value) {
      Log.initWriter();
    }

    customPlayerOutput.value = LocalStorageService.instance
        .getValue(LocalStorageService.kCustomPlayerOutput, false);

    videoOutputDriver.value = LocalStorageService.instance.getValue(
      LocalStorageService.kVideoOutputDriver,
      Platform.isAndroid ? "gpu" : "libmpv",
    );

    audioOutputDriver.value = LocalStorageService.instance.getValue(
      LocalStorageService.kAudioOutputDriver,
      Platform.isAndroid
          ? "audiotrack"
          : Platform.isLinux
              ? "pulse"
              : Platform.isWindows
                  ? "wasapi"
                  : Platform.isIOS
                      ? "audiounit"
                      : Platform.isMacOS
                          ? "coreaudio"
                          : "sdl",
    );

    videoHardwareDecoder.value = LocalStorageService.instance.getValue(
      LocalStorageService.kVideoHardwareDecoder,
      Platform.isAndroid ? "auto-safe" : "auto",
    );

    autoUpdateFollowEnable.value = LocalStorageService.instance
        .getValue(LocalStorageService.kAutoUpdateFollowEnable, true);

    autoUpdateFollowDuration.value = LocalStorageService.instance
        .getValue(LocalStorageService.kUpdateFollowDuration, 10);

    updateFollowThreadCount.value = LocalStorageService.instance
        .getValue(LocalStorageService.kUpdateFollowThreadCount, 0); // 默认 0 = 自动

    audioOnlyMode.value = LocalStorageService.instance
        .getValue(LocalStorageService.kAudioOnlyMode, false);

    backgroundKeepAlive.value = LocalStorageService.instance
        .getValue(LocalStorageService.kBackgroundKeepAlive, true);

    windowsTrayIntegration.value = LocalStorageService.instance
        .getValue(LocalStorageService.kWindowsTrayIntegration, true);

    ghostMode.value = LocalStorageService.instance
        .getValue(LocalStorageService.kGhostMode, false);
    ghostPanelColor.value = LocalStorageService.instance
        .getValue(LocalStorageService.kGhostPanelColor, 0xBFD0D0D0);
    final disabledPackages = LocalStorageService.instance
        .getValue(LocalStorageService.kEmoticonPackageDisabled, <String>[]);
    emoticonPackageDisabled
        .assignAll(disabledPackages.map((e) => e.toString()));
    autoSpamTextMsg.value = LocalStorageService.instance
        .getValue(LocalStorageService.kAutoSpamTextMsg, "");
    autoSpamTextInterval.value = LocalStorageService.instance
        .getValue(LocalStorageService.kAutoSpamTextInterval, 5);
    autoSpamTextChunkSize.value = LocalStorageService.instance
        .getValue(LocalStorageService.kAutoSpamTextChunkSize, 20);
    autoSpamTextDuration.value = LocalStorageService.instance
        .getValue(LocalStorageService.kAutoSpamTextDuration, 0);
    autoSpamEmotionInterval.value = LocalStorageService.instance
        .getValue(LocalStorageService.kAutoSpamEmotionInterval, 5);
    autoSpamEmotionDuration.value = LocalStorageService.instance
        .getValue(LocalStorageService.kAutoSpamEmotionDuration, 0);
    final storedEmotions = LocalStorageService.instance
        .getValue(LocalStorageService.kAutoSpamEmotions, <dynamic>[]);
    autoSpamEmotions.assignAll(
      storedEmotions.whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
    );
    autoSpamFavoritesInterval.value = LocalStorageService.instance
        .getValue(LocalStorageService.kAutoSpamFavoritesInterval, 5);
    autoSpamFavoritesDuration.value = LocalStorageService.instance
        .getValue(LocalStorageService.kAutoSpamFavoritesDuration, 0);
    final storedFavorites = LocalStorageService.instance
        .getValue(LocalStorageService.kAutoSpamFavorites, <dynamic>[]);
    autoSpamFavorites.assignAll(
      storedFavorites.whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
    );
    if (autoSpamFavorites.isEmpty) {
      autoSpamFavorites.add({'id': 1, 'name': '第1组', 'msg': ''});
    }
    autoSpamFavoritesIndex.value = LocalStorageService.instance
        .getValue(LocalStorageService.kAutoSpamFavoritesIndex, 0);
    if (autoSpamFavoritesIndex.value >= autoSpamFavorites.length) {
      autoSpamFavoritesIndex.value = 0;
    }

    initSiteSort();
    initHomeSort();

    super.onInit();
  }

  void initSiteSort() {
    var sort = LocalStorageService.instance
        .getValue(
          LocalStorageService.kSiteSort,
          Sites.allSites.keys.join(","),
        )
        .split(",");
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
    var sort = LocalStorageService.instance
        .getValue(
          LocalStorageService.kHomeSort,
          Constant.allHomePages.keys.join(","),
        )
        .split(",");
    //如果数量与allSites的数量不一致，将缺失的添加上
    if (sort.length != Constant.allHomePages.length) {
      var keys = Constant.allHomePages.keys.toList();
      for (var i = 0; i < keys.length; i++) {
        if (!sort.contains(keys[i])) {
          sort.add(keys[i]);
        }
      }
    }

    homeSort.value = sort;
  }

  void setNoFirstRun() {
    LocalStorageService.instance.setValue(LocalStorageService.kFirstRun, false);
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
    themeMode.value = i;
    var mode = ThemeMode.values[i];

    LocalStorageService.instance.setValue(LocalStorageService.kThemeMode, i);
    Get.changeThemeMode(mode);
  }

  var hardwareDecode = true.obs;
  void setHardwareDecode(bool e) {
    hardwareDecode.value = e;
    LocalStorageService.instance
        .setValue(LocalStorageService.kHardwareDecode, e);
  }

  var chatTextSize = 14.0.obs;
  void setChatTextSize(double e) {
    chatTextSize.value = e;
    LocalStorageService.instance.setValue(LocalStorageService.kChatTextSize, e);
  }

  var chatTextGap = 4.0.obs;
  void setChatTextGap(double e) {
    chatTextGap.value = e;
    LocalStorageService.instance.setValue(LocalStorageService.kChatTextGap, e);
  }

  var chatBubbleStyle = false.obs;
  void setChatBubbleStyle(bool e) {
    chatBubbleStyle.value = e;
    LocalStorageService.instance
        .setValue(LocalStorageService.kChatBubbleStyle, e);
  }

  var danmuSize = 16.0.obs;
  void setDanmuSize(double e) {
    danmuSize.value = e;
    LocalStorageService.instance.setValue(LocalStorageService.kDanmuSize, e);
  }

  var danmuSpeed = 10.0.obs;
  void setDanmuSpeed(double e) {
    danmuSpeed.value = e;
    LocalStorageService.instance.setValue(LocalStorageService.kDanmuSpeed, e);
  }

  var danmuArea = 0.8.obs;
  void setDanmuArea(double e) {
    danmuArea.value = e;
    LocalStorageService.instance.setValue(LocalStorageService.kDanmuArea, e);
  }

  var danmuOpacity = 1.0.obs;
  void setDanmuOpacity(double e) {
    danmuOpacity.value = e;
    LocalStorageService.instance.setValue(LocalStorageService.kDanmuOpacity, e);
  }

  var danmuEnable = true.obs;
  void setDanmuEnable(bool e) {
    danmuEnable.value = e;
    LocalStorageService.instance.setValue(LocalStorageService.kDanmuEnable, e);
  }

  var danmuStrokeWidth = 2.0.obs;
  void setDanmuStrokeWidth(double e) {
    danmuStrokeWidth.value = e;
    LocalStorageService.instance
        .setValue(LocalStorageService.kDanmuStrokeWidth, e);
  }

  var danmuFontWeight = 4.obs;
  void setDanmuFontWeight(int e) {
    danmuFontWeight.value = e;
    LocalStorageService.instance
        .setValue(LocalStorageService.kDanmuFontWeight, e);
  }

  static const String _defaultSubtitleModel = "";
  var subtitleEnable = false.obs;
  void setSubtitleEnable(bool e) {
    subtitleEnable.value = e;
    LocalStorageService.instance
        .setValue(LocalStorageService.kSubtitleEnable, e);
  }

  var subtitleFontSize = 16.0.obs;
  void setSubtitleFontSize(double e) {
    subtitleFontSize.value = e;
    LocalStorageService.instance
        .setValue(LocalStorageService.kSubtitleFontSize, e);
  }

  var subtitleBackgroundOpacity = 0.7.obs;
  void setSubtitleBackgroundOpacity(double e) {
    subtitleBackgroundOpacity.value = e;
    LocalStorageService.instance
        .setValue(LocalStorageService.kSubtitleBackgroundOpacity, e);
  }

  var subtitleModelName = _defaultSubtitleModel.obs;
  void setSubtitleModelName(String e) {
    subtitleModelName.value = e;
    LocalStorageService.instance
        .setValue(LocalStorageService.kSubtitleModelName, e);
  }

  var subtitleRecognitionMode = SubtitleRecognitionMode.local.obs;
  void setSubtitleRecognitionMode(SubtitleRecognitionMode mode) {
    subtitleRecognitionMode.value = mode;
    LocalStorageService.instance.setValue(
      LocalStorageService.kSubtitleRecognitionMode,
      mode.index,
    );
  }

  var subtitleOnlineProvider = SubtitleOnlineProvider.customWebSocket.obs;
  void setSubtitleOnlineProvider(SubtitleOnlineProvider provider) {
    subtitleOnlineProvider.value = provider;
    LocalStorageService.instance.setValue(
      LocalStorageService.kSubtitleOnlineProvider,
      provider.index,
    );
  }

  var subtitleOnlineApiUrl = "".obs;
  void setSubtitleOnlineApiUrl(String value) {
    subtitleOnlineApiUrl.value = value;
    LocalStorageService.instance
        .setValue(LocalStorageService.kSubtitleOnlineApiUrl, value);
  }

  var subtitleOnlineApiKey = "".obs;
  void setSubtitleOnlineApiKey(String value) {
    subtitleOnlineApiKey.value = value;
    LocalStorageService.instance
        .setValue(LocalStorageService.kSubtitleOnlineApiKey, value);
  }

  var subtitleOnlineApiKeyHeader = "Authorization".obs;
  void setSubtitleOnlineApiKeyHeader(String value) {
    subtitleOnlineApiKeyHeader.value = value;
    LocalStorageService.instance
        .setValue(LocalStorageService.kSubtitleOnlineApiKeyHeader, value);
  }

  var qualityLevel = 1.obs;
  void setQualityLevel(int level) {
    qualityLevel.value = level;
    LocalStorageService.instance
        .setValue(LocalStorageService.kQualityLevel, level);
  }

  var qualityLevelCellular = 1.obs;
  void setQualityLevelCellular(int level) {
    qualityLevelCellular.value = level;
    LocalStorageService.instance
        .setValue(LocalStorageService.kQualityLevelCellular, level);
  }

  var autoExitEnable = false.obs;
  void setAutoExitEnable(bool e) {
    autoExitEnable.value = e;
    LocalStorageService.instance
        .setValue(LocalStorageService.kAutoExitEnable, e);
  }

  var autoExitDuration = 60.obs;
  void setAutoExitDuration(int e) {
    autoExitDuration.value = e;
    LocalStorageService.instance
        .setValue(LocalStorageService.kAutoExitDuration, e);
  }

  var roomAutoExitDuration = 60.obs;
  void setRoomAutoExitDuration(int e) {
    roomAutoExitDuration.value = e;
    LocalStorageService.instance
        .setValue(LocalStorageService.kRoomAutoExitDuration, e);
  }

  var playerCompatMode = false.obs;
  void setPlayerCompatMode(bool e) {
    playerCompatMode.value = e;
    LocalStorageService.instance
        .setValue(LocalStorageService.kPlayerCompatMode, e);
  }

  var playerBufferSize = 32.obs;
  void setPlayerBufferSize(int e) {
    playerBufferSize.value = e;
    LocalStorageService.instance
        .setValue(LocalStorageService.kPlayerBufferSize, e);
  }

  var playerAutoPause = false.obs;
  void setPlayerAutoPause(bool e) {
    playerAutoPause.value = e;
    LocalStorageService.instance
        .setValue(LocalStorageService.kPlayerAutoPause, e);
  }

  var autoFullScreen = false.obs;
  void setAutoFullScreen(bool e) {
    autoFullScreen.value = e;
    LocalStorageService.instance
        .setValue(LocalStorageService.kAutoFullScreen, e);
  }

  var playershowSuperChat = true.obs;
  void setPlayerShowSuperChat(bool e) {
    playershowSuperChat.value = e;
    LocalStorageService.instance
        .setValue(LocalStorageService.kPlayerShowSuperChat, e);
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
    scaleMode.value = value;
    LocalStorageService.instance.setValue(
      LocalStorageService.kPlayerScaleMode,
      value,
    );
  }

  RxList<String> siteSort = RxList<String>();
  void setSiteSort(List<String> e) {
    siteSort.value = e;
    LocalStorageService.instance.setValue(
      LocalStorageService.kSiteSort,
      siteSort.join(","),
    );
  }

  RxList<String> homeSort = RxList<String>();
  void setHomeSort(List<String> e) {
    homeSort.value = e;
    LocalStorageService.instance.setValue(
      LocalStorageService.kHomeSort,
      homeSort.join(","),
    );
  }

  Rx<double> playerVolume = 100.0.obs;
  void setPlayerVolume(double value) {
    playerVolume.value = value;
    LocalStorageService.instance.setValue(
      LocalStorageService.kPlayerVolume,
      value,
    );
  }

  var pipHideDanmu = true.obs;
  void setPIPHideDanmu(bool e) {
    pipHideDanmu.value = e;
    LocalStorageService.instance.setValue(LocalStorageService.kPIPHideDanmu, e);
  }

  var styleColor = 0xff3498db.obs;
  void setStyleColor(int e) {
    styleColor.value = e;
    LocalStorageService.instance.setValue(LocalStorageService.kStyleColor, e);
  }

  var isDynamic = false.obs;
  void setIsDynamic(bool e) {
    isDynamic.value = e;
    LocalStorageService.instance.setValue(LocalStorageService.kIsDynamic, e);
  }

  var danmuTopMargin = 0.0.obs;
  void setDanmuTopMargin(double e) {
    danmuTopMargin.value = e;
    LocalStorageService.instance
        .setValue(LocalStorageService.kDanmuTopMargin, e);
  }

  var danmuBottomMargin = 0.0.obs;
  void setDanmuBottomMargin(double e) {
    danmuBottomMargin.value = e;
    LocalStorageService.instance
        .setValue(LocalStorageService.kDanmuBottomMargin, e);
  }

  var bilibiliLoginTip = true.obs;
  void setBiliBiliLoginTip(bool e) {
    bilibiliLoginTip.value = e;
    LocalStorageService.instance
        .setValue(LocalStorageService.kBilibiliLoginTip, e);
  }

  var logEnable = false.obs;
  void setLogEnable(bool e) {
    logEnable.value = e;
    LocalStorageService.instance.setValue(LocalStorageService.kLogEnable, e);
  }

  var customPlayerOutput = false.obs;
  void setCustomPlayerOutput(bool e) {
    customPlayerOutput.value = e;
    LocalStorageService.instance
        .setValue(LocalStorageService.kCustomPlayerOutput, e);
  }

  var videoOutputDriver = "".obs;
  void setVideoOutputDriver(String e) {
    videoOutputDriver.value = e;
    LocalStorageService.instance
        .setValue(LocalStorageService.kVideoOutputDriver, e);
  }

  var audioOutputDriver = "".obs;
  void setAudioOutputDriver(String e) {
    audioOutputDriver.value = e;
    LocalStorageService.instance
        .setValue(LocalStorageService.kAudioOutputDriver, e);
  }

  var videoHardwareDecoder = "".obs;
  void setVideoHardwareDecoder(String e) {
    videoHardwareDecoder.value = e;
    LocalStorageService.instance
        .setValue(LocalStorageService.kVideoHardwareDecoder, e);
  }

  var autoUpdateFollowEnable = false.obs;
  void setAutoUpdateFollowEnable(bool e) {
    autoUpdateFollowEnable.value = e;
    LocalStorageService.instance
        .setValue(LocalStorageService.kAutoUpdateFollowEnable, e);
  }

  var autoUpdateFollowDuration = 10.obs;
  void setAutoUpdateFollowDuration(int e) {
    autoUpdateFollowDuration.value = e;
    LocalStorageService.instance
        .setValue(LocalStorageService.kUpdateFollowDuration, e);
  }

  var updateFollowThreadCount = 4.obs;
  void setUpdateFollowThreadCount(int e) {
    updateFollowThreadCount.value = e;
    LocalStorageService.instance
        .setValue(LocalStorageService.kUpdateFollowThreadCount, e);
  }

  var playerForceHttps = false.obs;
  void setPlayerForceHttps(bool e) {
    playerForceHttps.value = e;
    LocalStorageService.instance
        .setValue(LocalStorageService.kPlayerForceHttps, e);
  }

  var audioOnlyMode = false.obs;
  void setAudioOnlyMode(bool e) {
    audioOnlyMode.value = e;
    LocalStorageService.instance
        .setValue(LocalStorageService.kAudioOnlyMode, e);
  }

  var backgroundKeepAlive = true.obs;
  void setBackgroundKeepAlive(bool e) {
    backgroundKeepAlive.value = e;
    LocalStorageService.instance
        .setValue(LocalStorageService.kBackgroundKeepAlive, e);
  }

  var windowsTrayIntegration = true.obs;
  void setWindowsTrayIntegration(bool e) {
    windowsTrayIntegration.value = e;
    LocalStorageService.instance
        .setValue(LocalStorageService.kWindowsTrayIntegration, e);
  }

  var ghostMode = false.obs;
  void setGhostMode(bool e) {
    ghostMode.value = e;
    LocalStorageService.instance.setValue(LocalStorageService.kGhostMode, e);
  }

  var ghostPanelColor = 0xBFD0D0D0.obs;
  void setGhostPanelColor(int value) {
    ghostPanelColor.value = value;
    LocalStorageService.instance
        .setValue(LocalStorageService.kGhostPanelColor, value);
  }

  var autoSpamTextMsg = "".obs;
  void setAutoSpamTextMsg(String value) {
    autoSpamTextMsg.value = value;
    LocalStorageService.instance
        .setValue(LocalStorageService.kAutoSpamTextMsg, value);
  }

  var autoSpamTextInterval = 5.obs;
  void setAutoSpamTextInterval(int value) {
    autoSpamTextInterval.value = value;
    LocalStorageService.instance
        .setValue(LocalStorageService.kAutoSpamTextInterval, value);
  }

  var autoSpamTextChunkSize = 20.obs;
  void setAutoSpamTextChunkSize(int value) {
    autoSpamTextChunkSize.value = value;
    LocalStorageService.instance
        .setValue(LocalStorageService.kAutoSpamTextChunkSize, value);
  }

  var autoSpamTextDuration = 0.obs;
  void setAutoSpamTextDuration(int value) {
    autoSpamTextDuration.value = value;
    LocalStorageService.instance
        .setValue(LocalStorageService.kAutoSpamTextDuration, value);
  }

  var autoSpamEmotionInterval = 5.obs;
  void setAutoSpamEmotionInterval(int value) {
    autoSpamEmotionInterval.value = value;
    LocalStorageService.instance
        .setValue(LocalStorageService.kAutoSpamEmotionInterval, value);
  }

  var autoSpamEmotionDuration = 0.obs;
  void setAutoSpamEmotionDuration(int value) {
    autoSpamEmotionDuration.value = value;
    LocalStorageService.instance
        .setValue(LocalStorageService.kAutoSpamEmotionDuration, value);
  }

  RxList<Map<String, dynamic>> autoSpamEmotions = <Map<String, dynamic>>[].obs;
  void setAutoSpamEmotions(List<Map<String, dynamic>> values) {
    autoSpamEmotions.assignAll(values);
    LocalStorageService.instance.setValue(
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
    autoSpamFavorites.assignAll(values);
    LocalStorageService.instance.setValue(
      LocalStorageService.kAutoSpamFavorites,
      values,
    );
  }

  void setAutoSpamFavoritesIndex(int value) {
    autoSpamFavoritesIndex.value = value;
    LocalStorageService.instance
        .setValue(LocalStorageService.kAutoSpamFavoritesIndex, value);
  }

  void setAutoSpamFavoritesInterval(int value) {
    autoSpamFavoritesInterval.value = value;
    LocalStorageService.instance
        .setValue(LocalStorageService.kAutoSpamFavoritesInterval, value);
  }

  void setAutoSpamFavoritesDuration(int value) {
    autoSpamFavoritesDuration.value = value;
    LocalStorageService.instance
        .setValue(LocalStorageService.kAutoSpamFavoritesDuration, value);
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
    LocalStorageService.instance.setValue(
      LocalStorageService.kEmoticonPackageDisabled,
      emoticonPackageDisabled.toList(),
    );
  }
}
