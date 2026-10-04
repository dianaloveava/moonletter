import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'core/app_info.dart';
import 'core/app_paths.dart';
import 'core/platform/windows_app.dart';
import 'core/platform/windows_app_providers.dart';
import 'data/data_providers.dart';
import 'data/db/database.dart';
import 'data/db/tables.dart';
import 'data/repo/member_repository.dart';
import 'data/repo/period_repository.dart';
import 'data/repo/settings_repository.dart';
import 'domain/reminder/reminder_providers.dart';
import 'domain/reminder/reminder_runner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    const WindowOptions options = WindowOptions(
      size: Size(1100, 760),
      minimumSize: Size(420, 640),
      center: true,
      title: AppInfo.displayName,
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  final AppPaths paths = await AppPaths.resolve();
  final AppDatabase database = AppDatabase.open(paths.databaseFile);
  final SettingsRepository settings = SettingsRepository(database);
  await settings.ensureDefaults();

  final ReminderRunner reminders = ReminderRunner(
    members: MemberRepository(database),
    periods: PeriodRepository(database),
    settings: settings,
    database: database,
  );
  await reminders.init();
  unawaited(reminders.rescheduleAll());

  WindowsApp? windowsApp;
  if (Platform.isWindows) {
    late final WindowsApp app;
    app = WindowsApp(
      // 需要在构造时就能互相引用，所以用 late 变量 + 闭包。
      // ignore: unnecessary_lambdas
      onOpenRequested: () => app.showWindow(),
      // 同步引擎在 Step 7 接入；托盘里的「立即同步」先留占位回调。
      onSyncRequested: () {},
      onQuitRequested: () async {
        reminders.dispose();
        await app.dispose();
        exit(0);
      },
    );
    await app.init(
      autostart: await settings.boolean(SettingKeys.autostart, fallback: true),
      closeToTray: await settings.boolean(
        SettingKeys.closeToTray,
        fallback: true,
      ),
    );
    windowsApp = app;
  }

  runApp(
    ProviderScope(
      overrides: [
        appPathsProvider.overrideWithValue(paths),
        databaseProvider.overrideWithValue(database),
        reminderRunnerProvider.overrideWithValue(reminders),
        windowsAppProvider.overrideWithValue(windowsApp),
      ],
      child: const MoonletterApp(),
    ),
  );
}
