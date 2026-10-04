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
