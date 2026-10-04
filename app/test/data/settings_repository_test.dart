import 'package:flutter_test/flutter_test.dart';
import 'package:moonletter/data/db/database.dart';
import 'package:moonletter/data/db/tables.dart';
import 'package:moonletter/data/repo/settings_repository.dart';

void main() {
  late AppDatabase db;
  late SettingsRepository settings;

  setUp(() {
    db = AppDatabase.memory();
    settings = SettingsRepository(db);
  });

  tearDown(() => db.close());

  test('ensureDefaults 补齐全部默认值且可重复调用', () async {
    expect(await settings.all(), isEmpty);

    final int added = await settings.ensureDefaults();
    expect(added, SettingDefaults.values.length);
    expect(await settings.ensureDefaults(), 0);

    expect(
      await settings.integer(SettingKeys.reminderGlobalLeadDays, fallback: 0),
      3,
    );
    expect(
      await settings.integer(SettingKeys.predictionWindow, fallback: 0),
      6,
    );
    expect(
      await settings.integer(SettingKeys.predictionFallbackCycle, fallback: 0),
      28,
    );
    expect(
      await settings.integer(SettingKeys.predictionFallbackPeriod, fallback: 0),
      5,
    );
    expect(
      await settings.integer(
        SettingKeys.predictionOvulationOffset,
        fallback: 0,
      ),
      14,
    );
    expect(
      await settings.integer(SettingKeys.predictionFertileBefore, fallback: 0),
      5,
    );
    expect(
      await settings.integer(SettingKeys.predictionFertileAfter, fallback: 0),
      4,
    );
    expect(
      await settings.string(SettingKeys.themeMode, fallback: ''),
      'system',
    );
    expect(await settings.string(SettingKeys.themeColor, fallback: ''), 'rose');
    expect(await settings.string(SettingKeys.language, fallback: ''), 'system');
    expect(
      await settings.boolean(SettingKeys.blurEnabled, fallback: false),
      isTrue,
    );
    expect(
      await settings.boolean(SettingKeys.notifyHideNames, fallback: true),
      isFalse,
    );
    expect(await settings.string(SettingKeys.lockKind, fallback: ''), 'none');
    expect(
      await settings.boolean(SettingKeys.autostart, fallback: false),
      isTrue,
    );
    expect(
      await settings.boolean(SettingKeys.closeToTray, fallback: false),
      isTrue,
    );
    expect(
      await settings.boolean(SettingKeys.autoCheckUpdate, fallback: false),
      isTrue,
    );
    expect(
      await settings.boolean(SettingKeys.syncEnabled, fallback: true),
      isFalse,
    );
    expect(
      await settings.string(SettingKeys.syncBackend, fallback: ''),
      'webdav',
    );
  });

  test('ensureDefaults 不覆盖用户已改的值', () async {
    await settings.setInt(SettingKeys.reminderGlobalLeadDays, 1);
    await settings.ensureDefaults();
    expect(
      await settings.integer(SettingKeys.reminderGlobalLeadDays, fallback: 0),
      1,
    );
  });

  test('setInt / setBool 后能读回，类型不匹配时回退默认值', () async {
    await settings.setInt(SettingKeys.predictionWindow, 8);
    await settings.setBool(SettingKeys.blurEnabled, false);
    expect(
      await settings.integer(SettingKeys.predictionWindow, fallback: 6),
      8,
    );
    expect(
      await settings.boolean(SettingKeys.blurEnabled, fallback: true),
      isFalse,
    );

    await settings.set(SettingKeys.predictionWindow, '不是数字');
    expect(
      await settings.integer(SettingKeys.predictionWindow, fallback: 6),
      6,
    );
  });

  test('watchAll 反映最新写入', () async {
    await settings.ensureDefaults();
    final Map<String, String> first = await settings.watchAll().first;
    expect(first[SettingKeys.themeMode], 'system');

    await settings.set(SettingKeys.themeColor, 'mint');
    expect(await settings.string(SettingKeys.themeColor, fallback: ''), 'mint');
  });
}
