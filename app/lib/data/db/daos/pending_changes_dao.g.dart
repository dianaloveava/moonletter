// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_changes_dao.dart';

// ignore_for_file: type=lint
mixin _$PendingChangesDaoMixin on DatabaseAccessor<AppDatabase> {
  $PendingChangesTable get pendingChanges => attachedDatabase.pendingChanges;
  PendingChangesDaoManager get managers => PendingChangesDaoManager(this);
}

class PendingChangesDaoManager {
  final _$PendingChangesDaoMixin _db;
  PendingChangesDaoManager(this._db);
  $$PendingChangesTableTableManager get pendingChanges =>
      $$PendingChangesTableTableManager(
        _db.attachedDatabase,
        _db.pendingChanges,
      );
}
