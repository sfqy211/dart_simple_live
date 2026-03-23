import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/widgets/settings/settings_card.dart';

class AppstyleSettingPage extends GetView<AppSettingsController> {
  AppstyleSettingPage({Key? key}) : super(key: key);

  final TextEditingController _fontController = TextEditingController();

  void _applyFont() {
    controller.setAppFontFamily(_fontController.text.trim());
    Get.changeTheme(AppStyle.lightTheme);
    Get.changeTheme(AppStyle.darkTheme);
    controller.setTheme(controller.themeMode.value);
  }

  @override
  Widget build(BuildContext context) {
    _fontController.text = controller.appFontFamily.value;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("外观设置"),
      ),
      body: ListView(
        padding: AppStyle.edgeInsetsA12,
        children: [
          Padding(
            padding: AppStyle.edgeInsetsA12,
            child: Text(
              "全局字体",
              style: Get.textTheme.titleSmall,
            ),
          ),
          SettingsCard(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _fontController,
                          decoration: const InputDecoration(
                            hintText: "输入字体名称，留空则使用默认字体",
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onSubmitted: (_) => _applyFont(),
                        ),
                      ),
                      AppStyle.hGap12,
                      ElevatedButton(
                        onPressed: _applyFont,
                        child: const Text("应用"),
                      ),
                    ],
                  ),
                ),
                if (Platform.isWindows)
                  const Padding(
                    padding: EdgeInsets.only(left: 12, right: 12, bottom: 12),
                    child: Text(
                      "Windows 常用字体: Microsoft YaHei, Segoe UI, SimHei, KaiTi, SimSun",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          AppStyle.vGap12,
          Padding(
            padding: AppStyle.edgeInsetsA12,
            child: Text(
              "显示主题",
              style: Get.textTheme.titleSmall,
            ),
          ),
          SettingsCard(
            child: Obx(
              () => RadioGroup(
                groupValue: controller.themeMode.value,
                onChanged: (e) {
                  controller.setTheme(e ?? 1);
                },
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<int>(
                      title: Text("浅色模式"),
                      visualDensity: VisualDensity.compact,
                      value: 1,
                      contentPadding: AppStyle.edgeInsetsH12,
                    ),
                    RadioListTile<int>(
                      title: Text("深色模式"),
                      visualDensity: VisualDensity.compact,
                      value: 2,
                      contentPadding: AppStyle.edgeInsetsH12,
                    ),
                  ],
                ),
              ),
            ),
          ),
          AppStyle.vGap12,
          Padding(
            padding: AppStyle.edgeInsetsA12,
            child: Text(
              "说明",
              style: Get.textTheme.titleSmall,
            ),
          ),
          SettingsCard(
            child: Padding(
              padding: AppStyle.edgeInsetsA12,
              child: Text(
                "当前外观重构已收敛为浅色 / 深色两套主题，优先保证桌面端的稳定性、可读性和一致性。",
                style: Get.textTheme.bodyMedium?.copyWith(
                  color: AppStyle.mutedTextColor(context),
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
