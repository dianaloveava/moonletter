import '../../core/utils/dates.dart';
import '../../data/db/database.dart';
import '../prediction/cycle_predictor.dart';
import '../prediction/prediction_config.dart';

/// 提醒触发时刻：本地时间上午 9 点（首版固定，可后续做成设置项）。
const int kReminderHour = 9;

/// 启动补发窗口：错过不超过这个时长就立刻补一条通知。
const Duration kCatchUpWindow = Duration(hours: 6);

/// 一条待触发的提醒。
class ReminderPlan {
  const ReminderPlan({
    required this.memberId,
    required this.periodStart,
    required this.fireAt,
    required this.notificationId,
  });

  final String memberId;

  /// 预测的下次经期开始日（`YYYY-MM-DD`）
  final String periodStart;

  /// 本地时间触发的具体时刻
  final DateTime fireAt;

  /// 稳定的通知 id（FNV-1a）
  final int notificationId;
}

/// FNV-1a 32 位散列，跨平台稳定（Dart 的 String.hashCode 不保证跨版本稳定）。
int fnv1a32(String value) {
  int hash = 0x811c9dc5;
  for (final int unit in value.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}

/// 计算每个人的下一次提醒（§5.2）。
/// 提前天数：`member.reminderLeadDays ?? globalLeadDays`；触发时刻 = (下次开始 - 提前天数) 的本地 09:00；
/// 已经过去的时刻不再排期（由 Windows 侧的启动补发逻辑兜底）。
List<ReminderPlan> planReminders({
  required List<Member> members,
  required Map<String, List<Period>> periodsByMember,
  required PredictionConfig config,
  required int globalLeadDays,
  required DateTime now,
  String? today,
}) {
  final String todayIso = today ?? LocalDate.of(now);
  final List<ReminderPlan> plans = <ReminderPlan>[];
  for (final Member member in members) {
    final Prediction? prediction = predict(
      member,
      periodsByMember[member.id] ?? const <Period>[],
      config,
      today: todayIso,
    );
    if (prediction == null) {
      continue;
    }
    final int lead = member.reminderLeadDays ?? globalLeadDays;
    final String target = LocalDate.addDays(prediction.nextStart, -lead);
    final DateTime fireAt = _atReminderHour(target);
    if (!fireAt.isAfter(now)) {
      continue;
    }
    plans.add(
      ReminderPlan(
        memberId: member.id,
        periodStart: prediction.nextStart,
        fireAt: fireAt,
        notificationId: fnv1a32(member.id) & 0x7FFFFFFF,
      ),
    );
  }
  plans.sort((ReminderPlan a, ReminderPlan b) => a.fireAt.compareTo(b.fireAt));
  return plans;
}

/// [date]（`YYYY-MM-DD`）当天的本地 [kReminderHour] 点。
DateTime _atReminderHour(String date) {
  final DateTime day = LocalDate.utcOf(date);
  return DateTime(day.year, day.month, day.day, kReminderHour);
}

/// 启动补发：找出已经错过、但还在 [kCatchUpWindow] 内的提醒。
List<ReminderPlan> missedReminders({
  required List<Member> members,
  required Map<String, List<Period>> periodsByMember,
  required PredictionConfig config,
  required int globalLeadDays,
  required DateTime now,
  String? today,
}) {
  final String todayIso = today ?? LocalDate.of(now);
  final List<ReminderPlan> missed = <ReminderPlan>[];
  for (final Member member in members) {
    final Prediction? prediction = predict(
      member,
      periodsByMember[member.id] ?? const <Period>[],
      config,
      today: todayIso,
    );
    if (prediction == null) {
      continue;
    }
    final int lead = member.reminderLeadDays ?? globalLeadDays;
    final String target = LocalDate.addDays(prediction.nextStart, -lead);
    final DateTime fireAt = _atReminderHour(target);
    final Duration since = now.difference(fireAt);
    if (since.isNegative || since > kCatchUpWindow) {
      continue;
    }
    missed.add(
      ReminderPlan(
        memberId: member.id,
        periodStart: prediction.nextStart,
        fireAt: fireAt,
        notificationId: fnv1a32(member.id) & 0x7FFFFFFF,
      ),
    );
  }
  return missed;
}
