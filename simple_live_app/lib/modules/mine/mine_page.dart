import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/log.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/routes/route_path.dart';
import 'package:simple_live_app/services/signalr_service.dart';
import 'package:simple_live_app/widgets/desktop_page_header.dart';
import 'package:url_launcher/url_launcher_string.dart';

class MinePage extends StatelessWidget {
  const MinePage({Key? key}) : super(key: key);

  void _showAboutDialog() {
    Get.dialog(
      AboutDialog(
        applicationIcon: Image.asset(
          'assets/images/logo.png',
          width: 48,
          height: 48,
        ),
        applicationName: "Simple Live",
        applicationVersion: "Ver ${Utils.packageInfo.version}",
        applicationLegalese: "简简单单看直播",
      ),
    );
  }

  Future<void> _openGithub() {
    return launchUrlString(
      "https://github.com/xiaoyaocz/dart_simple_live",
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _runDebugAction() async {
    final signalRService = SignalRService();
    await signalRService.connect();
    final room = await signalRService.createRoom();
    Log.logPrint(room);
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    final borderColor =
        AppStyle.borderColor(context).withAlpha(Get.isDarkMode ? 120 : 180);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: borderColor),
          bottom: BorderSide(color: borderColor),
        ),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppStyle.mutedTextColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(
    BuildContext context, {
    required _MineActionItem item,
    required bool showDivider,
  }) {
    final theme = Theme.of(context);
    final borderColor =
        AppStyle.borderColor(context).withAlpha(Get.isDarkMode ? 120 : 180);
    final mutedColor = AppStyle.mutedTextColor(context);

    return Material(
      color: theme.cardColor,
      child: InkWell(
        onTap: item.onTap,
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            border: Border(
              bottom: showDivider
                  ? BorderSide(color: borderColor)
                  : BorderSide.none,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Icon(
                  item.icon,
                  size: 20,
                  color: mutedColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (item.hint.isNotEmpty) ...[
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    item.hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: mutedColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ] else
                const SizedBox(width: 10),
              Icon(
                item.external ? Icons.open_in_new : Icons.chevron_right,
                size: 18,
                color: mutedColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, _MineSectionItem section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          context,
          title: section.title,
          description: section.description,
        ),
        ...section.items.asMap().entries.map(
              (entry) => _buildActionRow(
                context,
                item: entry.value,
                showDivider: entry.key != section.items.length - 1,
              ),
            ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    final sections = [
      _MineSectionItem(
        title: "资料",
        description: "记录、账号、同步和工具入口。",
        items: [
          _MineActionItem(
            icon: Remix.history_line,
            title: "观看记录",
            hint: "最近浏览",
            onTap: () => Get.toNamed(RoutePath.kHistory),
          ),
          _MineActionItem(
            icon: Remix.account_circle_line,
            title: "账号管理",
            hint: "登录与权限",
            onTap: () => Get.toNamed(RoutePath.kSettingsAccount),
          ),
          _MineActionItem(
            icon: Icons.sync,
            title: "数据同步",
            hint: "设备与配置",
            onTap: () => Get.toNamed(RoutePath.kSync),
          ),
          _MineActionItem(
            icon: Remix.link,
            title: "链接解析",
            hint: "通过链接直达",
            onTap: () => Get.toNamed(RoutePath.kTools),
          ),
        ],
      ),
      _MineSectionItem(
        title: "偏好",
        description: "界面、首页、播放和跟播设置。",
        items: [
          _MineActionItem(
            icon: Remix.moon_line,
            title: "外观设置",
            hint: "浅色 / 深色",
            onTap: () => Get.toNamed(RoutePath.kAppstyleSetting),
          ),
          _MineActionItem(
            icon: Remix.home_2_line,
            title: "主页设置",
            hint: "导航与首页",
            onTap: () => Get.toNamed(RoutePath.kSettingsIndexed),
          ),
          _MineActionItem(
            icon: Remix.play_circle_line,
            title: "直播设置",
            hint: "播放与窗口",
            onTap: () => Get.toNamed(RoutePath.kSettingsPlay),
          ),
          _MineActionItem(
            icon: Remix.text,
            title: "弹幕设置",
            hint: "显示与样式",
            onTap: () => Get.toNamed(RoutePath.kSettingsDanmu),
          ),
          _MineActionItem(
            icon: Remix.heart_line,
            title: "关注设置",
            hint: "关注页行为",
            onTap: () => Get.toNamed(RoutePath.kSettingsFollow),
          ),
          _MineActionItem(
            icon: Remix.timer_2_line,
            title: "定时关闭",
            hint: "自动退出",
            onTap: () => Get.toNamed(RoutePath.kSettingsAutoExit),
          ),
          _MineActionItem(
            icon: Remix.apps_line,
            title: "其他设置",
            hint: "系统与附加项",
            onTap: () => Get.toNamed(RoutePath.kSettingsOther),
          ),
        ],
      ),
      _MineSectionItem(
        title: "项目",
        description: "说明、源码与调试入口。",
        items: [
          _MineActionItem(
            icon: Remix.information_line,
            title: "关于",
            hint: "Ver ${Utils.packageInfo.version}",
            onTap: _showAboutDialog,
          ),
          const _MineActionItem(
            icon: Remix.error_warning_line,
            title: "免责声明",
            hint: "使用说明",
            onTap: Utils.showStatement,
          ),
          _MineActionItem(
            icon: Remix.github_line,
            title: "项目主页",
            hint: "GitHub",
            onTap: _openGithub,
            external: true,
          ),
          if (kDebugMode)
            _MineActionItem(
              icon: Remix.bug_line,
              title: "调试",
              hint: "SignalR 检查",
              onTap: _runDebugAction,
            ),
        ],
      ),
    ];

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        ...sections.map((section) => _buildSection(context, section)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppStyle.isDesktopLayout(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Get.isDarkMode
          ? SystemUiOverlayStyle.light.copyWith(
              systemNavigationBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              systemNavigationBarColor: Colors.transparent,
            ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: isDesktop
            ? null
            : AppBar(
                title: const Text("我的"),
              ),
        body: Column(
          children: [
            if (isDesktop)
              DesktopPageHeader(
                title: "我的",
                actions: [
                  DesktopPageHeaderBadge(
                    text: Get.isDarkMode ? "深色主题" : "浅色主题",
                  ),
                ],
              ),
            Expanded(
              child: _buildBody(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _MineSectionItem {
  final String title;
  final String description;
  final List<_MineActionItem> items;

  const _MineSectionItem({
    required this.title,
    required this.description,
    required this.items,
  });
}

class _MineActionItem {
  final IconData icon;
  final String title;
  final String hint;
  final VoidCallback onTap;
  final bool external;

  const _MineActionItem({
    required this.icon,
    required this.title,
    required this.hint,
    required this.onTap,
    this.external = false,
  });
}
