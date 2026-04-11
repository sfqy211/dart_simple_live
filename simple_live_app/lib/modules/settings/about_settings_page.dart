import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remixicon/remixicon.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/widgets/settings/settings_action.dart';
import 'package:simple_live_app/widgets/settings/settings_card.dart';
import 'package:simple_live_app/widgets/settings/settings_workspace.dart';
import 'package:simple_live_app/utils/windows_link_launcher.dart';

class AboutSettingsPage extends StatelessWidget {
  const AboutSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsPageScaffold(
      title: "关于",
      subtitle: "版本信息、项目主页与使用说明",
      body: AboutSettingsView(),
    );
  }
}

class AboutSettingsView extends StatelessWidget {
  const AboutSettingsView({super.key});

  Future<void> _openProjectHomepage() {
    return openExternalLink("https://github.com/sfqy211/dart_simple_live");
  }

  @override
  Widget build(BuildContext context) {
    final muted = AppStyle.mutedTextColor(context);

    return ListView(
      padding: AppStyle.contentPadding(context),
      children: [
        SettingsCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 56,
                  height: 56,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Simple Live",
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Ver ${Utils.packageInfo.version}",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: muted,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        AppStyle.vGap24,
        const SettingsSectionTitle(
          title: "项目信息",
        ),
        SettingsCard(
          child: Column(
            children: [
              SettingsAction(
                title: "项目主页",
                subtitle: "查看源码、更新记录与项目说明",
                value: "GitHub",
                leading: const Icon(Remix.github_line),
                onTap: _openProjectHomepage,
              ),
              if (kDebugMode) AppStyle.divider,
              if (kDebugMode)
                const ListTile(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Icon(Remix.information_line),
                  title: Text("当前为调试模式"),
                  subtitle: Text("发布版本不会显示这一提示。"),
                ),
            ],
          ),
        ),
        AppStyle.vGap24,
        const SettingsSectionTitle(
          title: "免责声明",
        ),
        SettingsCard(
          child: FutureBuilder<String>(
            future: rootBundle.loadString("assets/statement.txt"),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  snapshot.data!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.65,
                      ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
