import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'period_dao.g.dart';

@DriftAccessor(tables: <Type>[Periods])
class PeriodDao extends DatabaseAccessor<AppDatabase> with _$PeriodDaoMixin {
  PeriodDao(super.db);

  List<OrderingTerm Function($PeriodsTable)> get _ordering =>
      <OrderingTerm Function($PeriodsTable)>[
        ($PeriodsTable t) => OrderingTerm(expression: t.startDate),
      ];

  /// 全部未删除记录，按开始日升序。预测与日历都从这里取数。
  Future<List<Period>> listLive() =>
      (select(periods)
            ..where(($PeriodsTable t) => t.deletedAt.isNull())
            ..orderBy(_ordering))
          .get();

  Stream<List<Period>> watchLive() =>
      (select(periods)
            ..where(($PeriodsTable t) => t.deletedAt.isNull())
            ..orderBy(_ordering))
          .watch();

  /// 含墓碑在内的全部经期记录（导出与同步要用）。
  Future<List<Period>> listAllIncludingDeleted() =>
      (select(periods)..orderBy(_ordering)).get();

  Future<List<Period>> listLiveOf(String memberId) =>
      (select(periods)
            ..where(
              ($PeriodsTable t) =>
                  t.deletedAt.isNull() & t.memberId.equals(memberId),
            )
            ..orderBy(_ordering))
          .get();

  Stream<List<Period>> watchLiveOf(String memberId) =>
      (select(periods)
            ..where(
              ($PeriodsTable t) =>
                  t.deletedAt.isNull() & t.memberId.equals(memberId),
            )
            ..orderBy(_ordering))
          .watch();

  /// 该成员在该开始日上的未删除记录（部分唯一索引保证最多一条）。
  Future<Period?> liveOfDate(String memberId, String startDate) =>
      (select(periods)..where(
            ($PeriodsTable t) =>
                t.deletedAt.isNull() &
                t.memberId.equals(memberId) &
                t.startDate.equals(startDate),
          ))
          .getSingleOrNull();

  /// 与 `[from, to]` 有交集（含进行中的记录）的未删除记录，日历按可见月份查询用。
  Stream<List<Period>> watchLiveOverlapping(String from, String to) =>
      (select(periods)
            ..where(
              ($PeriodsTable t) =>
                  t.deletedAt.isNull() &
                  t.startDate.isSmallerOrEqualValue(to) &
                  (t.endDate.isNull() | t.endDate.isBiggerOrEqualValue(from)),
            )
            ..orderBy(_ordering))
          .watch();

  Future<Period?> byId(String id) => (select(
    periods,
  )..where(($PeriodsTable t) => t.id.equals(id))).getSingleOrNull();

  Future<void> upsert(PeriodsCompanion row) =>
      into(periods).insertOnConflictUpdate(row);

  Future<void> updateFields(String id, PeriodsCompanion changes) => (update(
    periods,
  )..where(($PeriodsTable t) => t.id.equals(id))).write(changes);

  Future<void> softDelete(String id, {required int at, required String by}) =>
      (update(periods)..where(($PeriodsTable t) => t.id.equals(id))).write(
        PeriodsCompanion(
          deletedAt: Value<int>(at),
          updatedAt: Value<int>(at),
          updatedBy: Value<String>(by),
        ),
      );

  /// 软删某成员的全部记录（删除档案时调用）。
  Future<List<String>> softDeleteAllOf(
    String memberId, {
    required int at,
    required String by,
  }) async {
    final List<Period> rows = await listLiveOf(memberId);
    for (final Period row in rows) {
      await softDelete(row.id, at: at, by: by);
    }
    return rows.map((Period row) => row.id).toList(growable: false);
  }
}
