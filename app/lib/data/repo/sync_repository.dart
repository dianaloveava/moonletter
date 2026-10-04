import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/sync/sync_codec.dart';
import '../db/database.dart';
import '../db/tables.dart';
import '../media/avatar_store.dart';

/// 记录级导入/导出：导出全部记录（含墓碑），导入时按 `(updatedAt, updatedBy)` 合并。
/// 应用远端记录时**不**改 `updated_at`，也**不**写 `pending_changes`（§4.2）。
class SyncRepository {
  SyncRepository(this._db, this._avatars);

  final AppDatabase _db;
  final AvatarStore _avatars;

  /// 本地全部记录；[includeAvatars] 为真时带上被引用的头像文件（base64）。
  Future<List<SyncRecord>> collectRecords({bool includeAvatars = true}) async {
    final List<SyncRecord> records = <SyncRecord>[];
    final List<Member> members = await _db.memberDao.listAllIncludingDeleted();
    final List<Period> periods = await _db.periodDao.listAllIncludingDeleted();
    records.addAll(members.map(SyncRecord.fromMember));
    records.addAll(periods.map(SyncRecord.fromPeriod));

    if (includeAvatars) {
      final Set<String> hashes = <String>{
        for (final Member member in members)
          if (member.deletedAt == null && member.avatarHash != null)
            member.avatarHash!,
      };
      for (final String hash in hashes) {
        final Uint8List? bytes = await _avatars.read(hash);
        if (bytes != null) {
          records.add(
            SyncRecord.fromAvatar(hash: hash, base64Png: base64Encode(bytes)),
          );
        }
      }
    }
    return records;
  }

  /// 只收集指定 `(t, id)` 的记录（同步的待上传队列用）。
  Future<List<SyncRecord>> collectRecordsByIds(
    Iterable<PendingChange> pending,
  ) async {
    final List<SyncRecord> records = <SyncRecord>[];
    for (final PendingChange change in pending) {
      switch (change.t) {
        case RecordType.member:
          final Member? member = await _db.memberDao.byId(change.id);
          if (member != null) {
            records.add(SyncRecord.fromMember(member));
          }
        case RecordType.period:
          final Period? period = await _db.periodDao.byId(change.id);
          if (period != null) {
            records.add(SyncRecord.fromPeriod(period));
          }
        case RecordType.avatar:
          final Uint8List? bytes = await _avatars.read(change.id);
          if (bytes != null) {
            records.add(
              SyncRecord.fromAvatar(
                hash: change.id,
                base64Png: base64Encode(bytes),
              ),
            );
          }
      }
    }
    return records;
  }

  /// 应用（合并后的）远端记录，返回写入条数。
  Future<int> applyRecords(Iterable<SyncRecord> records) async {
    int applied = 0;
    await _db.transaction(() async {
      for (final SyncRecord record in records) {
        switch (record.t) {
          case RecordType.member:
            await _applyMember(record);
          case RecordType.period:
            await _applyPeriod(record);
          case RecordType.avatar:
            await _applyAvatar(record);
          default:
            continue;
        }
        applied++;
      }
    });
    return applied;
  }

  Future<void> _applyMember(SyncRecord record) async {
    final Map<String, Object?>? data = record.data;
    if (record.deleted || data == null) {
      await _db.memberDao.updateFields(
        record.id,
        MembersCompanion(
          deletedAt: Value<int>(record.updatedAt),
          updatedAt: Value<int>(record.updatedAt),
          updatedBy: Value<String>(record.updatedBy),
        ),
      );
      return;
    }
    await _db.memberDao.upsert(
      MembersCompanion.insert(
        id: record.id,
        name: data['name'] as String? ?? '',
        age: Value<int?>(_int(data['age'])),
        heightCm: Value<double?>(_double(data['heightCm'])),
        weightKg: Value<double?>(_double(data['weightKg'])),
        note: Value<String?>(data['note'] as String?),
        avatarHash: Value<String?>(data['avatarHash'] as String?),
        colorIndex: Value<int>(_int(data['colorIndex']) ?? 0),
        defaultCycleDays: Value<int?>(_int(data['defaultCycleDays'])),
        defaultPeriodDays: Value<int?>(_int(data['defaultPeriodDays'])),
        reminderLeadDays: Value<int?>(_int(data['reminderLeadDays'])),
        sortOrder: Value<int>(_int(data['sortOrder']) ?? 0),
        createdAt: _int(data['createdAt']) ?? record.updatedAt,
        updatedAt: record.updatedAt,
        updatedBy: record.updatedBy,
        // 远端记录比本地新，本地可能还是墓碑，这里显式清掉。
        deletedAt: const Value<int?>(null),
      ),
    );
  }

  Future<void> _applyPeriod(SyncRecord record) async {
    final Map<String, Object?>? data = record.data;
    if (record.deleted || data == null) {
      await _db.periodDao.updateFields(
        record.id,
        PeriodsCompanion(
          deletedAt: Value<int>(record.updatedAt),
          updatedAt: Value<int>(record.updatedAt),
          updatedBy: Value<String>(record.updatedBy),
        ),
      );
      return;
    }
    final String memberId = data['memberId'] as String? ?? '';
    final String start = data['start'] as String? ?? '';
    if (memberId.isEmpty || start.isEmpty) {
      return;
    }

    // 两台设备可能各自为同一天建了一条（id 不同），局部唯一索引会挡住。
    // 按同样的「新者胜」规则处理：留下较新的那条，把旧的打墓碑。
    final Period? clash = await _db.periodDao.liveOfDate(memberId, start);
    if (clash != null && clash.id != record.id) {
      if (record.isNewerThan(SyncRecord.fromPeriod(clash))) {
        await _db.periodDao.updateFields(
          clash.id,
          PeriodsCompanion(
            deletedAt: Value<int>(record.updatedAt),
            updatedAt: Value<int>(record.updatedAt),
            updatedBy: Value<String>(record.updatedBy),
          ),
        );
      } else {
        return; // 本地那条更新，忽略远端
      }
    }

    await _db.periodDao.upsert(
      PeriodsCompanion.insert(
        id: record.id,
        memberId: memberId,
        startDate: start,
        endDate: Value<String?>(data['end'] as String?),
        createdAt: _int(data['createdAt']) ?? record.updatedAt,
        updatedAt: record.updatedAt,
        updatedBy: record.updatedBy,
        deletedAt: const Value<int?>(null),
      ),
    );
  }

  Future<void> _applyAvatar(SyncRecord record) async {
    final String? base64Png = record.data?['png'] as String?;
    if (record.deleted || base64Png == null) {
      return;
    }
    final Uint8List bytes = base64Decode(base64Png);
    final String hash = await _avatars.save(bytes);
    if (hash != record.id) {
      // 内容与文件名不符时不落盘（正常情况不会发生）。
      return;
    }
  }

  static int? _int(Object? value) => value is num
      ? value.toInt()
      : (value is String ? int.tryParse(value) : null);

  static double? _double(Object? value) => value is num
      ? value.toDouble()
      : (value is String ? double.tryParse(value) : null);
}
