import 'package:flutter/material.dart';
import 'package:simple_live_app/widgets/settings/settings_shared.dart';

class SettingsCard extends StatelessWidget {
  final Widget child;
  const SettingsCard({required this.child, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: settingsSurfaceColor(context),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: settingsItemRadius(context),
        side: BorderSide(
          color: settingsBorderColor(context),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: settingsItemRadius(context),
        ),
        child: child,
      ),
    );
  }
}
