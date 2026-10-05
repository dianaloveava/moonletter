import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:moonletter/core/app_paths.dart';
import 'package:moonletter/data/db/database.dart';
import 'package:moonletter/data/media/avatar_store.dart';
import 'package:moonletter/data/repo/member_repository.dart';
import 'package:moonletter/data/repo/period_repository.dart';
import 'package:moonletter/data/repo/sync_repository.dart';
import 'package:moonletter/data/secure/secure_store.dart';
import 'package:moonletter/domain/sync/remote_storage.dart';
import 'package:moonletter/domain/sync/sync_engine.dart';

/// 内存版远端存储：模拟 WebDAV / 中转服务的行为（同名文件不可覆盖）。
class _MemoryRemote implements RemoteStorage {
  final Map<String, Uint8List> files = <String, Uint8List>{};

  @override
  Future<void> ensureDir(String path) async {}

  @override
  Future<List<RemoteObject>> list(String prefix) async => files.keys
      .where((String key) => key.startsWith(prefix))
      .map(
        (String key) => RemoteObject(
          path: key,
          size: files[key]!.length,
          etag: '${files[key]!.length}',
        ),
      )
      .toList(growable: false);

  @override
  Future<Uint8List?> get(String path) async => files[path];

  @override
  Future<void> put(String path, Uint8List bytes) async {
    if (files.containsKey(path)) {
      throw AlreadyExistsException(path);
    }
    files[path] = bytes;
  }

  @override
  Future<void> delete(String path) async => files.remove(path);
}

/// 内存版安全存储。
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
  _Device(this.name) : db = AppDatabase.memory() {
    final AppPaths paths = AppPaths.forTesting(
      Directory.systemTemp.createTempSync('moonletter-sync-$name'),
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

  static late _MemoryRemote storage;
}

void main() {
  late _MemoryRemote remote;
  late _Device a;
  late _Device b;
  const String passphrase = 'moonletter-passphrase';

  setUp(() {
    remote = _MemoryRemote();
    _Device.storage = remote;
    a = _Device('a');
    b = _Device('b');
    // 两台设备的设备 id 固定下来，便于断言
    a.db.kvDao.put('device_id', 'device-a');
    b.db.kvDao.put('device_id', 'device-b');
  });

  tearDown(() async {
    await a.db.close();
    await b.db.close();
  });

  test('A 建成员 → B 同步后能看到', () async {
    await a.members.create(const MemberInput(name: '小月', age: 28));
    await a.engine.sync(passphrase: passphrase);

    final SyncResult result = await b.engine.sync(passphrase: passphrase);
    expect(result.filesRead, greaterThan(0));
    final List<Member> seen = await b.members.listAll();
    expect(seen, hasLength(1));
    expect(seen.single.name, '小月');
    expect(seen.single.age, 28);
  });

  test('B 改名 → A 同步后看到新名字', () async {
    final String id = await a.members.create(const MemberInput(name: '小月'));
    await a.engine.sync(passphrase: passphrase);
    await b.engine.sync(passphrase: passphrase);

    final Member onB = (await b.members.listAll()).single;
    await b.members.update(onB.id, const MemberInput(name: '小月月'));
    await b.engine.sync(passphrase: passphrase);
    await a.engine.sync(passphrase: passphrase);

    expect((await a.members.byId(id))!.name, '小月月');
  });

  test('A 删除后不会被旧数据复活', () async {
    final String id = await a.members.create(const MemberInput(name: '小月'));
    await a.periods.add(id, '2026-10-01', endDate: '2026-10-05');
    await a.engine.sync(passphrase: passphrase);
    await b.engine.sync(passphrase: passphrase);
    expect(await b.members.listAll(), hasLength(1));

    await a.members.delete(id);
    await a.engine.sync(passphrase: passphrase);
    await b.engine.sync(passphrase: passphrase);

    expect(await b.members.listAll(), isEmpty);
    expect(await b.periods.listAllLive(), isEmpty);
    // 双方都还能读到墓碑
    expect((await b.members.byId(id))!.deletedAt, isNotNull);
  });

  test('两边各自记录经期：同步后互不覆盖', () async {
    final String id = await a.members.create(const MemberInput(name: '小月'));
    await a.engine.sync(passphrase: passphrase);
    await b.engine.sync(passphrase: passphrase);

    // A 加 10-01，B 加 09-03
    await a.periods.add(id, '2026-10-01');
    await a.engine.sync(passphrase: passphrase);
    await b.engine.sync(passphrase: passphrase);
    await b.periods.add(id, '2026-09-03', endDate: '2026-09-07');
    await b.engine.sync(passphrase: passphrase);
    await a.engine.sync(passphrase: passphrase);

    final List<String> startsA = (await a.periods.listLiveOf(id))
        .map((dynamic p) => p.startDate as String)
        .toList();
    final List<String> startsB = (await b.periods.listLiveOf(id))
        .map((dynamic p) => p.startDate as String)
        .toList();
    expect(startsA, <String>['2026-09-03', '2026-10-01']);
    expect(startsB, startsA);
  });

  test('口令不对报错且本地数据不变', () async {
    await a.members.create(const MemberInput(name: '小月'));
    await a.engine.sync(passphrase: passphrase);

    await expectLater(
      b.engine.sync(passphrase: 'wrong-passphrase'),
      throwsA(isA<SyncAuthException>()),
    );
    expect(await b.members.listAll(), isEmpty);
  });

  test('日志累积到阈值后压缩成快照并清理旧日志', () async {
    // 每次写入一条经期记录并同步，制造多条日志
    final String id = await a.members.create(const MemberInput(name: '小月'));
    await a.engine.sync(passphrase: passphrase);
    for (int i = 0; i < SyncEngine.compactThreshold; i++) {
      await a.periods.add(id, '2026-08-${(i + 1).toString().padLeft(2, '0')}');
      await a.engine.sync(passphrase: passphrase);
    }
    final List<RemoteObject> logsAfter = await remote.list('logs/');
    final List<RemoteObject> snapshots = await remote.list('snapshots/');
    expect(snapshots, isNotEmpty, reason: '达到阈值后应生成快照');
    expect(
      logsAfter.length,
      lessThan(SyncEngine.compactThreshold),
      reason: '旧日志应被并入快照后删除',
    );

    // 新设备（空库）只靠快照也能拿到全部数据
    final _Device c = _Device('c');
    addTearDown(() async => c.db.close());
    await c.db.kvDao.put('device_id', 'device-c');
    await c.engine.sync(passphrase: passphrase);
    expect(await c.members.listAll(), hasLength(1));
    expect(await c.periods.listAllLive(), hasLength(SyncEngine.compactThreshold));
  });

  test('重置同步会清空远端并删掉本地主密钥', () async {
    await a.members.create(const MemberInput(name: '小月'));
    await a.engine.sync(passphrase: passphrase);
    expect(remote.files, isNotEmpty);

    await a.engine.resetRemote();
    expect(remote.files, isEmpty);
    expect(await a.secure.read(SecureStore.keySyncKey), isNull);
  });

  test('远端文件是密文，不包含明文名字', () async {
    await a.members.create(const MemberInput(name: '小月'));
    await a.engine.sync(passphrase: passphrase);

    final Uint8List log = remote.files.values.first;
    expect(
      utf8.decode(log, allowMalformed: true).contains('小月'),
      isFalse,
      reason: '上传的是密文',
    );
  });
}
