import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/theme_providers.dart';
import '../core/theme/tokens.dart';

/// 底部导航栏、侧边栏与底部弹层使用的毛玻璃容器。
/// `blurEnabledProvider` 关闭时退化为纯色，低端设备可用。
class GlassBar extends ConsumerWidget {
  const GlassBar({
    super.key,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    this.shape,
    this.border,
    this.opacity = 0.72,
  });

  static const double blurSigma = 20;

  final Widget child;
  final BorderRadius borderRadius;

  /// 连续曲率外形（底部弹层用）。非空时优先于 [borderRadius]。
  final ShapeBorder? shape;
  final Border? border;
  final double opacity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors colors = context.colors;
    final bool blur = ref.watch(blurEnabledProvider);
    final Color fill = blur
        ? colors.surface.withValues(alpha: opacity)
        : colors.surface;
    final ShapeBorder? shape = this.shape;

    final Widget content = shape != null
        ? DecoratedBox(
            decoration: ShapeDecoration(color: fill, shape: shape),
            child: child,
          )
        : DecoratedBox(
            decoration: BoxDecoration(
              color: fill,
              border: border,
              borderRadius: borderRadius,
            ),
            child: child,
          );

    return ClipPath(
      clipper: _GlassClipper(shape: shape, borderRadius: borderRadius),
      child: blur
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: content,
            )
          : content,
    );
  }
}

class _GlassClipper extends CustomClipper<Path> {
  const _GlassClipper({required this.shape, required this.borderRadius});

  final ShapeBorder? shape;
  final BorderRadius borderRadius;

  @override
  Path getClip(Size size) => shape?.getOuterPath(Offset.zero & size) ?? Path()
    ..addRRect(borderRadius.toRRect(Offset.zero & size));

  @override
  bool shouldReclip(_GlassClipper oldClipper) =>
      oldClipper.shape != shape || oldClipper.borderRadius != borderRadius;
}
