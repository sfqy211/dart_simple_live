import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/widgets/settings/settings_card.dart';
import 'package:simple_live_app/widgets/settings/settings_workspace.dart';

void showAppstyleSettingsPanel() {
  Utils.showRightDialog(
    title: "外观设置",
    width: 440,
    child: const AppstyleSettingView(
      usePanelPadding: true,
    ),
  );
}

class AppstyleSettingPage extends StatelessWidget {
  const AppstyleSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsPageScaffold(
      title: "外观设置",
      subtitle: "浅色 / 深色主题与桌面字体细节",
      body: AppstyleSettingView(),
    );
  }
}

class AppstyleSettingView extends StatefulWidget {
  final bool usePanelPadding;

  const AppstyleSettingView({
    this.usePanelPadding = false,
    super.key,
  });

  @override
  State<AppstyleSettingView> createState() => _AppstyleSettingViewState();
}

class _AppstyleSettingViewState extends State<AppstyleSettingView> {
  final AppSettingsController controller = AppSettingsController.instance;
  final TextEditingController _fontController = TextEditingController();

  @override
  void dispose() {
    _fontController.dispose();
    super.dispose();
  }

  void _applyFont() {
    controller.setAppFontFamily(_fontController.text.trim());
    Get.changeTheme(AppStyle.lightTheme);
    Get.changeTheme(AppStyle.darkTheme);
    controller.setTheme(controller.themeMode.value);
  }

  @override
  Widget build(BuildContext context) {
    _fontController.text = controller.appFontFamily.value;
    final padding = widget.usePanelPadding
        ? const EdgeInsets.fromLTRB(16, 16, 16, 24)
        : AppStyle.contentPadding(context);

    return ListView(
      padding: padding,
      children: [
        const SettingsSectionTitle(
          title: "全局字体",
          subtitle: "保留默认字体即可，只有在你明确知道目标字体已安装时再覆盖。",
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
                    FilledButton(
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
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
            ],
          ),
        ),
        AppStyle.vGap24,
        const SettingsSectionTitle(
          title: "显示主题",
          subtitle: "当前桌面端只保留浅色与深色两套主题，减少视觉分叉。",
        ),
        SettingsCard(
          child: Obx(
            () => RadioGroup<int>(
              groupValue: controller.themeMode.value,
              onChanged: (value) {
                controller.setTheme(value ?? 1);
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
        AppStyle.vGap24,
        const SettingsSectionTitle(
          title: "当前方向",
          subtitle: "这轮外观重构优先打磨桌面端的稳定性、密度与一致性。",
        ),
        SettingsCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "界面会继续朝更克制、更线性化的桌面工具风格收敛，减少多余圆角和悬浮感，让导航、设置与直播观看在长时间使用时更安静。",
              style: Get.textTheme.bodyMedium?.copyWith(
                color: AppStyle.mutedTextColor(context),
                height: 1.55,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
