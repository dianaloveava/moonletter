import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../core/l10n/gen/app_localizations.dart';
import '../../core/utils/dates.dart';
import '../../data/db/database.dart';
import '../../data/db/tables.dart';
import '../../data/repo/member_repository.dart';
import '../../data/repo/period_repository.dart';
import '../../data/repo/settings_repository.dart';
import '../prediction/prediction_config.dart';
import 'reminder_planner.dart';

/// 通知调度（§5.2）：
/// - Android：交给系统闹钟（`zonedSchedule`），重启后由插件的 BootReceiver 重新注册。
/// - Windows：不使用系统调度，进程内每分钟检查 + 启动时 6 小时内补发，
///   因此关闭程序后不会收到提醒（设置页有说明）。
class ReminderRunner {
  ReminderRunner({
    required this.members,
    required this.periods,
    required this.settings,
    required this.database,
  });

  static const String channelId = 'period_reminder';
  static const String channelName = '经期提醒';
  static const String channelDescription = '预测的下次经期开始前的提醒';
  static const String _windowsAppUserModelId = 'com.moonletter.app';
  static const String _windowsGuid = '8f6c1b74-3c62-4f5c-9d2f-9d5f0f1b6a31';

  final MemberRepository members;
  final PeriodRepository periods;
  final SettingsRepository settings;
  final AppDatabase database;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  List<ReminderPlan> _planCache = const <ReminderPlan>[];
  Timer? _timer;
  bool _ready = false;

  /// 精确闹钟是否可用（Android 12+ 需要用户授权，被拒时退化为不精确）。
  bool _exactAllowed = true;

  bool get _isDesktop =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  Future<void> init() async {
    if (_ready) {
      return;
    }
    tz_data.initializeTimeZones();
    try {
      final TimezoneInfo info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (error) {
      debugPrint('无法确定本地时区，使用默认时区：$error');
    }

    final InitializationSettings settings = InitializationSettings(
      android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
      windows: Platform.isWindows
          ? const WindowsInitializationSettings(
              appName: 'Moonletter',
              appUserModelId: _windowsAppUserModelId,
              guid: _windowsGuid,
            )
          : null,
    );
    await _plugin.initialize(settings: settings);

    final AndroidFlutterLocalNotificationsPlugin? android = Platform.isAndroid
        ? _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
        : null;
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.high,
      ),
    );
    _exactAllowed = await android?.canScheduleExactNotifications() ?? true;
    _ready = true;
  }

  /// 申请通知权限（Android 13+）。返回是否已授权。
  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) {
      return true;
    }
    final AndroidFlutterLocalNotificationsPlugin? android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final bool? granted = await android?.requestNotificationsPermission();
    return granted ?? true;
  }

  /// 申请精确闹钟权限（Android 12+）。返回是否已授权。
  Future<bool> requestExactAlarms() async {
    if (!Platform.isAndroid) {
      return true;
    }
    final AndroidFlutterLocalNotificationsPlugin? android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final bool? granted = await android?.requestExactAlarmsPermission();
    _exactAllowed = granted ?? false;
    return _exactAllowed;
  }

  bool get exactAlarmsAllowed => _exactAllowed;

  /// 重新计算并注册全部提醒。数据变更、设置变更、启动时调用。
  Future<void> rescheduleAll() async {
    if (!_ready) {
      return;
    }
    final List<Member> allMembers = await members.listAll();
    final Map<String, List<Period>> grouped = await periods.groupByMember();
    final Map<String, String> allSettings = await settings.all();
    final PredictionConfig config = PredictionConfig.fromSettings(allSettings);
    final int globalLead =
        int.tryParse(allSettings[SettingKeys.reminderGlobalLeadDays] ?? '') ??
        3;
    final bool hideNames =
        (allSettings[SettingKeys.notifyHideNames] ?? 'false') == 'true';
    final DateTime now = DateTime.now();

    final List<ReminderPlan> plans = planReminders(
      members: allMembers,
      periodsByMember: grouped,
      config: config,
      globalLeadDays: globalLead,
      now: now,
    );

    if (Platform.isAndroid) {
      await _plugin.cancelAll();
      final AppLocalizations l10n = await _localizations();
      for (final ReminderPlan plan in plans) {
        await _scheduleOnAndroid(
          plan: plan,
          memberName: _nameOf(allMembers, plan.memberId),
          hideNames: hideNames,
          l10n: l10n,
        );
      }
      _planCache = plans;
      return;
    }

    if (_isDesktop) {
      _planCache = plans;
      _timer ??= Timer.periodic(const Duration(minutes: 1), (_) {
        unawaited(_deliverDue(now: DateTime.now()));
      });
      await _catchUp(
        members: allMembers,
        grouped: grouped,
        config: config,
        globalLead: globalLead,
        hideNames: hideNames,
      );
    }
  }

  /// 停止进程内定时器（退出前调用）。
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _scheduleOnAndroid({
    required ReminderPlan plan,
    required String memberName,
    required bool hideNames,
    required AppLocalizations l10n,
  }) async {
    final ReminderText text = _textFor(
      l10n: l10n,
      memberName: memberName,
      periodStart: plan.periodStart,
      hideNames: hideNames,
    );
    final AndroidScheduleMode mode = _exactAllowed
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    try {
      await _plugin.zonedSchedule(
        id: plan.notificationId,
        title: text.title,
        body: text.body,
        scheduledDate: tz.TZDateTime.from(plan.fireAt, tz.local),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            visibility: hideNames
                ? NotificationVisibility.private
                : NotificationVisibility.public,
          ),
        ),
        androidScheduleMode: mode,
      );
    } catch (error) {
      _exactAllowed = false;
      debugPrint('精确闹钟不可用，改为不精确调度：$error');
      await _plugin.zonedSchedule(
        id: plan.notificationId,
        title: text.title,
        body: text.body,
        scheduledDate: tz.TZDateTime.from(plan.fireAt, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  /// 进程内到期检查（Windows）。
  Future<void> _deliverDue({required DateTime now}) async {
    final List<ReminderPlan> due = _planCache
        .where(
          (ReminderPlan plan) =>
              !plan.fireAt.isAfter(now) &&
              now.difference(plan.fireAt) <= kCatchUpWindow,
        )
        .toList();
    for (final ReminderPlan plan in due) {
      if (await database.reminderLogDao.hasNotified(
        plan.memberId,
        plan.periodStart,
      )) {
        continue;
      }
      await _deliver(plan);
    }
  }

  /// 启动补发：错过不超过 6 小时的提醒立刻补一条。
  Future<void> _catchUp({
    required List<Member> members,
    required Map<String, List<Period>> grouped,
    required PredictionConfig config,
    required int globalLead,
    required bool hideNames,
  }) async {
    final List<ReminderPlan> missed = missedReminders(
      members: members,
      periodsByMember: grouped,
      config: config,
      globalLeadDays: globalLead,
      now: DateTime.now(),
    );
    for (final ReminderPlan plan in missed) {
      if (await database.reminderLogDao.hasNotified(
        plan.memberId,
        plan.periodStart,
      )) {
        continue;
      }
      await _deliver(plan);
    }
  }

  Future<void> _deliver(ReminderPlan plan) async {
    final AppLocalizations l10n = await _localizations();
    final String name = await _nameOfId(plan.memberId);
    final bool hideNames =
        (await settings.all())[SettingKeys.notifyHideNames] == 'true';
    final ReminderText text = _textFor(
      l10n: l10n,
      memberName: name,
      periodStart: plan.periodStart,
      hideNames: hideNames,
    );
    await _plugin.show(
      id: plan.notificationId,
      title: text.title,
      body: text.body,
      notificationDetails: const NotificationDetails(
        windows: WindowsNotificationDetails(),
      ),
    );
    await database.reminderLogDao.markNotified(
      plan.memberId,
      plan.periodStart,
      Timestamps.now(),
    );
  }

  /// 提醒文案（§5.2）：标题固定，正文按「隐藏人名」开关切换。
  ReminderText _textFor({
    required AppLocalizations l10n,
    required String memberName,
    required String periodStart,
    required bool hideNames,
  }) {
    final Locale locale = _locale();
    return ReminderText(
      title: l10n.reminderTitle,
      body: hideNames
          ? l10n.reminderBodyNeutral
          : l10n.reminderBodyMember(
              memberName,
              _shortDate(locale, periodStart),
            ),
    );
  }

  Future<AppLocalizations> _localizations() async {
    final Locale locale = _locale();
    final Locale target = AppLocalizations.supportedLocales.firstWhere(
      (Locale candidate) => candidate.languageCode == locale.languageCode,
      orElse: () => AppLocalizations.supportedLocales.first,
    );
    return AppLocalizations.delegate.load(target);
  }

  Locale _locale() => PlatformDispatcher.instance.locale;

  String _shortDate(Locale locale, String isoDate) {
    final DateTime date = LocalDate.utcOf(isoDate);
    if (locale.languageCode == 'zh') {
      return '${date.month} 月 ${date.day} 日';
    }
    return '${date.month}/${date.day}';
  }

  String _nameOf(List<Member> members, String memberId) {
    for (final Member member in members) {
      if (member.id == memberId) {
        return member.name;
      }
    }
    return '';
  }

  Future<String> _nameOfId(String memberId) async {
    final Member? member = await members.byId(memberId);
    return member?.name ?? '';
  }
}

/// 通知标题与正文。
class ReminderText {
  const ReminderText({required this.title, required this.body});

  final String title;
  final String body;
}
