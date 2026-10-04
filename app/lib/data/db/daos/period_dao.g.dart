// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'period_dao.dart';

// ignore_for_file: type=lint
mixin _$PeriodDaoMixin on DatabaseAccessor<AppDatabase> {
  $MembersTable get members => attachedDatabase.members;
  $PeriodsTable get periods => attachedDatabase.periods;
  PeriodDaoManager get managers => PeriodDaoManager(this);
}

class PeriodDaoManager {
  final _$PeriodDaoMixin _db;
  PeriodDaoManager(this._db);
  $$MembersTableTableManager get members =>
      $$MembersTableTableManager(_db.attachedDatabase, _db.members);
  $$PeriodsTableTableManager get periods =>
      $$PeriodsTableTableManager(_db.attachedDatabase, _db.periods);
}
