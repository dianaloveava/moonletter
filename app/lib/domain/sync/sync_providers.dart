import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/dates.dart';
import '../../data/data_providers.dart';
import '../../data/db/tables.dart';
import '../../data/secure/secure_store.dart';
import 'relay_storage.dart';
import 'remote_storage.dart';
import 'sync_engine.dart';
import 'webdav_storage.dart';

/// 同步状态：空闲 / 正在同步 / 上次结果或错误。
class SyncState {
  const SyncState({
    this.running = false,
    this.message,
    this.lastSyncAt,
    this.error,
  });

  final bool running;
  final String? message;
  final DateTime? lastSyncAt;
  final String? error;
}

/// 同步尚未配置（缺服务地址或密码）时 [SyncState.error] 的取值，由界面翻成本地化文案。
const String kSyncSetupRequired = 'sync-setup-required';

/// 远端还是空的（或本机没记住主密钥）、必须由用户输入口令时的 error 取值。
const String kSyncPassphraseRequired = 'sync-passphrase-required';

/// 按设置里的配置组装远端存储；没配置好时返回 null。
RemoteStorage? buildRemoteStorage({
  required Map<String, String> settings,
  required String? webdavPassword,
}) {
  final String backend = settings[SettingKeys.syncBackend] ?? 'webdav';
  if (backend == 'relay') {
    final String url = (settings[SettingKeys.syncRelayUrl] ?? '').trim();
    final String namespace = (settings[SettingKeys.syncNamespace] ?? '').trim();
    if (url.isEmpty || namespace.isEmpty) {
      return null;
    }
    return RelayStorage(baseUrl: url, namespace: namespace);
  }
  final String url = (settings[SettingKeys.syncWebdavUrl] ?? '').trim();
  final String user = settings[SettingKeys.syncWebdavUser] ?? '';
  if (url.isEmpty || webdavPassword == null || webdavPassword.isEmpty) {
    return null;
  }
  return WebDavStorage(
    baseUrl: url,
    user: user,
    password: webdavPassword,
    directory: settings[SettingKeys.syncWebdavDir] ?? 'moonletter',
  );
}

/// 同步控制器：负责跑一次同步并维护 UI 状态。
class SyncController extends Notifier<SyncState> {
  @override
  SyncState build() => const SyncState();

  Future<void> syncNow({String? passphrase}) async {
    if (state.running) {
      return;
    }
    state = SyncState(running: true, lastSyncAt: state.lastSyncAt);
    try {
      final Map<String, String> settings = await ref
          .read(settingsRepositoryProvider)
          .all();
      final String? webdavPassword = await ref
          .read(secureStoreProvider)
          .read(SecureStore.keyWebdavPassword);
      final RemoteStorage? storage = buildRemoteStorage(
        settings: settings,
        webdavPassword: webdavPassword,
      );
      if (storage == null) {
        state = const SyncState(error: kSyncSetupRequired);
        return;
      }
      final SyncEngine engine = SyncEngine(
        storage: storage,
        repository: ref.read(syncRepositoryProvider),
        database: ref.read(databaseProvider),
        secure: ref.read(secureStoreProvider),
      );
      final SyncResult result = await engine.sync(passphrase: passphrase);
      final DateTime now = DateTime.now();
      await ref
          .read(settingsRepositoryProvider)
          .set(SettingKeys.syncLastAt, LocalDate.of(now));
      state = SyncState(
        lastSyncAt: now,
        message:
            '读取 ${result.filesRead} 个文件，合并 ${result.recordsApplied} 条，'
            '上传 ${result.recordsUploaded} 条',
      );
    } on SyncPassphraseNeeded {
      state = const SyncState(error: kSyncPassphraseRequired);
    } on SyncAuthException catch (error) {
      state = SyncState(error: error.message, lastSyncAt: state.lastSyncAt);
    } on SyncException catch (error) {
      state = SyncState(error: error.message, lastSyncAt: state.lastSyncAt);
    } catch (error) {
      // 网络/服务端错误原样抛出来是 DioException 这类开发者文案，对用户
      // 没有意义：页面只给一句能照着排查的话，细节留给日志。
      debugPrint('同步失败：$error');
      state = SyncState(
        error: '同步失败：连不上同步服务，检查服务地址、账号密码和网络',
        lastSyncAt: state.lastSyncAt,
      );
    }
  }

  /// 重置同步：清空远端并删除本地保存的主密钥。
  Future<void> resetRemote() async {
    final Map<String, String> settings = await ref
        .read(settingsRepositoryProvider)
        .all();
    final String? webdavPassword = await ref
        .read(secureStoreProvider)
        .read(SecureStore.keyWebdavPassword);
    final RemoteStorage? storage = buildRemoteStorage(
      settings: settings,
      webdavPassword: webdavPassword,
    );
    if (storage == null) {
      return;
    }
    final SyncEngine engine = SyncEngine(
      storage: storage,
      repository: ref.read(syncRepositoryProvider),
      database: ref.read(databaseProvider),
      secure: ref.read(secureStoreProvider),
    );
    await engine.resetRemote();
    state = const SyncState(message: '已重置同步');
  }
}

final syncControllerProvider = NotifierProvider<SyncController, SyncState>(
  SyncController.new,
);
