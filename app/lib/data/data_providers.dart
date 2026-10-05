import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_paths.dart';
import 'db/database.dart';
import 'media/avatar_store.dart';
import 'repo/member_repository.dart';
import 'repo/period_repository.dart';
import 'repo/settings_repository.dart';
import 'repo/sync_repository.dart';
import 'secure/secure_store.dart';

/// 数据库实例。启动时在 `main.dart` 里 `overrideWithValue` 注入。
final Provider<AppDatabase> databaseProvider = Provider<AppDatabase>(
  (Ref ref) => throw StateError('databaseProvider 必须在启动时注入'),
);

final Provider<MemberRepository> memberRepositoryProvider =
    Provider<MemberRepository>(
      (Ref ref) => MemberRepository(ref.watch(databaseProvider)),
    );

final Provider<PeriodRepository> periodRepositoryProvider =
    Provider<PeriodRepository>(
      (Ref ref) => PeriodRepository(ref.watch(databaseProvider)),
    );

final Provider<SettingsRepository> settingsRepositoryProvider =
    Provider<SettingsRepository>(
      (Ref ref) => SettingsRepository(ref.watch(databaseProvider)),
    );

/// 记录级导入导出与同步共用的仓储（含墓碑与头像）。
final Provider<SyncRepository> syncRepositoryProvider =
    Provider<SyncRepository>(
      (Ref ref) => SyncRepository(
        ref.watch(databaseProvider),
        ref.watch(avatarStoreProvider),
      ),
    );

/// 应用数据目录。启动时在 `main.dart` 里 `overrideWithValue` 注入。
final Provider<AppPaths> appPathsProvider = Provider<AppPaths>(
  (Ref ref) => throw StateError('appPathsProvider 必须在启动时注入'),
);

final Provider<AvatarStore> avatarStoreProvider = Provider<AvatarStore>(
  (Ref ref) => AvatarStore(ref.watch(appPathsProvider)),
);

final Provider<SecureStore> secureStoreProvider = Provider<SecureStore>(
  (Ref ref) => SecureStore(),
);

/// 本机设备 id，首次读取时生成并写入 `kv`。
final FutureProvider<String> deviceIdProvider = FutureProvider<String>(
  (Ref ref) => ref.watch(databaseProvider).kvDao.deviceId(),
);

/// 全部设置（值均为 TEXT）。主题、语言、提醒都监听它。
final StreamProvider<Map<String, String>> settingsProvider =
    StreamProvider<Map<String, String>>(
      (Ref ref) => ref.watch(settingsRepositoryProvider).watchAll(),
    );

/// 未删除的成员列表。
final StreamProvider<List<Member>> membersProvider =
    StreamProvider<List<Member>>(
      (Ref ref) => ref.watch(memberRepositoryProvider).watchAll(),
    );
