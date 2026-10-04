import 'dart:math' as math;

import '../../core/utils/dates.dart';
import '../../data/db/database.dart';
import 'prediction_config.dart';

/// 某一天的状态（§6.3 日历单元格三态 + 干净/未知）。
enum DayKind {
  /// 命中已记录的实际经期。
  period,

  /// 命中按周期推算的经期，或下一次预计经期。
  predictedPeriod,

  /// 排卵日。
  ovulation,

  /// 危险期（排卵前 5 天 + 后 4 天）。
  fertile,

  /// 安全期。
  safe,

  /// 该成员还没有任何记录，或该日在最早记录之前。
  unknown,
}

/// 由历史记录算出的周期与经期长度（§5.1 规则 1）。
class CycleStats {
  const CycleStats({
    required this.cycleDays,
    required this.periodDays,
    required this.cycleFromRecords,
    required this.periodFromRecords,
    required this.recentCycles,
  });

  final int cycleDays;
  final int periodDays;

  /// true = 由历史间隔平均得到；false = 用了档案值或全局回退值。
  final bool cycleFromRecords;
  final bool periodFromRecords;

  /// 参与平均的最近间隔（升序，长度 ≤ `window`）。
  final List<int> recentCycles;
}

/// 一次预测（§5.1 规则 2、3）。
class Prediction {
  const Prediction({
    required this.nextStart,
    required this.ovulation,
    required this.fertileFrom,
    required this.fertileTo,
    required this.stats,
    required this.config,
  });

  /// 下一次预计开始日，保证晚于预测时的今天。
  final String nextStart;

  /// [nextStart] 所属周期的排卵日。
  final String ovulation;

  /// 危险期起（含）。
  final String fertileFrom;

  /// 危险期止（含）。
  final String fertileTo;

  final CycleStats stats;
  final PredictionConfig config;
}

/// 只保留未删除记录，按开始日升序。
List<Period> _liveSorted(List<Period> periods) =>
    periods.where((Period p) => p.deletedAt == null).toList()
      ..sort((Period a, Period b) => a.startDate.compareTo(b.startDate));

/// 取末尾 [window] 项；[window] ≤ 0 时视为没有历史。
List<int> _tail(List<int> values, int window) {
  if (window <= 0 || values.isEmpty) {
    return const <int>[];
  }
  return values.length <= window
      ? values
      : values.sublist(values.length - window);
}

int _average(List<int> values) =>
    (values.reduce((int a, int b) => a + b) / values.length).round();

/// 相邻开始日间隔（升序）。
List<int> _recentCycles(List<Period> live, int window) {
  final List<int> gaps = <int>[];
  for (int i = 1; i < live.length; i++) {
    gaps.add(LocalDate.diffDays(live[i - 1].startDate, live[i].startDate));
  }
  return _tail(gaps, window);
}

/// 已结束记录的经期长度（升序）。
List<int> _recentDurations(List<Period> live, int window) {
  final List<int> durations = <int>[
    for (final Period p in live)
      if (p.endDate != null) LocalDate.diffDays(p.startDate, p.endDate!) + 1,
  ];
  return _tail(durations, window);
}

/// §5.1 规则 1：周期天数取最近 `window` 个间隔的平均值四舍五入，
/// 不足 1 个间隔时用档案值、再退回全局回退值；经期天数同理。
CycleStats computeStats(
  List<Period> periods,
  Member member,
  PredictionConfig cfg,
) {
  final List<Period> live = _liveSorted(periods);
  final List<int> cycles = _recentCycles(live, cfg.window);
  final List<int> durations = _recentDurations(live, cfg.window);
  return CycleStats(
    cycleDays: cycles.isEmpty
        ? (member.defaultCycleDays ?? cfg.fallbackCycle)
        : _average(cycles),
    periodDays: durations.isEmpty
        ? (member.defaultPeriodDays ?? cfg.fallbackPeriod)
        : _average(durations),
    cycleFromRecords: cycles.isNotEmpty,
    periodFromRecords: durations.isNotEmpty,
    recentCycles: cycles,
  );
}

/// §5.1 规则 2、3：没有任何记录时返回 null。
/// [today] 仅用于测试注入，省略时取本地今天。
Prediction? predict(
  Member member,
  List<Period> periods,
  PredictionConfig cfg, {
  String? today,
}) {
  final List<Period> live = _liveSorted(periods);
  if (live.isEmpty) {
    return null;
  }
  final CycleStats stats = computeStats(live, member, cfg);
  final String now = today ?? LocalDate.today();
  final int cycleDays = math.max(1, stats.cycleDays);
  String nextStart = LocalDate.addDays(live.last.startDate, cycleDays);
  while (!LocalDate.isAfter(nextStart, now)) {
    nextStart = LocalDate.addDays(nextStart, cycleDays);
  }
  final String ovulation = LocalDate.addDays(nextStart, -cfg.ovulationOffset);
  return Prediction(
    nextStart: nextStart,
    ovulation: ovulation,
    fertileFrom: LocalDate.addDays(ovulation, -cfg.fertileBefore),
    fertileTo: LocalDate.addDays(ovulation, cfg.fertileAfter),
    stats: stats,
    config: cfg,
  );
}

/// ≤ [date] 的最近一个预测开始日（按周期向过去/未来无限延伸）。
String _cycleStartAtOrBefore(String date, String nextStart, int cycleDays) {
  final int offset = LocalDate.diffDays(nextStart, date);
  final int cycles = offset >= 0
      ? offset ~/ cycleDays
      : -((-offset + cycleDays - 1) ~/ cycleDays);
  String start = LocalDate.addDays(nextStart, cycles * cycleDays);
  // 取整边界最多差一个周期，修正一下。
  while (LocalDate.isAfter(start, date)) {
    start = LocalDate.addDays(start, -cycleDays);
  }
  while (!LocalDate.isAfter(LocalDate.addDays(start, cycleDays), date)) {
    start = LocalDate.addDays(start, cycleDays);
  }
  return start;
}

/// 该日在「实际或预测经期」中的第几天（1 起）；不在经期窗口内返回 null。
/// 日历页日期面板用它显示「经期第 N 天 / 预计经期第 N 天」。
int? periodDayIndex(
  String date,
  List<Period> periods,
  Prediction? prediction, {
  String? today,
}) {
  final List<Period> live = _liveSorted(periods);
  final String now = today ?? LocalDate.today();
  for (final Period period in live) {
    if (LocalDate.isBefore(date, period.startDate)) {
      break;
    }
    final String end = period.endDate ?? now;
    if (!LocalDate.isAfter(date, end)) {
      return LocalDate.diffDays(period.startDate, date) + 1;
    }
  }
  final Prediction? p = prediction;
  if (p == null ||
      live.isEmpty ||
      LocalDate.isBefore(date, live.first.startDate)) {
    return null;
  }
  final int cycleDays = math.max(1, p.stats.cycleDays);
  final int periodDays = math.max(1, p.stats.periodDays);
  final String cycleStart = _cycleStartAtOrBefore(date, p.nextStart, cycleDays);
  final int index = LocalDate.diffDays(cycleStart, date);
  return index < periodDays ? index + 1 : null;
}

/// §5.1 规则 4：把任意一天分类。未来任意一天都能分类（按周期无限前推）。
DayKind dayKind(
  String date,
  List<Period> periods,
  Prediction? prediction, {
  String? today,
}) {
  final List<Period> live = _liveSorted(periods);
  final String now = today ?? LocalDate.today();
  for (final Period p in live) {
    if (LocalDate.isBefore(date, p.startDate)) {
      break; // 记录按开始日升序，后面的记录更不可能命中
    }
    final String end = p.endDate ?? now;
    if (!LocalDate.isAfter(date, end)) {
      return DayKind.period;
    }
  }
  if (prediction == null || live.isEmpty) {
    return DayKind.unknown;
  }
  if (LocalDate.isBefore(date, live.first.startDate)) {
    return DayKind.unknown;
  }
  final CycleStats stats = prediction.stats;
  final int cycleDays = math.max(1, stats.cycleDays);
  final String cycleStart = _cycleStartAtOrBefore(
    date,
    prediction.nextStart,
    cycleDays,
  );
  if (LocalDate.diffDays(cycleStart, date) < math.max(1, stats.periodDays)) {
    return DayKind.predictedPeriod;
  }
  // 该日所属周期的排卵日 = 本周期结束日（= 下一个预计开始日）往前推。
  final String boundary = LocalDate.addDays(cycleStart, cycleDays);
  final String ovulation = LocalDate.addDays(
    boundary,
    -prediction.config.ovulationOffset,
  );
  if (date == ovulation) {
    return DayKind.ovulation;
  }
  final String fertileFrom = LocalDate.addDays(
    ovulation,
    -prediction.config.fertileBefore,
  );
  final String fertileTo = LocalDate.addDays(
    ovulation,
    prediction.config.fertileAfter,
  );
  if (!LocalDate.isBefore(date, fertileFrom) &&
      !LocalDate.isAfter(date, fertileTo)) {
    return DayKind.fertile;
  }
  return DayKind.safe;
}
