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
import 'package:simple_live_app/modules/live_room/widgets/live_room_chat_input_bar.dart';
import 'package:simple_live_app/modules/settings/voice_recognition_settings_page.dart';
import 'package:simple_live_app/services/follow_service.dart';
import 'package:simple_live_app/widgets/desktop_refresh_button.dart';
import 'package:simple_live_app/widgets/follow_user_item.dart';
import 'package:simple_live_app/widgets/keep_alive_wrapper.dart';
import 'package:simple_live_app/widgets/net_image.dart';
import 'package:simple_live_app/widgets/app_shell.dart';
import 'package:simple_live_app/widgets/settings/settings_action.dart';
import 'package:simple_live_app/widgets/settings/settings_card.dart';
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
    return page;
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

    Widget buildToggleAction({
      required IconData icon,
      required String label,
      required bool selected,
      required VoidCallback onPressed,
    }) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: selected
                ? scheme.primary.withAlpha(Get.isDarkMode ? 96 : 84)
                : borderColor,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          backgroundColor: selected
              ? scheme.primary.withAlpha(Get.isDarkMode ? 28 : 18)
              : panelColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          foregroundColor: selected ? scheme.primary : null,
          textStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      );
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

    double resolveDesktopPlayerAspectRatio() {
      final scaleMode = AppSettingsController.instance.scaleMode.value;
      if (scaleMode == 3) {
        return 16 / 9;
      }
      if (scaleMode == 4) {
        return 4 / 3;
      }
      final width = controller.player.state.width;
      final height = controller.player.state.height;
      if (width != null && height != null && width > 0 && height > 0) {
        return width / height;
      }
      return 16 / 9;
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
                    Obx(
                      () => Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: NetImage(
                          controller.detail.value?.userAvatar ?? "",
                          width: 44,
                          height: 44,
                          borderRadius: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                                Flexible(
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
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Remix.fire_fill,
                                      size: 14,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      Utils.onlineToString(
                                        controller.detail.value?.online ?? 0,
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: scheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
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
                      tooltip: "复制链接",
                      onPressed: controller.copyUrl,
                      icon: const Icon(Icons.link_outlined),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const dividerWidth = 1.0;
                const minSideWidth = 320.0;
                const maxSideWidth = 460.0;
                const bottomActionBarHeight = 72.0;

                return StreamBuilder<int?>(
                  stream: controller.player.stream.height,
                  initialData: controller.player.state.height,
                  builder: (context, snapshot) {
                    final playerAspectRatio = resolveDesktopPlayerAspectRatio();
                    final playerHeight =
                        (constraints.maxHeight - bottomActionBarHeight)
                            .clamp(0.0, constraints.maxHeight);
                    final preferredPlayerWidth =
                        playerHeight * playerAspectRatio;
                    final preferredSideWidth = constraints.maxWidth -
                        dividerWidth -
                        preferredPlayerWidth;
                    final sideW = preferredSideWidth.clamp(
                      minSideWidth,
                      maxSideWidth,
                    );
                    final playerW =
                        (constraints.maxWidth - dividerWidth - sideW)
                            .clamp(0.0, constraints.maxWidth);

                    return Row(
                      children: [
                        SizedBox(
                          width: playerW,
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
                                padding:
                                    const EdgeInsets.fromLTRB(16, 12, 16, 12),
                                child: Obx(
                                  () => Row(
                                    children: [
                                      Expanded(
                                        child: buildSecondaryAction(
                                          icon: Icons.high_quality_outlined,
                                          label: "画质",
                                          onPressed:
                                              controller.showQualitySheet,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: buildSecondaryAction(
                                          icon: Icons.route_outlined,
                                          label: "线路",
                                          onPressed:
                                              controller.showPlayUrlsSheet,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: buildSecondaryAction(
                                          icon: Icons.crop_free_outlined,
                                          label: "尺寸",
                                          onPressed: controller
                                              .showPlayerSettingsSheet,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: buildToggleAction(
                                          icon: Icons.blur_on_outlined,
                                          label: "浮窗",
                                          selected:
                                              controller.ghostModeState.value,
                                          onPressed:
                                              controller.toggleGhostModeQuick,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: buildToggleAction(
                                          icon: Icons
                                              .picture_in_picture_alt_outlined,
                                          label: "小窗",
                                          selected:
                                              controller.smallWindowState.value,
                                          onPressed:
                                              controller.smallWindowState.value
                                                  ? controller.exitSmallWindow
                                                  : controller.enterSmallWindow,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: buildToggleAction(
                                          icon: Icons.subtitles_outlined,
                                          label: "字幕",
                                          selected:
                                              controller.subtitleEnabled.value,
                                          onPressed: () {
                                            AppSettingsController.instance
                                                .setSubtitleEnable(
                                              !controller.subtitleEnabled.value,
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: dividerWidth,
                          color: borderColor,
                        ),
                        SizedBox(
                          width: sideW,
                          child: Container(
                            color: panelColor,
                            child: buildMessageArea(),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPhoneUI(BuildContext context) {
    return Stack(
      children: [
        Column(
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
        ),
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
              child: Row(
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
              ),
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
            return Stack(children: [playerControls(state, controller)]);
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
  }

  Widget buildSubtitleBubble(
    BuildContext context, {
    required Color backgroundColor,
    required TextStyle textStyle,
    Color? borderColor,
    double? maxWidth,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth ?? MediaQuery.of(context).size.width - 32,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: borderColor == null ? null : Border.all(color: borderColor),
        ),
        child: Text(
          controller.subtitleText.value,
          textAlign: TextAlign.center,
          style: textStyle,
        ),
      ),
    );
  }

  Widget buildSubtitleOverlay() {
    return Obx(
      () {
        final context = Get.context;
        final isDesktop = context != null && AppStyle.isDesktopLayout(context);
        if (!controller.subtitleEnabled.value) {
          return const SizedBox.shrink();
        }
        if (controller.subtitleText.value.isEmpty) {
          return const SizedBox.shrink();
        }
        if (!isDesktop &&
            !controller.fullScreenState.value &&
            !controller.smallWindowState.value) {
          return const SizedBox.shrink();
        }
        final subtitleBottom =
            isDesktop ? (controller.fullScreenState.value ? 96.0 : 40.0) : 24.0;
        final adaptiveMaxWidth = MediaQuery.of(Get.context!).size.width - 32;
        if (adaptiveMaxWidth > 0) {
          return Positioned(
            left: 16,
            right: 16,
            bottom: subtitleBottom,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: buildSubtitleBubble(
                Get.context!,
                maxWidth: adaptiveMaxWidth,
                backgroundColor: Colors.black.withValues(
                    alpha: AppSettingsController
                        .instance.subtitleBackgroundOpacity.value),
                textStyle: TextStyle(
                  color: Colors.white,
                  fontSize:
                      AppSettingsController.instance.subtitleFontSize.value,
                  fontWeight: controller.subtitleIsPartial.value
                      ? FontWeight.normal
                      : FontWeight.w600,
                ),
              ),
            ),
          );
        }
        return Positioned(
          left: 16,
          right: 16,
          bottom: subtitleBottom,
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
          final maxWidth = MediaQuery.of(context).size.width - 40;
          return Positioned(
            left: offset.dx,
            top: offset.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                final newOffset =
                    controller.subtitlePosition.value! + details.delta;
                final size = MediaQuery.of(context).size;
                if (newOffset.dx > 20 &&
                    newOffset.dx < size.width - 20 &&
                    newOffset.dy > 50 &&
                    newOffset.dy < size.height - 50) {
                  controller.subtitlePosition.value = newOffset;
                }
              },
              child: FractionalTranslation(
                translation: const Offset(-0.5, -0.5),
                child: buildSubtitleBubble(
                  context,
                  maxWidth: maxWidth,
                  backgroundColor: Theme.of(context).cardColor.withValues(
                      alpha: AppSettingsController
                          .instance.subtitleBackgroundOpacity.value),
                  borderColor: Colors.grey.withAlpha(40),
                  textStyle: TextStyle(
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

        final adaptiveMaxWidth = MediaQuery.of(context).size.width - 24;
        if (adaptiveMaxWidth > 0) {
          return Positioned(
            left: 12,
            right: 12,
            bottom: bottomPadding,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onPanStart: (details) {
                  final renderBox = context.findRenderObject() as RenderBox?;
                  controller.subtitlePosition.value = renderBox == null
                      ? details.globalPosition
                      : renderBox.globalToLocal(details.globalPosition);
                },
                child: buildSubtitleBubble(
                  context,
                  maxWidth: adaptiveMaxWidth,
                  backgroundColor: Theme.of(context).cardColor.withValues(
                      alpha: AppSettingsController
                          .instance.subtitleBackgroundOpacity.value),
                  borderColor: Colors.grey.withAlpha(40),
                  textStyle: TextStyle(
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
                  Text(
                    controller.detail.value?.title ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppStyle.mutedTextColor(context),
                    ),
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
              onPressed: controller.copyUrl,
              icon: const Icon(Remix.file_copy_line),
              label: const Text("复制链接"),
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
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelPadding: EdgeInsets.zero,
                  indicatorWeight: 2,
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
            if (controller.site.id == Constant.kBiliBili)
              buildOptimizedChatInput(),
          ],
        ),
      ),
    );
  }

  Widget buildOptimizedChatInput() {
    final context = Get.context!;
    final theme = Theme.of(context);
    final borderColor =
        AppStyle.borderColor(context).withAlpha(Get.isDarkMode ? 120 : 180);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          top: BorderSide(color: borderColor),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: LiveRoomChatInputBar(
        controller: controller,
        inputHeight: 44,
        actionButtonSize: 44,
        spacing: 12,
      ),
    );
  }

  Widget buildChatInput() {
    final context = Get.context!;
    final scheme = Theme.of(context).colorScheme;
    final borderColor =
        AppStyle.borderColor(context).withAlpha(Get.isDarkMode ? 120 : 180);
    final inputFill = scheme.surfaceContainerHighest.withAlpha(
      Get.isDarkMode ? 96 : 150,
    );

    Widget buildActionButton({
      required IconData icon,
      required String tooltip,
      required VoidCallback onTap,
    }) {
      return Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: inputFill,
              border: Border.all(
                color: borderColor.withAlpha(Get.isDarkMode ? 120 : 180),
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onTap,
              child: Icon(icon, size: 20),
            ),
          ),
        ),
      );
    }

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
          buildActionButton(
            icon: Remix.emotion_line,
            tooltip: "表情包",
            onTap: controller.showEmotionPanel,
          ),
          AppStyle.hGap8,
          buildActionButton(
            icon: Icons.auto_awesome_outlined,
            tooltip: "自动发送",
            onTap: controller.showAutoSpamSheet,
          ),
          AppStyle.hGap8,
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: inputFill,
                border: Border.all(
                  color: borderColor.withAlpha(Get.isDarkMode ? 120 : 170),
                ),
              ),
              child: TextField(
                controller: controller.chatInputController,
                decoration: const InputDecoration(
                  hintText: "发送弹幕...",
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    controller.sendChatMessage(value.trim());
                  }
                },
              ),
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
                borderRadius: BorderRadius.circular(10),
              ),
              minimumSize: const Size(44, 38),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            child: const Icon(Icons.send_rounded, size: 18),
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
            "直播内显示",
            style: Get.textTheme.titleSmall,
          ),
        ),
        SettingsCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(
                () => SettingsSwitch(
                  title: "播放区显示SC",
                  value:
                      AppSettingsController.instance.playershowSuperChat.value,
                  onChanged: (e) {
                    AppSettingsController.instance.setPlayerShowSuperChat(e);
                  },
                ),
              ),
              AppStyle.divider,
              Obx(
                () => SettingsSwitch(
                  title: controller.ghostModeState.value ? "关闭透明浮窗" : "开启透明浮窗",
                  value: controller.ghostModeState.value,
                  onChanged: (value) {
                    controller.toggleGhostModeQuick();
                  },
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: AppStyle.edgeInsetsA12,
          child: Text(
            "房间工具",
            style: Get.textTheme.titleSmall,
          ),
        ),
        SettingsCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (controller.site.id == Constant.kBiliBili)
                SettingsAction(
                  title: "表情包筛选",
                  onTap: controller.showEmoticonPackageSettingsSheet,
                ),
              if (controller.site.id == Constant.kBiliBili) AppStyle.divider,
              SettingsAction(
                title: "字幕设置",
                onTap: showSubtitleSettings,
              ),
              AppStyle.divider,
              SettingsAction(
                title: "播放信息",
                onTap: controller.showDebugInfo,
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

  void showSubtitleSettings() {
    if (AppStyle.isDesktopLayout(Get.context!)) {
      Utils.showRightDialog(
        title: "字幕设置",
        width: 420,
        useSystem: true,
        child: const VoiceRecognitionSettingsView(),
      );
      return;
    }
    Get.to(() => const VoiceRecognitionSettingsPage());
  }

  void showMore() {
    final rootContext = Get.context!;
    final isDesktop = AppStyle.isDesktopLayout(rootContext);
    final showEmoticonSettings = controller.site.id == Constant.kBiliBili;

    showModalBottomSheet(
      context: rootContext,
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

            Widget buildSectionTitle(String title) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              );
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
                  buildSectionTitle("房间工具"),
                  if (!isDesktop)
                    ListTile(
                      leading: const Icon(Icons.refresh),
                      title: const Text("刷新"),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        closeSheet();
                        controller.refreshRoom();
                      },
                    ),
                  if (!isDesktop)
                    ListTile(
                      leading: const Icon(Icons.play_circle_outline),
                      trailing: const Icon(Icons.chevron_right),
                      title: const Text("切换清晰度"),
                      onTap: () {
                        Get.back();
                        controller.showQualitySheet();
                      },
                    ),
                  if (showEmoticonSettings)
                    ListTile(
                      leading: const Icon(Icons.emoji_emotions_outlined),
                      title: const Text("表情包筛选"),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Get.back();
                        controller.showEmoticonPackageSettingsSheet();
                      },
                    ),
                  if (!isDesktop)
                    ListTile(
                      leading: const Icon(Icons.switch_video_outlined),
                      title: const Text("切换线路"),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Get.back();
                        controller.showPlayUrlsSheet();
                      },
                    ),
                  if (!isDesktop)
                    ListTile(
                      leading: const Icon(Icons.aspect_ratio_outlined),
                      title: const Text("画面尺寸"),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Get.back();
                        controller.showPlayerSettingsSheet();
                      },
                    ),
                  if (!isDesktop)
                    ListTile(
                      leading: const Icon(Icons.camera_alt_outlined),
                      title: const Text("截图"),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        closeSheet();
                        controller.saveScreenshot();
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
                  buildSectionTitle("调试信息"),
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
