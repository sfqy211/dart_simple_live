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
    final fillColor = _hovered
        ? (isDark ? const Color(0xFF252526) : const Color(0xFFF8F8F8))
        : (isDark ? const Color(0xFF202020) : Colors.white);

    final decoration = BoxDecoration(
      color: fillColor,
      borderRadius: radius,
      border: Border.all(
        color: _hovered
            ? scheme.primary.withAlpha(isDark ? 90 : 72)
            : theme.dividerColor.withAlpha(isDark ? 110 : 165),
      ),
    );

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: widget.onTap,
          overlayColor: WidgetStateProperty.all(
            scheme.primary.withAlpha(isDark ? 18 : 12),
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
