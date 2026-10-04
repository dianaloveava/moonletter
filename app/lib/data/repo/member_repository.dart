import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/dates.dart';
import '../db/daos/member_dao.dart';
import '../db/database.dart';
import '../db/tables.dart';

/// 档案表单的输入值。
class MemberInput {
  const MemberInput({
    required this.name,
    this.age,
    this.heightCm,
    this.weightKg,
    this.note,
    this.avatarHash,
    this.colorIndex = 0,
    this.defaultCycleDays,
    this.defaultPeriodDays,
    this.reminderLeadDays,
  });

  final String name;
  final int? age;
  final double? heightCm;
  final double? weightKg;
  final String? note;
  final String? avatarHash;
  final int colorIndex;
  final int? defaultCycleDays;
  final int? defaultPeriodDays;
  final int? reminderLeadDays;
}

/// 成员档案读写。每次写入都会盖 `updated_at` / `updated_by` 并入队 `pending_changes`。
class MemberRepository {
  MemberRepository(this._db);

  final AppDatabase _db;

  Stream<List<Member>> watchAll() => _db.memberDao.watchAll();

  Future<List<Member>> listAll() => _db.memberDao.listAll();

  Future<Member?> byId(String id) => _db.memberDao.byId(id);

  /// 单个成员（含墓碑），档案详情页跟随变化。
  Stream<Member?> watchById(String id) => _db.memberDao.watchById(id);

  Future<String> create(MemberInput input) async {
    final String deviceId = await _db.kvDao.deviceId();
    final int now = Timestamps.now();
    final String id = const Uuid().v4();
    final int sortOrder = await _db.memberDao.nextSortOrder();
    await _db.transaction(() async {
      await _db.memberDao.upsert(
        MemberDao.buildCompanion(
          id: id,
          name: input.name,
          age: input.age,
          heightCm: input.heightCm,
          weightKg: input.weightKg,
          note: input.note,
          avatarHash: input.avatarHash,
          colorIndex: input.colorIndex,
          defaultCycleDays: input.defaultCycleDays,
          defaultPeriodDays: input.defaultPeriodDays,
          reminderLeadDays: input.reminderLeadDays,
          sortOrder: sortOrder,
          createdAt: now,
          updatedAt: now,
          updatedBy: deviceId,
        ),
      );
      await _db.pendingChangesDao.mark(RecordType.member, id);
    });
    return id;
  }

  Future<void> update(String id, MemberInput input) async {
    final String deviceId = await _db.kvDao.deviceId();
    final int now = Timestamps.now();
    await _db.transaction(() async {
      await _db.memberDao.updateFields(
        id,
        MembersCompanion(
          name: Value<String>(input.name),
          age: Value<int?>(input.age),
          heightCm: Value<double?>(input.heightCm),
          weightKg: Value<double?>(input.weightKg),
          note: Value<String?>(input.note),
          avatarHash: Value<String?>(input.avatarHash),
          colorIndex: Value<int>(input.colorIndex),
          defaultCycleDays: Value<int?>(input.defaultCycleDays),
          defaultPeriodDays: Value<int?>(input.defaultPeriodDays),
          reminderLeadDays: Value<int?>(input.reminderLeadDays),
          updatedAt: Value<int>(now),
          updatedBy: Value<String>(deviceId),
        ),
      );
      await _db.pendingChangesDao.mark(RecordType.member, id);
    });
  }

  /// 只改头像 hash（头像编辑走这里，避免整表覆写）。
  Future<void> setAvatarHash(String id, String? hash) async {
    final String deviceId = await _db.kvDao.deviceId();
    final int now = Timestamps.now();
    await _db.transaction(() async {
      await _db.memberDao.updateFields(
        id,
        MembersCompanion(
          avatarHash: Value<String?>(hash),
          updatedAt: Value<int>(now),
          updatedBy: Value<String>(deviceId),
        ),
      );
      await _db.pendingChangesDao.mark(RecordType.member, id);
    });
  }

  /// 软删除档案：连它的经期记录一起打墓碑，并各自入队待上传。
  Future<void> delete(String id) async {
    final String deviceId = await _db.kvDao.deviceId();
    final int now = Timestamps.now();
    await _db.transaction(() async {
      final List<String> periodIds = await _db.periodDao.softDeleteAllOf(
        id,
        at: now,
        by: deviceId,
      );
      await _db.memberDao.softDelete(id, at: now, by: deviceId);
      await _db.pendingChangesDao.mark(RecordType.member, id);
      await _db.pendingChangesDao.markAll(RecordType.period, periodIds);
    });
  }
}
