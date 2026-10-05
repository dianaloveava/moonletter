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
          TargetPlatform.android: _SlidePageTransitionsBuilder(),
          TargetPlatform.windows: _SlidePageTransitionsBuilder(),
          TargetPlatform.linux: _SlidePageTransitionsBuilder(),
          TargetPlatform.macOS: _SlidePageTransitionsBuilder(),
          TargetPlatform.iOS: _SlidePageTransitionsBuilder(),
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

/// 二三级页面的切换动效：新页面（不透明）从右侧整屏滑入盖住旧页面，旧页面不动。
/// 不用淡入淡出：两层同时半透明时上下两个页面会互相透出、叠在一起，而且整屏
/// opacity 每帧都要开离屏图层重绘，在中低端机上就是肉眼可见的一顿。
/// 时长 250ms、弹簧曲线，与分栏切换、弹层保持同一套动效语言。
class _SlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const _SlidePageTransitionsBuilder();

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
      position: animation.drive(
        Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Motion.spring)),
      ),
      child: child,
    );
  }
}
