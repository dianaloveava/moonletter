import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'pending_changes_dao.g.dart';

/// 待上传队列。本地写入后入队，Step 7 上传成功后出队；应用远端记录时不写这里。
@DriftAccessor(tables: <Type>[PendingChanges])
class PendingChangesDao extends DatabaseAccessor<AppDatabase>
    with _$PendingChangesDaoMixin {
  PendingChangesDao(super.db);

  Future<void> mark(String t, String id) =>
      into(pendingChanges)
          .insertOnConflictUpdate(PendingChangesCompanion.insert(t: t, id: id));

  Future<void> markAll(String t, Iterable<String> ids) async {
    await batch((Batch batch) {
      batch.insertAllOnConflictUpdate(pendingChanges, <PendingChangesCompanion>[
        for (final String id in ids)
          PendingChangesCompanion.insert(t: t, id: id),
      ]);
    });
  }

  Future<List<PendingChange>> all() => select(pendingChanges).get();

  Future<void> clear(String t, String id) => (delete(
    pendingChanges,
  )..where(($PendingChangesTable r) => r.t.equals(t) & r.id.equals(id))).go();

  Future<void> clearAll(Iterable<PendingChange> rows) async {
    await batch((Batch batch) {
      for (final PendingChange row in rows) {
        batch.deleteWhere(
          pendingChanges,
          ($PendingChangesTable r) => r.t.equals(row.t) & r.id.equals(row.id),
        );
      }
    });
  }
}
