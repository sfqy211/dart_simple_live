import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/widgets/settings/settings_card.dart';
import 'package:simple_live_app/widgets/settings/settings_shared.dart';

class SettingsNumber extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String unit;
  final int value;
  final int step;
  final int min;
  final int max;
  final String? displayValue;
  final Function(int)? onChanged;
  const SettingsNumber(
      {required this.title,
      required this.value,
      required this.max,
      this.subtitle,
      this.onChanged,
      this.step = 1,
      this.min = 0,
      this.unit = '',
      this.displayValue,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      visualDensity: VisualDensity.compact,
      title: Text(
        title,
        style: Get.textTheme.bodyLarge,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: settingsItemRadius(context),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: Get.textTheme.bodySmall!.copyWith(
                color: settingsMutedColor(context),
              ),
            ),
      contentPadding: AppStyle.edgeInsetsL16.copyWith(right: 12),
      trailing: Container(
        decoration: BoxDecoration(
          color: settingsInlineSurfaceColor(context),
          borderRadius: settingsItemRadius(context),
          border: Border.all(
            color: settingsBorderColor(context),
          ),
        ),
        height: 36,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              padding: AppStyle.edgeInsetsA4,
              constraints: const BoxConstraints(
                minHeight: 32,
              ),
              onPressed: () {
                int newValue = value - step;
                if (newValue < min) {
                  newValue = min;
                }
                onChanged?.call(newValue);
              },
              icon: Icon(
                Icons.remove,
                color: Get.textTheme.bodyMedium!.color!.withAlpha(150),
              ),
            ),
            Text(
              displayValue ?? "$value$unit",
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(color: settingsMutedColor(context)),
            ),
            IconButton(
              padding: AppStyle.edgeInsetsA4,
              constraints: const BoxConstraints(
                minHeight: 32,
              ),
              onPressed: () {
                int newValue = value + step;
                if (newValue > max) {
                  newValue = max;
                }
                onChanged?.call(newValue);
              },
              icon: Icon(
                Icons.add,
                color: Get.textTheme.bodyMedium!.color!.withAlpha(150),
              ),
            ),
          ],
        ),
      ),
      onTap: () => openSilder(context),
    );
  }

  void openSilder(BuildContext context) {
    if (AppStyle.isDesktopLayout(context)) {
      Utils.showRightDialog(
        title: title,
        width: 380,
        child: _SettingsNumberPanel(
          title: title,
          subtitle: subtitle,
          value: value,
          min: min,
          max: max,
          step: step,
          unit: unit,
          onChanged: onChanged,
        ),
      );
      return;
    }

    var newValue = value.obs;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      useSafeArea: true, //useSafeArea似乎无效
      builder: (_) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: AppStyle.edgeInsetsH16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: Get.textTheme.titleMedium,
                  ),
                  Obx(
                    () => Text(
                      "${newValue.value}$unit",
                      style: Get.textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
            Obx(
              () => Slider(
                value: newValue.value.toDouble(),
                min: min.toDouble(),
                max: max.toDouble(),
                onChanged: (e) {
                  newValue.value = e.toInt();
                },
              ),
            ),
            Padding(
              padding: AppStyle.edgeInsetsH16,
              child: TextButton(
                onPressed: () {
                  onChanged?.call(newValue.value);
                  Get.back();
                },
                child: const Text("确定"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsNumberPanel extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String unit;
  final int value;
  final int step;
  final int min;
  final int max;
  final Function(int)? onChanged;

  const _SettingsNumberPanel({
    required this.title,
    required this.value,
    required this.max,
    this.subtitle,
    this.onChanged,
    this.step = 1,
    this.min = 0,
    this.unit = '',
  });

  @override
  State<_SettingsNumberPanel> createState() => _SettingsNumberPanelState();
}

class _SettingsNumberPanelState extends State<_SettingsNumberPanel> {
  late int currentValue;

  @override
  void initState() {
    super.initState();
    currentValue = widget.value;
  }

  void _applyValue(int nextValue) {
    setState(() {
      currentValue = nextValue.clamp(widget.min, widget.max).toInt();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppStyle.contentPadding(context),
      children: [
        if (widget.subtitle != null && widget.subtitle!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: Text(
              widget.subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: settingsMutedColor(context),
                    height: 1.45,
                  ),
            ),
          ),
        SettingsCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "$currentValue${widget.unit}",
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _applyValue(currentValue - widget.step),
                      icon: const Icon(Icons.remove),
                    ),
                    IconButton(
                      onPressed: () => _applyValue(currentValue + widget.step),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: currentValue.toDouble(),
                  min: widget.min.toDouble(),
                  max: widget.max.toDouble(),
                  onChanged: (value) {
                    _applyValue(value.toInt());
                  },
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () {
                    widget.onChanged?.call(currentValue);
                    Utils.hideRightDialog();
                  },
                  child: const Text("应用"),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
