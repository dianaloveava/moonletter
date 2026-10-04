// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '月信';

  @override
  String get tabCalendar => '日历';

  @override
  String get tabProfiles => '档案';

  @override
  String get tabSettings => '设置';

  @override
  String get commonCancel => '取消';

  @override
  String get commonSave => '保存';

  @override
  String get commonDelete => '删除';

  @override
  String get commonRetry => '重试';

  @override
  String get calendarEmptyMonth => '本月没有记录';

  @override
  String get calendarToday => '今天';

  @override
  String calendarMonthLabel(int year, int month) {
    return '$year 年 $month 月';
  }

  @override
  String get weekdayMon => '一';

  @override
  String get weekdayTue => '二';

  @override
  String get weekdayWed => '三';

  @override
  String get weekdayThu => '四';

  @override
  String get weekdayFri => '五';

  @override
  String get weekdaySat => '六';

  @override
  String get weekdaySun => '日';

  @override
  String get calendarPrevMonth => '上个月';

  @override
  String get calendarNextMonth => '下个月';

  @override
  String get calendarDayEmpty => '这一天没有记录';

  @override
  String get dayKindPeriod => '经期';

  @override
  String get dayKindPredicted => '预计经期';

  @override
  String get dayKindOvulation => '排卵日';

  @override
  String get dayKindFertile => '危险期';

  @override
  String get dayKindSafe => '安全期';

  @override
  String get dayKindUnknown => '无记录';

  @override
  String dayPeriodDay(int day) {
    return '经期第 $day 天';
  }

  @override
  String dayPredictedPeriodDay(int day) {
    return '预计经期第 $day 天';
  }

  @override
  String get profilesEmpty => '还没有成员';

  @override
  String get profilesAdd => '添加成员';

  @override
  String get memberAddTitle => '添加成员';

  @override
  String get memberEditTitle => '编辑成员';

  @override
  String get memberDetailInfo => '基本信息';

  @override
  String get memberDetailCycle => '周期设置';

  @override
  String get memberDetailReminder => '提醒';

  @override
  String get memberDetailRecords => '经期记录';

  @override
  String get memberDetailPredictNext => '下次预计开始';

  @override
  String get memberDetailPredictOvulation => '排卵日';

  @override
  String get memberDetailPredictFertile => '危险期';

  @override
  String get periodOngoingLabel => '进行中';

  @override
  String get reminderTitle => '经期提醒';

  @override
  String reminderBodyMember(String name, String date) {
    return '$name 预计 $date 开始';
  }

  @override
  String get reminderBodyNeutral => '经期将至，注意身体';

  @override
  String get memberDetailCalendar => '个人日历';

  @override
  String get memberRecordsEmpty => '还没有经期记录';

  @override
  String get memberRecordsAdd => '添加记录';

  @override
  String get memberDeleteTitle => '删除成员';

  @override
  String get memberDeleteMessage => '该成员与她的经期记录会从本机移除。';

  @override
  String get memberName => '昵称';

  @override
  String get memberNameRequired => '请填写昵称';

  @override
  String get memberAge => '年龄';

  @override
  String get memberHeight => '身高';

  @override
  String get memberWeight => '体重';

  @override
  String get memberNote => '描述';

  @override
  String get memberAvatar => '头像';

  @override
  String get memberAvatarPick => '选择照片';

  @override
  String get memberAvatarClear => '移除照片';

  @override
  String get memberCycleDays => '周期天数';

  @override
  String get memberPeriodDays => '经期天数';

  @override
  String get memberLastStart => '最近一次开始日期';

  @override
  String get memberReminderLead => '提醒提前';

  @override
  String get memberReminderFollowGlobal => '跟随全局';

  @override
  String get memberAgeRange => '年龄需在 0 到 120 之间';

  @override
  String get memberCycleRange => '周期天数需在 15 到 60 之间';

  @override
  String get memberPeriodRange => '经期天数需在 1 到 15 之间';

  @override
  String memberStatusPeriod(int day) {
    return '经期第 $day 天';
  }

  @override
  String memberStatusUpcoming(int days) {
    return '距下次 $days 天';
  }

  @override
  String memberStatusLate(int days) {
    return '已推迟 $days 天';
  }

  @override
  String get memberStatusNoRecords => '还没有记录';

  @override
  String get periodAddTitle => '添加经期';

  @override
  String get periodEditTitle => '编辑经期';

  @override
  String get periodStartLabel => '开始日';

  @override
  String get periodEndLabel => '结束日（可留空）';

  @override
  String get periodStartRequired => '请选择开始日期';

  @override
  String get periodEndBeforeStart => '结束日不能早于开始日';

  @override
  String get unitCm => '厘米';

  @override
  String get unitKg => '千克';

  @override
  String unitDay(int days) {
    return '$days 天';
  }

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsAbout => '关于';

  @override
  String get settingsDebugDatabase => '数据库文件';

  @override
  String get settingsDebugRows => '数据表行数';

  @override
  String get settingsNotifications => '提醒设置';

  @override
  String get settingsReminderLead => '全局提前天数';

  @override
  String get settingsReminderHideNames => '通知不显示人名';

  @override
  String get settingsReminderPermission => '权限';

  @override
  String get settingsReminderNotifications => '通知权限';

  @override
  String get settingsReminderExactAlarms => '精确闹钟';

  @override
  String get settingsReminderBattery => '电池优化';

  @override
  String get settingsReminderBatteryHint => '提醒不准时，把本应用加入电池优化白名单';

  @override
  String get settingsReminderAutostartHint => '部分系统需要允许自启动，重启后提醒才有效';

  @override
  String get settingsReminderWindowsHint => '关闭程序后不会收到提醒';

  @override
  String get settingsReminderAllowed => '已允许';

  @override
  String get settingsReminderNotAllowed => '未允许';

  @override
  String get settingsReminderNone => '没有需要设置的成员';

  @override
  String get commonOn => '开';

  @override
  String get commonOff => '关';

  @override
  String get lockUnlockTitle => '解锁';

  @override
  String get lockEnterPin => '输入 6 位 PIN';

  @override
  String get lockWrongPin => 'PIN 不正确';

  @override
  String lockCooldown(int seconds) {
    return '请 $seconds 秒后再试';
  }

  @override
  String get lockUseBiometrics => '用生物识别解锁';

  @override
  String get lockLocked => '已锁定';

  @override
  String get lockSetPin => '设置 6 位 PIN';

  @override
  String get lockConfirmPin => '再输一次';

  @override
  String get lockPinMismatch => '两次输入不一致';

  @override
  String get lockChangePin => '修改 PIN';

  @override
  String get lockDisable => '关闭应用锁';

  @override
  String get lockDisableConfirm => '关闭后打开应用不再需要解锁。';

  @override
  String get lockHintImmediate => '切到后台会立即锁定并隐藏内容';

  @override
  String get settingsPrivacy => '隐私';

  @override
  String get settingsAppLock => '应用锁';

  @override
  String get settingsBiometric => '生物识别解锁';

  @override
  String get settingsGeneral => '通用';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsLanguageSystem => '跟随系统';

  @override
  String get settingsAppearance => '外观';

  @override
  String get settingsThemeMode => '主题模式';

  @override
  String get settingsThemeSystem => '跟随系统';

  @override
  String get settingsThemeLight => '浅色';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsThemeColor => '主题色';

  @override
  String get settingsBlur => '界面模糊效果';

  @override
  String get settingsBlurHint => '低端设备建议关闭';

  @override
  String get settingsPrediction => '预测规则';

  @override
  String get settingsPredictionWindow => '参与平均的记录条数';

  @override
  String get settingsPredictionFallbackCycle => '默认周期天数';

  @override
  String get settingsPredictionFallbackPeriod => '默认经期天数';

  @override
  String get settingsPredictionOvulationOffset => '排卵日提前天数';

  @override
  String get settingsPredictionFertileBefore => '危险期提前天数';

  @override
  String get settingsPredictionFertileAfter => '危险期延后天数';

  @override
  String get settingsVersion => '版本';

  @override
  String get settingsLicense => '开源协议';

  @override
  String get settingsRepository => '仓库';

  @override
  String get settingsDisclaimer => '预测结果仅供参考，不能作为避孕或医疗依据。';

  @override
  String get settingsWindows => 'Windows';

  @override
  String get settingsAutostart => '开机自启';

  @override
  String get settingsCloseToTray => '关闭窗口最小化到托盘';

  @override
  String get settingsUpdate => '自动更新';

  @override
  String get settingsAutoCheckUpdate => '启动时检查更新';

  @override
  String get settingsCheckUpdate => '检查更新';

  @override
  String settingsUpdateAvailable(String version) {
    return '发现新版本 $version';
  }

  @override
  String get settingsUpToDate => '已是最新版本';

  @override
  String get settingsUpdateFailed => '检查更新失败';

  @override
  String get settingsUpdateOpen => '打开下载页';

  @override
  String get settingsData => '数据';

  @override
  String get settingsImportExport => '导入导出';

  @override
  String get accentRose => '玫瑰';

  @override
  String get accentPeach => '蜜桃';

  @override
  String get accentAmber => '琥珀';

  @override
  String get accentMoss => '苔绿';

  @override
  String get accentMint => '薄荷';

  @override
  String get accentMist => '雾蓝';

  @override
  String get accentLavender => '薰衣草';

  @override
  String get accentGraphite => '石墨';

  @override
  String get dataExportJson => '导出数据（JSON）';

  @override
  String get dataExportCsv => '导出经期（CSV）';

  @override
  String get dataImport => '导入数据';

  @override
  String get dataExportCancelled => '已取消';

  @override
  String dataExportedMembers(int count) {
    return '已导出 $count 个成员';
  }

  @override
  String dataExportedPeriods(int count) {
    return '已导出 $count 条经期记录';
  }

  @override
  String dataImportedRecords(int count) {
    return '已导入 $count 条记录';
  }

  @override
  String get dataExportFailed => '导出失败';

  @override
  String get dataImportFailed => '导入失败';

  @override
  String get syncTitle => '云同步';

  @override
  String get syncEnabled => '启用同步';

  @override
  String get syncBackend => '同步方式';

  @override
  String get syncBackendWebdav => 'WebDAV';

  @override
  String get syncBackendRelay => '中转服务';

  @override
  String get syncWebdavUrl => '服务地址';

  @override
  String get syncWebdavUser => '用户名';

  @override
  String get syncWebdavPassword => '密码';

  @override
  String get syncWebdavDir => '子目录';

  @override
  String get syncRelayUrl => '服务地址';

  @override
  String get syncNamespace => '同步 ID';

  @override
  String get syncPassphrase => '口令';

  @override
  String get syncPassphraseSet => '设置口令';

  @override
  String get syncPassphraseWarn => '口令只保存在本机且不上传。丢失后无法解密已上传的数据，也无法找回。';

  @override
  String get syncNow => '立即同步';

  @override
  String get syncLastAt => '上次同步';

  @override
  String get syncNever => '还没有同步过';

  @override
  String get syncReset => '重置同步';

  @override
  String get syncResetConfirm => '会清空远端数据并删除本机保存的密钥，需要重新设置口令。';
}
