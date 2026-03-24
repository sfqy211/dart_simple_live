// ignore_for_file: prefer_const_constructors

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/log.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/modules/mine/account/account_controller.dart';
import 'package:simple_live_app/modules/mine/account/account_page.dart';
import 'package:simple_live_app/modules/settings/appstyle_setting_page.dart';
import 'package:simple_live_app/modules/settings/auto_exit_settings_page.dart';
import 'package:simple_live_app/modules/settings/danmu_settings_page.dart';
import 'package:simple_live_app/modules/settings/follow_settings_page.dart';
import 'package:simple_live_app/modules/settings/indexed_settings/indexed_settings_controller.dart';
import 'package:simple_live_app/modules/settings/indexed_settings/indexed_settings_page.dart';
import 'package:simple_live_app/modules/settings/other/other_settings_controller.dart';
import 'package:simple_live_app/modules/settings/other/other_settings_page.dart';
import 'package:simple_live_app/modules/settings/play_settings_page.dart';
import 'package:simple_live_app/modules/settings/settings_side_panels.dart';
import 'package:simple_live_app/modules/sync/sync_page.dart';
import 'package:simple_live_app/routes/route_path.dart';
import 'package:simple_live_app/services/signalr_service.dart';
import 'package:simple_live_app/widgets/desktop_page_header.dart';
import 'package:simple_live_app/widgets/settings/settings_workspace.dart';
import 'package:url_launcher/url_launcher_string.dart';

enum _MineDesktopEntry {
  account,
  sync,
  indexed,
  play,
  danmu,
  follow,
  other,
}

enum _MineActionType {
  workspace,
  panel,
  route,
  external,
  callback,
}

class MinePage extends StatefulWidget {
  const MinePage({Key? key}) : super(key: key);

  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> {
  _MineDesktopEntry _selectedEntry = _MineDesktopEntry.indexed;

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

  List<_MineActionSection> _desktopSections() {
    return [
      const _MineActionSection(
        title: "资料",
        description: "记录、账号、同步与工具。",
        items: [
          _MineActionItem(
            icon: Remix.history_line,
            title: "观看记录",
            hint: "最近浏览",
            type: _MineActionType.route,
            routeName: RoutePath.kHistory,
          ),
          _MineActionItem(
            icon: Remix.account_circle_line,
            title: "账号管理",
            hint: "登录与权限",
            type: _MineActionType.workspace,
            entry: _MineDesktopEntry.account,
          ),
          _MineActionItem(
            icon: Icons.sync,
            title: "数据同步",
            hint: "设备与配置",
            type: _MineActionType.workspace,
            entry: _MineDesktopEntry.sync,
          ),
          _MineActionItem(
            icon: Remix.link,
            title: "链接解析",
            hint: "通过链接直达",
            type: _MineActionType.route,
            routeName: RoutePath.kTools,
          ),
        ],
      ),
      const _MineActionSection(
        title: "偏好",
        description: "界面、首页、播放和跟播设置。",
        items: [
          _MineActionItem(
            icon: Remix.moon_line,
            title: "外观设置",
            hint: "侧滑面板",
            type: _MineActionType.panel,
            panelAction: showAppstyleSettingsPanel,
          ),
          _MineActionItem(
            icon: Remix.home_2_line,
            title: "主页设置",
            hint: "工作台",
            type: _MineActionType.workspace,
            entry: _MineDesktopEntry.indexed,
          ),
          _MineActionItem(
            icon: Remix.play_circle_line,
            title: "直播设置",
            hint: "工作台",
            type: _MineActionType.workspace,
            entry: _MineDesktopEntry.play,
          ),
          _MineActionItem(
            icon: Remix.text,
            title: "弹幕设置",
            hint: "工作台",
            type: _MineActionType.workspace,
            entry: _MineDesktopEntry.danmu,
          ),
          _MineActionItem(
            icon: Remix.heart_line,
            title: "关注设置",
            hint: "工作台",
            type: _MineActionType.workspace,
            entry: _MineDesktopEntry.follow,
          ),
          _MineActionItem(
            icon: Remix.timer_2_line,
            title: "定时关闭",
            hint: "侧滑面板",
            type: _MineActionType.panel,
            panelAction: showAutoExitSettingsPanel,
          ),
          _MineActionItem(
            icon: Remix.apps_line,
            title: "其他设置",
            hint: "工作台",
            type: _MineActionType.workspace,
            entry: _MineDesktopEntry.other,
          ),
        ],
      ),
      _MineActionSection(
        title: "项目",
        description: "说明、源码与调试入口。",
        items: [
          const _MineActionItem(
            icon: Remix.information_line,
            title: "关于",
            hint: "侧滑面板",
            type: _MineActionType.panel,
            panelAction: showAboutPanel,
          ),
          const _MineActionItem(
            icon: Remix.error_warning_line,
            title: "免责声明",
            hint: "侧滑面板",
            type: _MineActionType.panel,
            panelAction: showStatementPanel,
          ),
          _MineActionItem(
            icon: Remix.github_line,
            title: "项目主页",
            hint: "GitHub",
            type: _MineActionType.external,
            callback: _openGithub,
          ),
          if (kDebugMode)
            _MineActionItem(
              icon: Remix.bug_line,
              title: "调试",
              hint: "SignalR 检查",
              type: _MineActionType.callback,
              callback: _runDebugAction,
            ),
        ],
      ),
    ];
  }

  List<_MineActionSection> _mobileSections() {
    return [
      const _MineActionSection(
        title: "资料",
        description: "记录、账号、同步和工具入口。",
        items: [
          _MineActionItem(
            icon: Remix.history_line,
            title: "观看记录",
            hint: "最近浏览",
            type: _MineActionType.route,
            routeName: RoutePath.kHistory,
          ),
          _MineActionItem(
            icon: Remix.account_circle_line,
            title: "账号管理",
            hint: "登录与权限",
            type: _MineActionType.route,
            routeName: RoutePath.kSettingsAccount,
          ),
          _MineActionItem(
            icon: Icons.sync,
            title: "数据同步",
            hint: "设备与配置",
            type: _MineActionType.route,
            routeName: RoutePath.kSync,
          ),
          _MineActionItem(
            icon: Remix.link,
            title: "链接解析",
            hint: "通过链接直达",
            type: _MineActionType.route,
            routeName: RoutePath.kTools,
          ),
        ],
      ),
      _MineActionSection(
        title: "偏好",
        description: "界面、首页、播放和跟播设置。",
        items: [
          _MineActionItem(
            icon: Remix.moon_line,
            title: "外观设置",
            hint: "浅色 / 深色",
            type: _MineActionType.route,
            routeName: RoutePath.kAppstyleSetting,
          ),
          _MineActionItem(
            icon: Remix.home_2_line,
            title: "主页设置",
            hint: "导航与首页",
            type: _MineActionType.route,
            routeName: RoutePath.kSettingsIndexed,
          ),
          _MineActionItem(
            icon: Remix.play_circle_line,
            title: "直播设置",
            hint: "播放与窗口",
            type: _MineActionType.route,
            routeName: RoutePath.kSettingsPlay,
          ),
          _MineActionItem(
            icon: Remix.text,
            title: "弹幕设置",
            hint: "显示与样式",
            type: _MineActionType.route,
            routeName: RoutePath.kSettingsDanmu,
          ),
          _MineActionItem(
            icon: Remix.heart_line,
            title: "关注设置",
            hint: "关注页行为",
            type: _MineActionType.route,
            routeName: RoutePath.kSettingsFollow,
          ),
          _MineActionItem(
            icon: Remix.timer_2_line,
            title: "定时关闭",
            hint: "自动退出",
            type: _MineActionType.route,
            routeName: RoutePath.kSettingsAutoExit,
          ),
          _MineActionItem(
            icon: Remix.apps_line,
            title: "其他设置",
            hint: "系统与附加项",
            type: _MineActionType.route,
            routeName: RoutePath.kSettingsOther,
          ),
        ],
      ),
      _MineActionSection(
        title: "项目",
        description: "说明、源码与调试入口。",
        items: [
          _MineActionItem(
            icon: Remix.information_line,
            title: "关于",
            hint: "版本信息",
            type: _MineActionType.callback,
            callback: () async => _showAboutDialog(),
          ),
          _MineActionItem(
            icon: Remix.error_warning_line,
            title: "免责声明",
            hint: "使用说明",
            type: _MineActionType.callback,
            callback: () async {
              await Utils.showStatement();
            },
          ),
          _MineActionItem(
            icon: Remix.github_line,
            title: "项目主页",
            hint: "GitHub",
            type: _MineActionType.external,
            callback: _openGithub,
          ),
          if (kDebugMode)
            _MineActionItem(
              icon: Remix.bug_line,
              title: "调试",
              hint: "SignalR 检查",
              type: _MineActionType.callback,
              callback: _runDebugAction,
            ),
        ],
      ),
    ];
  }

  void _ensureEntryBinding(_MineDesktopEntry entry) {
    switch (entry) {
      case _MineDesktopEntry.account:
        if (!Get.isRegistered<AccountController>()) {
          Get.put(AccountController());
        }
        break;
      case _MineDesktopEntry.indexed:
        if (!Get.isRegistered<IndexedSettingsController>()) {
          Get.put(IndexedSettingsController());
        }
        break;
      case _MineDesktopEntry.other:
        if (!Get.isRegistered<OtherSettingsController>()) {
          Get.put(OtherSettingsController());
        }
        break;
      case _MineDesktopEntry.sync:
      case _MineDesktopEntry.play:
      case _MineDesktopEntry.danmu:
      case _MineDesktopEntry.follow:
        break;
    }
  }

  Future<void> _handleDesktopAction(_MineActionItem item) async {
    switch (item.type) {
      case _MineActionType.workspace:
        if (item.entry == null) return;
        _ensureEntryBinding(item.entry!);
        setState(() {
          _selectedEntry = item.entry!;
        });
        break;
      case _MineActionType.panel:
        item.panelAction?.call();
        break;
      case _MineActionType.route:
        if (item.routeName != null) {
          await Get.toNamed(item.routeName!);
        }
        break;
      case _MineActionType.external:
      case _MineActionType.callback:
        await item.callback?.call();
        break;
    }
  }

  Future<void> _handleMobileAction(_MineActionItem item) async {
    switch (item.type) {
      case _MineActionType.route:
        if (item.routeName != null) {
          await Get.toNamed(item.routeName!);
        }
        break;
      case _MineActionType.panel:
        item.panelAction?.call();
        break;
      case _MineActionType.external:
      case _MineActionType.callback:
        await item.callback?.call();
        break;
      case _MineActionType.workspace:
        break;
    }
  }

  Widget _buildDesktopSidebar() {
    final sections = _desktopSections();
    final borderColor =
        AppStyle.borderColor(context).withAlpha(Get.isDarkMode ? 120 : 180);

    return Container(
      width: 312,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          right: BorderSide(color: borderColor),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        children: [
          for (final section in sections) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
              child: Text(
                section.title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Text(
                section.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppStyle.mutedTextColor(context),
                    ),
              ),
            ),
            ...section.items.map(_buildDesktopSidebarItem),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildDesktopSidebarItem(_MineActionItem item) {
    final selected =
        item.type == _MineActionType.workspace && item.entry == _selectedEntry;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fillColor = selected
        ? scheme.primary.withAlpha(Get.isDarkMode ? 24 : 14)
        : Colors.transparent;
    final borderColor = selected
        ? scheme.primary.withAlpha(Get.isDarkMode ? 72 : 48)
        : Colors.transparent;
    final textColor = selected ? scheme.onSurface : theme.colorScheme.onSurface;
    final hintColor =
        selected ? scheme.onSurfaceVariant : AppStyle.mutedTextColor(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleDesktopAction(item),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Icon(
                    item.icon,
                    size: 20,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: textColor,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item.hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: hintColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkspaceContent() {
    _ensureEntryBinding(_selectedEntry);

    switch (_selectedEntry) {
      case _MineDesktopEntry.account:
        return const SettingsWorkspace(
          title: "账号管理",
          subtitle: "登录状态与账号能力",
          child: AccountView(),
        );
      case _MineDesktopEntry.sync:
        return const SettingsWorkspace(
          title: "数据同步",
          subtitle: "局域网、房间与 WebDAV 同步",
          child: SyncView(),
        );
      case _MineDesktopEntry.indexed:
        return const SettingsWorkspace(
          title: "主页设置",
          subtitle: "首页栏目与展示顺序",
          child: IndexedSettingsView(),
        );
      case _MineDesktopEntry.play:
        return const SettingsWorkspace(
          title: "直播设置",
          subtitle: "播放、任务栏与透明浮窗相关选项",
          child: PlaySettingsView(),
        );
      case _MineDesktopEntry.danmu:
        return SettingsWorkspace(
          title: "弹幕设置",
          subtitle: "显示密度、字号与屏蔽规则",
          child: ListView(
            padding: AppStyle.contentPadding(context),
            children: const [
              DanmuSettingsView(),
            ],
          ),
        );
      case _MineDesktopEntry.follow:
        return const SettingsWorkspace(
          title: "关注设置",
          subtitle: "关注列表自动刷新与并发控制",
          child: FollowSettingsView(),
        );
      case _MineDesktopEntry.other:
        return const SettingsWorkspace(
          title: "其他设置",
          subtitle: "配置维护、播放内核与日志记录",
          child: OtherSettingsView(),
        );
    }
  }

  Widget _buildDesktopBody() {
    return Row(
      children: [
        _buildDesktopSidebar(),
        Expanded(
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeOutCubic,
              child: KeyedSubtree(
                key: ValueKey(_selectedEntry),
                child: _buildWorkspaceContent(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileSectionHeader(
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

  Widget _buildMobileActionRow(
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
        onTap: () => _handleMobileAction(item),
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
                item.type == _MineActionType.external
                    ? Icons.open_in_new
                    : Icons.chevron_right,
                size: 18,
                color: mutedColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileBody() {
    final sections = _mobileSections();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        ...sections.map(
          (section) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMobileSectionHeader(
                context,
                title: section.title,
                description: section.description,
              ),
              ...section.items.asMap().entries.map(
                    (entry) => _buildMobileActionRow(
                      context,
                      item: entry.value,
                      showDivider: entry.key != section.items.length - 1,
                    ),
                  ),
            ],
          ),
        ),
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
              child: isDesktop ? _buildDesktopBody() : _buildMobileBody(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MineActionSection {
  final String title;
  final String description;
  final List<_MineActionItem> items;

  const _MineActionSection({
    required this.title,
    required this.description,
    required this.items,
  });
}

class _MineActionItem {
  final IconData icon;
  final String title;
  final String hint;
  final _MineActionType type;
  final _MineDesktopEntry? entry;
  final String? routeName;
  final VoidCallback? panelAction;
  final Future<void> Function()? callback;

  const _MineActionItem({
    required this.icon,
    required this.title,
    required this.hint,
    required this.type,
    this.entry,
    this.routeName,
    this.panelAction,
    this.callback,
  });
}
