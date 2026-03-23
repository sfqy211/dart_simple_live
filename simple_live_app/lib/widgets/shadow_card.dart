import 'package:flutter/material.dart';
import 'package:simple_live_app/app/app_style.dart';

class ShadowCard extends StatefulWidget {
  final Widget child;
  final double radius;
  final Function()? onTap;
  const ShadowCard({
    required this.child,
    this.radius = 8.0,
    this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  State<ShadowCard> createState() => _ShadowCardState();
}

class _ShadowCardState extends State<ShadowCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(widget.radius);
    final canHover = AppStyle.isDesktopPlatform() && widget.onTap != null;

    final shadowBase = isDark
        ? const <BoxShadow>[]
        : [
            BoxShadow(
              blurRadius: 18,
              spreadRadius: -6,
              offset: const Offset(0, 10),
              color: Colors.black.withAlpha(12),
            ),
          ];
    final shadowHover = isDark
        ? const <BoxShadow>[]
        : [
            BoxShadow(
              blurRadius: 28,
              spreadRadius: -10,
              offset: const Offset(0, 14),
              color: Colors.black.withAlpha(18),
            ),
          ];

    final decoration = BoxDecoration(
      borderRadius: radius,
      border: Border.all(
        color: theme.dividerColor.withAlpha(isDark ? 130 : 180),
      ),
      boxShadow: _hovered ? shadowHover : shadowBase,
    );

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      transformAlignment: Alignment.center,
      transform:
          Matrix4.translationValues(0, (_hovered ? -2 : 0).toDouble(), 0),
      decoration: decoration,
      child: Material(
        color: theme.cardColor.withAlpha(isDark ? 238 : 255),
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: widget.onTap,
          overlayColor: WidgetStateProperty.all(
            scheme.primary.withAlpha(isDark ? 18 : 14),
          ),
          child: widget.child,
        ),
      ),
    );

    if (!canHover) {
      return card;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: card,
    );
  }
}
