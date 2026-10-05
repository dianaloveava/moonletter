import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:moonletter/core/app_paths.dart';
import 'package:moonletter/data/db/database.dart';
import 'package:moonletter/data/media/avatar_store.dart';
import 'package:moonletter/data/repo/sync_repository.dart';
import 'package:moonletter/data/secure/secure_store.dart';
import 'package:moonletter/domain/sync/remote_storage.dart';
import 'package:moonletter/domain/sync/sync_engine.dart';

/// 空的内存远端：get 一律返回 null，方便测「远端还没建 kdf.json」的分支。
class _EmptyStorage implements RemoteStorage {
  final Map<String, Uint8List> files = <String, Uint8List>{};

  @override
  Future<List<RemoteObject>> list(String prefix) async => <RemoteObject>[];

  @override
  Future<Uint8List?> get(String path) async => files[path];

  @override
  Future<void> put(String path, Uint8List bytes) async => files[path] = bytes;

  @override
  Future<void> delete(String path) async => files.remove(path);

  @override
  Future<void> ensureDir(String path) async {}
}

class _MemorySecureStore extends SecureStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

void main() {
  late AppDatabase db;
  late _EmptyStorage storage;
  late _MemorySecureStore secure;
  late SyncEngine engine;

  setUp(() {
    db = AppDatabase.memory();
    storage = _EmptyStorage();
    secure = _MemorySecureStore();
    engine = SyncEngine(
      storage: storage,
      repository: SyncRepository(
        db,
        AvatarStore(
          AppPaths.forTesting(
            Directory.systemTemp.createTempSync('moonletter-passphrase-test'),
          ),
        ),
      ),
      database: db,
      secure: secure,
    );
  });

  tearDown(() async => db.close());

  test('远端为空且没给口令：抛 SyncPassphraseNeeded，界面据此当场问口令', () async {
    await expectLater(
      engine.sync(passphrase: null),
      throwsA(isA<SyncPassphraseNeeded>()),
    );
  });

  test('同上但口令不对：远端已有 kdf.json 时抛 SyncAuthException', () async {
    // 先用正确口令把远端建起来（kdf.json 写入）。
    await engine.sync(passphrase: 'moonletter-passphrase');
    // 换一台没记住主密钥的设备，用错误口令同步。
    final SyncEngine other = SyncEngine(
      storage: storage,
      repository: SyncRepository(
        db,
        AvatarStore(
          AppPaths.forTesting(
            Directory.systemTemp.createTempSync('moonletter-passphrase-other'),
          ),
        ),
      ),
      database: db,
      secure: _MemorySecureStore(),
    );
    await expectLater(
      other.sync(passphrase: 'wrong-passphrase'),
      throwsA(isA<SyncAuthException>()),
    );
  });
}
