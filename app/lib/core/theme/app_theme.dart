import 'package:flutter/material.dart';

import '../motion.dart';
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
          TargetPlatform.android: _SlideFadePageTransitionsBuilder(),
          TargetPlatform.windows: _SlideFadePageTransitionsBuilder(),
          TargetPlatform.linux: _SlideFadePageTransitionsBuilder(),
          TargetPlatform.macOS: _SlideFadePageTransitionsBuilder(),
          TargetPlatform.iOS: _SlideFadePageTransitionsBuilder(),
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

/// 二三级页面的切换动效：进场页淡入 + 从右侧 6% 滑入，出场页向左轻移做出层叠感。
/// 时长 250ms、弹簧曲线，与弹层、分栏切换保持同一套动效语言。
class _SlideFadePageTransitionsBuilder extends PageTransitionsBuilder {
  const _SlideFadePageTransitionsBuilder();

  @override
  Duration get transitionDuration => Motion.medium;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: secondaryAnimation.drive(
        Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-0.04, 0),
        ).chain(CurveTween(curve: Motion.spring)),
      ),
      child: SlideTransition(
        position: animation.drive(
          Tween<Offset>(
            begin: const Offset(0.06, 0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Motion.spring)),
        ),
        child: FadeTransition(
          opacity: animation.drive(
            CurveTween(curve: const Interval(0, 0.6, curve: Curves.easeOut)),
          ),
          child: child,
        ),
      ),
    );
  }
}
