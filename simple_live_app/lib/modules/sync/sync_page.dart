import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/routes/route_path.dart';
import 'package:simple_live_app/widgets/settings/settings_action.dart';
import 'package:simple_live_app/widgets/settings/settings_card.dart';
import 'package:simple_live_app/widgets/settings/settings_workspace.dart';

class SyncPage extends StatelessWidget {
  const SyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsPageScaffold(
      title: "数据同步",
      subtitle: "局域网、房间与 WebDAV 同步",
      actions: [
        if (GetPlatform.isAndroid)
          TextButton.icon(
            onPressed: _scanQr,
            icon: const Icon(Remix.qr_scan_line),
            label: const Text("扫一扫"),
          ),
      ],
      body: const SyncView(),
    );
  }

  Future<void> _scanQr() async {
    final result = await Get.toNamed(RoutePath.kSyncScan);
    if (result == null || result.isEmpty) {
      return;
    }
    if (result.length == 5) {
      Get.toNamed(RoutePath.kRemoteSyncRoom, arguments: result);
    } else {
      Get.toNamed(RoutePath.kLocalSync, arguments: result);
    }
  }
}

class SyncView extends StatelessWidget {
  const SyncView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppStyle.contentPadding(context),
      children: [
        const SettingsSectionTitle(
          title: "远程同步",
          subtitle: "适合跨设备共享观看记录、设置与账号信息。",
        ),
        SettingsCard(
          child: Column(
            children: [
              SettingsAction(
                title: "创建房间",
                subtitle: "其他设备可以通过房间号加入",
                leading: const Icon(Remix.home_wifi_line),
                onTap: () => Get.toNamed(RoutePath.kRemoteSyncRoom),
              ),
              AppStyle.divider,
              SettingsAction(
                title: "加入房间",
                subtitle: "加入其他设备创建的房间",
                leading: const Icon(Remix.add_circle_line),
                onTap: () async {
                  final input = await Utils.showEditTextDialog(
                    "",
                    title: "加入房间",
                    hintText: "请输入房间号，不区分大小写",
                    validate: (text) {
                      if (text.isEmpty) {
                        SmartDialog.showToast("房间号不能为空");
                        return false;
                      }
                      if (text.length != 5) {
                        SmartDialog.showToast("请输入 5 位房间号");
                        return false;
                      }
                      return true;
                    },
                  );
                  if (input != null && input.isNotEmpty) {
                    Get.toNamed(
                      RoutePath.kRemoteSyncRoom,
                      arguments: input.toUpperCase(),
                    );
                  }
                },
              ),
              AppStyle.divider,
              SettingsAction(
                title: "WebDAV",
                subtitle: "通过 WebDAV 同步数据",
                leading: const Icon(Icons.cloud_upload_outlined),
                onTap: () => Get.toNamed(RoutePath.kRemoteSyncWebDav),
              ),
            ],
          ),
        ),
        AppStyle.vGap24,
        const SettingsSectionTitle(
          title: "局域网同步",
          subtitle: "同一局域网内快速同步数据与配置。",
        ),
        SettingsCard(
          child: SettingsAction(
            title: "局域网同步",
            subtitle: "在本地网络内同步数据",
            leading: const Icon(Remix.device_line),
            onTap: () => Get.toNamed(RoutePath.kLocalSync),
          ),
        ),
      ],
    );
  }
}
