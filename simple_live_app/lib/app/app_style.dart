import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class AppColors {
  static const Color seed = Color(0xFF0A64D6);

  static final ColorScheme lightColorScheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
  );
  static final ColorScheme darkColorScheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.dark,
  );

  static const Color lightScaffold = Color(0xFFF3F3F3);
  static const Color darkScaffold = Color(0xFF181818);

  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color darkCard = Color(0xFF202020);

  static const Color ghostLightPanel = Color(0xD9F3F3F3);
  static const Color ghostDarkPanel = Color(0xD9202020);

  static const Color black333 = Color(0xFF333333);
}

class AppStyle {
  static String? get defaultFontFamily => "Microsoft YaHei";

  static ThemeData get lightTheme {
    final scheme = AppColors.lightColorScheme;
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      visualDensity: VisualDensity.standard,
    );
    final textTheme = base.textTheme.apply(fontFamily: defaultFontFamily);

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.lightScaffold,
      canvasColor: AppColors.lightScaffold,
      cardColor: AppColors.lightCard,
      dividerColor: const Color(0xFFE3E3E8),
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
        dividerColor: dividerColorWithBrightness(false),
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
        backgroundColor: AppColors.lightCard,
        indicatorColor: scheme.primary.withAlpha(14),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: dividerColorWithBrightness(false)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: dividerColorWithBrightness(false)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          side: BorderSide(
            color: dividerColorWithBrightness(false),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        showCheckmark: false,
        side: BorderSide(color: dividerColorWithBrightness(false)),
        selectedColor: scheme.primary.withAlpha(14),
        backgroundColor: AppColors.lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        labelStyle: textTheme.labelLarge,
      ),
      scrollbarTheme: ScrollbarThemeData(
        radius: const Radius.circular(4),
        thickness: WidgetStateProperty.all(5),
        thumbColor: WidgetStateProperty.all(
          Colors.black.withAlpha(50),
        ),
        trackColor: WidgetStateProperty.all(Colors.transparent),
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
    final textTheme = base.textTheme.apply(fontFamily: defaultFontFamily);

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.darkScaffold,
      canvasColor: AppColors.darkScaffold,
      cardColor: AppColors.darkCard,
      dividerColor: const Color(0xFF38383A),
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
        dividerColor: dividerColorWithBrightness(true),
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
        backgroundColor: AppColors.darkCard,
        indicatorColor: scheme.primary.withAlpha(18),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: const Color(0xFF252526),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: dividerColorWithBrightness(true)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: dividerColorWithBrightness(true)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          side: BorderSide(
            color: dividerColorWithBrightness(true),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        showCheckmark: false,
        side: BorderSide(color: dividerColorWithBrightness(true)),
        selectedColor: scheme.primary.withAlpha(18),
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        labelStyle: textTheme.labelLarge,
      ),
      scrollbarTheme: ScrollbarThemeData(
        radius: const Radius.circular(4),
        thickness: WidgetStateProperty.all(5),
        thumbColor: WidgetStateProperty.all(
          Colors.white.withAlpha(68),
        ),
        trackColor: WidgetStateProperty.all(Colors.transparent),
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

  static bool isDesktopPlatform() => true;

  static bool isDesktopLayout(BuildContext context) =>
      isDesktopPlatform() && MediaQuery.of(context).size.width >= 960;

  static Color dividerColorWithBrightness(bool isDark) =>
      isDark ? const Color(0xFF313131) : const Color(0xFFD9D9D9);

  static double panelRadius(BuildContext context, {bool compact = false}) =>
      isDesktopLayout(context) ? (compact ? 4 : 0) : (compact ? 10 : 12);

  static EdgeInsets shellPadding(BuildContext context) =>
      isDesktopLayout(context) ? EdgeInsets.zero : EdgeInsets.zero;

  static EdgeInsets contentPadding(BuildContext context) =>
      isDesktopLayout(context)
          ? const EdgeInsets.fromLTRB(16, 16, 16, 16)
          : edgeInsetsA12;

  static Color borderColor(BuildContext context) =>
      Theme.of(context).dividerColor;

  static Color mutedTextColor(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  static BoxDecoration shellBackground(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? AppColors.darkScaffold : AppColors.lightScaffold,
    );
  }

  static BoxDecoration panelDecoration(
    BuildContext context, {
    bool emphasized = false,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(panelRadius(context)),
    );
  }

  static BoxDecoration panelInnerDecoration(
    BuildContext context, {
    bool emphasized = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final base = emphasized
        ? (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF))
        : (isDark ? const Color(0xFF202020) : const Color(0xFFF8F8F8));
    return BoxDecoration(
      color: base,
      borderRadius: BorderRadius.circular(panelRadius(context)),
      border: Border.all(
        color: borderColor(context).withAlpha(isDark ? 110 : 170),
      ),
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
