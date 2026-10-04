import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/data_providers.dart';
import '../data/db/tables.dart';

/// 从设置表里读原始字符串（数据未就绪时用默认值）。
String _read(Ref ref, String key, String fallback) {
  final AsyncValue<Map<String, String>> settings = ref.watch(settingsProvider);
  return switch (settings) {
    AsyncData<Map<String, String>>(value: final Map<String, String> values) =>
      values[key] ?? fallback,
    _ => fallback,
  };
}

/// 界面语言：跟随系统 / 中文 / English。
class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() => switch (_read(ref, SettingKeys.language, 'system')) {
    'zh' => const Locale('zh'),
    'en' => const Locale('en'),
    _ => null,
  };

  Future<void> set(String value) =>
      ref.read(settingsRepositoryProvider).set(SettingKeys.language, value);

  /// 当前设置里的语言 id（`system` / `zh` / `en`）。
  String get id => _read(ref, SettingKeys.language, 'system');
}

final localeProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);

/// Windows：开机自启（默认开）。
class AutostartController extends Notifier<bool> {
  @override
  bool build() => _read(ref, SettingKeys.autostart, 'true') == 'true';

  Future<void> set(bool value) => ref
      .read(settingsRepositoryProvider)
      .setBool(SettingKeys.autostart, value);
}

final autostartProvider = NotifierProvider<AutostartController, bool>(
  AutostartController.new,
);

/// Windows：关闭窗口时最小化到托盘（默认开）。
class CloseToTrayController extends Notifier<bool> {
  @override
  bool build() => _read(ref, SettingKeys.closeToTray, 'true') == 'true';

  Future<void> set(bool value) => ref
      .read(settingsRepositoryProvider)
      .setBool(SettingKeys.closeToTray, value);
}

final closeToTrayProvider = NotifierProvider<CloseToTrayController, bool>(
  CloseToTrayController.new,
);

/// 启动时自动检查更新。
class AutoCheckUpdateController extends Notifier<bool> {
  @override
  bool build() => _read(ref, SettingKeys.autoCheckUpdate, 'true') == 'true';

  Future<void> set(bool value) => ref
      .read(settingsRepositoryProvider)
      .setBool(SettingKeys.autoCheckUpdate, value);
}

final autoCheckUpdateProvider =
    NotifierProvider<AutoCheckUpdateController, bool>(
      AutoCheckUpdateController.new,
    );
