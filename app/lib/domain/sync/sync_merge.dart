import 'sync_codec.dart';

/// 按记录合并：以 `(t, id)` 为键，`(updatedAt, updatedBy)` 大者胜（§8.2）。
/// 合并是幂等的，与处理顺序无关；`deleted` 记录同样参与比较，所以删除不会被旧数据复活。
List<SyncRecord> mergeRecords(
  Iterable<SyncRecord> local,
  Iterable<SyncRecord> remote,
) {
  final Map<String, SyncRecord> merged = <String, SyncRecord>{};
  for (final SyncRecord record in local) {
    merged[_key(record)] = record;
  }
  for (final SyncRecord record in remote) {
    final SyncRecord? existing = merged[_key(record)];
    if (existing == null || record.isNewerThan(existing)) {
      merged[_key(record)] = record;
    }
  }
  return merged.values.toList(growable: false);
}

/// 需要写回本地的记录：远端比本地新，或本地没有。
List<SyncRecord> diffToApply(
  Iterable<SyncRecord> local,
  Iterable<SyncRecord> remote,
) {
  final Map<String, SyncRecord> localByKey = <String, SyncRecord>{
    for (final SyncRecord record in local) _key(record): record,
  };
  final List<SyncRecord> pending = <SyncRecord>[];
  for (final SyncRecord record in remote) {
    final SyncRecord? existing = localByKey[_key(record)];
    if (existing == null || record.isNewerThan(existing)) {
      pending.add(record);
    }
  }
  return pending;
}

String _key(SyncRecord record) => '${record.t}:${record.id}';

/// 备份导入要写回本地的记录。
///
/// 与同步不同（§8.2：墓碑参与比较，删除不会被旧数据复活），手动导入是用户主动的"恢复"动作：
/// 文件里的**存活**记录如果在本地是墓碑，就以 [now] 与 [deviceId] 重写，
/// 让墓碑失效，并且下次同步会把这个恢复上传出去。
/// 其余记录仍按时间戳取新，避免用旧备份覆盖更新的本地内容。
List<SyncRecord> recordsToRestore(
  Iterable<SyncRecord> local,
  Iterable<SyncRecord> incoming, {
  required String deviceId,
  required DateTime now,
}) {
  final Map<String, SyncRecord> localByKey = <String, SyncRecord>{
    for (final SyncRecord record in local) _key(record): record,
  };
  final List<SyncRecord> restored = <SyncRecord>[];
  for (final SyncRecord record in incoming) {
    final SyncRecord? existing = localByKey[_key(record)];
    if (existing == null || record.isNewerThan(existing)) {
      restored.add(record);
    } else if (existing.deleted && !record.deleted) {
      restored.add(
        SyncRecord(
          t: record.t,
          id: record.id,
          updatedAt: now.millisecondsSinceEpoch,
          updatedBy: deviceId,
          data: record.data,
        ),
      );
    }
  }
  return restored;
}
