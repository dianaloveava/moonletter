import 'dart:math' as math;

import '../../core/utils/dates.dart';
import '../../data/db/database.dart';
import 'cycle_predictor.dart';
import 'prediction_config.dart';

/// 档案列表状态行的类型。
enum MemberStatusKind {
  /// 一条记录都没有。
  noRecords,

  /// 正在经期中。
  period,

  /// 距下次预计开始还有几天。
  upcoming,

  /// 已过预计开始日但还没有新记录。
  late,
}

/// 档案列表的状态文案数据（§9 Step 2）。
class MemberStatus {
  const MemberStatus({required this.kind, required this.days});

  final MemberStatusKind kind;

  /// [MemberStatusKind.period] = 经期第几天；
  /// [MemberStatusKind.upcoming] = 距下次开始的天数（0 = 预计今天开始）；
  /// [MemberStatusKind.late] = 已推迟的天数。
  final int days;
}

/// 状态行规则：正在经期中 > 已推迟 > 距下次。没有任何记录时返回 [MemberStatusKind.noRecords]。
MemberStatus memberStatus(
  Member member,
  List<Period> periods,
  PredictionConfig cfg, {
  String? today,
}) {
  final String now = today ?? LocalDate.today();
  final List<Period> live =
      periods.where((Period p) => p.deletedAt == null).toList()
        ..sort((Period a, Period b) => a.startDate.compareTo(b.startDate));
  if (live.isEmpty) {
    return const MemberStatus(kind: MemberStatusKind.noRecords, days: 0);
  }
  final Period last = live.last;
  final String end = last.endDate ?? now;
  final int dayOfPeriod = LocalDate.diffDays(last.startDate, now) + 1;
  if (!LocalDate.isBefore(now, last.startDate) &&
      !LocalDate.isAfter(now, end)) {
    return MemberStatus(kind: MemberStatusKind.period, days: dayOfPeriod);
  }
  final int cycleDays = math.max(1, computeStats(live, member, cfg).cycleDays);
  final String expected = LocalDate.addDays(last.startDate, cycleDays);
  final int diff = LocalDate.diffDays(expected, now);
  if (diff > 0) {
    return MemberStatus(kind: MemberStatusKind.late, days: diff);
  }
  return MemberStatus(kind: MemberStatusKind.upcoming, days: -diff);
}
