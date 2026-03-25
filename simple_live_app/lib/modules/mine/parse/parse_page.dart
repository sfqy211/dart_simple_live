import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/modules/mine/parse/parse_controller.dart';
import 'package:simple_live_app/widgets/settings/settings_card.dart';
import 'package:simple_live_app/widgets/settings/settings_workspace.dart';

class ParsePage extends GetView<ParseController> {
  const ParsePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsPageScaffold(
      title: "链接解析",
      subtitle: "通过链接直达直播间或提取播放直链",
      body: ParseView(),
    );
  }
}

class ParseView extends GetView<ParseController> {
  const ParseView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppStyle.contentPadding(context),
      children: [
        const SettingsSectionTitle(
          title: "跳转直播间",
          subtitle: "粘贴直播链接后直接进入对应直播间。",
        ),
        SettingsCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  minLines: 3,
                  maxLines: 3,
                  controller: controller.roomJumpToController,
                  textInputAction: TextInputAction.go,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "输入或粘贴哔哩哔哩直播链接",
                    contentPadding: AppStyle.edgeInsetsA12,
                  ),
                  onSubmitted: controller.jumpToRoom,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    controller.jumpToRoom(controller.roomJumpToController.text);
                  },
                  icon: const Icon(Remix.play_circle_line),
                  label: const Text("链接跳转"),
                ),
              ],
            ),
          ),
        ),
        AppStyle.vGap24,
        const SettingsSectionTitle(
          title: "获取直链",
          subtitle: "解析直播链接并复制可用播放线路。",
        ),
        SettingsCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  minLines: 3,
                  maxLines: 3,
                  controller: controller.getUrlController,
                  textInputAction: TextInputAction.go,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "输入或粘贴哔哩哔哩直播链接",
                    contentPadding: AppStyle.edgeInsetsA12,
                  ),
                  onSubmitted: controller.getPlayUrl,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    controller.getPlayUrl(controller.getUrlController.text);
                  },
                  icon: const Icon(Remix.link),
                  label: const Text("获取直链"),
                ),
              ],
            ),
          ),
        ),
        AppStyle.vGap24,
        const SettingsSectionTitle(
          title: "当前支持",
          subtitle: "目前只保留哔哩哔哩相关链接解析。",
        ),
        const SettingsCard(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: SelectableText(
              '''支持以下链接类型:
https://live.bilibili.com/xxxxx
https://b23.tv/xxxxx''',
              style: TextStyle(color: Colors.grey, height: 1.6),
            ),
          ),
        ),
      ],
    );
  }
}
