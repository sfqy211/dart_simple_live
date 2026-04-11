import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/widgets/settings/settings_card.dart';
import 'package:simple_live_app/widgets/settings/settings_menu.dart';
import 'package:simple_live_app/widgets/settings/settings_number.dart';
import 'package:simple_live_app/widgets/settings/settings_switch.dart';
import 'package:simple_live_app/widgets/settings/settings_workspace.dart';

class PlaySettingsPage extends GetView<AppSettingsController> {
  const PlaySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsPageScaffold(
      title: "直播设置",
      subtitle: "播放、任务栏与透明浮窗相关选项",
      body: PlaySettingsView(),
    );
  }
}

class PlaySettingsView extends GetView<AppSettingsController> {
  const PlaySettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppStyle.contentPadding(context),
      children: [
        const SettingsSectionTitle(
          title: "播放器",
          subtitle: "播放器内核、尺寸模式与桌面端行为控制。",
        ),
        SettingsCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(
                () => SettingsSwitch(
                  title: "硬件解码",
                  value: controller.hardwareDecode.value,
                  subtitle: "播放失败时可尝试关闭这一项",
                  onChanged: controller.setHardwareDecode,
                ),
              ),
              AppStyle.divider,
              Obx(
                () => SettingsSwitch(
                  title: "进入后台自动暂停",
                  value: controller.playerAutoPause.value,
                  onChanged: controller.setPlayerAutoPause,
                ),
              ),
              AppStyle.divider,
              Obx(
                () => SettingsMenu<int>(
                  title: "画面尺寸",
                  value: controller.scaleMode.value,
                  valueMap: const {
                    0: "适应",
                    1: "拉伸",
                    2: "铺满",
                    3: "16:9",
                    4: "4:3",
                  },
                  onChanged: controller.setScaleMode,
                ),
              ),
              AppStyle.divider,
              Obx(
                () => SettingsSwitch(
                  title: "使用 HTTPS 链接",
                  subtitle: "将 http 链接替换为 https",
                  value: controller.playerForceHttps.value,
                  onChanged: controller.setPlayerForceHttps,
                ),
              ),
              AppStyle.divider,
              Obx(
                () => SettingsSwitch(
                  title: "Windows 任务栏托盘集成",
                  subtitle: "点击关闭按钮时最小化到托盘",
                  value: controller.windowsTrayIntegration.value,
                  onChanged: controller.setWindowsTrayIntegration,
                ),
              ),
              AppStyle.divider,
              Obx(
                () => SettingsSwitch(
                  title: "透明浮窗模式",
                  subtitle: "边工作边看直播的桌面模式",
                  value: controller.ghostMode.value,
                  onChanged: controller.setGhostMode,
                ),
              ),
            ],
          ),
        ),
        AppStyle.vGap24,
        const SettingsSectionTitle(
          title: "直播间",
          subtitle: "控制进入直播间后的默认行为。",
        ),
        SettingsCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(
                () => SettingsSwitch(
                  title: "进入直播间自动全屏",
                  value: controller.autoFullScreen.value,
                  onChanged: controller.setAutoFullScreen,
                ),
              ),
              AppStyle.divider,
              Obx(
                () => SettingsSwitch(
                  title: "播放器中显示 SC",
                  value: controller.playershowSuperChat.value,
                  onChanged: controller.setPlayerShowSuperChat,
                ),
              ),
            ],
          ),
        ),
        AppStyle.vGap24,
        const SettingsSectionTitle(
          title: "清晰度",
          subtitle: "根据网络环境设定默认清晰度偏好。",
        ),
        SettingsCard(
          child: Column(
            children: [
              Obx(
                () => SettingsMenu<int>(
                  title: "默认清晰度",
                  value: controller.qualityLevel.value,
                  valueMap: const {
                    0: "最低",
                    1: "中等",
                    2: "最高",
                  },
                  onChanged: controller.setQualityLevel,
                ),
              ),
              AppStyle.divider,
              Obx(
                () => SettingsMenu<int>(
                  title: "数据网络清晰度",
                  value: controller.qualityLevelCellular.value,
                  valueMap: const {
                    0: "最低",
                    1: "中等",
                    2: "最高",
                  },
                  onChanged: controller.setQualityLevelCellular,
                ),
              ),
            ],
          ),
        ),
        AppStyle.vGap24,
        const SettingsSectionTitle(
          title: "聊天区",
          subtitle: "右侧聊天区的密度与显示样式。",
        ),
        SettingsCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(
                () => SettingsNumber(
                  title: "文字大小",
                  value: controller.chatTextSize.value.toInt(),
                  min: 8,
                  max: 36,
                  onChanged: (value) {
                    controller.setChatTextSize(value.toDouble());
                  },
                ),
              ),
              AppStyle.divider,
              Obx(
                () => SettingsNumber(
                  title: "上下间隔",
                  value: controller.chatTextGap.value.toInt(),
                  min: 0,
                  max: 12,
                  onChanged: (value) {
                    controller.setChatTextGap(value.toDouble());
                  },
                ),
              ),
              AppStyle.divider,
              Obx(
                () => SettingsSwitch(
                  title: "气泡样式",
                  value: controller.chatBubbleStyle.value,
                  onChanged: controller.setChatBubbleStyle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
