import 'package:flutter/material.dart';

/// 视觉规格的唯一来源：颜色、圆角、间距、字号。
/// 其它文件不得硬编码色值与尺寸，一律从这里取。
abstract final class AppRadii {
  /// 卡片、分组列表、弹层
  static const double card = 20;

  /// 按钮、输入框、单元格
  static const double control = 16;

  /// 小标签、头像占位
  static const double chip = 10;

  /// 连续曲率平滑度
  static const double smoothing = 0.6;
}

abstract final class AppSpacing {
  static const double x1 = 8;
  static const double x2 = 16;
  static const double x3 = 24;
  static const double x4 = 32;

  /// 页面左右内边距
  static const double pageMobile = 20;
  static const double pageDesktop = 24;

  /// 分组列表之间的间距
  static const double groupGap = 24;

  /// 桌面端内容区最大宽度
  static const double contentMaxWidth = 1100;

  /// 底部导航切左侧边栏的宽度阈值
  static const double breakpoint = 720;
}

abstract final class AppFonts {
  /// 内置 Inter（拉丁字母与数字），中文走系统字体。
  static const String family = 'Inter';
  static const List<String> fallback = <String>[
    'Microsoft YaHei UI',
    'Noto Sans CJK SC',
    'PingFang SC',
    'sans-serif',
  ];
}

abstract final class AppType {
  static const TextStyle display = TextStyle(
    fontFamily: AppFonts.family,
    fontFamilyFallback: AppFonts.fallback,
    fontSize: 28,
    height: 34 / 28,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle title = TextStyle(
    fontFamily: AppFonts.family,
    fontFamilyFallback: AppFonts.fallback,
    fontSize: 20,
    height: 24 / 20,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle headline = TextStyle(
    fontFamily: AppFonts.family,
    fontFamilyFallback: AppFonts.fallback,
    fontSize: 17,
    height: 22 / 17,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle body = TextStyle(
    fontFamily: AppFonts.family,
    fontFamilyFallback: AppFonts.fallback,
    fontSize: 15,
    height: 20 / 15,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: AppFonts.family,
    fontFamilyFallback: AppFonts.fallback,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: AppFonts.family,
    fontFamilyFallback: AppFonts.fallback,
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w500,
  );
}

/// 主题色预设（设置 → 外观）。
enum AppAccent {
  rose('rose', Color(0xFFC4737F), Color(0xFFD98C97)),
  peach('peach', Color(0xFFD08A6A), Color(0xFFE0A183)),
  amber('amber', Color(0xFFC29A55), Color(0xFFD4AF6E)),
  moss('moss', Color(0xFF6F9E7F), Color(0xFF85B394)),
  mint('mint', Color(0xFF5FA6A0), Color(0xFF74BDB6)),
  mist('mist', Color(0xFF6D8FBF), Color(0xFF84A6D4)),
  lavender('lavender', Color(0xFF8B84C6), Color(0xFFA29BDB)),
  graphite('graphite', Color(0xFF7C828C), Color(0xFF949AA5));

  const AppAccent(this.id, this.light, this.dark);

  final String id;
  final Color light;
  final Color dark;

  static AppAccent fromId(String? id) => values.firstWhere(
    (AppAccent accent) => accent.id == id,
    orElse: () => AppAccent.rose,
  );

  Color of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}

/// 无头像时的默认底色，按成员 color_index 取用。
const List<Color> kDefaultAvatarColors = <Color>[
  Color(0xFFE4A0A6),
  Color(0xFFE8BE8E),
  Color(0xFFC9D59B),
  Color(0xFF9ED0C2),
  Color(0xFFA3C0E0),
  Color(0xFFB7AEE0),
  Color(0xFFE0AACE),
  Color(0xFFB8BCC4),
];

/// 主题扩展：语义色随明暗模式切换，经期/危险期/安全期颜色不随主题色变化。
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.text,
    required this.textSecondary,
    required this.separator,
    required this.periodRed,
    required this.periodRedSoft,
    required this.fertilePink,
    required this.ovulationFill,
    required this.safeFill,
    required this.safeStrong,
    required this.onAccent,
    required this.accent,
  });

  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color text;
  final Color textSecondary;
  final Color separator;
  final Color periodRed;
  final Color periodRedSoft;
  final Color fertilePink;
  final Color ovulationFill;
  final Color safeFill;
  final Color safeStrong;
  final Color onAccent;
  final Color accent;

  /// 主题色的浅色底（选中态背景等）。
  Color get accentTint => accent.withValues(alpha: 0.12);

  static const AppColors light = AppColors(
    bg: Color(0xFFF7F7F9),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF1F1F4),
    text: Color(0xFF1C1C1E),
    textSecondary: Color(0xFF6E6E73),
    separator: Color(0xFFE4E4E9),
    periodRed: Color(0xFFD9575F),
    periodRedSoft: Color(0xFFF7C9CC),
    fertilePink: Color(0xFFE39BAB),
    ovulationFill: Color(0xFFFBE3EA),
    safeFill: Color(0xFFE8F2E9),
    safeStrong: Color(0xFF86AE90),
    onAccent: Color(0xFFFFFFFF),
    accent: Color(0xFFC4737F),
  );

  static const AppColors dark = AppColors(
    bg: Color(0xFF121214),
    surface: Color(0xFF1C1C1F),
    surfaceAlt: Color(0xFF26262A),
    text: Color(0xFFF2F2F5),
    textSecondary: Color(0xFF9A9AA0),
    separator: Color(0xFF35353A),
    periodRed: Color(0xFFC9505A),
    periodRedSoft: Color(0xFF4A2A2E),
    fertilePink: Color(0xFFC88B9B),
    ovulationFill: Color(0xFF3A2A31),
    safeFill: Color(0xFF26332A),
    safeStrong: Color(0xFF5F8A6B),
    onAccent: Color(0xFFFFFFFF),
    accent: Color(0xFFD98C97),
  );

  static AppColors of(Brightness brightness, AppAccent accent) {
    final AppColors base = brightness == Brightness.dark ? dark : light;
    return base.copyWith(accent: accent.of(brightness));
  }

  @override
  AppColors copyWith({Color? accent}) => AppColors(
    bg: bg,
    surface: surface,
    surfaceAlt: surfaceAlt,
    text: text,
    textSecondary: textSecondary,
    separator: separator,
    periodRed: periodRed,
    periodRedSoft: periodRedSoft,
    fertilePink: fertilePink,
    ovulationFill: ovulationFill,
    safeFill: safeFill,
    safeStrong: safeStrong,
    onAccent: onAccent,
    accent: accent ?? this.accent,
  );

  @override
  AppColors lerp(covariant AppColors? other, double t) {
    if (other == null) {
      return this;
    }
    return AppColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      text: Color.lerp(text, other.text, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      separator: Color.lerp(separator, other.separator, t)!,
      periodRed: Color.lerp(periodRed, other.periodRed, t)!,
      periodRedSoft: Color.lerp(periodRedSoft, other.periodRedSoft, t)!,
      fertilePink: Color.lerp(fertilePink, other.fertilePink, t)!,
      ovulationFill: Color.lerp(ovulationFill, other.ovulationFill, t)!,
      safeFill: Color.lerp(safeFill, other.safeFill, t)!,
      safeStrong: Color.lerp(safeStrong, other.safeStrong, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }
}

/// 读取当前主题的颜色集合：`context.colors`。
extension AppColorsContext on BuildContext {
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
}
