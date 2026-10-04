import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/dates.dart';
import '../db/database.dart';
import '../db/tables.dart';

/// 经期记录读写。`periods` 是开始日的唯一来源，档案表单的「最近一次开始日期」也写到这里。
class PeriodRepository {
  PeriodRepository(this._db);

  final AppDatabase _db;

  Stream<List<Period>> watchAllLive() => _db.periodDao.watchLive();

  Future<List<Period>> listAllLive() => _db.periodDao.listLive();

  Stream<List<Period>> watchLiveOf(String memberId) =>
      _db.periodDao.watchLiveOf(memberId);

  /// 全部未删除记录按成员分组，供日历与预测使用（跟随数据库变化）。
  Stream<Map<String, List<Period>>> watchGrouped() =>
      _db.periodDao.watchLive().map(_group);

  /// 与某个月份有交集的未删除记录（日历页按可见月份订阅）。
  Stream<List<Period>> watchOverlapping(String from, String to) =>
      _db.periodDao.watchLiveOverlapping(from, to);

  Future<List<Period>> listLiveOf(String memberId) =>
      _db.periodDao.listLiveOf(memberId);

  /// 全部未删除记录按成员分组，按开始日升序。日历与预测都从这里取数。
  Future<Map<String, List<Period>>> groupByMember() async =>
      _group(await _db.periodDao.listLive());

  static Map<String, List<Period>> _group(List<Period> rows) {
    final Map<String, List<Period>> grouped = <String, List<Period>>{};
    for (final Period row in rows) {
      grouped.putIfAbsent(row.memberId, () => <Period>[]).add(row);
    }
    return grouped;
  }

  /// 该成员最近一条未删除记录；没有则 null。
  Future<Period?> latestOf(String memberId) async {
    final List<Period> rows = await _db.periodDao.listLiveOf(memberId);
    return rows.isEmpty ? null : rows.last;
  }

  Future<String> add(
    String memberId,
    String startDate, {
    String? endDate,
  }) async {
    final String deviceId = await _db.kvDao.deviceId();
    final int now = Timestamps.now();
    final String id = const Uuid().v4();
    await _db.transaction(() async {
      await _db.periodDao.upsert(
        PeriodsCompanion.insert(
          id: id,
          memberId: memberId,
          startDate: startDate,
          endDate: Value<String?>(endDate),
          createdAt: now,
          updatedAt: now,
          updatedBy: deviceId,
        ),
      );
      await _db.pendingChangesDao.mark(RecordType.period, id);
    });
    return id;
  }

  /// 档案表单的「最近一次开始日期」：同日期已有记录则原样保留；最近一条还没结束则改它的开始日；
  /// 否则插入一条 `end_date = null` 的新记录。这样不会留下两条「进行中」。
  Future<String> setLastStartDate(String memberId, String startDate) async {
    final Period? same = await _db.periodDao.liveOfDate(memberId, startDate);
    if (same != null) {
      return same.id;
    }
    final Period? latest = await latestOf(memberId);
    if (latest != null && latest.endDate == null) {
      await setStart(latest.id, startDate);
      return latest.id;
    }
    return add(memberId, startDate);
  }

  /// 改开始日；同一成员在该日已有另一条未删除记录时抛 [StateError]。
  Future<void> setStart(String id, String startDate) async {
    final Period? row = await _db.periodDao.byId(id);
    if (row == null) {
      throw StateError('经期记录不存在：$id');
    }
    final Period? clash = await _db.periodDao.liveOfDate(
      row.memberId,
      startDate,
    );
    if (clash != null && clash.id != id) {
      throw StateError('该成员在 $startDate 已有一条经期记录');
    }
    await _write(
      id,
      (int now, String by) => PeriodsCompanion(
        startDate: Value<String>(startDate),
        updatedAt: Value<int>(now),
        updatedBy: Value<String>(by),
      ),
    );
  }

  /// 结束日可为 null（表示进行中）。
  Future<void> setEnd(String id, String? endDate) => _write(
    id,
    (int now, String by) => PeriodsCompanion(
      endDate: Value<String?>(endDate),
      updatedAt: Value<int>(now),
      updatedBy: Value<String>(by),
    ),
  );

  /// 软删除一条记录（墓碑保留，避免同步时复活）。
  Future<void> delete(String id) async {
    final String deviceId = await _db.kvDao.deviceId();
    final int now = Timestamps.now();
    await _db.transaction(() async {
      await _db.periodDao.softDelete(id, at: now, by: deviceId);
      await _db.pendingChangesDao.mark(RecordType.period, id);
    });
  }

  Future<void> _write(
    String id,
    PeriodsCompanion Function(int now, String deviceId) build,
  ) async {
    final String deviceId = await _db.kvDao.deviceId();
    final int now = Timestamps.now();
    await _db.transaction(() async {
      await _db.periodDao.updateFields(id, build(now, deviceId));
      await _db.pendingChangesDao.mark(RecordType.period, id);
    });
  }
}
