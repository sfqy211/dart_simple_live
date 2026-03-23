import 'package:flutter/material.dart';
import 'package:simple_live_app/app/app_style.dart';

class AppShellFrame extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final bool safeArea;

  const AppShellFrame({
    required this.child,
    this.padding,
    this.safeArea = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: padding ?? AppStyle.shellPadding(context),
      child: child,
    );

    return DecoratedBox(
      decoration: AppStyle.shellBackground(context),
      child: safeArea ? SafeArea(child: body) : body,
    );
  }
}

class AppPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final bool emphasized;
  final Clip clipBehavior;

  const AppPanel({
    required this.child,
    this.padding,
    this.emphasized = false,
    this.clipBehavior = Clip.none,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppStyle.panelDecoration(
        context,
        emphasized: emphasized,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          AppStyle.isDesktopLayout(context) ? 28 : 20,
        ),
        clipBehavior: clipBehavior,
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}
