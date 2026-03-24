import 'package:flutter/material.dart';

class FilterButton extends StatelessWidget {
  final bool selected;
  final String text;
  final Function()? onTap;
  const FilterButton({
    this.selected = false,
    required this.text,
    this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = selected
        ? scheme.primary.withAlpha(isDark ? 78 : 56)
        : theme.dividerColor.withAlpha(isDark ? 120 : 180);
    final fillColor =
        selected ? scheme.primary.withAlpha(isDark ? 22 : 14) : theme.cardColor;
    final textColor = selected ? scheme.onSurface : scheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: theme.textTheme.labelLarge?.copyWith(
              color: textColor,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
