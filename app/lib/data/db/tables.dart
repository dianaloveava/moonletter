import 'package:drift/drift.dart';

/// 记录类型：同步日志与待上传队列里用它区分表。
abstract final class RecordType {
  static const String member = 'member';
  static const String period = 'period';
  static const String avatar = 'avatar';
}

/// `settings` 表的键清单（值一律 TEXT）。设备本地，不参与同步。
abstract final class SettingKeys {
  static const String themeMode = 'theme_mode';
  static const String themeColor = 'theme_color';
  static const String language = 'language';
  static const String blurEnabled = 'blur_enabled';
  static const String reminderGlobalLeadDays = 'reminder_global_lead_days';
  static const String predictionWindow = 'prediction_window';
  static const String predictionFallbackCycle = 'prediction_fallback_cycle';
  static const String predictionFallbackPeriod = 'prediction_fallback_period';
  static const String predictionOvulationOffset = 'prediction_ovulation_offset';
  static const String predictionFertileBefore = 'prediction_fertile_before';
  static const String predictionFertileAfter = 'prediction_fertile_after';
  static const String notifyHideNames = 'notify_hide_names';
  static const String lockKind = 'lock_kind';
  static const String autostart = 'autostart';
  static const String closeToTray = 'close_to_tray';
  static const String autoCheckUpdate = 'auto_check_update';
  static const String syncEnabled = 'sync_enabled';
  static const String syncBackend = 'sync_backend';
  static const String syncWebdavUrl = 'sync_webdav_url';
  static const String syncWebdavUser = 'sync_webdav_user';
  static const String syncWebdavDir = 'sync_webdav_dir';
  static const String syncRelayUrl = 'sync_relay_url';
  static const String syncNamespace = 'sync_namespace';
  static const String syncLastAt = 'sync_last_at';
}

/// `settings` 表的默认值。首次启动时补齐缺失键，之后一切读取都走 DB。
abstract final class SettingDefaults {
  static const Map<String, String> values = <String, String>{
    SettingKeys.themeMode: 'system',
    SettingKeys.themeColor: 'rose',
    SettingKeys.language: 'system',
    SettingKeys.blurEnabled: 'true',
    SettingKeys.reminderGlobalLeadDays: '3',
    SettingKeys.predictionWindow: '6',
    SettingKeys.predictionFallbackCycle: '28',
    SettingKeys.predictionFallbackPeriod: '5',
    SettingKeys.predictionOvulationOffset: '14',
    SettingKeys.predictionFertileBefore: '5',
    SettingKeys.predictionFertileAfter: '4',
    SettingKeys.notifyHideNames: 'false',
    SettingKeys.lockKind: 'none',
    SettingKeys.autostart: 'true',
    SettingKeys.closeToTray: 'true',
    SettingKeys.autoCheckUpdate: 'true',
    SettingKeys.syncEnabled: 'false',
    SettingKeys.syncBackend: 'webdav',
    SettingKeys.syncWebdavUrl: '',
    SettingKeys.syncWebdavUser: '',
    SettingKeys.syncWebdavDir: 'moonletter',
    SettingKeys.syncRelayUrl: '',
    SettingKeys.syncNamespace: '',
    SettingKeys.syncLastAt: '',
  };
}

/// `kv` 表的键清单。设备本地，不参与同步。
abstract final class KvKeys {
  static const String deviceId = 'device_id';
}

/// 成员档案。日期列是 `YYYY-MM-DD` 文本，时间戳是毫秒 epoch，主键是 uuid v4。
class Members extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get age => integer().nullable()();

  /// 身高（厘米）
  RealColumn get heightCm => real().nullable()();

  /// 体重（千克）
  RealColumn get weightKg => real().nullable()();
  TextColumn get note => text().nullable()();

  /// 头像 PNG 的内容 hash（sha256），null = 默认首字头像
  TextColumn get avatarHash => text().nullable()();

  /// 0..7，默认头像底色，取自 kDefaultAvatarColors
  IntColumn get colorIndex => integer().withDefault(const Constant(0))();

  /// 档案里填的周期天数，为空则用全局回退值
  IntColumn get defaultCycleDays => integer().nullable()();

  /// 档案里填的经期天数，为空则用全局回退值
  IntColumn get defaultPeriodDays => integer().nullable()();

  /// 提醒提前天数，null = 跟随全局
  IntColumn get reminderLeadDays => integer().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  /// 最后写入的设备 id，合并时的次级比较键
  TextColumn get updatedBy => text()();

  /// 非空 = 墓碑
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// 经期记录。`start_date` 是唯一来源，档案里的「最近一次开始日期」写到这里。
class Periods extends Table {
  TextColumn get id => text()();
  TextColumn get memberId => text().references(Members, #id)();
  TextColumn get startDate => text()();

  /// null = 进行中
  TextColumn get endDate => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  TextColumn get updatedBy => text()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// 设备本地设置（不参与同步）。
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{key};
}

/// 设备本地键值（device_id、last_sync_at 等，不参与同步）。
class Kv extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{key};
}

/// 待上传队列：本地写入后插入，上传成功才清空。
class PendingChanges extends Table {
  /// [RecordType] 之一
  TextColumn get t => text()();
  TextColumn get id => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{t, id};
}

/// 已处理的远端文件，避免重复下载与重复应用。
class RemoteFiles extends Table {
  TextColumn get path => text()();
  TextColumn get etag => text().nullable()();
  IntColumn get size => integer().nullable()();
  IntColumn get appliedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{path};
}

/// Windows 进程内提醒的去重记录（Android 的调度由系统持有，不写这里）。
class ReminderLog extends Table {
  TextColumn get memberId => text()();
  TextColumn get periodStart => text()();
  IntColumn get notifiedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{memberId, periodStart};
}
