import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data_providers.dart';
import '../../data/db/tables.dart';
import 'tokens.dart';

/// 从设置表里读原始字符串（数据未就绪时用默认值）。
String _readSetting(Ref ref, String key, String fallback) {
  final AsyncValue<Map<String, String>> settings = ref.watch(settingsProvider);
  return switch (settings) {
    AsyncData<Map<String, String>>(value: final Map<String, String> values) =>
      values[key] ?? fallback,
    _ => fallback,
  };
}

/// 外观设置：主题模式 / 主题色 / 毛玻璃，全部持久化到 `settings` 表。
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() =>
      switch (_readSetting(ref, SettingKeys.themeMode, 'system')) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  Future<void> set(ThemeMode value) => ref.read(settingsRepositoryProvider).set(
    SettingKeys.themeMode,
    switch (value) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    },
  );
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

class AccentController extends Notifier<AppAccent> {
  @override
  AppAccent build() =>
      AppAccent.fromId(_readSetting(ref, SettingKeys.themeColor, 'rose'));

  Future<void> set(AppAccent value) => ref
      .read(settingsRepositoryProvider)
      .set(SettingKeys.themeColor, value.id);
}

final accentProvider = NotifierProvider<AccentController, AppAccent>(
  AccentController.new,
);

/// 毛玻璃效果开关（低端设备可关闭，退化为纯色）。
class BlurEnabledController extends Notifier<bool> {
  @override
  bool build() => _readSetting(ref, SettingKeys.blurEnabled, 'true') == 'true';

  Future<void> set(bool value) => ref
      .read(settingsRepositoryProvider)
      .setBool(SettingKeys.blurEnabled, value);
}

final blurEnabledProvider = NotifierProvider<BlurEnabledController, bool>(
  BlurEnabledController.new,
);
