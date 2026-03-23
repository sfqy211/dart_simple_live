import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:simple_live_app/app/controller/app_settings_controller.dart';

class AppColors {
  // Subtle, cool-toned seed that stays quiet in both light/dark themes.
  static const Color seed = Color(0xFF4C78FF);

  static final ColorScheme lightColorScheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
  );
  static final ColorScheme darkColorScheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.dark,
  );

  // Tuned scaffolds for a calmer, more premium feel than pure white/black.
  static const Color lightScaffold = Color(0xFFF6F7F9);
  static const Color darkScaffold = Color(0xFF0B0F14);

  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color darkCard = Color(0xFF111824);

  static const Color ghostLightPanel = Color(0xDCF1F4F7);
  static const Color ghostDarkPanel = Color(0xD9121822);

  static const Color black333 = Color(0xFF333333);
}

class AppStyle {
  static String? get _fontFamily {
    final value = AppSettingsController.instance.appFontFamily.value;
    if (value.isNotEmpty) {
      return value;
    }
    return Platform.isWindows ? "Microsoft YaHei" : null;
  }

  static ThemeData get lightTheme {
    final scheme = AppColors.lightColorScheme;
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      visualDensity: VisualDensity.standard,
    );
    final textTheme = base.textTheme.apply(fontFamily: _fontFamily);

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.lightScaffold,
      canvasColor: AppColors.lightScaffold,
      cardColor: AppColors.lightCard,
      dividerColor: scheme.outlineVariant.withAlpha(140),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        foregroundColor: scheme.onSurface,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        labelColor: scheme.onSurface,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
        overlayColor: WidgetStateProperty.all(
          scheme.primary.withAlpha(18),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: scheme.primary.withAlpha(18),
        selectedIconTheme: IconThemeData(color: scheme.onSurface),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 56,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withAlpha(18),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withAlpha(120),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        dense: true,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  static ThemeData get darkTheme {
    final scheme = AppColors.darkColorScheme;
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      visualDensity: VisualDensity.standard,
    );
    final textTheme = base.textTheme.apply(fontFamily: _fontFamily);

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.darkScaffold,
      canvasColor: AppColors.darkScaffold,
      cardColor: AppColors.darkCard,
      dividerColor: scheme.outlineVariant.withAlpha(130),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        foregroundColor: scheme.onSurface,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        labelColor: scheme.onSurface,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
        overlayColor: WidgetStateProperty.all(
          scheme.primary.withAlpha(20),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: scheme.primary.withAlpha(22),
        selectedIconTheme: IconThemeData(color: scheme.onSurface),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 56,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withAlpha(22),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withAlpha(120),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        dense: true,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  static const vGap4 = SizedBox(
    height: 4,
  );
  static const vGap8 = SizedBox(
    height: 8,
  );
  static const vGap12 = SizedBox(
    height: 12,
  );
  static const vGap20 = SizedBox(
    height: 20,
  );
  static const vGap24 = SizedBox(
    height: 24,
  );
  static const vGap32 = SizedBox(
    height: 32,
  );
  static const vGap48 = SizedBox(
    height: 48,
  );

  static const hGap4 = SizedBox(
    width: 4,
  );
  static const hGap8 = SizedBox(
    width: 8,
  );
  static const hGap12 = SizedBox(
    width: 12,
  );
  static const hGap16 = SizedBox(
    width: 16,
  );

  static const hGap24 = SizedBox(
    width: 24,
  );
  static const hGap32 = SizedBox(
    width: 32,
  );
  static const hGap48 = SizedBox(
    width: 48,
  );

  static const edgeInsetsH4 = EdgeInsets.symmetric(horizontal: 4);
  static const edgeInsetsH8 = EdgeInsets.symmetric(horizontal: 8);
  static const edgeInsetsH12 = EdgeInsets.symmetric(horizontal: 12);
  static const edgeInsetsH16 = EdgeInsets.symmetric(horizontal: 16);
  static const edgeInsetsH20 = EdgeInsets.symmetric(horizontal: 20);
  static const edgeInsetsH24 = EdgeInsets.symmetric(horizontal: 24);

  static const edgeInsetsV4 = EdgeInsets.symmetric(vertical: 4);
  static const edgeInsetsV8 = EdgeInsets.symmetric(vertical: 8);
  static const edgeInsetsV12 = EdgeInsets.symmetric(vertical: 12);
  static const edgeInsetsV24 = EdgeInsets.symmetric(vertical: 24);

  static const edgeInsetsA4 = EdgeInsets.all(4);
  static const edgeInsetsA8 = EdgeInsets.all(8);
  static const edgeInsetsA12 = EdgeInsets.all(12);
  static const edgeInsetsA16 = EdgeInsets.all(16);
  static const edgeInsetsA20 = EdgeInsets.all(20);
  static const edgeInsetsA24 = EdgeInsets.all(24);

  static const edgeInsetsR4 = EdgeInsets.only(right: 4);
  static const edgeInsetsR8 = EdgeInsets.only(right: 8);
  static const edgeInsetsR12 = EdgeInsets.only(right: 12);
  static const edgeInsetsR16 = EdgeInsets.only(right: 16);
  static const edgeInsetsR20 = EdgeInsets.only(right: 20);
  static const edgeInsetsR24 = EdgeInsets.only(right: 24);

  static const edgeInsetsL4 = EdgeInsets.only(left: 4);
  static const edgeInsetsL8 = EdgeInsets.only(left: 8);
  static const edgeInsetsL12 = EdgeInsets.only(left: 12);
  static const edgeInsetsL16 = EdgeInsets.only(left: 16);
  static const edgeInsetsL20 = EdgeInsets.only(left: 20);
  static const edgeInsetsL24 = EdgeInsets.only(left: 24);

  static const edgeInsetsT4 = EdgeInsets.only(top: 4);
  static const edgeInsetsT8 = EdgeInsets.only(top: 8);
  static const edgeInsetsT12 = EdgeInsets.only(top: 12);
  static const edgeInsetsT24 = EdgeInsets.only(top: 24);

  static const edgeInsetsB4 = EdgeInsets.only(bottom: 4);
  static const edgeInsetsB8 = EdgeInsets.only(bottom: 8);
  static const edgeInsetsB12 = EdgeInsets.only(bottom: 12);
  static const edgeInsetsB24 = EdgeInsets.only(bottom: 24);

  static BorderRadius radius4 = BorderRadius.circular(4);
  static BorderRadius radius8 = BorderRadius.circular(8);
  static BorderRadius radius12 = BorderRadius.circular(12);
  static BorderRadius radius24 = BorderRadius.circular(24);
  static BorderRadius radius32 = BorderRadius.circular(32);
  static BorderRadius radius48 = BorderRadius.circular(48);

  /// 顶部状态栏的高度
  static double get statusBarHeight => MediaQuery.of(Get.context!).padding.top;

  /// 底部导航条的高度
  static double get bottomBarHeight =>
      MediaQuery.of(Get.context!).padding.bottom;

  static bool isDesktopPlatform() =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  static bool isDesktopLayout(BuildContext context) =>
      isDesktopPlatform() && MediaQuery.of(context).size.width >= 960;

  static EdgeInsets shellPadding(BuildContext context) =>
      isDesktopLayout(context)
          ? const EdgeInsets.fromLTRB(20, 20, 20, 20)
          : EdgeInsets.zero;

  static EdgeInsets contentPadding(BuildContext context) =>
      isDesktopLayout(context)
          ? const EdgeInsets.fromLTRB(24, 24, 24, 24)
          : edgeInsetsA12;

  static Color borderColor(BuildContext context) =>
      Theme.of(context).dividerColor;

  static Color mutedTextColor(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  static BoxDecoration shellBackground(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [
                Color(0xFF090D12),
                Color(0xFF0D131C),
                Color(0xFF111824),
              ]
            : const [
                Color(0xFFF9FAFC),
                Color(0xFFF2F4F7),
                Color(0xFFEDF1F5),
              ],
      ),
    );
  }

  static BoxDecoration panelDecoration(
    BuildContext context, {
    bool emphasized = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return BoxDecoration(
      color: emphasized
          ? theme.cardColor.withAlpha(isDark ? 248 : 252)
          : theme.cardColor.withAlpha(isDark ? 236 : 245),
      borderRadius: BorderRadius.circular(isDesktopLayout(context) ? 28 : 20),
      border: Border.all(
        color: borderColor(context).withAlpha(isDark ? 120 : 180),
      ),
      boxShadow: isDark
          ? const []
          : [
              BoxShadow(
                color: Colors.black.withAlpha(emphasized ? 18 : 10),
                blurRadius: emphasized ? 28 : 20,
                offset: const Offset(0, 10),
              ),
            ],
    );
  }

  static Divider get divider => Divider(
        height: 1,
        thickness: 1,
        indent: 16,
        endIndent: 16,
        color: Get.theme.dividerColor,
      );
}
