import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'tokens.dart';

/// 主题构建：颜色、字号、页面切换与弹层的统一外观。
abstract final class AppTheme {
  static ThemeData build({
    required Brightness brightness,
    required AppAccent accent,
  }) {
    final AppColors colors = AppColors.of(brightness, accent);
    final ColorScheme scheme =
        ColorScheme.fromSeed(
          seedColor: colors.accent,
          brightness: brightness,
        ).copyWith(
          primary: colors.accent,
          onPrimary: colors.onAccent,
          surface: colors.surface,
          onSurface: colors.text,
          surfaceContainerHighest: colors.surfaceAlt,
          outlineVariant: colors.separator,
          error: colors.periodRed,
        );

    final TextTheme textTheme = const TextTheme(
      displaySmall: AppType.display,
      titleLarge: AppType.title,
      titleMedium: AppType.headline,
      bodyMedium: AppType.body,
      bodySmall: AppType.bodySmall,
      labelSmall: AppType.caption,
    ).apply(bodyColor: colors.text, displayColor: colors.text);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.bg,
      canvasColor: colors.bg,
      fontFamily: AppFonts.family,
      fontFamilyFallback: AppFonts.fallback,
      textTheme: textTheme,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      extensions: <ThemeExtension<dynamic>>[colors],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppType.title.copyWith(color: colors.text),
      ),
      dividerTheme: DividerThemeData(
        color: colors.separator,
        thickness: 1,
        space: 1,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: colors.surface,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppType.headline.copyWith(color: colors.text),
        contentTextStyle: AppType.body.copyWith(color: colors.textSecondary),
      ),
    );
  }
}
