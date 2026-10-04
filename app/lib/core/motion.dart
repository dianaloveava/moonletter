import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

/// 动效与触感：时长常量、弹簧曲线、Android 触感反馈。
abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 300);

  /// 页面切换与弹层统一使用弹簧曲线。
  static final Curve spring = SpringCurve();
  static final Curve springFast = SpringCurve(stiffness: 700);

  /// 点击、切页
  static void tap() => _run(HapticFeedback.selectionClick);

  /// 删除、确认等稍重的操作
  static void impact() => _run(HapticFeedback.lightImpact);

  static void _run(VoidCallback action) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      action();
    }
  }
}

/// 临界阻尼弹簧曲线：dampingRatio = 1.0、stiffness = 500（默认）。
/// 用 [SpringSimulation] 采样成查找表，供 [Curve] 接口使用。
class SpringCurve extends Curve {
  SpringCurve({this.dampingRatio = 1.0, this.stiffness = 500}) {
    _table = _sample(dampingRatio, stiffness);
  }

  final double dampingRatio;
  final double stiffness;

  late final Float64List _table;

  static final Map<(double, double), Float64List> _cache =
      <(double, double), Float64List>{};

  static Float64List _sample(double dampingRatio, double stiffness) {
    final key = (dampingRatio, stiffness);
    final cached = _cache[key];
    if (cached != null) {
      return cached;
    }

    const double mass = 1;
    final double damping = 2 * dampingRatio * math.sqrt(stiffness * mass);
    final simulation = SpringSimulation(
      SpringDescription(mass: mass, stiffness: stiffness, damping: damping),
      0,
      1,
      0,
    )..tolerance = const Tolerance(distance: 0.0005, velocity: 0.0005);

    final double settle = simulation.x(0) >= 1 ? 1 : _settleTime(simulation);
    const int samples = 128;
    final table = Float64List(samples + 1);
    for (int i = 0; i <= samples; i++) {
      final double x = simulation.x(settle * i / samples);
      table[i] = x.clamp(0.0, 1.0);
    }
    table[samples] = 1;
    _cache[key] = table;
    return table;
  }

  static double _settleTime(SpringSimulation simulation) {
    const double step = 1 / 240;
    double t = 0;
    while (t < 2 && !simulation.isDone(t)) {
      t += step;
    }
    return t;
  }

  @override
  double transformInternal(double t) {
    if (t <= 0) {
      return 0;
    }
    if (t >= 1) {
      return 1;
    }
    final double pos = t * (_table.length - 1);
    final int index = pos.floor();
    final double fraction = pos - index;
    return _table[index] + (_table[index + 1] - _table[index]) * fraction;
  }
}
