import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/modules/mine/account/account_controller.dart';

class AccountPage extends GetView<AccountController> {
  const AccountPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("账号管理"),
      ),
      body: ListView(
        children: const [
          Padding(
            padding: AppStyle.edgeInsetsA12,
            child: Text(
              "哔哩哔哩账号需要登录才能看高清晰度的直播。",
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
