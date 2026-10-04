import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'member_dao.g.dart';

@DriftAccessor(tables: <Type>[Members])
class MemberDao extends DatabaseAccessor<AppDatabase> with _$MemberDaoMixin {
  MemberDao(super.db);

  List<OrderingTerm Function($MembersTable)> get _ordering =>
      <OrderingTerm Function($MembersTable)>[
        ($MembersTable t) => OrderingTerm(expression: t.sortOrder),
        ($MembersTable t) => OrderingTerm(expression: t.createdAt),
      ];

  Stream<List<Member>> watchAll() =>
      (select(members)
            ..where(($MembersTable t) => t.deletedAt.isNull())
            ..orderBy(_ordering))
          .watch();

  Future<List<Member>> listAll() =>
      (select(members)
            ..where(($MembersTable t) => t.deletedAt.isNull())
            ..orderBy(_ordering))
          .get();

  /// 含墓碑在内的全部成员（导出与同步要用）。
  Future<List<Member>> listAllIncludingDeleted() =>
      (select(members)..orderBy(_ordering)).get();

  Future<Member?> byId(String id) => (select(
    members,
  )..where(($MembersTable t) => t.id.equals(id))).getSingleOrNull();

  /// 单个成员（含墓碑），档案详情页用它跟随数据变化。
  Stream<Member?> watchById(String id) => (select(
    members,
  )..where(($MembersTable t) => t.id.equals(id))).watchSingleOrNull();

  Future<void> upsert(MembersCompanion row) =>
      into(members).insertOnConflictUpdate(row);

  Future<void> updateFields(String id, MembersCompanion changes) => (update(
    members,
  )..where(($MembersTable t) => t.id.equals(id))).write(changes);

  Future<void> softDelete(String id, {required int at, required String by}) =>
      (update(members)..where(($MembersTable t) => t.id.equals(id))).write(
        MembersCompanion(
          deletedAt: Value<int>(at),
          updatedAt: Value<int>(at),
          updatedBy: Value<String>(by),
        ),
      );

  /// 新增成员时排到列表末尾。
  Future<int> nextSortOrder() async {
    final Expression<int> maxOrder = members.sortOrder.max();
    final int? current =
        await (selectOnly(members)..addColumns(<Expression<Object>>[maxOrder]))
            .map((TypedResult row) => row.read(maxOrder))
            .getSingleOrNull();
    return (current ?? -1) + 1;
  }

  /// 生成实体的公共字段：新增时 `createdAt == updatedAt == now`。
  static MembersCompanion buildCompanion({
    required String id,
    required String name,
    int? age,
    double? heightCm,
    double? weightKg,
    String? note,
    String? avatarHash,
    required int colorIndex,
    int? defaultCycleDays,
    int? defaultPeriodDays,
    int? reminderLeadDays,
    required int sortOrder,
    required int createdAt,
    required int updatedAt,
    required String updatedBy,
  }) {
    return MembersCompanion.insert(
      id: id,
      name: name,
      age: Value<int?>(age),
      heightCm: Value<double?>(heightCm),
      weightKg: Value<double?>(weightKg),
      note: Value<String?>(note),
      avatarHash: Value<String?>(avatarHash),
      colorIndex: Value<int>(colorIndex),
      defaultCycleDays: Value<int?>(defaultCycleDays),
      defaultPeriodDays: Value<int?>(defaultPeriodDays),
      reminderLeadDays: Value<int?>(reminderLeadDays),
      sortOrder: Value<int>(sortOrder),
      createdAt: createdAt,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
    );
  }
}
