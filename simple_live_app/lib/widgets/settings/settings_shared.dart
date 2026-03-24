import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/app_style.dart';

BorderRadius settingsItemRadius(BuildContext context) =>
    BorderRadius.circular(AppStyle.panelRadius(context, compact: true));

Color settingsMutedColor(BuildContext context) =>
    AppStyle.mutedTextColor(context);

Color settingsSurfaceColor(BuildContext context) => Theme.of(context).cardColor;

Color settingsInlineSurfaceColor(BuildContext context) {
  final theme = Theme.of(context);
  return theme.brightness == Brightness.dark
      ? const Color(0xFF252526)
      : const Color(0xFFF6F6F6);
}

Color settingsBorderColor(BuildContext context) {
  return AppStyle.borderColor(context).withAlpha(Get.isDarkMode ? 120 : 180);
}
