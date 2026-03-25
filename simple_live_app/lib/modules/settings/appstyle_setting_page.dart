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
      subtitle: "仅保留浅色与深色主题，持续统一桌面端界面气质。",
      body: AppstyleSettingView(),
    );
  }
}

class AppstyleSettingView extends StatelessWidget {
  final bool usePanelPadding;

  const AppstyleSettingView({
    this.usePanelPadding = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = AppSettingsController.instance;
    final padding = usePanelPadding
        ? const EdgeInsets.fromLTRB(16, 16, 16, 24)
        : AppStyle.contentPadding(context);

    return ListView(
      padding: padding,
      children: [
        const SettingsSectionTitle(
          title: "显示主题",
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
      ],
    );
  }
}
