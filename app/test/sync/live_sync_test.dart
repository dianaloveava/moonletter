// 与真实远端联调的集成测试：默认跳过，设置了环境变量才运行。
//
// WebDAV（WsgiDAV，见计划 Step 7 验收）：
//   pip install wsgidav
//   wsgidav --host=127.0.0.1 --port=1900 --root=D:\tmp\dav --auth=anonymous
//   MOONLETTER_LIVE_SYNC_URL=http://127.0.0.1:1900 flutter test test/sync/live_sync_test.dart
//
// 中转服务（Cloudflare Worker 本地模式）：
//   cd server/relay && npx wrangler dev --port=8787
//   MOONLETTER_LIVE_SYNC_URL=http://127.0.0.1:8787 flutter test test/sync/live_sync_test.dart
//
// 每个用例都会新建一个随机命名空间 / 目录，互不干扰；结束时尽力清理远端。
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:moonletter/core/app_paths.dart';
import 'package:moonletter/data/db/database.dart';
import 'package:moonletter/data/media/avatar_store.dart';
import 'package:moonletter/data/repo/member_repository.dart';
import 'package:moonletter/data/repo/period_repository.dart';
import 'package:moonletter/data/repo/sync_repository.dart';
import 'package:moonletter/data/secure/secure_store.dart';
import 'package:moonletter/domain/sync/relay_storage.dart';
import 'package:moonletter/domain/sync/remote_storage.dart';
import 'package:moonletter/domain/sync/sync_engine.dart';
import 'package:moonletter/domain/sync/webdav_storage.dart';

/// 内存版安全存储（远端是真实的，本地密钥不落盘）。
class _MemorySecureStore extends SecureStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

class _Device {
  _Device(this.name, RemoteStorage storage) : db = AppDatabase.memory() {
    final AppPaths paths = AppPaths.forTesting(
      Directory.systemTemp.createTempSync('moonletter-live-$name'),
    );
    repository = SyncRepository(db, AvatarStore(paths));
    secure = _MemorySecureStore();
    engine = SyncEngine(
      storage: storage,
      repository: repository,
      database: db,
      secure: secure,
    );
    members = MemberRepository(db);
    periods = PeriodRepository(db);
  }

  final String name;
  final AppDatabase db;
  late final SyncRepository repository;
  late final _MemorySecureStore secure;
  late final SyncEngine engine;
  late final MemberRepository members;
  late final PeriodRepository periods;

  Future<void> dispose() async {
    await db.close();
  }
}

const String _namespaceAlphabet = 'abcdefghijklmnopqrstuvwxyz234567';

String _randomName() {
  final Random random = Random.secure();
  return List<String>.generate(
    26,
    (_) => _namespaceAlphabet[random.nextInt(_namespaceAlphabet.length)],
  ).join();
}

/// 每次调用都返回指向同一个服务、但命名空间全新的存储。
RemoteStorage _newRemote(String url, String kind) {
  if (kind == 'relay') {
    return RelayStorage(baseUrl: url, namespace: _randomName());
  }
  return WebDavStorage(
    baseUrl: url,
    user: 'anonymous',
    password: '',
    directory: 'moonletter-live-${_randomName().substring(0, 12)}',
  );
}

void main() {
  final String? url = Platform.environment['MOONLETTER_LIVE_SYNC_URL'];
  final bool isRelay =
      (Platform.environment['MOONLETTER_LIVE_SYNC_KIND'] ??
          (url != null && url.contains(':8787') ? 'relay' : 'webdav')) ==
      'relay';

  const String passphrase = 'moonletter-live-passphrase';

  late _Device a;
  late _Device b;
  late RemoteStorage storage;

  setUp(() {
    storage = _newRemote(url!, isRelay ? 'relay' : 'webdav');
    a = _Device('a', storage);
    b = _Device('b', storage);
    a.db.kvDao.put('device_id', 'live-device-a');
    b.db.kvDao.put('device_id', 'live-device-b');
  });

  tearDown(() async {
    try {
      await a.engine.resetRemote();
    } catch (_) {
      // 清理失败不影响断言结果。
    }
    await a.dispose();
    await b.dispose();
  });

  group(
    '真实远端联调（${isRelay ? '中转服务' : 'WebDAV'} @ $url）',
    () {
      test('建成员 → 对端可见 → 改名 → 对端可见 → 删除 → 不复活', () async {
        final String id = await a.members.create(
          const MemberInput(name: '小月'),
        );
        await a.periods.add(id, '2026-10-01');

        final SyncResult first = await a.engine.sync(passphrase: passphrase);
        expect(first.recordsUploaded, greaterThan(0));

        final SyncResult seen = await b.engine.sync(passphrase: passphrase);
        expect(seen.filesRead, greaterThan(0));
        final List<Member> onB = await b.members.listAll();
        expect(onB.single.name, '小月');
        expect((await b.periods.listLiveOf(id)).single.startDate, '2026-10-01');

        await b.members.update(onB.single.id, const MemberInput(name: '小月月'));
        await b.engine.sync(passphrase: passphrase);
        await a.engine.sync(passphrase: passphrase);
        expect((await a.members.byId(id))!.name, '小月月');

        await a.members.delete(id);
        await a.engine.sync(passphrase: passphrase);
        await b.engine.sync(passphrase: passphrase);
        expect(await b.members.listAll(), isEmpty);

        // 老设备再同步一次也不能把删除的记录带回来。
        await a.engine.sync(passphrase: passphrase);
        await b.engine.sync(passphrase: passphrase);
        expect(await b.members.listAll(), isEmpty);
      });

      test('错误口令被拒绝且本地数据不变', () async {
        await a.members.create(const MemberInput(name: '小月'));
        await a.engine.sync(passphrase: passphrase);
        await b.engine.sync(passphrase: passphrase);

        await expectLater(
          a.engine.sync(passphrase: 'wrong-passphrase'),
          throwsA(isA<SyncAuthException>()),
        );
        expect((await a.members.listAll()).single.name, '小月');
      });
    },
    skip: url == null
        ? '未设置 MOONLETTER_LIVE_SYNC_URL（需要本地 WsgiDAV 或 wrangler dev）'
        : null,
  );
}
