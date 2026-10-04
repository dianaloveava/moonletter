import 'package:drift/drift.dart';

import '../../../core/utils/dates.dart';
import '../database.dart';
import '../tables.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: <Type>[Settings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  /// 全量设置，键值都是 TEXT。设置页直接监听这个流。
  Stream<Map<String, String>> watchAll() => select(settings).watch().map(
    (List<Setting> rows) => <String, String>{
      for (final Setting row in rows) row.key: row.value,
    },
  );

  Future<Map<String, String>> all() async {
    final List<Setting> rows = await select(settings).get();
    return <String, String>{for (final Setting row in rows) row.key: row.value};
  }

  Future<String?> value(String key) async {
    final Setting? row = await (select(
      settings,
    )..where(($SettingsTable t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> put(String key, String value) => into(settings)
      .insertOnConflictUpdate(
        SettingsCompanion.insert(
          key: key,
          value: value,
          updatedAt: Timestamps.now(),
        ),
      );

  Future<void> putAll(Map<String, String> values) async {
    final int now = Timestamps.now();
    await batch((Batch batch) {
      batch.insertAllOnConflictUpdate(settings, <SettingsCompanion>[
        for (final MapEntry<String, String> entry in values.entries)
          SettingsCompanion.insert(
            key: entry.key,
            value: entry.value,
            updatedAt: now,
          ),
      ]);
    });
  }

  Future<void> remove(String key) =>
      (delete(settings)..where(($SettingsTable t) => t.key.equals(key))).go();
}
