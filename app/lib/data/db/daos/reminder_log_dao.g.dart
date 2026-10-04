// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_log_dao.dart';

// ignore_for_file: type=lint
mixin _$ReminderLogDaoMixin on DatabaseAccessor<AppDatabase> {
  $ReminderLogTable get reminderLog => attachedDatabase.reminderLog;
  ReminderLogDaoManager get managers => ReminderLogDaoManager(this);
}

class ReminderLogDaoManager {
  final _$ReminderLogDaoMixin _db;
  ReminderLogDaoManager(this._db);
  $$ReminderLogTableTableManager get reminderLog =>
      $$ReminderLogTableTableManager(_db.attachedDatabase, _db.reminderLog);
}
