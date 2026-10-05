import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:moonletter/core/app_paths.dart';
import 'package:moonletter/data/db/database.dart';
import 'package:moonletter/data/db/tables.dart';
import 'package:moonletter/data/media/avatar_store.dart';
import 'package:moonletter/data/repo/member_repository.dart';
import 'package:moonletter/data/repo/period_repository.dart';
import 'package:moonletter/data/repo/sync_repository.dart';
import 'package:moonletter/domain/backup/backup_csv.dart';
import 'package:moonletter/domain/backup/backup_json.dart';
import 'package:moonletter/domain/sync/sync_codec.dart';
import 'package:moonletter/domain/sync/sync_merge.dart';

void main() {
  late AppDatabase db;
  late Directory dir;
  late SyncRepository repository;
  late MemberRepository members;
  late PeriodRepository periods;

  setUp(() {
    db = AppDatabase.memory();
    dir = Directory.systemTemp.createTempSync('moonletter-backup-test');
    repository = SyncRepository(db, AvatarStore(AppPaths.forTesting(dir)));
    members = MemberRepository(db);
    periods = PeriodRepository(db);
  });

  tearDown(() async {
    await db.close();
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  test('JSON 备份往返：导出→导入到空库后数据一致（含头像）', () async {
    final String id = await members.create(
      const MemberInput(
        name: '小月',
        age: 28,
        heightCm: 165.5,
        defaultCycleDays: 30,
      ),
    );
    await periods.add(id, '2026-10-01', endDate: '2026-10-05');
    final String avatarHash = await AvatarStore(AppPaths.forTesting(dir))
        .saveFromImage(_pngBytes());
    await members.setAvatarHash(id, avatarHash);

    final List<SyncRecord> exported = await repository.collectRecords();
    final String json = encodeBackupJson(exported);

    // 导入到另一个空库
    final AppDatabase target = AppDatabase.memory();
    addTearDown(target.close);
    final Directory targetDir = Directory.systemTemp.createTempSync(
      'moonletter-backup-target',
    );
    addTearDown(() {
      if (targetDir.existsSync()) {
        targetDir.deleteSync(recursive: true);
      }
    });
    final SyncRepository targetRepo = SyncRepository(
      target,
      AvatarStore(AppPaths.forTesting(targetDir)),
    );
    final List<SyncRecord> incoming = decodeBackupJson(json);
    final List<SyncRecord> local = await targetRepo.collectRecords(
      includeAvatars: false,
    );
    final int applied = await targetRepo.applyRecords(
      recordsToRestore(
        local,
        incoming,
        deviceId: 'test-device',
        now: DateTime.now(),
      ),
    );
    expect(applied, greaterThan(0));

    final List<Member> targetMembers = await target.memberDao.listAll();
    expect(targetMembers, hasLength(1));
    expect(targetMembers.single.name, '小月');
    expect(targetMembers.single.age, 28);
    expect(targetMembers.single.heightCm, 165.5);
    expect(targetMembers.single.defaultCycleDays, 30);
    expect(targetMembers.single.avatarHash, avatarHash);
    expect(
      File(AppPaths.forTesting(targetDir).avatarFile(avatarHash).path)
          .existsSync(),
      isTrue,
      reason: '头像文件也要恢复',
    );

    final List<Period> targetPeriods = await target.periodDao.listLive();
    expect(targetPeriods, hasLength(1));
    expect(targetPeriods.single.startDate, '2026-10-01');
    expect(targetPeriods.single.endDate, '2026-10-05');
  });

  test('合并：新记录胜出，删除墓碑不会被旧数据复活', () {
    const SyncRecord older = SyncRecord(
      t: RecordType.member,
      id: 'm1',
      updatedAt: 100,
      updatedBy: 'a',
      data: <String, Object?>{'name': '旧名字'},
    );
    const SyncRecord newer = SyncRecord(
      t: RecordType.member,
      id: 'm1',
      updatedAt: 200,
      updatedBy: 'b',
      data: <String, Object?>{'name': '新名字'},
    );
    const SyncRecord deletion = SyncRecord(
      t: RecordType.member,
      id: 'm1',
      updatedAt: 300,
      updatedBy: 'a',
      deleted: true,
    );

    expect(
      mergeRecords(<SyncRecord>[older], <SyncRecord>[newer]).single.updatedAt,
      200,
    );
    expect(
      mergeRecords(<SyncRecord>[deletion], <SyncRecord>[older]).single.deleted,
      isTrue,
      reason: '删除比本地新 → 保持删除',
    );
    expect(
      mergeRecords(<SyncRecord>[older], <SyncRecord>[deletion]).single.deleted,
      isTrue,
    );

    // 时间相同，用设备 id 兜底，结果必须稳定
    const SyncRecord a = SyncRecord(
      t: RecordType.period,
      id: 'p1',
      updatedAt: 500,
      updatedBy: 'device-a',
      data: <String, Object?>{'start': '2026-10-01'},
    );
    const SyncRecord b = SyncRecord(
      t: RecordType.period,
      id: 'p1',
      updatedAt: 500,
      updatedBy: 'device-b',
      data: <String, Object?>{'start': '2026-10-02'},
    );
    expect(
      mergeRecords(<SyncRecord>[a], <SyncRecord>[b]).single.updatedBy,
      'device-b',
    );
    expect(
      mergeRecords(<SyncRecord>[b], <SyncRecord>[a]).single.updatedBy,
      'device-b',
    );
  });

  test('导入不会覆盖更新的本地记录', () async {
    final String id = await members.create(const MemberInput(name: '本地新名字'));
    final Member local = (await members.byId(id))!;
    final List<SyncRecord> stale = <SyncRecord>[
      SyncRecord(
        t: RecordType.member,
        id: id,
        updatedAt: local.updatedAt - 1000,
        updatedBy: 'other-device',
        data: <String, Object?>{
          'name': '别的设备上的旧名字',
          'createdAt': local.createdAt,
        },
      ),
    ];
    final List<SyncRecord> localRecords = await repository.collectRecords(
      includeAvatars: false,
    );
    final int applied = await repository.applyRecords(
      recordsToRestore(
        localRecords,
        stale,
        deviceId: 'test-device',
        now: DateTime.now(),
      ),
    );
    expect(applied, 0);
    expect((await members.byId(id))!.name, '本地新名字');
  });

  test('导入恢复被删除的成员与其经期记录', () async {
    final String id = await members.create(
      const MemberInput(name: '小月', defaultCycleDays: 30),
    );
    await periods.add(id, '2026-10-01', endDate: '2026-10-05');
    final String json = encodeBackupJson(
      await repository.collectRecords(includeAvatars: false),
    );

    await members.delete(id);
    expect(await members.listAll(), isEmpty);
    expect(await periods.listAllLive(), isEmpty);

    final List<SyncRecord> local = await repository.collectRecords(
      includeAvatars: false,
    );
    final int applied = await repository.applyRecords(
      recordsToRestore(
        local,
        decodeBackupJson(json),
        deviceId: 'test-device',
        now: DateTime.now(),
      ),
    );

    expect(applied, 2, reason: '成员与经期记录都恢复');
    final Member restored = (await members.listAll()).single;
    expect(restored.name, '小月');
    expect(restored.updatedBy, 'test-device');
    expect(
      restored.updatedAt,
      greaterThan(local.firstWhere((r) => r.id == id).updatedAt),
      reason: '恢复要盖新的时间戳，否则下次同步会被旧墓碑再次删掉',
    );
    final Period period = (await periods.listAllLive()).single;
    expect(period.startDate, '2026-10-01');
    expect(period.endDate, '2026-10-05');
  });

  test('CSV 带 BOM 且能原样解析回来', () async {
    final String id = await members.create(const MemberInput(name: '小月, 冷冷'));
    await periods.add(id, '2026-10-01', endDate: '2026-10-05');

    final List<Period> live = await periods.listAllLive();
    final String csv = encodePeriodsCsv(live, <String, String>{id: '小月, 冷冷'});
    expect(csv.startsWith(kCsvBom), isTrue, reason: 'Excel 需要 BOM');
    expect(csv.contains('"小月, 冷冷"'), isTrue, reason: '含逗号的字段要转义');

    final List<CsvPeriodRow> rows = decodePeriodsCsv(csv);
    expect(rows, hasLength(1));
    expect(rows.single.member, '小月, 冷冷');
    expect(rows.single.start, '2026-10-01');
    expect(rows.single.end, '2026-10-05');
  });

  test('CSV：空结束日与无效行处理', () {
    final String csv =
        '$kCsvBom成员,开始日期,结束日期\r\n'
        '小月,2026-10-01,\r\n'
        '\r\n'
        ',2026-10-02,2026-10-03\r\n'
        '小月,,,\r\n';
    final List<CsvPeriodRow> rows = decodePeriodsCsv(csv);
    expect(rows, hasLength(1));
    expect(rows.single.end, isNull);
  });

  test('备份文件格式不对时报错', () {
    expect(() => decodeBackupJson('{"format":"other"}'), throwsFormatException);
    expect(() => decodeBackupJson('不是 JSON'), throwsFormatException);
    expect(
      () => decodeBackupJson('{"format":"moonletter","version":9}'),
      throwsFormatException,
    );
  });
}

/// 一张 4×4 的小 PNG，用来测头像往返。
Uint8List _pngBytes() {
  final img.Image image = img.Image(width: 4, height: 4);
  img.fill(image, color: img.ColorRgb8(180, 90, 120));
  return Uint8List.fromList(img.encodePng(image));
}
