import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/widgets/settings/settings_shared.dart';
import 'package:simple_live_app/widgets/settings/settings_card.dart';

class SettingsMenu<T> extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Map<T, String> valueMap;
  final T value;

  final Function(T)? onChanged;
  const SettingsMenu({
    required this.title,
    required this.value,
    required this.valueMap,
    this.subtitle,
    this.onChanged,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      visualDensity: VisualDensity.compact,
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: settingsItemRadius(context),
      ),
      contentPadding: AppStyle.edgeInsetsL16.copyWith(right: 8),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: Get.textTheme.bodySmall!.copyWith(
                color: settingsMutedColor(context),
              ),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            valueMap[value]!.tr,
            style: Theme.of(context)
                .textTheme
                .bodyMedium!
                .copyWith(color: settingsMutedColor(context)),
          ),
          AppStyle.hGap4,
          Icon(
            Icons.chevron_right,
            color: settingsMutedColor(context),
          ),
        ],
      ),
      onTap: () => openMenu(context),
    );
  }

  void openMenu(BuildContext context) {
    if (AppStyle.isDesktopLayout(context)) {
      Utils.showRightDialog(
        title: title,
        width: 360,
        child: _SettingsMenuPanel<T>(
          title: title,
          subtitle: subtitle,
          value: value,
          valueMap: valueMap,
          onChanged: onChanged,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      useSafeArea: true, //useSafeArea似乎无效
      builder: (_) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: RadioGroup(
            groupValue: value,
            onChanged: (e) {
              Get.back();
              onChanged?.call(e as T);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: valueMap.keys
                  .map(
                    (e) => RadioListTile(
                      value: e,
                      title: Text(
                        (valueMap[e]?.tr) ?? "???",
                        style: Get.textTheme.bodyMedium,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsMenuPanel<T> extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Map<T, String> valueMap;
  final T value;
  final Function(T)? onChanged;

  const _SettingsMenuPanel({
    required this.title,
    required this.value,
    required this.valueMap,
    this.subtitle,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppStyle.contentPadding(context),
      children: [
        if (subtitle != null && subtitle!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: settingsMutedColor(context),
                    height: 1.45,
                  ),
            ),
          ),
        Material(
          color: Colors.transparent,
          child: RadioGroup(
            groupValue: value,
            onChanged: (selected) {
              if (selected == null) return;
              onChanged?.call(selected as T);
              Utils.hideRightDialog();
            },
            child: SettingsCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: valueMap.keys
                    .map(
                      (entry) => RadioListTile<T>(
                        value: entry,
                        title: Text(
                          valueMap[entry]?.tr ?? "???",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        contentPadding: AppStyle.edgeInsetsH16,
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
