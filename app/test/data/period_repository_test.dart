import 'package:flutter_test/flutter_test.dart';
import 'package:moonletter/data/db/database.dart';
import 'package:moonletter/data/db/tables.dart';
import 'package:moonletter/data/repo/member_repository.dart';
import 'package:moonletter/data/repo/period_repository.dart';

void main() {
  late AppDatabase db;
  late MemberRepository members;
  late PeriodRepository periods;
  late String memberId;

  setUp(() async {
    db = AppDatabase.memory();
    members = MemberRepository(db);
    periods = PeriodRepository(db);
    memberId = await members.create(const MemberInput(name: '小月'));
  });

  tearDown(() => db.close());

  test('新增记录：写 pending_changes，按开始日升序返回', () async {
    final String second = await periods.add(memberId, '2026-03-29');
    await periods.add(memberId, '2026-03-01', endDate: '2026-03-05');

    final List<Period> rows = await periods.listLiveOf(memberId);
    expect(rows.map((Period row) => row.startDate), <String>[
      '2026-03-01',
      '2026-03-29',
    ]);
    expect(rows.first.endDate, '2026-03-05');
    expect(rows.last.endDate, isNull);

    final List<String> pending = (await db.pendingChangesDao.all())
        .where((PendingChange row) => row.t == RecordType.period)
        .map((PendingChange row) => row.id)
        .toList();
    expect(pending, contains(second));
  });

  test('同一成员同一天不会出现两条未删除记录', () async {
    await periods.add(memberId, '2026-03-01');

    await expectLater(periods.add(memberId, '2026-03-01'), throwsA(anything));
    expect(await periods.listLiveOf(memberId), hasLength(1));
  });

  test('墓碑不影响同一天重新添加', () async {
    final String id = await periods.add(memberId, '2026-03-01');
    await periods.delete(id);
    expect(await periods.listLiveOf(memberId), isEmpty);
    final Period? tombstone = await db.periodDao.byId(id);
    expect(tombstone!.deletedAt, isNotNull);

    final String again = await periods.add(memberId, '2026-03-01');
    expect(again, isNot(id));
    expect(await periods.listLiveOf(memberId), hasLength(1));
  });

  test('setLastStartDate：最近一条未结束时改它的开始日', () async {
    final String id = await periods.add(memberId, '2026-03-01');
    final String returned = await periods.setLastStartDate(
      memberId,
      '2026-03-04',
    );

    expect(returned, id);
    final List<Period> rows = await periods.listLiveOf(memberId);
    expect(rows, hasLength(1));
    expect(rows.single.startDate, '2026-03-04');
    expect(rows.single.endDate, isNull);
  });

  test('setLastStartDate：同日期已有记录时原样返回', () async {
    final String id = await periods.add(memberId, '2026-03-01');
    expect(await periods.setLastStartDate(memberId, '2026-03-01'), id);
    expect(await periods.listLiveOf(memberId), hasLength(1));
  });

  test('setLastStartDate：最近一条已结束则新增一条进行中的记录', () async {
    await periods.add(memberId, '2026-03-01', endDate: '2026-03-05');
    await periods.setLastStartDate(memberId, '2026-03-29');

    final List<Period> rows = await periods.listLiveOf(memberId);
    expect(rows, hasLength(2));
    expect(rows.last.startDate, '2026-03-29');
    expect(rows.last.endDate, isNull);
  });

  test('setStart 撞上另一条未删除记录时抛错且不写入', () async {
    final String first = await periods.add(memberId, '2026-03-01');
    await periods.add(memberId, '2026-03-29');

    await expectLater(periods.setStart(first, '2026-03-29'), throwsStateError);
    final Period row = (await db.periodDao.byId(first))!;
    expect(row.startDate, '2026-03-01');
  });

  test('setEnd 可以清空与写入结束日', () async {
    final String id = await periods.add(memberId, '2026-03-01');
    await periods.setEnd(id, '2026-03-06');
    expect((await db.periodDao.byId(id))!.endDate, '2026-03-06');
    await periods.setEnd(id, null);
    expect((await db.periodDao.byId(id))!.endDate, isNull);
  });

  test('groupByMember 只返回未删除记录', () async {
    final String other = await members.create(const MemberInput(name: '阿冷'));
    await periods.add(memberId, '2026-03-01');
    await periods.add(other, '2026-03-02');
    final String removed = await periods.add(other, '2026-03-30');
    await periods.delete(removed);

    final Map<String, List<Period>> grouped = await periods.groupByMember();
    expect(grouped.keys.toSet(), <String>{memberId, other});
    expect(grouped[memberId], hasLength(1));
    expect(grouped[other], hasLength(1));
  });
}
