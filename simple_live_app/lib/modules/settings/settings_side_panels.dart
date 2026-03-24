import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/utils.dart';

void showAboutPanel() {
  Utils.showRightDialog(
    title: "关于",
    width: 420,
    child: const _AboutPanelView(),
  );
}

void showStatementPanel() {
  Utils.showRightDialog(
    title: "免责声明",
    width: 520,
    child: const _StatementPanelView(),
  );
}

class _AboutPanelView extends StatelessWidget {
  const _AboutPanelView();

  @override
  Widget build(BuildContext context) {
    final muted = AppStyle.mutedTextColor(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border.all(
              color: AppStyle.borderColor(context)
                  .withAlpha(Get.isDarkMode ? 120 : 180),
            ),
          ),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
        const SizedBox(height: 16),
        const _PanelBlock(
          title: "产品定位",
          content: "面向长期看直播的桌面端观看工具，强调克制、稳定，以及长时间使用时的舒适感。",
        ),
        const SizedBox(height: 12),
        const _PanelBlock(
          title: "当前方向",
          content: "保留浅色 / 深色两套主题，减少圆角，改为更贴近桌面工具的线性分隔与满铺式布局。",
        ),
      ],
    );
  }
}

class _StatementPanelView extends StatelessWidget {
  const _StatementPanelView();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: rootBundle.loadString("assets/statement.txt"),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border.all(
                  color: AppStyle.borderColor(context)
                      .withAlpha(Get.isDarkMode ? 120 : 180),
                ),
              ),
              child: SelectableText(
                snapshot.data!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.65,
                    ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PanelBlock extends StatelessWidget {
  final String title;
  final String content;

  const _PanelBlock({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(
          color: AppStyle.borderColor(context)
              .withAlpha(Get.isDarkMode ? 120 : 180),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppStyle.mutedTextColor(context),
                  height: 1.55,
                ),
          ),
        ],
      ),
    );
  }
}
