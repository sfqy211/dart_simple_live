import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/modules/settings/other/other_settings_controller.dart';
import 'package:simple_live_app/widgets/settings/settings_card.dart';
import 'package:simple_live_app/widgets/settings/settings_menu.dart';
import 'package:simple_live_app/widgets/settings/settings_switch.dart';
import 'package:simple_live_app/widgets/settings/settings_workspace.dart';
import 'package:url_launcher/url_launcher_string.dart';

class OtherSettingsPage extends GetView<OtherSettingsController> {
  const OtherSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsPageScaffold(
      title: "其他设置",
      subtitle: "配置维护、播放内核与日志记录",
      body: OtherSettingsView(),
    );
  }
}

class OtherSettingsView extends GetView<OtherSettingsController> {
  const OtherSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppStyle.contentPadding(context),
      children: [
        const SettingsSectionTitle(
          title: "配置维护",
          subtitle: "导入、导出或恢复默认配置。",
        ),
        SettingsCard(
          child: Padding(
            padding: AppStyle.edgeInsetsA4,
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: controller.exportConfig,
                    label: const Text("导出配置"),
                    icon: const Icon(Remix.export_line),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: controller.importConfig,
                    label: const Text("导入配置"),
                    icon: const Icon(Remix.import_line),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: controller.resetDefaultConfig,
                    label: const Text("重置配置"),
                    icon: const Icon(Remix.restart_line),
                  ),
                ),
              ],
            ),
          ),
        ),
        AppStyle.vGap24,
        const SettingsSectionTitle(
          title: "播放器高级设置",
          subtitle: "不确定含义时请保持默认，修改前建议先阅读 MPV 文档。",
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Text.rich(
            TextSpan(
              text: "修改前建议先查阅 ",
              children: [
                WidgetSpan(
                  child: GestureDetector(
                    onTap: () {
                      launchUrlString(
                        "https://mpv.io/manual/stable/#video-output-drivers",
                      );
                    },
                    child: const Text(
                      "MPV 文档",
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                const TextSpan(text: "，避免误改影响播放稳定性。"),
              ],
            ),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        SettingsCard(
          child: Column(
            children: [
              Obx(
                () => SettingsSwitch(
                  value:
                      AppSettingsController.instance.customPlayerOutput.value,
                  title: "自定义输出驱动与硬件加速",
                  onChanged:
                      AppSettingsController.instance.setCustomPlayerOutput,
                ),
              ),
              AppStyle.divider,
              Obx(
                () => SettingsMenu(
                  title: "视频输出驱动 (--vo)",
                  value: AppSettingsController.instance.videoOutputDriver.value,
                  valueMap: controller.videoOutputDrivers,
                  onChanged:
                      AppSettingsController.instance.setVideoOutputDriver,
                ),
              ),
              AppStyle.divider,
              Obx(
                () => SettingsMenu(
                  title: "音频输出驱动 (--ao)",
                  value: AppSettingsController.instance.audioOutputDriver.value,
                  valueMap: controller.audioOutputDrivers,
                  onChanged:
                      AppSettingsController.instance.setAudioOutputDriver,
                ),
              ),
              AppStyle.divider,
              Obx(
                () => SettingsMenu(
                  title: "硬件解码器 (--hwdec)",
                  value:
                      AppSettingsController.instance.videoHardwareDecoder.value,
                  valueMap: controller.hardwareDecoder,
                  onChanged:
                      AppSettingsController.instance.setVideoHardwareDecoder,
                ),
              ),
            ],
          ),
        ),
        AppStyle.vGap24,
        const SettingsSectionTitle(
          title: "日志记录",
          subtitle: "用于定位问题，日志文件可以导出或保存。",
        ),
        SettingsCard(
          child: Column(
            children: [
              Obx(
                () => SettingsSwitch(
                  value: AppSettingsController.instance.logEnable.value,
                  title: "开启日志记录",
                  subtitle: "开启后会记录调试日志，可提供给开发者排查问题",
                  onChanged: controller.setLogEnable,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "日志列表",
                  style: Get.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: controller.cleanLog,
                label: const Text("清空日志"),
                icon: const Icon(Icons.clear_all),
              ),
            ],
          ),
        ),
        SettingsCard(
          child: SizedBox(
            height: 300,
            child: Obx(
              () => ListView.separated(
                itemCount: controller.logFiles.length,
                separatorBuilder: (context, index) => AppStyle.divider,
                itemBuilder: (context, index) {
                  final item = controller.logFiles[index];
                  return ListTile(
                    visualDensity: VisualDensity.compact,
                    contentPadding: AppStyle.edgeInsetsL12.copyWith(right: 4),
                    title: Text(item.name),
                    subtitle: Text(Utils.parseFileSize(item.size)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => controller.shareLogFile(item),
                          icon: const Icon(Icons.share),
                        ),
                        IconButton(
                          onPressed: () => controller.saveLogFile(item),
                          icon: const Icon(Icons.save),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
