import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';

/// 连续曲率圆角（squircle）路径。
///
/// 算法移植自 `figma_squircle` 0.6.3（MIT License，Copyright (c) 2021 Aloïs Deniel），
/// 公式来自 Figma 的 https://www.figma.com/blog/desperately-seeking-squircles/
/// 与本仓无依赖关系，只保留所需的最小实现。
Path squirclePath(
  Rect rect, {
  double radius = AppRadii.control,
  double smoothing = AppRadii.smoothing,
}) {
  final double w = rect.width;
  final double h = rect.height;
  if (w <= 0 || h <= 0) {
    return Path();
  }

  final double maxRadius = math.min(w, h) / 2;
  final double cornerRadius = math.min(radius, maxRadius);
  if (cornerRadius <= 0) {
    return Path()..addRect(rect);
  }

  // 12.2 in the article: corner extends `p` from the edge.
  final double p = math.min((1 + smoothing) * cornerRadius, maxRadius);

  final double angleAlpha;
  final double angleBeta;
  if (cornerRadius <= maxRadius / 2) {
    angleBeta = 90 * (1 - smoothing);
    angleAlpha = 45 * smoothing;
  } else {
    final double diffRatio = (cornerRadius - maxRadius / 2) / (maxRadius / 2);
    angleBeta = 90 * (1 - smoothing * (1 - diffRatio));
    angleAlpha = 45 * smoothing * (1 - diffRatio);
  }
  final double angleTheta = (90 - angleBeta) / 2;

  final double p3ToP4Distance =
      cornerRadius * math.tan(_radians(angleTheta / 2));
  final double circularSectionLength =
      math.sin(_radians(angleBeta / 2)) * cornerRadius * math.sqrt2;

  final double c = p3ToP4Distance * math.cos(_radians(angleAlpha));
  final double d = c * math.tan(_radians(angleAlpha));
  final double b = (p - circularSectionLength - c - d) / 3;
  final double a = 2 * b;

  final Radius arcRadius = Radius.circular(cornerRadius);
  final Path path = Path()
    // 上边 → 右上角
    ..moveTo(math.max(w / 2, w - p), 0)
    ..cubicTo(w - (p - a), 0, w - (p - a - b), 0, w - (p - a - b - c), d)
    ..relativeArcToPoint(
      Offset(circularSectionLength, circularSectionLength),
      radius: arcRadius,
    )
    ..cubicTo(w, p - a - b, w, p - a, w, math.min(h / 2, p))
    // 右边 → 右下角
    ..lineTo(w, math.max(h / 2, h - p))
    ..cubicTo(w, h - (p - a), w, h - (p - a - b), w - d, h - (p - a - b - c))
    ..relativeArcToPoint(
      Offset(-circularSectionLength, circularSectionLength),
      radius: arcRadius,
    )
    ..cubicTo(w - (p - a - b), h, w - (p - a), h, math.max(w / 2, w - p), h)
    // 下边 → 左下角
    ..lineTo(math.min(w / 2, p), h)
    ..cubicTo(p - a, h, p - a - b, h, p - a - b - c, h - d)
    ..relativeArcToPoint(
      Offset(-circularSectionLength, -circularSectionLength),
      radius: arcRadius,
    )
    ..cubicTo(0, h - (p - a - b), 0, h - (p - a), 0, math.max(h / 2, h - p))
    // 左边 → 左上角
    ..lineTo(0, math.min(h / 2, p))
    ..cubicTo(0, p - a, 0, p - a - b, d, p - a - b - c)
    ..relativeArcToPoint(
      Offset(circularSectionLength, -circularSectionLength),
      radius: arcRadius,
    )
    ..cubicTo(p - a - b, 0, p - a, 0, math.min(w / 2, p), 0)
    ..close();

  return path.shift(rect.topLeft);
}

double _radians(double degrees) => degrees * math.pi / 180;

/// 连续曲率圆角形状，可当 [OutlinedBorder] 用在按钮、弹层与卡片上：
/// `ShapeDecoration(color: c, shape: SquircleBorder())`。
@immutable
class SquircleBorder extends OutlinedBorder {
  const SquircleBorder({
    this.radius = AppRadii.control,
    this.smoothing = AppRadii.smoothing,
    super.side = BorderSide.none,
  });

  /// 卡片、分组列表用 [AppRadii.card]，按钮与输入框用 [AppRadii.control]。
  final double radius;
  final double smoothing;

  @override
  OutlinedBorder copyWith({BorderSide? side}) => SquircleBorder(
    radius: radius,
    smoothing: smoothing,
    side: side ?? this.side,
  );

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  ShapeBorder scale(double t) => SquircleBorder(
    radius: radius * t,
    smoothing: smoothing,
    side: side.scale(t),
  );

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => squirclePath(
    rect.deflate(side.width),
    radius: math.max(0, radius - side.width),
    smoothing: smoothing,
  );

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      squirclePath(rect, radius: radius, smoothing: smoothing);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width == 0) {
      return;
    }
    // 线宽画在路径正中，向左内缩半个线宽，保持「描边在轮廓内侧」的观感。
    canvas.drawPath(
      squirclePath(
        rect.deflate(side.width / 2),
        radius: math.max(0, radius - side.width / 2),
        smoothing: smoothing,
      ),
      side.toPaint(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SquircleBorder &&
      other.radius == radius &&
      other.smoothing == smoothing &&
      other.side == side;

  @override
  int get hashCode => Object.hash(radius, smoothing, side);
}

/// 只有上侧两个角是连续曲率的形状，用于底部弹层（下角延伸到屏幕外，不绘制圆角）。
@immutable
class TopSquircleBorder extends ShapeBorder {
  const TopSquircleBorder({
    this.radius = AppRadii.card,
    this.smoothing = AppRadii.smoothing,
  });

  final double radius;
  final double smoothing;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  ShapeBorder scale(double t) =>
      TopSquircleBorder(radius: radius * t, smoothing: smoothing);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => squirclePath(
    Rect.fromLTRB(rect.left, rect.top, rect.right, rect.bottom + radius * 2),
    radius: radius,
    smoothing: smoothing,
  );

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  bool operator ==(Object other) =>
      other is TopSquircleBorder &&
      other.radius == radius &&
      other.smoothing == smoothing;

  @override
  int get hashCode => Object.hash(radius, smoothing);
}

/// 输入框的连续曲率边框（[InputDecoration] 只接受 [InputBorder]）。
@immutable
class SquircleInputBorder extends InputBorder {
  const SquircleInputBorder({
    super.borderSide = BorderSide.none,
    this.radius = AppRadii.control,
    this.smoothing = AppRadii.smoothing,
  });

  final double radius;
  final double smoothing;

  @override
  InputBorder copyWith({BorderSide? borderSide}) => SquircleInputBorder(
    borderSide: borderSide ?? this.borderSide,
    radius: radius,
    smoothing: smoothing,
  );

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(borderSide.width);

  @override
  bool get isOutline => false;

  @override
  ShapeBorder scale(double t) => SquircleInputBorder(
    borderSide: borderSide.scale(t),
    radius: radius * t,
    smoothing: smoothing,
  );

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => squirclePath(
    rect.deflate(borderSide.width),
    radius: math.max(0, radius - borderSide.width),
    smoothing: smoothing,
  );

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      squirclePath(rect, radius: radius, smoothing: smoothing);

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0,
    double gapPercentage = 0,
    TextDirection? textDirection,
  }) {
    if (borderSide.style == BorderStyle.none || borderSide.width == 0) {
      return;
    }
    canvas.drawPath(
      squirclePath(
        rect.deflate(borderSide.width / 2),
        radius: math.max(0, radius - borderSide.width / 2),
        smoothing: smoothing,
      ),
      borderSide.toPaint(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SquircleInputBorder &&
      other.radius == radius &&
      other.smoothing == smoothing &&
      other.borderSide == borderSide;

  @override
  int get hashCode => Object.hash(radius, smoothing, borderSide);
}

/// 把子树裁剪成连续曲率圆角。
class SquircleClipper extends CustomClipper<Path> {
  const SquircleClipper({
    this.radius = AppRadii.control,
    this.smoothing = AppRadii.smoothing,
  });

  final double radius;
  final double smoothing;

  @override
  Path getClip(Size size) =>
      squirclePath(Offset.zero & size, radius: radius, smoothing: smoothing);

  @override
  bool shouldReclip(SquircleClipper oldClipper) =>
      oldClipper.radius != radius || oldClipper.smoothing != smoothing;
}
