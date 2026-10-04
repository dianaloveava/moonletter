import 'package:flutter_test/flutter_test.dart';
import 'package:moonletter/data/db/database.dart';
import 'package:moonletter/data/db/tables.dart';
import 'package:moonletter/data/repo/member_repository.dart';

void main() {
  late AppDatabase db;
  late MemberRepository members;

  setUp(() {
    db = AppDatabase.memory();
    members = MemberRepository(db);
  });

  tearDown(() => db.close());

  test('创建成员：写 pending_changes、盖设备 id、排序号递增', () async {
    final String first = await members.create(
      const MemberInput(name: '小月', age: 28),
    );
    final String second = await members.create(const MemberInput(name: '阿冷'));

    final List<Member> rows = await members.listAll();
    expect(rows, hasLength(2));
    expect(rows.first.name, '小月');
    expect(rows.first.age, 28);
    expect(rows.first.sortOrder, lessThan(rows.last.sortOrder));
    expect(rows.first.createdAt, rows.first.updatedAt);
    expect(rows.first.updatedBy, isNotEmpty);

    final String deviceId = await db.kvDao.deviceId();
    expect(rows.first.updatedBy, deviceId);
    expect(await db.kvDao.deviceId(), deviceId, reason: '设备 id 只生成一次');

    final List<String> pending = (await db.pendingChangesDao.all())
        .map((PendingChange row) => '${row.t}:${row.id}')
        .toList();
    expect(pending, containsAll(<String>['member:$first', 'member:$second']));
  });

  test('更新成员：改字段并刷新 updatedAt / updatedBy，不动 sortOrder', () async {
    final String id = await members.create(const MemberInput(name: '小月'));
    final Member before = (await members.byId(id))!;

    await members.update(
      id,
      const MemberInput(
        name: '小月',
        age: 30,
        heightCm: 165.5,
        weightKg: 52.3,
        note: '对坚果过敏',
        colorIndex: 3,
        defaultCycleDays: 31,
        defaultPeriodDays: 6,
        reminderLeadDays: 2,
      ),
    );

    final Member after = (await members.byId(id))!;
    expect(after.age, 30);
    expect(after.heightCm, 165.5);
    expect(after.weightKg, 52.3);
    expect(after.note, '对坚果过敏');
    expect(after.colorIndex, 3);
    expect(after.defaultCycleDays, 31);
    expect(after.defaultPeriodDays, 6);
    expect(after.reminderLeadDays, 2);
    expect(after.sortOrder, before.sortOrder);
    expect(after.createdAt, before.createdAt);
    expect(after.updatedAt, greaterThanOrEqualTo(before.updatedAt));
  });

  test('setAvatarHash 只改头像字段', () async {
    final String id = await members.create(
      const MemberInput(name: '小月', age: 25),
    );
    await members.setAvatarHash(id, 'a' * 64);
    final Member after = (await members.byId(id))!;
    expect(after.avatarHash, 'a' * 64);
    expect(after.age, 25);
  });

  test('软删除成员：列表里消失，墓碑行仍可读且进 pending_changes', () async {
    final String id = await members.create(const MemberInput(name: '小月'));
    await db.pendingChangesDao.clear(RecordType.member, id);

    await members.delete(id);

    expect(await members.listAll(), isEmpty);
    final Member? tombstone = await db.memberDao.byId(id);
    expect(tombstone, isNotNull);
    expect(tombstone!.deletedAt, isNotNull);
    expect(tombstone.name, '小月');
    final List<PendingChange> pending = await db.pendingChangesDao.all();
    expect(
      pending.map((PendingChange row) => '${row.t}:${row.id}'),
      contains('member:$id'),
    );
  });

  test('删除成员会连带软删它的经期记录', () async {
    final String id = await members.create(const MemberInput(name: '小月'));
    await db.periodDao.upsert(
      PeriodsCompanion.insert(
        id: 'p1',
        memberId: id,
        startDate: '2026-03-01',
        createdAt: 1,
        updatedAt: 1,
        updatedBy: 'test',
      ),
    );
    await db.periodDao.upsert(
      PeriodsCompanion.insert(
        id: 'p2',
        memberId: id,
        startDate: '2026-03-29',
        createdAt: 1,
        updatedAt: 1,
        updatedBy: 'test',
      ),
    );

    await members.delete(id);

    expect(await db.periodDao.listLiveOf(id), isEmpty);
    final List<PendingChange> pending = await db.pendingChangesDao.all();
    expect(
      pending.where((PendingChange row) => row.t == RecordType.period),
      hasLength(2),
    );
  });
}
