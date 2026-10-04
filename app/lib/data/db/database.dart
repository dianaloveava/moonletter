import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'daos/kv_dao.dart';
import 'daos/member_dao.dart';
import 'daos/pending_changes_dao.dart';
import 'daos/period_dao.dart';
import 'daos/remote_files_dao.dart';
import 'daos/reminder_log_dao.dart';
import 'daos/settings_dao.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: <Type>[
    Members,
    Periods,
    Settings,
    Kv,
    PendingChanges,
    RemoteFiles,
    ReminderLog,
  ],
  daos: <Type>[
    MemberDao,
    PeriodDao,
    SettingsDao,
    KvDao,
    PendingChangesDao,
    RemoteFilesDao,
    ReminderLogDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// 生产库：放在应用支持目录，后台 isolate 打开，开启 WAL。
  factory AppDatabase.open(File file) => AppDatabase(
    NativeDatabase.createInBackground(
      file,
      setup: (db) => db.execute('PRAGMA journal_mode = WAL'),
    ),
  );

  /// 测试库：内存，不落盘。
  factory AppDatabase.memory() => AppDatabase(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_periods_live '
        'ON periods(member_id, start_date) WHERE deleted_at IS NULL',
      );
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // 预留：schemaVersion 升到 2 时按 from 分支补迁移 + 重建索引。
    },
    beforeOpen: (OpeningDetails details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
