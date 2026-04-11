// ignore_for_file: prefer_const_constructors

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/log.dart';
import 'package:simple_live_app/modules/mine/account/account_controller.dart';
import 'package:simple_live_app/modules/mine/account/account_page.dart';
import 'package:simple_live_app/modules/mine/history/history_controller.dart';
import 'package:simple_live_app/modules/mine/history/history_page.dart';
import 'package:simple_live_app/modules/mine/parse/parse_controller.dart';
import 'package:simple_live_app/modules/mine/parse/parse_page.dart';
import 'package:simple_live_app/modules/settings/about_settings_page.dart';
import 'package:simple_live_app/modules/settings/appstyle_setting_page.dart';
import 'package:simple_live_app/modules/settings/auto_exit_settings_page.dart';
import 'package:simple_live_app/modules/settings/danmu_settings_page.dart';
import 'package:simple_live_app/modules/settings/follow_settings_page.dart';
import 'package:simple_live_app/modules/settings/indexed_settings/indexed_settings_controller.dart';
import 'package:simple_live_app/modules/settings/indexed_settings/indexed_settings_page.dart';
import 'package:simple_live_app/modules/settings/other/other_settings_controller.dart';
import 'package:simple_live_app/modules/settings/other/other_settings_page.dart';
import 'package:simple_live_app/modules/settings/play_settings_page.dart';
import 'package:simple_live_app/modules/settings/voice_recognition_settings_page.dart';
import 'package:simple_live_app/modules/sync/sync_page.dart';
import 'package:simple_live_app/routes/route_path.dart';
import 'package:simple_live_app/services/signalr_service.dart';
import 'package:simple_live_app/widgets/desktop_page_header.dart';
import 'package:simple_live_app/widgets/desktop_workbench.dart';
import 'package:simple_live_app/widgets/settings/settings_workspace.dart';

enum _MineDesktopEntry {
  history,
  account,
  sync,
  tools,
  appearance,
  indexed,
  play,
  danmu,
  subtitle,
  follow,
  autoExit,
  other,
  about,
}

enum _MineMobileActionType {
  route,
  page,
  callback,
}

class MinePage extends StatefulWidget {
  const MinePage({super.key});

  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> {
  _MineDesktopEntry _selectedEntry = _MineDesktopEntry.indexed;

  Future<void> _runDebugAction() async {
    final signalRService = SignalRService();
    await signalRService.connect();
    final room = await signalRService.createRoom();
    Log.logPrint(room);
  }

  List<DesktopWorkbenchSectionData> _desktopSections() {
    return [
      DesktopWorkbenchSectionData(
        title: "资料",
        description: "记录、账号、同步与工具入口。",
        items: [
          _desktopItem(
            entry: _MineDesktopEntry.history,
            icon: Remix.history_line,
            title: "观看记录",
            hint: "最近浏览",
          ),
          _desktopItem(
            entry: _MineDesktopEntry.account,
            icon: Remix.account_circle_line,
            title: "账号管理",
            hint: "登录与权限",
          ),
          _desktopItem(
            entry: _MineDesktopEntry.sync,
            icon: Icons.sync,
            title: "数据同步",
            hint: "设备与配置",
          ),
          _desktopItem(
            entry: _MineDesktopEntry.tools,
            icon: Remix.link,
            title: "链接解析",
            hint: "通过链接直达",
          ),
        ],
      ),
      DesktopWorkbenchSectionData(
        title: "偏好",
        description: "界面、导航、播放和关注相关设置。",
        items: [
          _desktopItem(
            entry: _MineDesktopEntry.appearance,
            icon: Remix.moon_line,
            title: "外观设置",
            hint: "浅色 / 深色",
          ),
          _desktopItem(
            entry: _MineDesktopEntry.indexed,
            icon: Remix.home_2_line,
            title: "导航设置",
            hint: "栏位与顺序",
          ),
          _desktopItem(
            entry: _MineDesktopEntry.play,
            icon: Remix.play_circle_line,
            title: "直播设置",
            hint: "播放与浮窗",
          ),
          _desktopItem(
            entry: _MineDesktopEntry.danmu,
            icon: Remix.text,
            title: "弹幕设置",
            hint: "显示与屏蔽",
          ),
          _desktopItem(
            entry: _MineDesktopEntry.subtitle,
            icon: Icons.subtitles_outlined,
            title: "字幕设置",
            hint: "本地/在线识别",
          ),
          _desktopItem(
            entry: _MineDesktopEntry.follow,
            icon: Remix.heart_line,
            title: "关注设置",
            hint: "刷新与并发",
          ),
          _desktopItem(
            entry: _MineDesktopEntry.autoExit,
            icon: Remix.timer_2_line,
            title: "定时关闭",
            hint: "自动退出",
          ),
          _desktopItem(
            entry: _MineDesktopEntry.other,
            icon: Remix.apps_line,
            title: "其他设置",
            hint: "系统与附加项",
          ),
        ],
      ),
      DesktopWorkbenchSectionData(
        title: "项目",
        description: "版本信息、说明与调试入口。",
        items: [
          _desktopItem(
            entry: _MineDesktopEntry.about,
            icon: Remix.information_line,
            title: "关于",
            hint: "说明与项目主页",
          ),
          if (kDebugMode)
            DesktopWorkbenchItemData(
              icon: Remix.bug_line,
              title: "调试",
              hint: "SignalR 检查",
              selected: false,
              onTap: _runDebugAction,
            ),
        ],
      ),
    ];
  }

  DesktopWorkbenchItemData _desktopItem({
    required _MineDesktopEntry entry,
    required IconData icon,
    required String title,
    required String hint,
  }) {
    return DesktopWorkbenchItemData(
      icon: icon,
      title: title,
      hint: hint,
      selected: _selectedEntry == entry,
      onTap: () => _selectDesktopEntry(entry),
    );
  }

  List<_MineMobileSection> _mobileSections() {
    return [
      _MineMobileSection(
        title: "资料",
        description: "记录、账号、同步和工具入口。",
        items: [
          _MineMobileItem(
            icon: Remix.history_line,
            title: "观看记录",
            hint: "最近浏览",
            type: _MineMobileActionType.route,
            routeName: RoutePath.kHistory,
          ),
          _MineMobileItem(
            icon: Remix.account_circle_line,
            title: "账号管理",
            hint: "登录与权限",
            type: _MineMobileActionType.route,
            routeName: RoutePath.kSettingsAccount,
          ),
          _MineMobileItem(
            icon: Icons.sync,
            title: "数据同步",
            hint: "设备与配置",
            type: _MineMobileActionType.route,
            routeName: RoutePath.kSync,
          ),
          _MineMobileItem(
            icon: Remix.link,
            title: "链接解析",
            hint: "通过链接直达",
            type: _MineMobileActionType.route,
            routeName: RoutePath.kTools,
          ),
        ],
      ),
      _MineMobileSection(
        title: "偏好",
        description: "界面、导航、播放和关注相关设置。",
        items: [
          _MineMobileItem(
            icon: Remix.moon_line,
            title: "外观设置",
            hint: "浅色 / 深色",
            type: _MineMobileActionType.route,
            routeName: RoutePath.kAppstyleSetting,
          ),
          _MineMobileItem(
            icon: Remix.home_2_line,
            title: "导航设置",
            hint: "栏位与顺序",
            type: _MineMobileActionType.route,
            routeName: RoutePath.kSettingsIndexed,
          ),
          _MineMobileItem(
            icon: Remix.play_circle_line,
            title: "直播设置",
            hint: "播放与浮窗",
            type: _MineMobileActionType.route,
            routeName: RoutePath.kSettingsPlay,
          ),
          _MineMobileItem(
            icon: Remix.text,
            title: "弹幕设置",
            hint: "显示与屏蔽",
            type: _MineMobileActionType.route,
            routeName: RoutePath.kSettingsDanmu,
          ),
          _MineMobileItem(
            icon: Icons.subtitles_outlined,
            title: "字幕设置",
            hint: "本地/在线识别",
            type: _MineMobileActionType.page,
            pageBuilder: () => const VoiceRecognitionSettingsPage(),
          ),
          _MineMobileItem(
            icon: Remix.heart_line,
            title: "关注设置",
            hint: "刷新与并发",
            type: _MineMobileActionType.route,
            routeName: RoutePath.kSettingsFollow,
          ),
          _MineMobileItem(
            icon: Remix.timer_2_line,
            title: "定时关闭",
            hint: "自动退出",
            type: _MineMobileActionType.route,
            routeName: RoutePath.kSettingsAutoExit,
          ),
          _MineMobileItem(
            icon: Remix.apps_line,
            title: "其他设置",
            hint: "系统与附加项",
            type: _MineMobileActionType.route,
            routeName: RoutePath.kSettingsOther,
          ),
        ],
      ),
      _MineMobileSection(
        title: "项目",
        description: "版本信息、说明与调试入口。",
        items: [
          _MineMobileItem(
            icon: Remix.information_line,
            title: "关于",
            hint: "说明与项目主页",
            type: _MineMobileActionType.page,
            pageBuilder: () => const AboutSettingsPage(),
          ),
          if (kDebugMode)
            _MineMobileItem(
              icon: Remix.bug_line,
              title: "调试",
              hint: "SignalR 检查",
              type: _MineMobileActionType.callback,
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
      case _MineDesktopEntry.history:
        if (!Get.isRegistered<HistoryController>()) {
          Get.put(HistoryController());
        }
        break;
      case _MineDesktopEntry.tools:
        if (!Get.isRegistered<ParseController>()) {
          Get.put(ParseController());
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
      case _MineDesktopEntry.appearance:
      case _MineDesktopEntry.play:
      case _MineDesktopEntry.danmu:
      case _MineDesktopEntry.follow:
      case _MineDesktopEntry.autoExit:
      case _MineDesktopEntry.about:
      case _MineDesktopEntry.subtitle:
        break;
    }
  }

  void _selectDesktopEntry(_MineDesktopEntry entry) {
    _ensureEntryBinding(entry);
    setState(() {
      _selectedEntry = entry;
    });
  }

  Future<void> _handleMobileAction(_MineMobileItem item) async {
    switch (item.type) {
      case _MineMobileActionType.route:
        if (item.routeName != null) {
          await Get.toNamed(item.routeName!);
        }
        break;
      case _MineMobileActionType.page:
        if (item.pageBuilder != null) {
          await Get.to<dynamic>(item.pageBuilder!);
        }
        break;
      case _MineMobileActionType.callback:
        await item.callback?.call();
        break;
    }
  }

  Widget _buildWorkspaceContent() {
    _ensureEntryBinding(_selectedEntry);

    switch (_selectedEntry) {
      case _MineDesktopEntry.history:
        return SettingsWorkspace(
          title: "观看记录",
          subtitle: "最近访问过的直播间",
          actions: [
            TextButton.icon(
              onPressed: Get.find<HistoryController>().clean,
              icon: const Icon(Icons.delete_outline),
              label: const Text("清空"),
            ),
          ],
          child: const HistoryView(),
        );
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
      case _MineDesktopEntry.tools:
        return const SettingsWorkspace(
          title: "链接解析",
          subtitle: "通过链接直达直播间或提取播放直链",
          child: ParseView(),
        );
      case _MineDesktopEntry.appearance:
        return const SettingsWorkspace(
          title: "外观设置",
          subtitle: "浅色 / 深色主题与字体细节",
          child: AppstyleSettingView(),
        );
      case _MineDesktopEntry.indexed:
        return const SettingsWorkspace(
          title: "导航设置",
          subtitle: "侧边栏与底部栏顺序",
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
      case _MineDesktopEntry.subtitle:
        return const SettingsWorkspace(
          title: "字幕设置",
          subtitle: "本地模型与在线识别配置",
          child: VoiceRecognitionSettingsView(),
        );
      case _MineDesktopEntry.follow:
        return const SettingsWorkspace(
          title: "关注设置",
          subtitle: "关注列表自动刷新与并发控制",
          child: FollowSettingsView(),
        );
      case _MineDesktopEntry.autoExit:
        return const SettingsWorkspace(
          title: "定时关闭",
          subtitle: "适合长时间挂机观看时控制退出节奏",
          child: AutoExitSettingsView(),
        );
      case _MineDesktopEntry.other:
        return const SettingsWorkspace(
          title: "其他设置",
          subtitle: "配置维护、播放内核与日志记录",
          child: OtherSettingsView(),
        );
      case _MineDesktopEntry.about:
        return const SettingsWorkspace(
          title: "关于",
          subtitle: "版本信息、项目主页与使用说明",
          child: AboutSettingsView(),
        );
    }
  }

  Widget _buildDesktopBody() {
    return DesktopWorkbenchLayout(
      sidebar: DesktopWorkbenchSidebar(
        sections: _desktopSections(),
      ),
      content: AnimatedSwitcher(
        duration: const Duration(milliseconds: 160),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeOutCubic,
        child: KeyedSubtree(
          key: ValueKey(_selectedEntry),
          child: _buildWorkspaceContent(),
        ),
      ),
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
    required _MineMobileItem item,
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
                item.type == _MineMobileActionType.page
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
        backgroundColor: isDesktop
            ? Colors.transparent
            : Theme.of(context).scaffoldBackgroundColor,
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

class _MineMobileSection {
  final String title;
  final String description;
  final List<_MineMobileItem> items;

  const _MineMobileSection({
    required this.title,
    required this.description,
    required this.items,
  });
}

class _MineMobileItem {
  final IconData icon;
  final String title;
  final String hint;
  final _MineMobileActionType type;
  final String? routeName;
  final Widget Function()? pageBuilder;
  final Future<void> Function()? callback;

  const _MineMobileItem({
    required this.icon,
    required this.title,
    required this.hint,
    required this.type,
    this.routeName,
    this.pageBuilder,
    this.callback,
  });
}
