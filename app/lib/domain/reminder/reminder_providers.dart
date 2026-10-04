import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data_providers.dart';
import 'reminder_runner.dart';

/// 提醒调度器。启动时在 `main.dart` 里 `overrideWithValue` 注入同一个实例。
final Provider<ReminderRunner> reminderRunnerProvider =
    Provider<ReminderRunner>(
      (Ref ref) => ReminderRunner(
        members: ref.watch(memberRepositoryProvider),
        periods: ref.watch(periodRepositoryProvider),
        settings: ref.watch(settingsRepositoryProvider),
        database: ref.watch(databaseProvider),
      ),
    );
