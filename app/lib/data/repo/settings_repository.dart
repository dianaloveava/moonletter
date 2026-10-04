import '../db/database.dart';
import '../db/tables.dart';

/// `settings` 表读写。值一律 TEXT，由调用方转类型；设备本地，不参与同步。
class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  Stream<Map<String, String>> watchAll() => _db.settingsDao.watchAll();

  Future<Map<String, String>> all() => _db.settingsDao.all();

  /// 补齐缺失的默认值键，返回补写的键数量。启动时调用一次。
  Future<int> ensureDefaults() async {
    final Map<String, String> current = await _db.settingsDao.all();
    final Map<String, String> missing = <String, String>{
      for (final MapEntry<String, String> entry
          in SettingDefaults.values.entries)
        if (!current.containsKey(entry.key)) entry.key: entry.value,
    };
    if (missing.isEmpty) {
      return 0;
    }
    await _db.settingsDao.putAll(missing);
    return missing.length;
  }

  Future<String> string(String key, {required String fallback}) async =>
      await _db.settingsDao.value(key) ?? fallback;

  Future<int> integer(String key, {required int fallback}) async {
    final String raw = await string(key, fallback: '$fallback');
    return int.tryParse(raw) ?? fallback;
  }

  Future<bool> boolean(String key, {required bool fallback}) async {
    final String raw = await string(key, fallback: fallback ? 'true' : 'false');
    return raw == 'true';
  }

  Future<void> set(String key, String value) => _db.settingsDao.put(key, value);

  Future<void> setBool(String key, bool value) =>
      _db.settingsDao.put(key, value ? 'true' : 'false');

  Future<void> setInt(String key, int value) =>
      _db.settingsDao.put(key, '$value');
}
