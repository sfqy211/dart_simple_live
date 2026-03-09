import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/widgets/settings/settings_card.dart';
import 'package:simple_live_app/widgets/settings/settings_switch.dart';

class AppstyleSettingPage extends GetView<AppSettingsController> {
  AppstyleSettingPage({Key? key}) : super(key: key);

  final TextEditingController _fontController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    _fontController.text = controller.appFontFamily.value;
    return Scaffold(
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
                            hintText: "输入字体名称 (留空使用默认)",
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onSubmitted: (value) {
                            controller.setAppFontFamily(value);
                            Get.changeTheme(AppStyle.lightTheme);
                            Get.changeTheme(AppStyle.darkTheme);
                            // 重新应用当前主题模式以触发刷新
                            controller.setTheme(controller.themeMode.value);
                          },
                        ),
                      ),
                      AppStyle.hGap12,
                      ElevatedButton(
                        onPressed: () {
                          controller.setAppFontFamily(_fontController.text);
                          Get.changeTheme(AppStyle.lightTheme);
                          Get.changeTheme(AppStyle.darkTheme);
                          // 重新应用当前主题模式以触发刷新
                          controller.setTheme(controller.themeMode.value);
                        },
                        child: const Text("应用"),
                      ),
                    ],
                  ),
                ),
                if (Platform.isWindows)
                  const Padding(
                    padding: EdgeInsets.only(left: 12, right: 12, bottom: 12),
                    child: Text(
                      "提示: Windows 下常用字体: Microsoft YaHei, SimHei, KaiTi, SimSun, Segoe UI",
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
                  controller.setTheme(e ?? 0);
                },
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<int>(
                      title: Text(
                        "跟随系统",
                      ),
                      visualDensity: VisualDensity.compact,
                      value: 0,
                      contentPadding: AppStyle.edgeInsetsH12,
                    ),
                    RadioListTile<int>(
                      title: Text(
                        "浅色模式",
                      ),
                      visualDensity: VisualDensity.compact,
                      value: 1,
                      contentPadding: AppStyle.edgeInsetsH12,
                    ),
                    RadioListTile<int>(
                      title: Text(
                        "深色模式",
                      ),
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
              "主题颜色",
              style: Get.textTheme.titleSmall,
            ),
          ),
          SettingsCard(
            child: Obx(
              () => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SettingsSwitch(
                    value: controller.isDynamic.value,
                    title: "动态取色",
                    onChanged: (e) {
                      controller.setIsDynamic(e);
                      Get.forceAppUpdate();
                    },
                  ),
                  if (!controller.isDynamic.value) AppStyle.divider,
                  if (!controller.isDynamic.value)
                    Padding(
                      padding: AppStyle.edgeInsetsA12,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Color>[
                          const Color(0xffEF5350),
                          const Color(0xff3498db),
                          const Color(0xffF06292),
                          const Color(0xff9575CD),
                          const Color(0xff26C6DA),
                          const Color(0xff26A69A),
                          const Color(0xffFFF176),
                          const Color(0xffFF9800),
                        ]
                            .map(
                              (e) => GestureDetector(
                                onTap: () {
                                  controller.setStyleColor(e.toARGB32());
                                  Get.forceAppUpdate();
                                },
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: e,
                                    borderRadius: AppStyle.radius4,
                                    border: Border.all(
                                      color: Colors.grey.withAlpha(50),
                                      width: 1,
                                    ),
                                  ),
                                  child: Obx(
                                    () => Center(
                                      child: Icon(
                                        Icons.check,
                                        color: controller.styleColor.value ==
                                                e.toARGB32()
                                            ? Colors.white
                                            : Colors.transparent,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// extension ColorExt on Color {
//   static int _floatToInt8(double x) {
//     return (x * 255.0).round() & 0xff;
//   }

//   int get v =>
//       _floatToInt8(a) << 24 |
//       _floatToInt8(r) << 16 |
//       _floatToInt8(g) << 8 |
//       _floatToInt8(b) << 0;
// }
