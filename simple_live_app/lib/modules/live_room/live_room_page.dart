import 'dart:io';

import 'package:floating/floating.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:remixicon/remixicon.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/constant.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/modules/live_room/live_room_controller.dart';
import 'package:simple_live_app/modules/live_room/player/player_controls.dart';
import 'package:simple_live_app/modules/live_room/player/audio_mode_cover.dart';
import 'package:simple_live_app/services/follow_service.dart';
import 'package:simple_live_app/routes/route_path.dart';
import 'package:simple_live_app/widgets/desktop_refresh_button.dart';
import 'package:simple_live_app/widgets/follow_user_item.dart';
import 'package:simple_live_app/widgets/keep_alive_wrapper.dart';
import 'package:simple_live_app/widgets/net_image.dart';
import 'package:simple_live_app/widgets/app_shell.dart';
import 'package:simple_live_app/widgets/settings/settings_action.dart';
import 'package:simple_live_app/widgets/settings/settings_card.dart';
import 'package:simple_live_app/widgets/settings/settings_number.dart';
import 'package:simple_live_app/widgets/settings/settings_switch.dart';
import 'package:simple_live_app/widgets/superchat_card.dart';
import 'package:simple_live_core/simple_live_core.dart';

class LiveRoomPage extends GetView<LiveRoomController> {
  const LiveRoomPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final page = Obx(
      () {
        if (controller.loadError.value) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("直播间加载失败"),
            ),
            body: Padding(
              padding: AppStyle.edgeInsetsA12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LottieBuilder.asset(
                    'assets/lotties/error.json',
                    height: 140,
                    repeat: false,
                  ),
                  const Text(
                    "直播间加载失败",
                    textAlign: TextAlign.center,
                  ),
                  AppStyle.vGap4,
                  Text(
                    controller.error?.toString() ?? "未知错误",
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  AppStyle.vGap4,
                  Text(
                    "${controller.rxSite.value.id} - ${controller.rxRoomId.value}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: controller.copyErrorDetail,
                        icon: const Icon(Remix.file_copy_line),
                        label: const Text("复制信息"),
                      ),
                      TextButton.icon(
                        onPressed: controller.refreshRoom,
                        icon: const Icon(Remix.refresh_line),
                        label: const Text("刷新"),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        }
        if (controller.fullScreenState.value) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (e, r) {
              controller.exitFull();
            },
            child: Scaffold(
              body: buildMediaPlayer(),
            ),
          );
        } else {
          return buildPageUI();
        }
      },
    );
    if (!Platform.isAndroid) {
      return page;
    }
    return PiPSwitcher(
      floating: controller.pip,
      childWhenDisabled: page,
      childWhenEnabled: buildMediaPlayer(),
    );
  }

  Widget buildPageUI() {
    return OrientationBuilder(
      builder: (context, orientation) {
        final isDesktop = AppStyle.isDesktopLayout(context);
        return Scaffold(
          backgroundColor: isDesktop
              ? Colors.transparent
              : Theme.of(context).scaffoldBackgroundColor,
          appBar: isDesktop
              ? null
              : AppBar(
                  title: Obx(
                    () => Text(controller.detail.value?.title ?? "直播间"),
                  ),
                  actions: buildAppbarActions(context),
                ),
          body: isDesktop
              ? buildDesktopUI(context)
              : orientation == Orientation.portrait
                  ? buildPhoneUI(context)
                  : buildTabletUI(context),
        );
      },
    );
  }

  Widget buildDesktopUI(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final borderColor =
        AppStyle.borderColor(context).withAlpha(Get.isDarkMode ? 120 : 180);
    final panelColor = theme.cardColor;

    Widget buildQuickChip({
      required IconData icon,
      required String label,
      required bool selected,
      required ValueChanged<bool>? onSelected,
      String? tooltip,
    }) {
      final chip = FilterChip(
        showCheckmark: false,
        avatar: Icon(icon, size: 16),
        label: Text(label),
        selected: selected,
        onSelected: onSelected,
        side: BorderSide(
          color: selected
              ? scheme.primary.withAlpha(Get.isDarkMode ? 84 : 68)
              : borderColor,
        ),
        backgroundColor: panelColor,
        selectedColor: scheme.primary.withAlpha(Get.isDarkMode ? 24 : 14),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        labelStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      );
      if (tooltip == null || tooltip.isEmpty) {
        return chip;
      }
      return Tooltip(message: tooltip, child: chip);
    }

    Widget buildSecondaryAction({
      required IconData icon,
      required String label,
      required VoidCallback onPressed,
    }) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: borderColor),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          backgroundColor: panelColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      );
    }

    Widget buildStatTile({
      required IconData icon,
      required String label,
      required String value,
    }) {
      return Container(
        constraints: const BoxConstraints(minWidth: 140),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: scheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return AppShellFrame(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: panelColor,
              border: Border(
                bottom: BorderSide(color: borderColor),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: "返回",
                      onPressed: Get.back,
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Obx(
                        () => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              controller.detail.value?.title ?? "直播间",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.1,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.asset(
                                    controller.site.logo,
                                    width: 14,
                                    height: 14,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    controller.detail.value?.userName ?? "",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Icon(
                                  Remix.fire_fill,
                                  size: 14,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  Utils.onlineToString(
                                    controller.detail.value?.online ?? 0,
                                  ),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      tooltip: "刷新",
                      onPressed: controller.refreshRoom,
                      icon: const Icon(Remix.refresh_line),
                    ),
                    Obx(
                      () => IconButton(
                        tooltip: controller.followed.value ? "取消关注" : "关注",
                        onPressed: controller.followed.value
                            ? controller.removeFollowUser
                            : controller.followUser,
                        icon: Icon(
                          controller.followed.value
                              ? Remix.heart_fill
                              : Remix.heart_line,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: "分享",
                      onPressed: controller.share,
                      icon: const Icon(Remix.share_line),
                    ),
                    IconButton(
                      tooltip: "更多",
                      onPressed: showMore,
                      icon: const Icon(Icons.more_horiz),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Obx(
                  () {
                    final isAudio = controller.audioOnlyMode.value;
                    final isGhost = controller.ghostModeState.value;
                    final isMini = controller.smallWindowState.value;
                    final isSubtitle = controller.subtitleEnabled.value;
                    final canToggleGhost = isAudio || isGhost;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        buildQuickChip(
                          icon: isAudio
                              ? Remix.video_line
                              : Icons.headphones_outlined,
                          label: isAudio ? "视频" : "黑听",
                          selected: isAudio,
                          onSelected: (_) => controller.toggleAudioMode(),
                        ),
                        buildQuickChip(
                          icon: Icons.blur_on_outlined,
                          label: "透明浮窗",
                          selected: isGhost,
                          onSelected: canToggleGhost
                              ? (_) => controller.toggleGhostMode()
                              : null,
                          tooltip: canToggleGhost ? null : "需先开启黑听模式",
                        ),
                        buildQuickChip(
                          icon: Icons.picture_in_picture_alt_outlined,
                          label: "小窗",
                          selected: isMini,
                          onSelected: (selected) {
                            if (selected) {
                              controller.enterSmallWindow();
                            } else {
                              controller.exitSmallWindow();
                            }
                          },
                        ),
                        buildQuickChip(
                          icon: Icons.subtitles_outlined,
                          label: "字幕",
                          selected: isSubtitle,
                          onSelected: (selected) {
                            AppSettingsController.instance
                                .setSubtitleEnable(selected);
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final sideW = (constraints.maxWidth * 0.32).clamp(360.0, 440.0);
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              color: const Color(0xFF05070A),
                              child: Center(
                                child: buildMediaPlayer(),
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: panelColor,
                              border: Border(
                                top: BorderSide(color: borderColor),
                              ),
                            ),
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            child: Obx(
                              () => Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          controller.audioOnlyMode.value
                                              ? "黑听工作区"
                                              : "播放工作区",
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          controller.audioOnlyMode.value
                                              ? "保留聊天与字幕，把界面收束成更安静的桌面陪伴模式。"
                                              : "让视频保持主角位置，把高频调整收纳到更克制的次级层。",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: scheme.onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    alignment: WrapAlignment.end,
                                    children: [
                                      buildSecondaryAction(
                                        icon: Icons.high_quality_outlined,
                                        label: "清晰度",
                                        onPressed: controller.showQualitySheet,
                                      ),
                                      buildSecondaryAction(
                                        icon: Icons.route_outlined,
                                        label: "线路",
                                        onPressed: controller.showPlayUrlsSheet,
                                      ),
                                      buildSecondaryAction(
                                        icon: Icons.crop_free_outlined,
                                        label: "画面",
                                        onPressed:
                                            controller.showPlayerSettingsSheet,
                                      ),
                                      buildSecondaryAction(
                                        icon: Icons.camera_alt_outlined,
                                        label: "截图",
                                        onPressed: controller.saveScreenshot,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      color: borderColor,
                    ),
                    SizedBox(
                      width: sideW,
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: panelColor,
                              border: Border(
                                bottom: BorderSide(color: borderColor),
                              ),
                            ),
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                            child: Obx(
                              () => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      NetImage(
                                        controller.detail.value?.userAvatar ??
                                            "",
                                        width: 56,
                                        height: 56,
                                        borderRadius: 4,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              controller
                                                      .detail.value?.userName ??
                                                  "",
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              controller.detail.value?.title ??
                                                  "直播间",
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color:
                                                        scheme.onSurfaceVariant,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      buildStatTile(
                                        icon: Icons.public_outlined,
                                        label: "平台",
                                        value: controller.site.name,
                                      ),
                                      buildStatTile(
                                        icon: Remix.fire_fill,
                                        label: "热度",
                                        value: Utils.onlineToString(
                                          controller.detail.value?.online ?? 0,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: controller.copyUrl,
                                          icon: const Icon(Icons.link_outlined),
                                          label: const Text("复制链接"),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: controller.share,
                                          icon: const Icon(Remix.share_line),
                                          label: const Text("分享"),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              color: panelColor,
                              child: buildMessageArea(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPhoneUI(BuildContext context) {
    final borderColor =
        AppStyle.borderColor(context).withAlpha(Get.isDarkMode ? 120 : 180);
    return Stack(
      children: [
        Obx(() {
          if (controller.audioOnlyMode.value) {
            // 黑听模式：显示控制界面和弹幕栏
            return Column(
              children: [
                // 黑听模式控制界面
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border(
                      bottom: BorderSide(
                        color: borderColor,
                      ),
                    ),
                  ),
                  padding: AppStyle.edgeInsetsA12,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              "纯净黑听模式",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: controller.toggleAudioMode,
                            icon: const Icon(Remix.video_line),
                            label: const Text("切换到视频模式"),
                          ),
                        ],
                      ),
                      AppStyle.vGap12,
                      Row(
                        children: [
                          Icon(
                            Icons.volume_down,
                            size: 20,
                            color: Theme.of(context).iconTheme.color,
                          ),
                          Expanded(
                            child: Obx(
                              () => Slider(
                                value: AppSettingsController
                                    .instance.playerVolume.value,
                                min: 0,
                                max: 100,
                                onChanged: (value) {
                                  controller.player.setVolume(value);
                                  AppSettingsController.instance
                                      .setPlayerVolume(value);
                                },
                              ),
                            ),
                          ),
                          Obx(
                            () => Text(
                              "${AppSettingsController.instance.playerVolume.value.toInt()}%",
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                buildUserProfile(context),
                Expanded(
                  child: buildMessageArea(),
                ),
                buildBottomActions(context),
              ],
            );
          } else {
            // 正常模式：显示视频栏和弹幕栏
            return Column(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: buildMediaPlayer(),
                ),
                buildUserProfile(context),
                Expanded(
                  child: buildMessageArea(),
                ),
                buildBottomActions(context),
              ],
            );
          }
        }),
        buildFloatingSubtitleBar(context),
      ],
    );
  }

  Widget buildTabletUI(BuildContext context) {
    final borderColor =
        AppStyle.borderColor(context).withAlpha(Get.isDarkMode ? 120 : 180);
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: Obx(() {
                if (controller.audioOnlyMode.value) {
                  return Row(
                    children: [
                      Container(
                        width: 320,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          border: Border(
                            right: BorderSide(
                              color: borderColor,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                border: Border(
                                  bottom: BorderSide(
                                    color: borderColor,
                                  ),
                                ),
                              ),
                              padding: AppStyle.edgeInsetsA12,
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          "纯净黑听模式",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      ElevatedButton.icon(
                                        onPressed: controller.toggleAudioMode,
                                        icon: const Icon(Remix.video_line),
                                        label: const Text("切换到视频模式"),
                                      ),
                                    ],
                                  ),
                                  AppStyle.vGap12,
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.volume_down,
                                        size: 20,
                                        color:
                                            Theme.of(context).iconTheme.color,
                                      ),
                                      Expanded(
                                        child: Obx(
                                          () => Slider(
                                            value: AppSettingsController
                                                .instance.playerVolume.value,
                                            min: 0,
                                            max: 100,
                                            onChanged: (value) {
                                              controller.player
                                                  .setVolume(value);
                                              AppSettingsController.instance
                                                  .setPlayerVolume(value);
                                            },
                                          ),
                                        ),
                                      ),
                                      Obx(
                                        () => Text(
                                          "${AppSettingsController.instance.playerVolume.value.toInt()}%",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.color,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            buildUserProfile(context),
                          ],
                        ),
                      ),
                      Expanded(
                        child: buildMessageArea(),
                      ),
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      Expanded(
                        flex: 7,
                        child: Container(
                          color: Colors.black,
                          child: Center(
                            child: buildMediaPlayer(),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            buildUserProfile(context),
                            Expanded(
                              child: buildMessageArea(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
              }),
            ),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                  top: BorderSide(
                    color: borderColor,
                  ),
                ),
              ),
              padding: AppStyle.edgeInsetsV4.copyWith(
                bottom: AppStyle.bottomBarHeight + 4,
              ),
              child: Row(
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      textStyle: const TextStyle(fontSize: 14),
                    ),
                    onPressed: controller.refreshRoom,
                    icon: const Icon(Remix.refresh_line),
                    label: const Text("刷新"),
                  ),
                  AppStyle.hGap4,
                  Obx(
                    () => controller.followed.value
                        ? TextButton.icon(
                            style: TextButton.styleFrom(
                              textStyle: const TextStyle(fontSize: 14),
                            ),
                            onPressed: controller.removeFollowUser,
                            icon: const Icon(Remix.heart_fill),
                            label: const Text("取消关注"),
                          )
                        : TextButton.icon(
                            style: TextButton.styleFrom(
                              textStyle: const TextStyle(fontSize: 14),
                            ),
                            onPressed: controller.followUser,
                            icon: const Icon(Remix.heart_line),
                            label: const Text("关注"),
                          ),
                  ),
                  const Expanded(child: Center()),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      textStyle: const TextStyle(fontSize: 14),
                    ),
                    onPressed: controller.share,
                    icon: const Icon(Remix.share_line),
                    label: const Text("分享"),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      textStyle: const TextStyle(fontSize: 14),
                    ),
                    onPressed: controller.copyUrl,
                    icon: const Icon(Remix.file_copy_line),
                    label: const Text("复制链接"),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      textStyle: const TextStyle(fontSize: 14),
                    ),
                    onPressed: controller.copyPlayUrl,
                    icon: const Icon(Remix.file_copy_line),
                    label: const Text("复制播放直链"),
                  ),
                ],
              ),
            ),
          ],
        ),
        buildFloatingSubtitleBar(context),
      ],
    );
  }

  Widget buildMediaPlayer() {
    var boxFit = BoxFit.contain;
    double? aspectRatio;
    if (AppSettingsController.instance.scaleMode.value == 0) {
      boxFit = BoxFit.contain;
    } else if (AppSettingsController.instance.scaleMode.value == 1) {
      boxFit = BoxFit.fill;
    } else if (AppSettingsController.instance.scaleMode.value == 2) {
      boxFit = BoxFit.cover;
    } else if (AppSettingsController.instance.scaleMode.value == 3) {
      boxFit = BoxFit.contain;
      aspectRatio = 16 / 9;
    } else if (AppSettingsController.instance.scaleMode.value == 4) {
      boxFit = BoxFit.contain;
      aspectRatio = 4 / 3;
    }

    return Obx(() {
      return Stack(
        children: [
          Video(
            key: controller.globalPlayerKey,
            controller: controller.videoController,
            pauseUponEnteringBackgroundMode:
                AppSettingsController.instance.playerAutoPause.value,
            resumeUponEnteringForegroundMode:
                AppSettingsController.instance.playerAutoPause.value,
            controls: (state) {
              return Stack(
                children: [
                  Obx(
                    () => Visibility(
                      visible: controller.audioOnlyMode.value,
                      child: const AudioModeCover(),
                    ),
                  ),
                  playerControls(state, controller),
                ],
              );
            },
            aspectRatio: aspectRatio,
            fit: boxFit,
            wakelock: false,
          ),
          buildSubtitleOverlay(),
          Obx(
            () => Visibility(
              visible: !controller.liveStatus.value,
              child: const Center(
                child: Text(
                  "未开播",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget buildSubtitleOverlay() {
    return Obx(
      () {
        if (!controller.subtitleEnabled.value) {
          return const SizedBox.shrink();
        }
        if (controller.subtitleText.value.isEmpty) {
          return const SizedBox.shrink();
        }
        if (!controller.fullScreenState.value &&
            !controller.smallWindowState.value) {
          return const SizedBox.shrink();
        }
        return Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              // 【修改 1】将 withOpacity 改为 withValues(alpha: ...)
              color: Colors.black.withValues(
                  alpha: AppSettingsController
                      .instance.subtitleBackgroundOpacity.value),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              controller.subtitleText.value,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: AppSettingsController.instance.subtitleFontSize.value,
                fontWeight: controller.subtitleIsPartial.value
                    ? FontWeight.normal
                    : FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildFloatingSubtitleBar(BuildContext context) {
    return Obx(
      () {
        if (controller.fullScreenState.value ||
            controller.smallWindowState.value) {
          return const SizedBox.shrink();
        }
        if (!controller.subtitleEnabled.value ||
            controller.subtitleText.value.isEmpty) {
          return const SizedBox.shrink();
        }

        // 动态计算底部距离，避免遮挡输入框
        // 手机模式下，如果有底部操作栏或输入框，需要抬高位置
        // 平板模式下，如果有输入框，也需要抬高位置
        double bottomPadding = AppStyle.bottomBarHeight + 60;

        // 如果是 B站且有输入框，需要额外抬高
        if (controller.site.id == Constant.kBiliBili) {
          bottomPadding += 60; // 预估输入框高度
        }

        // 使用自定义位置或默认位置
        final offset = controller.subtitlePosition.value;

        if (offset != null) {
          return Positioned(
            left: offset.dx,
            top: offset.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                // 更新位置
                final newOffset =
                    controller.subtitlePosition.value! + details.delta;
                // 简单的边界限制，防止完全拖出屏幕
                final size = MediaQuery.of(context).size;
                if (newOffset.dx > -100 &&
                    newOffset.dx < size.width - 20 &&
                    newOffset.dy > 50 &&
                    newOffset.dy < size.height - 50) {
                  controller.subtitlePosition.value = newOffset;
                }
              },
              child: Container(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width - 40),
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  // 【修改 2】将 withOpacity 改为 withValues(alpha: ...)
                  color: Theme.of(context).cardColor.withValues(
                      alpha: AppSettingsController
                          .instance.subtitleBackgroundOpacity.value),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withAlpha(40)),
                ),
                child: Text(
                  controller.subtitleText.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize:
                        AppSettingsController.instance.subtitleFontSize.value,
                    fontWeight: controller.subtitleIsPartial.value
                        ? FontWeight.normal
                        : FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }

        return Positioned(
          left: 12,
          right: 12,
          bottom: bottomPadding,
          child: GestureDetector(
            onPanStart: (details) {
              // 开始拖动时，计算当前的绝对位置并初始化 subtitlePosition
              // 由于是 bottom 定位，需要转换为 top/left
              // 但这里我们简单处理：第一次拖动时，将位置设置到手指所在位置附近
              controller.subtitlePosition.value =
                  details.globalPosition - const Offset(50, 20);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                // 【修改 3】将 withOpacity 改为 withValues(alpha: ...)
                color: Theme.of(context).cardColor.withValues(
                    alpha: AppSettingsController
                        .instance.subtitleBackgroundOpacity.value),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withAlpha(40)),
              ),
              child: Text(
                controller.subtitleText.value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize:
                      AppSettingsController.instance.subtitleFontSize.value,
                  fontWeight: controller.subtitleIsPartial.value
                      ? FontWeight.normal
                      : FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildUserProfile(BuildContext context) {
    final borderColor =
        AppStyle.borderColor(context).withAlpha(Get.isDarkMode ? 120 : 180);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: borderColor,
          ),
          bottom: BorderSide(
            color: borderColor,
          ),
        ),
      ),
      padding: AppStyle.edgeInsetsA8.copyWith(
        left: 12,
        right: 12,
      ),
      child: Obx(
        () => Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: borderColor.withAlpha(Get.isDarkMode ? 160 : 200),
                ),
                borderRadius: AppStyle.radius24,
              ),
              child: NetImage(
                controller.detail.value?.userAvatar ?? "",
                width: 48,
                height: 48,
                borderRadius: 24,
              ),
            ),
            AppStyle.hGap12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.detail.value?.userName ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppStyle.vGap4,
                  Row(
                    children: [
                      Image.asset(
                        controller.site.logo,
                        width: 20,
                      ),
                      AppStyle.hGap4,
                      Text(
                        controller.site.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppStyle.mutedTextColor(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AppStyle.hGap12,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Remix.fire_fill,
                  size: 20,
                  color: Colors.orange,
                ),
                AppStyle.hGap4,
                Text(
                  Utils.onlineToString(
                    controller.detail.value?.online ?? 0,
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBottomActions(BuildContext context) {
    final borderColor =
        AppStyle.borderColor(context).withAlpha(Get.isDarkMode ? 120 : 180);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: borderColor,
          ),
        ),
      ),
      padding: EdgeInsets.only(bottom: AppStyle.bottomBarHeight),
      child: Row(
        children: [
          Expanded(
            child: Obx(
              () => controller.followed.value
                  ? TextButton.icon(
                      style: TextButton.styleFrom(
                        textStyle: const TextStyle(fontSize: 14),
                      ),
                      onPressed: controller.removeFollowUser,
                      icon: const Icon(Remix.heart_fill),
                      label: const Text("取消关注"),
                    )
                  : TextButton.icon(
                      style: TextButton.styleFrom(
                        textStyle: const TextStyle(fontSize: 14),
                      ),
                      onPressed: controller.followUser,
                      icon: const Icon(Remix.heart_line),
                      label: const Text("关注"),
                    ),
            ),
          ),
          Expanded(
            child: TextButton.icon(
              style: TextButton.styleFrom(
                textStyle: const TextStyle(fontSize: 14),
              ),
              onPressed: controller.refreshRoom,
              icon: const Icon(Remix.refresh_line),
              label: const Text("刷新"),
            ),
          ),
          Expanded(
            child: TextButton.icon(
              style: TextButton.styleFrom(
                textStyle: const TextStyle(fontSize: 14),
              ),
              onPressed: controller.share,
              icon: const Icon(Remix.share_line),
              label: const Text("分享"),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMessageArea() {
    final context = Get.context!;
    final theme = Theme.of(context);
    final isDesktop = AppStyle.isDesktopLayout(context);
    final borderColor =
        AppStyle.borderColor(context).withAlpha(Get.isDarkMode ? 120 : 180);
    final tabs = <Widget>[
      const Tab(text: "鑱婂ぉ"),
      if (controller.site.id == Constant.kBiliBili)
        Tab(
          child: Obx(
            () => Text(
              controller.superChats.isNotEmpty
                  ? "SC(${controller.superChats.length})"
                  : "SC",
            ),
          ),
        ),
      const Tab(text: "鍏虫敞"),
      const Tab(text: "璁剧疆"),
    ];
    return DefaultTabController(
      length: tabs.length,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
        ),
        child: Column(
          children: [
            if (isDesktop)
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border(
                    bottom: BorderSide(color: borderColor),
                  ),
                ),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.label,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 10),
                  indicatorWeight: 2,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  dividerColor: Colors.transparent,
                  tabs: [
                    const Tab(
                      text: "聊天",
                    ),
                    if (controller.site.id == Constant.kBiliBili)
                      Tab(
                        child: Obx(
                          () => Text(
                            controller.superChats.isNotEmpty
                                ? "SC(${controller.superChats.length})"
                                : "SC",
                          ),
                        ),
                      ),
                    const Tab(
                      text: "关注",
                    ),
                    const Tab(
                      text: "设置",
                    ),
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  border: Border(
                    bottom: BorderSide(color: borderColor),
                  ),
                ),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelPadding: EdgeInsets.zero,
                  indicatorWeight: 1.0,
                  dividerColor: Colors.transparent,
                  tabs: [
                    const Tab(
                      text: "聊天",
                    ),
                    if (controller.site.id == Constant.kBiliBili)
                      Tab(
                        child: Obx(
                          () => Text(
                            controller.superChats.isNotEmpty
                                ? "SC(${controller.superChats.length})"
                                : "SC",
                          ),
                        ),
                      ),
                    const Tab(
                      text: "关注",
                    ),
                    const Tab(
                      text: "设置",
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ColoredBox(
                color: theme.scaffoldBackgroundColor,
                child: TabBarView(
                  children: [
                    Obx(
                      () => Stack(
                        children: [
                          ListView.separated(
                            controller: controller.scrollController,
                            separatorBuilder: (_, i) => Obx(
                              () => SizedBox(
                                // *2与原来的EdgeInsets.symmetric(vertical: )做兼容
                                height: AppSettingsController
                                        .instance.chatTextGap.value *
                                    2,
                              ),
                            ),
                            padding: isDesktop
                                ? const EdgeInsets.fromLTRB(16, 12, 16, 12)
                                : AppStyle.edgeInsetsA12,
                            itemCount: controller.messages.length,
                            itemBuilder: (_, i) {
                              var item = controller.messages[i];
                              return buildMessageItem(item);
                            },
                          ),
                          Visibility(
                            visible: controller.disableAutoScroll.value,
                            child: Positioned(
                              right: 12,
                              bottom: 12,
                              child: FilledButton.tonalIcon(
                                onPressed: () {
                                  controller.disableAutoScroll.value = false;
                                  controller.chatScrollToBottom();
                                },
                                icon: const Icon(Icons.expand_more),
                                label: const Text("最新"),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (controller.site.id == Constant.kBiliBili)
                      buildSuperChats(),
                    buildFollowList(),
                    buildSettings(),
                  ],
                ),
              ),
            ),
            if (controller.site.id == Constant.kBiliBili) buildChatInput(),
          ],
        ),
      ),
    );
  }

  Widget buildChatInput() {
    final context = Get.context!;
    final scheme = Theme.of(context).colorScheme;
    final borderColor =
        AppStyle.borderColor(context).withAlpha(Get.isDarkMode ? 120 : 180);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: borderColor,
          ),
        ),
      ),
      padding: AppStyle.edgeInsetsA8.copyWith(
        bottom: 8,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: controller.showEmotionPanel,
            icon: const Icon(Remix.emotion_line),
            tooltip: "表情包",
          ),
          Expanded(
            child: TextField(
              controller: controller.chatInputController,
              decoration: InputDecoration(
                hintText: "发送弹幕...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: scheme.surfaceContainerHighest
                    .withAlpha(Get.isDarkMode ? 80 : 120),
                contentPadding: AppStyle.edgeInsetsH12,
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  controller.sendChatMessage(value.trim());
                }
              },
            ),
          ),
          AppStyle.hGap8,
          FilledButton.tonal(
            onPressed: () {
              var message = controller.chatInputController.text.trim();
              if (message.isNotEmpty) {
                controller.sendChatMessage(message);
              }
            },
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              padding: AppStyle.edgeInsetsH16,
            ),
            child: const Text("发送"),
          ),
        ],
      ),
    );
  }

  Widget buildMessageItem(LiveMessage message) {
    if (message.userName == "LiveSysMessage") {
      return Obx(
        () => Text(
          message.message,
          style: TextStyle(
            color: Colors.grey,
            fontSize: AppSettingsController.instance.chatTextSize.value,
          ),
        ),
      );
    }

    return Obx(
      () => AppSettingsController.instance.chatBubbleStyle.value
          ? Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.withAlpha(25),
                      //borderRadius: AppStyle.radius8,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    padding:
                        AppStyle.edgeInsetsA4.copyWith(left: 12, right: 12),
                    child: Text.rich(
                      TextSpan(
                        text: "${message.userName}：",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize:
                              AppSettingsController.instance.chatTextSize.value,
                        ),
                        children: [
                          TextSpan(
                            text: message.message,
                            style: TextStyle(
                              color: Get.isDarkMode
                                  ? Colors.white
                                  : AppColors.black333,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Text.rich(
              TextSpan(
                text: "${message.userName}：",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: AppSettingsController.instance.chatTextSize.value,
                ),
                children: [
                  TextSpan(
                    text: message.message,
                    style: TextStyle(
                      color: Get.isDarkMode ? Colors.white : AppColors.black333,
                    ),
                  )
                ],
              ),
            ),
    );
  }

  Widget buildSuperChats() {
    return KeepAliveWrapper(
      child: Obx(
        () => ListView.separated(
          padding: AppStyle.edgeInsetsA12,
          itemCount: controller.superChats.length,
          separatorBuilder: (_, i) => AppStyle.vGap12,
          itemBuilder: (_, i) {
            var item = controller.superChats[i];
            return SuperChatCard(
              item,
              onExpire: () {
                controller.removeSuperChats();
              },
            );
          },
        ),
      ),
    );
  }

  Widget buildSettings() {
    return ListView(
      padding: AppStyle.edgeInsetsA12,
      children: [
        Obx(
          () => Visibility(
            visible: controller.autoExitEnable.value,
            child: ListTile(
              leading: const Icon(Icons.timer_outlined),
              visualDensity: VisualDensity.compact,
              title: Text("${parseDuration(controller.countdown.value)}后自动关闭"),
            ),
          ),
        ),
        Padding(
          padding: AppStyle.edgeInsetsA12,
          child: Text(
            "聊天区",
            style: Get.textTheme.titleSmall,
          ),
        ),
        SettingsCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(
                () => SettingsNumber(
                  title: "文字大小",
                  value:
                      AppSettingsController.instance.chatTextSize.value.toInt(),
                  min: 8,
                  max: 36,
                  onChanged: (e) {
                    AppSettingsController.instance
                        .setChatTextSize(e.toDouble());
                  },
                ),
              ),
              AppStyle.divider,
              Obx(
                () => SettingsNumber(
                  title: "上下间隔",
                  value:
                      AppSettingsController.instance.chatTextGap.value.toInt(),
                  min: 0,
                  max: 12,
                  onChanged: (e) {
                    AppSettingsController.instance.setChatTextGap(e.toDouble());
                  },
                ),
              ),
              AppStyle.divider,
              Obx(
                () => SettingsSwitch(
                  title: "气泡样式",
                  value: AppSettingsController.instance.chatBubbleStyle.value,
                  onChanged: (e) {
                    AppSettingsController.instance.setChatBubbleStyle(e);
                  },
                ),
              ),
              AppStyle.divider,
              Obx(
                () => SettingsSwitch(
                  title: "播放器中显示SC",
                  value:
                      AppSettingsController.instance.playershowSuperChat.value,
                  onChanged: (e) {
                    AppSettingsController.instance.setPlayerShowSuperChat(e);
                  },
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: AppStyle.edgeInsetsA12,
          child: Text(
            "更多设置",
            style: Get.textTheme.titleSmall,
          ),
        ),
        SettingsCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SettingsAction(
                title: "关键词屏蔽",
                onTap: controller.showDanmuShield,
              ),
              AppStyle.divider,
              SettingsAction(
                title: "弹幕设置",
                onTap: controller.showDanmuSettingsSheet,
              ),
              AppStyle.divider,
              SettingsAction(
                title: "字幕设置",
                onTap: () => Get.toNamed(RoutePath.kSettingsSubtitle),
              ),
              AppStyle.divider,
              SettingsAction(
                title: "定时关闭",
                onTap: controller.showAutoExitSheet,
              ),
              AppStyle.divider,
              Obx(
                () => ListTile(
                  leading: const Icon(Icons.audiotrack),
                  title: Text(
                      controller.audioOnlyMode.value ? "切换到视频模式" : "切换到黑听模式"),
                  trailing: Switch(
                    value: controller.audioOnlyMode.value,
                    onChanged: (value) {
                      controller.toggleAudioMode();
                    },
                  ),
                ),
              ),
              AppStyle.divider,
              Obx(
                () => Visibility(
                  visible: true,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.visibility),
                        title: Text(controller.ghostModeState.value
                            ? "关闭透明模式"
                            : "开启透明模式"),
                        trailing: Switch(
                          value: controller.ghostModeState.value,
                          onChanged: controller.audioOnlyMode.value
                              ? (value) {
                                  controller.toggleGhostMode();
                                }
                              : null,
                          activeThumbColor: controller.audioOnlyMode.value
                              ? null
                              : Colors.grey,
                          inactiveTrackColor: Colors.grey,
                        ),
                      ),
                      AppStyle.divider,
                    ],
                  ),
                ),
              ),
              if (controller.site.id == Constant.kBiliBili)
                SettingsAction(
                  title: "自动发送",
                  onTap: controller.showAutoSpamSheet,
                ),
              if (controller.site.id == Constant.kBiliBili) AppStyle.divider,
              SettingsAction(
                title: "画面尺寸",
                onTap: controller.showPlayerSettingsSheet,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildFollowList() {
    return Obx(
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
                    playing: controller.rxSite.value.id == item.siteId &&
                        controller.rxRoomId.value == item.roomId,
                    onTap: () {
                      controller.resetRoom(
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
    );
  }

  List<Widget> buildAppbarActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          showMore();
        },
        icon: const Icon(Icons.more_horiz),
      ),
    ];
  }

  void showMore() {
    showModalBottomSheet(
      context: Get.context!,
      constraints: const BoxConstraints(
        maxWidth: 600,
      ),
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            void closeSheet() {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            }

            return Container(
              padding: EdgeInsets.only(
                bottom: AppStyle.bottomBarHeight,
              ),
              child: ListView(
                controller: scrollController,
                children: [
                  ListTile(
                    title: const Text("更多"),
                    trailing: IconButton(
                      onPressed: closeSheet,
                      icon: const Icon(Remix.close_line),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.refresh),
                    title: const Text("刷新"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      controller.refreshRoom();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.play_circle_outline),
                    trailing: const Icon(Icons.chevron_right),
                    title: const Text("切换清晰度"),
                    onTap: () {
                      Get.back();
                      controller.showQualitySheet();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.emoji_emotions_outlined),
                    title: const Text("表情包筛选"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Get.back();
                      controller.showEmoticonPackageSettingsSheet();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.switch_video_outlined),
                    title: const Text("切换线路"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Get.back();
                      controller.showPlayUrlsSheet();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.aspect_ratio_outlined),
                    title: const Text("画面尺寸"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Get.back();
                      controller.showPlayerSettingsSheet();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.camera_alt_outlined),
                    title: const Text("截图"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      controller.saveScreenshot();
                    },
                  ),
                  Visibility(
                    visible: Platform.isAndroid,
                    child: ListTile(
                      leading: const Icon(Icons.picture_in_picture),
                      title: const Text("小窗播放"),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Get.back();
                        controller.enablePIP();
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.timer_outlined),
                    title: const Text("定时关闭"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Get.back();
                      controller.showAutoExitSheet();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.share_sharp),
                    title: const Text("分享直播间"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Get.back();
                      controller.share();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.copy),
                    title: const Text("复制链接"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Get.back();
                      controller.copyUrl();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.open_in_new),
                    title: const Text("APP中打开"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Get.back();
                      controller.openNaviteAPP();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    title: const Text("播放信息"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Get.back();
                      controller.showDebugInfo();
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String parseDuration(int sec) {
    // 转为时分秒
    var h = sec ~/ 3600;
    var m = (sec % 3600) ~/ 60;
    var s = sec % 60;
    if (h > 0) {
      return "${h.toString().padLeft(2, '0')}小时${m.toString().padLeft(2, '0')}分钟${s.toString().padLeft(2, '0')}秒";
    }
    if (m > 0) {
      return "${m.toString().padLeft(2, '0')}分钟${s.toString().padLeft(2, '0')}秒";
    }
    return "${s.toString().padLeft(2, '0')}秒";
  }
}
