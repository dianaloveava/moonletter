import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('zh'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'月信'**
  String get appTitle;

  /// No description provided for @tabCalendar.
  ///
  /// In zh, this message translates to:
  /// **'日历'**
  String get tabCalendar;

  /// No description provided for @tabProfiles.
  ///
  /// In zh, this message translates to:
  /// **'档案'**
  String get tabProfiles;

  /// No description provided for @tabSettings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get tabSettings;

  /// No description provided for @commonCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get commonDelete;

  /// No description provided for @commonRetry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get commonRetry;

  /// No description provided for @calendarEmptyMonth.
  ///
  /// In zh, this message translates to:
  /// **'本月没有记录'**
  String get calendarEmptyMonth;

  /// No description provided for @calendarToday.
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get calendarToday;

  /// No description provided for @calendarMonthLabel.
  ///
  /// In zh, this message translates to:
  /// **'{year} 年 {month} 月'**
  String calendarMonthLabel(int year, int month);

  /// No description provided for @weekdayMon.
  ///
  /// In zh, this message translates to:
  /// **'一'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In zh, this message translates to:
  /// **'二'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In zh, this message translates to:
  /// **'三'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In zh, this message translates to:
  /// **'四'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In zh, this message translates to:
  /// **'五'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In zh, this message translates to:
  /// **'六'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In zh, this message translates to:
  /// **'日'**
  String get weekdaySun;

  /// No description provided for @calendarPrevMonth.
  ///
  /// In zh, this message translates to:
  /// **'上个月'**
  String get calendarPrevMonth;

  /// No description provided for @calendarNextMonth.
  ///
  /// In zh, this message translates to:
  /// **'下个月'**
  String get calendarNextMonth;

  /// No description provided for @calendarDayEmpty.
  ///
  /// In zh, this message translates to:
  /// **'这一天没有记录'**
  String get calendarDayEmpty;

  /// No description provided for @dayKindPeriod.
  ///
  /// In zh, this message translates to:
  /// **'经期'**
  String get dayKindPeriod;

  /// No description provided for @dayKindPredicted.
  ///
  /// In zh, this message translates to:
  /// **'预计经期'**
  String get dayKindPredicted;

  /// No description provided for @dayKindOvulation.
  ///
  /// In zh, this message translates to:
  /// **'排卵日'**
  String get dayKindOvulation;

  /// No description provided for @dayKindFertile.
  ///
  /// In zh, this message translates to:
  /// **'危险期'**
  String get dayKindFertile;

  /// No description provided for @dayKindSafe.
  ///
  /// In zh, this message translates to:
  /// **'安全期'**
  String get dayKindSafe;

  /// No description provided for @dayKindUnknown.
  ///
  /// In zh, this message translates to:
  /// **'无记录'**
  String get dayKindUnknown;

  /// No description provided for @dayPeriodDay.
  ///
  /// In zh, this message translates to:
  /// **'经期第 {day} 天'**
  String dayPeriodDay(int day);

  /// No description provided for @dayPredictedPeriodDay.
  ///
  /// In zh, this message translates to:
  /// **'预计经期第 {day} 天'**
  String dayPredictedPeriodDay(int day);

  /// No description provided for @profilesEmpty.
  ///
  /// In zh, this message translates to:
  /// **'还没有成员'**
  String get profilesEmpty;

  /// No description provided for @profilesAdd.
  ///
  /// In zh, this message translates to:
  /// **'添加成员'**
  String get profilesAdd;

  /// No description provided for @memberAddTitle.
  ///
  /// In zh, this message translates to:
  /// **'添加成员'**
  String get memberAddTitle;

  /// No description provided for @memberEditTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑成员'**
  String get memberEditTitle;

  /// No description provided for @memberDetailInfo.
  ///
  /// In zh, this message translates to:
  /// **'基本信息'**
  String get memberDetailInfo;

  /// No description provided for @memberDetailCycle.
  ///
  /// In zh, this message translates to:
  /// **'周期设置'**
  String get memberDetailCycle;

  /// No description provided for @memberDetailReminder.
  ///
  /// In zh, this message translates to:
  /// **'提醒'**
  String get memberDetailReminder;

  /// No description provided for @memberDetailRecords.
  ///
  /// In zh, this message translates to:
  /// **'经期记录'**
  String get memberDetailRecords;

  /// No description provided for @memberDetailPredictNext.
  ///
  /// In zh, this message translates to:
  /// **'下次预计开始'**
  String get memberDetailPredictNext;

  /// No description provided for @memberDetailPredictOvulation.
  ///
  /// In zh, this message translates to:
  /// **'排卵日'**
  String get memberDetailPredictOvulation;

  /// No description provided for @memberDetailPredictFertile.
  ///
  /// In zh, this message translates to:
  /// **'危险期'**
  String get memberDetailPredictFertile;

  /// No description provided for @periodOngoingLabel.
  ///
  /// In zh, this message translates to:
  /// **'进行中'**
  String get periodOngoingLabel;

  /// No description provided for @reminderTitle.
  ///
  /// In zh, this message translates to:
  /// **'经期提醒'**
  String get reminderTitle;

  /// No description provided for @reminderBodyMember.
  ///
  /// In zh, this message translates to:
  /// **'{name} 预计 {date} 开始'**
  String reminderBodyMember(String name, String date);

  /// No description provided for @reminderBodyNeutral.
  ///
  /// In zh, this message translates to:
  /// **'经期将至，注意身体'**
  String get reminderBodyNeutral;

  /// No description provided for @memberDetailCalendar.
  ///
  /// In zh, this message translates to:
  /// **'个人日历'**
  String get memberDetailCalendar;

  /// No description provided for @memberRecordsEmpty.
  ///
  /// In zh, this message translates to:
  /// **'还没有经期记录'**
  String get memberRecordsEmpty;

  /// No description provided for @memberRecordsAdd.
  ///
  /// In zh, this message translates to:
  /// **'添加记录'**
  String get memberRecordsAdd;

  /// No description provided for @memberDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除成员'**
  String get memberDeleteTitle;

  /// No description provided for @memberDeleteMessage.
  ///
  /// In zh, this message translates to:
  /// **'该成员与她的经期记录会从本机移除。'**
  String get memberDeleteMessage;

  /// No description provided for @memberName.
  ///
  /// In zh, this message translates to:
  /// **'昵称'**
  String get memberName;

  /// No description provided for @memberNameRequired.
  ///
  /// In zh, this message translates to:
  /// **'请填写昵称'**
  String get memberNameRequired;

  /// No description provided for @memberAge.
  ///
  /// In zh, this message translates to:
  /// **'年龄'**
  String get memberAge;

  /// No description provided for @memberHeight.
  ///
  /// In zh, this message translates to:
  /// **'身高'**
  String get memberHeight;

  /// No description provided for @memberWeight.
  ///
  /// In zh, this message translates to:
  /// **'体重'**
  String get memberWeight;

  /// No description provided for @memberNote.
  ///
  /// In zh, this message translates to:
  /// **'描述'**
  String get memberNote;

  /// No description provided for @memberAvatar.
  ///
  /// In zh, this message translates to:
  /// **'头像'**
  String get memberAvatar;

  /// No description provided for @memberAvatarPick.
  ///
  /// In zh, this message translates to:
  /// **'选择照片'**
  String get memberAvatarPick;

  /// No description provided for @memberAvatarClear.
  ///
  /// In zh, this message translates to:
  /// **'移除照片'**
  String get memberAvatarClear;

  /// No description provided for @memberCycleDays.
  ///
  /// In zh, this message translates to:
  /// **'周期天数'**
  String get memberCycleDays;

  /// No description provided for @memberPeriodDays.
  ///
  /// In zh, this message translates to:
  /// **'经期天数'**
  String get memberPeriodDays;

  /// No description provided for @memberLastStart.
  ///
  /// In zh, this message translates to:
  /// **'最近一次开始日期'**
  String get memberLastStart;

  /// No description provided for @memberReminderLead.
  ///
  /// In zh, this message translates to:
  /// **'提醒提前'**
  String get memberReminderLead;

  /// No description provided for @memberReminderFollowGlobal.
  ///
  /// In zh, this message translates to:
  /// **'跟随全局'**
  String get memberReminderFollowGlobal;

  /// No description provided for @memberAgeRange.
  ///
  /// In zh, this message translates to:
  /// **'年龄需在 0 到 120 之间'**
  String get memberAgeRange;

  /// No description provided for @memberCycleRange.
  ///
  /// In zh, this message translates to:
  /// **'周期天数需在 15 到 60 之间'**
  String get memberCycleRange;

  /// No description provided for @memberPeriodRange.
  ///
  /// In zh, this message translates to:
  /// **'经期天数需在 1 到 15 之间'**
  String get memberPeriodRange;

  /// No description provided for @memberStatusPeriod.
  ///
  /// In zh, this message translates to:
  /// **'经期第 {day} 天'**
  String memberStatusPeriod(int day);

  /// No description provided for @memberStatusUpcoming.
  ///
  /// In zh, this message translates to:
  /// **'距下次 {days} 天'**
  String memberStatusUpcoming(int days);

  /// No description provided for @memberStatusLate.
  ///
  /// In zh, this message translates to:
  /// **'已推迟 {days} 天'**
  String memberStatusLate(int days);

  /// No description provided for @memberStatusNoRecords.
  ///
  /// In zh, this message translates to:
  /// **'还没有记录'**
  String get memberStatusNoRecords;

  /// No description provided for @periodAddTitle.
  ///
  /// In zh, this message translates to:
  /// **'添加经期'**
  String get periodAddTitle;

  /// No description provided for @periodEditTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑经期'**
  String get periodEditTitle;

  /// No description provided for @periodStartLabel.
  ///
  /// In zh, this message translates to:
  /// **'开始日'**
  String get periodStartLabel;

  /// No description provided for @periodEndLabel.
  ///
  /// In zh, this message translates to:
  /// **'结束日（可留空）'**
  String get periodEndLabel;

  /// No description provided for @periodStartRequired.
  ///
  /// In zh, this message translates to:
  /// **'请选择开始日期'**
  String get periodStartRequired;

  /// No description provided for @periodEndBeforeStart.
  ///
  /// In zh, this message translates to:
  /// **'结束日不能早于开始日'**
  String get periodEndBeforeStart;

  /// No description provided for @unitCm.
  ///
  /// In zh, this message translates to:
  /// **'厘米'**
  String get unitCm;

  /// No description provided for @unitKg.
  ///
  /// In zh, this message translates to:
  /// **'千克'**
  String get unitKg;

  /// No description provided for @unitDay.
  ///
  /// In zh, this message translates to:
  /// **'{days} 天'**
  String unitDay(int days);

  /// No description provided for @settingsTitle.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settingsTitle;

  /// No description provided for @settingsAbout.
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get settingsAbout;

  /// No description provided for @settingsDebugDatabase.
  ///
  /// In zh, this message translates to:
  /// **'数据库文件'**
  String get settingsDebugDatabase;

  /// No description provided for @settingsDebugRows.
  ///
  /// In zh, this message translates to:
  /// **'数据表行数'**
  String get settingsDebugRows;

  /// No description provided for @settingsNotifications.
  ///
  /// In zh, this message translates to:
  /// **'提醒设置'**
  String get settingsNotifications;

  /// No description provided for @settingsReminderLead.
  ///
  /// In zh, this message translates to:
  /// **'全局提前天数'**
  String get settingsReminderLead;

  /// No description provided for @settingsReminderHideNames.
  ///
  /// In zh, this message translates to:
  /// **'通知不显示人名'**
  String get settingsReminderHideNames;

  /// No description provided for @settingsReminderPermission.
  ///
  /// In zh, this message translates to:
  /// **'权限'**
  String get settingsReminderPermission;

  /// No description provided for @settingsReminderNotifications.
  ///
  /// In zh, this message translates to:
  /// **'通知权限'**
  String get settingsReminderNotifications;

  /// No description provided for @settingsReminderExactAlarms.
  ///
  /// In zh, this message translates to:
  /// **'精确闹钟'**
  String get settingsReminderExactAlarms;

  /// No description provided for @settingsReminderBattery.
  ///
  /// In zh, this message translates to:
  /// **'电池优化'**
  String get settingsReminderBattery;

  /// No description provided for @settingsReminderBatteryHint.
  ///
  /// In zh, this message translates to:
  /// **'提醒不准时，把本应用加入电池优化白名单'**
  String get settingsReminderBatteryHint;

  /// No description provided for @settingsReminderAutostartHint.
  ///
  /// In zh, this message translates to:
  /// **'部分系统需要允许自启动，重启后提醒才有效'**
  String get settingsReminderAutostartHint;

  /// No description provided for @settingsReminderWindowsHint.
  ///
  /// In zh, this message translates to:
  /// **'关闭程序后不会收到提醒'**
  String get settingsReminderWindowsHint;

  /// No description provided for @settingsReminderAllowed.
  ///
  /// In zh, this message translates to:
  /// **'已允许'**
  String get settingsReminderAllowed;

  /// No description provided for @settingsReminderNotAllowed.
  ///
  /// In zh, this message translates to:
  /// **'未允许'**
  String get settingsReminderNotAllowed;

  /// No description provided for @settingsReminderNone.
  ///
  /// In zh, this message translates to:
  /// **'没有需要设置的成员'**
  String get settingsReminderNone;

  /// No description provided for @commonOn.
  ///
  /// In zh, this message translates to:
  /// **'开'**
  String get commonOn;

  /// No description provided for @commonOff.
  ///
  /// In zh, this message translates to:
  /// **'关'**
  String get commonOff;

  /// No description provided for @lockUnlockTitle.
  ///
  /// In zh, this message translates to:
  /// **'解锁'**
  String get lockUnlockTitle;

  /// No description provided for @lockEnterPin.
  ///
  /// In zh, this message translates to:
  /// **'输入 6 位 PIN'**
  String get lockEnterPin;

  /// No description provided for @lockWrongPin.
  ///
  /// In zh, this message translates to:
  /// **'PIN 不正确'**
  String get lockWrongPin;

  /// No description provided for @lockCooldown.
  ///
  /// In zh, this message translates to:
  /// **'请 {seconds} 秒后再试'**
  String lockCooldown(int seconds);

  /// No description provided for @lockUseBiometrics.
  ///
  /// In zh, this message translates to:
  /// **'用生物识别解锁'**
  String get lockUseBiometrics;

  /// No description provided for @lockLocked.
  ///
  /// In zh, this message translates to:
  /// **'已锁定'**
  String get lockLocked;

  /// No description provided for @lockSetPin.
  ///
  /// In zh, this message translates to:
  /// **'设置 6 位 PIN'**
  String get lockSetPin;

  /// No description provided for @lockConfirmPin.
  ///
  /// In zh, this message translates to:
  /// **'再输一次'**
  String get lockConfirmPin;

  /// No description provided for @lockPinMismatch.
  ///
  /// In zh, this message translates to:
  /// **'两次输入不一致'**
  String get lockPinMismatch;

  /// No description provided for @lockChangePin.
  ///
  /// In zh, this message translates to:
  /// **'修改 PIN'**
  String get lockChangePin;

  /// No description provided for @lockDisable.
  ///
  /// In zh, this message translates to:
  /// **'关闭应用锁'**
  String get lockDisable;

  /// No description provided for @lockDisableConfirm.
  ///
  /// In zh, this message translates to:
  /// **'关闭后打开应用不再需要解锁。'**
  String get lockDisableConfirm;

  /// No description provided for @lockHintImmediate.
  ///
  /// In zh, this message translates to:
  /// **'切到后台会立即锁定并隐藏内容'**
  String get lockHintImmediate;

  /// No description provided for @settingsPrivacy.
  ///
  /// In zh, this message translates to:
  /// **'隐私'**
  String get settingsPrivacy;

  /// No description provided for @settingsAppLock.
  ///
  /// In zh, this message translates to:
  /// **'应用锁'**
  String get settingsAppLock;

  /// No description provided for @settingsBiometric.
  ///
  /// In zh, this message translates to:
  /// **'生物识别解锁'**
  String get settingsBiometric;

  /// No description provided for @settingsGeneral.
  ///
  /// In zh, this message translates to:
  /// **'通用'**
  String get settingsGeneral;

  /// No description provided for @settingsLanguage.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsAppearance.
  ///
  /// In zh, this message translates to:
  /// **'外观'**
  String get settingsAppearance;

  /// No description provided for @settingsThemeMode.
  ///
  /// In zh, this message translates to:
  /// **'主题模式'**
  String get settingsThemeMode;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In zh, this message translates to:
  /// **'浅色'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In zh, this message translates to:
  /// **'深色'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeColor.
  ///
  /// In zh, this message translates to:
  /// **'主题色'**
  String get settingsThemeColor;

  /// No description provided for @settingsBlur.
  ///
  /// In zh, this message translates to:
  /// **'界面模糊效果'**
  String get settingsBlur;

  /// No description provided for @settingsBlurHint.
  ///
  /// In zh, this message translates to:
  /// **'低端设备建议关闭'**
  String get settingsBlurHint;

  /// No description provided for @settingsPrediction.
  ///
  /// In zh, this message translates to:
  /// **'预测规则'**
  String get settingsPrediction;

  /// No description provided for @settingsPredictionWindow.
  ///
  /// In zh, this message translates to:
  /// **'参与平均的记录条数'**
  String get settingsPredictionWindow;

  /// No description provided for @settingsPredictionFallbackCycle.
  ///
  /// In zh, this message translates to:
  /// **'默认周期天数'**
  String get settingsPredictionFallbackCycle;

  /// No description provided for @settingsPredictionFallbackPeriod.
  ///
  /// In zh, this message translates to:
  /// **'默认经期天数'**
  String get settingsPredictionFallbackPeriod;

  /// No description provided for @settingsPredictionOvulationOffset.
  ///
  /// In zh, this message translates to:
  /// **'排卵日提前天数'**
  String get settingsPredictionOvulationOffset;

  /// No description provided for @settingsPredictionFertileBefore.
  ///
  /// In zh, this message translates to:
  /// **'危险期提前天数'**
  String get settingsPredictionFertileBefore;

  /// No description provided for @settingsPredictionFertileAfter.
  ///
  /// In zh, this message translates to:
  /// **'危险期延后天数'**
  String get settingsPredictionFertileAfter;

  /// No description provided for @settingsVersion.
  ///
  /// In zh, this message translates to:
  /// **'版本'**
  String get settingsVersion;

  /// No description provided for @settingsLicense.
  ///
  /// In zh, this message translates to:
  /// **'开源协议'**
  String get settingsLicense;

  /// No description provided for @settingsRepository.
  ///
  /// In zh, this message translates to:
  /// **'仓库'**
  String get settingsRepository;

  /// No description provided for @settingsDisclaimer.
  ///
  /// In zh, this message translates to:
  /// **'预测结果仅供参考，不能作为避孕或医疗依据。'**
  String get settingsDisclaimer;

  /// No description provided for @settingsWindows.
  ///
  /// In zh, this message translates to:
  /// **'Windows'**
  String get settingsWindows;

  /// No description provided for @settingsAutostart.
  ///
  /// In zh, this message translates to:
  /// **'开机自启'**
  String get settingsAutostart;

  /// No description provided for @settingsCloseToTray.
  ///
  /// In zh, this message translates to:
  /// **'关闭窗口最小化到托盘'**
  String get settingsCloseToTray;

  /// No description provided for @settingsUpdate.
  ///
  /// In zh, this message translates to:
  /// **'自动更新'**
  String get settingsUpdate;

  /// No description provided for @settingsAutoCheckUpdate.
  ///
  /// In zh, this message translates to:
  /// **'启动时检查更新'**
  String get settingsAutoCheckUpdate;

  /// No description provided for @settingsCheckUpdate.
  ///
  /// In zh, this message translates to:
  /// **'检查更新'**
  String get settingsCheckUpdate;

  /// No description provided for @settingsUpdateAvailable.
  ///
  /// In zh, this message translates to:
  /// **'发现新版本 {version}'**
  String settingsUpdateAvailable(String version);

  /// No description provided for @settingsUpToDate.
  ///
  /// In zh, this message translates to:
  /// **'已是最新版本'**
  String get settingsUpToDate;

  /// No description provided for @settingsUpdateFailed.
  ///
  /// In zh, this message translates to:
  /// **'检查更新失败'**
  String get settingsUpdateFailed;

  /// No description provided for @settingsUpdateOpen.
  ///
  /// In zh, this message translates to:
  /// **'打开下载页'**
  String get settingsUpdateOpen;

  /// No description provided for @settingsData.
  ///
  /// In zh, this message translates to:
  /// **'数据'**
  String get settingsData;

  /// No description provided for @settingsImportExport.
  ///
  /// In zh, this message translates to:
  /// **'导入导出'**
  String get settingsImportExport;

  /// No description provided for @accentRose.
  ///
  /// In zh, this message translates to:
  /// **'玫瑰'**
  String get accentRose;

  /// No description provided for @accentPeach.
  ///
  /// In zh, this message translates to:
  /// **'蜜桃'**
  String get accentPeach;

  /// No description provided for @accentAmber.
  ///
  /// In zh, this message translates to:
  /// **'琥珀'**
  String get accentAmber;

  /// No description provided for @accentMoss.
  ///
  /// In zh, this message translates to:
  /// **'苔绿'**
  String get accentMoss;

  /// No description provided for @accentMint.
  ///
  /// In zh, this message translates to:
  /// **'薄荷'**
  String get accentMint;

  /// No description provided for @accentMist.
  ///
  /// In zh, this message translates to:
  /// **'雾蓝'**
  String get accentMist;

  /// No description provided for @accentLavender.
  ///
  /// In zh, this message translates to:
  /// **'薰衣草'**
  String get accentLavender;

  /// No description provided for @accentGraphite.
  ///
  /// In zh, this message translates to:
  /// **'石墨'**
  String get accentGraphite;

  /// No description provided for @dataExportJson.
  ///
  /// In zh, this message translates to:
  /// **'导出数据（JSON）'**
  String get dataExportJson;

  /// No description provided for @dataExportCsv.
  ///
  /// In zh, this message translates to:
  /// **'导出经期（CSV）'**
  String get dataExportCsv;

  /// No description provided for @dataImport.
  ///
  /// In zh, this message translates to:
  /// **'导入数据'**
  String get dataImport;

  /// No description provided for @dataExportCancelled.
  ///
  /// In zh, this message translates to:
  /// **'已取消'**
  String get dataExportCancelled;

  /// No description provided for @dataExportedMembers.
  ///
  /// In zh, this message translates to:
  /// **'已导出 {count} 个成员'**
  String dataExportedMembers(int count);

  /// No description provided for @dataExportedPeriods.
  ///
  /// In zh, this message translates to:
  /// **'已导出 {count} 条经期记录'**
  String dataExportedPeriods(int count);

  /// No description provided for @dataImportedRecords.
  ///
  /// In zh, this message translates to:
  /// **'已导入 {count} 条记录'**
  String dataImportedRecords(int count);

  /// No description provided for @dataExportFailed.
  ///
  /// In zh, this message translates to:
  /// **'导出失败'**
  String get dataExportFailed;

  /// No description provided for @dataImportFailed.
  ///
  /// In zh, this message translates to:
  /// **'导入失败'**
  String get dataImportFailed;

  /// No description provided for @syncTitle.
  ///
  /// In zh, this message translates to:
  /// **'云同步'**
  String get syncTitle;

  /// No description provided for @syncEnabled.
  ///
  /// In zh, this message translates to:
  /// **'启用同步'**
  String get syncEnabled;

  /// No description provided for @syncBackend.
  ///
  /// In zh, this message translates to:
  /// **'同步方式'**
  String get syncBackend;

  /// No description provided for @syncBackendWebdav.
  ///
  /// In zh, this message translates to:
  /// **'WebDAV'**
  String get syncBackendWebdav;

  /// No description provided for @syncBackendRelay.
  ///
  /// In zh, this message translates to:
  /// **'中转服务'**
  String get syncBackendRelay;

  /// No description provided for @syncWebdavUrl.
  ///
  /// In zh, this message translates to:
  /// **'服务地址'**
  String get syncWebdavUrl;

  /// No description provided for @syncWebdavUser.
  ///
  /// In zh, this message translates to:
  /// **'用户名'**
  String get syncWebdavUser;

  /// No description provided for @syncWebdavPassword.
  ///
  /// In zh, this message translates to:
  /// **'密码'**
  String get syncWebdavPassword;

  /// No description provided for @syncWebdavDir.
  ///
  /// In zh, this message translates to:
  /// **'子目录'**
  String get syncWebdavDir;

  /// No description provided for @syncRelayUrl.
  ///
  /// In zh, this message translates to:
  /// **'服务地址'**
  String get syncRelayUrl;

  /// No description provided for @syncNamespace.
  ///
  /// In zh, this message translates to:
  /// **'同步 ID'**
  String get syncNamespace;

  /// No description provided for @syncPassphrase.
  ///
  /// In zh, this message translates to:
  /// **'口令'**
  String get syncPassphrase;

  /// No description provided for @syncPassphraseSet.
  ///
  /// In zh, this message translates to:
  /// **'设置口令'**
  String get syncPassphraseSet;

  /// No description provided for @syncPassphraseWarn.
  ///
  /// In zh, this message translates to:
  /// **'口令只保存在本机且不上传。丢失后无法解密已上传的数据，也无法找回。'**
  String get syncPassphraseWarn;

  /// No description provided for @syncNow.
  ///
  /// In zh, this message translates to:
  /// **'立即同步'**
  String get syncNow;

  /// No description provided for @syncLastAt.
  ///
  /// In zh, this message translates to:
  /// **'上次同步'**
  String get syncLastAt;

  /// No description provided for @syncNever.
  ///
  /// In zh, this message translates to:
  /// **'还没有同步过'**
  String get syncNever;

  /// No description provided for @syncReset.
  ///
  /// In zh, this message translates to:
  /// **'重置同步'**
  String get syncReset;

  /// No description provided for @syncResetConfirm.
  ///
  /// In zh, this message translates to:
  /// **'会清空远端数据并删除本机保存的密钥，需要重新设置口令。'**
  String get syncResetConfirm;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
