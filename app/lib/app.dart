import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_info.dart';
import 'core/app_settings_providers.dart';
import 'core/l10n/gen/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_providers.dart';
import 'core/theme/tokens.dart';
import 'data/data_providers.dart';
import 'domain/prediction/prediction_providers.dart';
import 'domain/reminder/reminder_providers.dart';
import 'features/lock/lock_gate.dart';

class MoonletterApp extends ConsumerStatefulWidget {
  const MoonletterApp({super.key});

  @override
  ConsumerState<MoonletterApp> createState() => _MoonletterAppState();
}

class _MoonletterAppState extends ConsumerState<MoonletterApp> {
  Timer? _rescheduleDebounce;

  /// 成员、经期记录或设置变化后重算提醒（防抖 2 秒）。
  void _scheduleReschedule() {
    _rescheduleDebounce?.cancel();
    _rescheduleDebounce = Timer(const Duration(seconds: 2), () {
      unawaited(ref.read(reminderRunnerProvider).rescheduleAll());
    });
  }

  @override
  void dispose() {
    _rescheduleDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeMode mode = ref.watch(themeModeProvider);
    final AppAccent accent = ref.watch(accentProvider);
    final Locale? locale = ref.watch(localeProvider);

    ref
      ..listen(membersProvider, (_, _) => _scheduleReschedule())
      ..listen(periodsByMemberProvider, (_, _) => _scheduleReschedule())
      ..listen(settingsProvider, (_, _) => _scheduleReschedule());

    return MaterialApp.router(
      title: AppInfo.displayName,
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
      theme: AppTheme.build(brightness: Brightness.light, accent: accent),
      darkTheme: AppTheme.build(brightness: Brightness.dark, accent: accent),
      themeMode: mode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (BuildContext context, Widget? child) =>
          LockGate(child: child ?? const SizedBox.shrink()),
    );
  }
}
