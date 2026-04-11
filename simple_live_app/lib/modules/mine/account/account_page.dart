import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/modules/mine/account/account_controller.dart';
import 'package:simple_live_app/routes/route_path.dart';
import 'package:simple_live_app/services/bilibili_account_service.dart';
import 'package:simple_live_app/widgets/settings/settings_action.dart';
import 'package:simple_live_app/widgets/settings/settings_card.dart';
import 'package:simple_live_app/widgets/settings/settings_workspace.dart';

class AccountPage extends GetView<AccountController> {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsPageScaffold(
      title: "账号管理",
      subtitle: "登录状态与账号能力",
      body: AccountView(),
    );
  }
}

class AccountView extends GetView<AccountController> {
  const AccountView({super.key});

  @override
  Widget build(BuildContext context) {
    final service = BiliBiliAccountService.instance;

    return ListView(
      padding: AppStyle.contentPadding(context),
      children: [
        const SettingsSectionTitle(
          title: "账号状态",
          subtitle: "当前版本只保留哔哩哔哩账号能力。",
        ),
        SettingsCard(
          child: Obx(
            () => ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              title: Text(service.logined.value ? service.name.value : "未登录"),
              subtitle: Text(
                service.logined.value
                    ? "已解锁高画质、弹幕发送等账号能力"
                    : "登录后可解锁更完整的观看与互动体验",
              ),
              trailing: OutlinedButton(
                onPressed: controller.bilibiliTap,
                child: Text(service.logined.value ? "退出登录" : "快速登录"),
              ),
            ),
          ),
        ),
        AppStyle.vGap24,
        const SettingsSectionTitle(
          title: "登录方式",
          subtitle: "根据当前设备环境选择合适的登录方式。",
        ),
        SettingsCard(
          child: Column(
            children: [
              SettingsAction(
                title: "扫码登录",
                subtitle: "使用哔哩哔哩 App 扫码登录",
                onTap: () => Get.toNamed(RoutePath.kBiliBiliQRLogin),
              ),
              AppStyle.divider,
              SettingsAction(
                title: "Web 登录",
                subtitle: "在内置页面输入账号密码登录",
                onTap: () => Get.toNamed(RoutePath.kBiliBiliWebLogin),
              ),
              AppStyle.divider,
              SettingsAction(
                title: "Cookie 登录",
                subtitle: "手动输入 Cookie 完成登录",
                onTap: controller.doBiliBiliCookieLogin,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
