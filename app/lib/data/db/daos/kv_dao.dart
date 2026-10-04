import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database.dart';
import '../tables.dart';

part 'kv_dao.g.dart';

@DriftAccessor(tables: <Type>[Kv])
class KvDao extends DatabaseAccessor<AppDatabase> with _$KvDaoMixin {
  KvDao(super.db);

  Future<String?> value(String key) async {
    final KvData? row = await (select(
      kv,
    )..where(($KvTable t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> put(String key, String value) =>
      into(kv)
          .insertOnConflictUpdate(KvCompanion.insert(key: key, value: value));

  /// 本机设备 id（uuid v4），首次调用时生成并持久化。合并时作为次级比较键。
  Future<String> deviceId() async {
    final String? existing = await value(KvKeys.deviceId);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final String created = const Uuid().v4();
    await put(KvKeys.deviceId, created);
    return created;
  }
}
