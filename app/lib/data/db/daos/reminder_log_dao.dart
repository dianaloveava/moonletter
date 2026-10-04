import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'reminder_log_dao.g.dart';

/// Windows 进程内提醒的去重记录（Android 由系统闹钟持有，不写这里）。
@DriftAccessor(tables: <Type>[ReminderLog])
class ReminderLogDao extends DatabaseAccessor<AppDatabase>
    with _$ReminderLogDaoMixin {
  ReminderLogDao(super.db);

  Future<bool> hasNotified(String memberId, String periodStart) async {
    final ReminderLogData? row =
        await (select(reminderLog)..where(
              ($ReminderLogTable t) =>
                  t.memberId.equals(memberId) &
                  t.periodStart.equals(periodStart),
            ))
            .getSingleOrNull();
    return row != null;
  }

  Future<void> markNotified(
    String memberId,
    String periodStart,
    int notifiedAt,
  ) => into(reminderLog).insertOnConflictUpdate(
    ReminderLogCompanion.insert(
      memberId: memberId,
      periodStart: periodStart,
      notifiedAt: notifiedAt,
    ),
  );

  /// 清理过期记录，避免长期累积。
  Future<void> pruneBefore(int millis) =>
      (delete(reminderLog)..where(
            ($ReminderLogTable t) => t.notifiedAt.isSmallerThanValue(millis),
          ))
          .go();
}
