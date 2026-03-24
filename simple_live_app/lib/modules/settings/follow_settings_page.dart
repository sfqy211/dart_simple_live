import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/services/follow_service.dart';
import 'package:simple_live_app/widgets/settings/settings_action.dart';
import 'package:simple_live_app/widgets/settings/settings_card.dart';
import 'package:simple_live_app/widgets/settings/settings_switch.dart';
import 'package:simple_live_app/widgets/settings/settings_workspace.dart';

class FollowSettingsPage extends GetView<AppSettingsController> {
  const FollowSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsPageScaffold(
      title: "关注设置",
      subtitle: "关注列表自动刷新与并发控制",
      body: FollowSettingsView(),
    );
  }
}

class FollowSettingsView extends GetView<AppSettingsController> {
  const FollowSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppStyle.contentPadding(context),
      children: [
        const SettingsSectionTitle(
          title: "刷新策略",
          subtitle: "自动刷新关注主播的开播状态，并控制并发数量。",
        ),
        SettingsCard(
          child: Column(
            children: [
              Obx(
                () => SettingsSwitch(
                  value: controller.autoUpdateFollowEnable.value,
                  title: "自动刷新关注直播状态",
                  onChanged: (value) {
                    controller.setAutoUpdateFollowEnable(value);
                    FollowService.instance.initTimer();
                  },
                ),
              ),
              Obx(
                () => Visibility(
                  visible: controller.autoUpdateFollowEnable.value,
                  child: AppStyle.divider,
                ),
              ),
              Obx(
                () => Visibility(
                  visible: controller.autoUpdateFollowEnable.value,
                  child: SettingsAction(
                    title: "自动刷新间隔",
                    value:
                        "${controller.autoUpdateFollowDuration.value ~/ 60}小时${controller.autoUpdateFollowDuration.value % 60}分钟",
                    onTap: () => setTimer(context),
                  ),
                ),
              ),
              AppStyle.divider,
              Obx(
                () {
                  final threadCount = controller.updateFollowThreadCount.value;
                  final displayValue = threadCount == 0 ? "自动" : "$threadCount";

                  return SettingsAction(
                    title: "刷新并发数",
                    subtitle: "0 表示自动根据 CPU 核心数估算，或手动设置 1-20",
                    value: displayValue,
                    onTap: () => showConcurrencyEditor(context),
                  );
                },
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
        hour: controller.autoUpdateFollowDuration.value ~/ 60,
        minute: controller.autoUpdateFollowDuration.value % 60,
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
    controller.setAutoUpdateFollowDuration(duration.inMinutes);
    FollowService.instance.initTimer();
  }

  void showConcurrencyEditor(BuildContext context) {
    final cpuCount = Platform.numberOfProcessors;
    final autoValue = (cpuCount * 2.5).round().clamp(4, 20).toInt();
    final content = _FollowConcurrencyEditor(
      currentValue: controller.updateFollowThreadCount.value,
      cpuCount: cpuCount,
      autoValue: autoValue,
      onChanged: controller.setUpdateFollowThreadCount,
      onClose: AppStyle.isDesktopLayout(context)
          ? Utils.hideRightDialog
          : () => Get.back(),
    );

    if (AppStyle.isDesktopLayout(context)) {
      Utils.showRightDialog(
        title: "刷新并发数",
        width: 420,
        child: content,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => SafeArea(
        top: false,
        child: content,
      ),
    );
  }
}

class _FollowConcurrencyEditor extends StatefulWidget {
  final int currentValue;
  final int cpuCount;
  final int autoValue;
  final ValueChanged<int> onChanged;
  final VoidCallback onClose;

  const _FollowConcurrencyEditor({
    required this.currentValue,
    required this.cpuCount,
    required this.autoValue,
    required this.onChanged,
    required this.onClose,
  });

  @override
  State<_FollowConcurrencyEditor> createState() =>
      _FollowConcurrencyEditorState();
}

class _FollowConcurrencyEditorState extends State<_FollowConcurrencyEditor> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentValue == 0 ? '' : widget.currentValue.toString(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submitCustomValue() {
    final number = int.tryParse(_controller.text.trim());
    if (number == null || number < 0 || number > 20) {
      SmartDialog.showToast("请输入 0-20 之间的数值");
      return;
    }
    widget.onChanged(number);
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppStyle.contentPadding(context),
      children: [
        SettingsSectionTitle(
          title: "自动推荐",
          subtitle:
              "当前设备 CPU 核心数 ${widget.cpuCount}，推荐并发数 ${widget.autoValue}。",
        ),
        SettingsCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickOption(0, "自动 (${widget.autoValue})"),
                _buildQuickOption(4, "4"),
                _buildQuickOption(8, "8"),
                _buildQuickOption(12, "12"),
                _buildQuickOption(16, "16"),
                _buildQuickOption(20, "20"),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const SettingsSectionTitle(
          title: "手动输入",
          subtitle: "输入 0-20 之间的整数，0 表示自动模式。",
        ),
        SettingsCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "并发数",
                      hintText: "0-20",
                    ),
                    onSubmitted: (_) => _submitCustomValue(),
                  ),
                ),
                AppStyle.hGap12,
                FilledButton(
                  onPressed: _submitCustomValue,
                  child: const Text("应用"),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickOption(int value, String label) {
    final selected = widget.currentValue == value;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (active) {
        if (!active) return;
        widget.onChanged(value);
        widget.onClose();
      },
    );
  }
}
