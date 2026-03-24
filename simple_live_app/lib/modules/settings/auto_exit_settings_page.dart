import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/widgets/settings/settings_action.dart';
import 'package:simple_live_app/widgets/settings/settings_card.dart';
import 'package:simple_live_app/widgets/settings/settings_switch.dart';
import 'package:simple_live_app/widgets/settings/settings_workspace.dart';

void showAutoExitSettingsPanel() {
  Utils.showRightDialog(
    title: "定时关闭",
    width: 420,
    child: const AutoExitSettingsView(
      usePanelPadding: true,
    ),
  );
}

class AutoExitSettingsPage extends StatelessWidget {
  const AutoExitSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsPageScaffold(
      title: "定时关闭",
      subtitle: "适合长时间挂机观看时控制退出节奏",
      body: AutoExitSettingsView(),
    );
  }
}

class AutoExitSettingsView extends GetView<AppSettingsController> {
  final bool usePanelPadding;

  const AutoExitSettingsView({
    this.usePanelPadding = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final padding = usePanelPadding
        ? const EdgeInsets.fromLTRB(16, 16, 16, 24)
        : AppStyle.contentPadding(context);

    return ListView(
      padding: padding,
      children: [
        const SettingsSectionTitle(
          title: "自动退出",
          subtitle: "从进入直播间开始计时，到点后自动退出应用。",
        ),
        SettingsCard(
          child: Column(
            children: [
              Obx(
                () => SettingsSwitch(
                  value: controller.autoExitEnable.value,
                  title: "启用定时关闭",
                  onChanged: controller.setAutoExitEnable,
                ),
              ),
              Obx(
                () => Visibility(
                  visible: controller.autoExitEnable.value,
                  child: AppStyle.divider,
                ),
              ),
              Obx(
                () => Visibility(
                  visible: controller.autoExitEnable.value,
                  child: SettingsAction(
                    title: "自动关闭时间",
                    value:
                        "${controller.autoExitDuration.value ~/ 60}小时${controller.autoExitDuration.value % 60}分钟",
                    subtitle: "从进入直播间开始倒计时",
                    onTap: () => setTimer(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> setTimer(BuildContext context) async {
    final value = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: controller.autoExitDuration.value ~/ 60,
        minute: controller.autoExitDuration.value % 60,
      ),
      initialEntryMode: TimePickerEntryMode.inputOnly,
      builder: (_, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: true,
          ),
          child: child!,
        );
      },
    );
    if (value == null || (value.hour == 0 && value.minute == 0)) {
      return;
    }
    final duration = Duration(hours: value.hour, minutes: value.minute);
    controller.setAutoExitDuration(duration.inMinutes);
  }
}
