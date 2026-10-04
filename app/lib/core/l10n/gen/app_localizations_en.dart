// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Moonletter';

  @override
  String get tabCalendar => 'Calendar';

  @override
  String get tabProfiles => 'Profiles';

  @override
  String get tabSettings => 'Settings';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonRetry => 'Retry';

  @override
  String get calendarEmptyMonth => 'No records this month';

  @override
  String get calendarToday => 'Today';

  @override
  String calendarMonthLabel(int year, int month) {
    return '$month $year';
  }

  @override
  String get weekdayMon => 'Mo';

  @override
  String get weekdayTue => 'Tu';

  @override
  String get weekdayWed => 'We';

  @override
  String get weekdayThu => 'Th';

  @override
  String get weekdayFri => 'Fr';

  @override
  String get weekdaySat => 'Sa';

  @override
  String get weekdaySun => 'Su';

  @override
  String get calendarPrevMonth => 'Previous month';

  @override
  String get calendarNextMonth => 'Next month';

  @override
  String get calendarDayEmpty => 'No records this day';

  @override
  String get dayKindPeriod => 'Period';

  @override
  String get dayKindPredicted => 'Predicted period';

  @override
  String get dayKindOvulation => 'Ovulation';

  @override
  String get dayKindFertile => 'Fertile window';

  @override
  String get dayKindSafe => 'Safe';

  @override
  String get dayKindUnknown => 'No data';

  @override
  String dayPeriodDay(int day) {
    return 'Day $day of period';
  }

  @override
  String dayPredictedPeriodDay(int day) {
    return 'Predicted day $day of period';
  }

  @override
  String get profilesEmpty => 'No members yet';

  @override
  String get profilesAdd => 'Add member';

  @override
  String get memberAddTitle => 'Add member';

  @override
  String get memberEditTitle => 'Edit member';

  @override
  String get memberDetailInfo => 'Details';

  @override
  String get memberDetailCycle => 'Cycle';

  @override
  String get memberDetailReminder => 'Reminder';

  @override
  String get memberDetailRecords => 'Period records';

  @override
  String get memberDetailPredictNext => 'Next start';

  @override
  String get memberDetailPredictOvulation => 'Ovulation';

  @override
  String get memberDetailPredictFertile => 'Fertile window';

  @override
  String get periodOngoingLabel => 'Ongoing';

  @override
  String get reminderTitle => 'Period reminder';

  @override
  String reminderBodyMember(String name, String date) {
    return '$name expected to start $date';
  }

  @override
  String get reminderBodyNeutral => 'Period approaching, take care';

  @override
  String get memberDetailCalendar => 'Personal calendar';

  @override
  String get memberRecordsEmpty => 'No period records yet';

  @override
  String get memberRecordsAdd => 'Add record';

  @override
  String get memberDeleteTitle => 'Delete member';

  @override
  String get memberDeleteMessage =>
      'This member and her period records will be removed from this device.';

  @override
  String get memberName => 'Name';

  @override
  String get memberNameRequired => 'Enter a name';

  @override
  String get memberAge => 'Age';

  @override
  String get memberHeight => 'Height';

  @override
  String get memberWeight => 'Weight';

  @override
  String get memberNote => 'Note';

  @override
  String get memberAvatar => 'Photo';

  @override
  String get memberAvatarPick => 'Choose photo';

  @override
  String get memberAvatarClear => 'Remove photo';

  @override
  String get memberCycleDays => 'Cycle length';

  @override
  String get memberPeriodDays => 'Period length';

  @override
  String get memberLastStart => 'Last start date';

  @override
  String get memberReminderLead => 'Remind ahead';

  @override
  String get memberReminderFollowGlobal => 'Follow global';

  @override
  String get memberAgeRange => 'Age must be between 0 and 120';

  @override
  String get memberCycleRange => 'Cycle length must be between 15 and 60';

  @override
  String get memberPeriodRange => 'Period length must be between 1 and 15';

  @override
  String memberStatusPeriod(int day) {
    return 'Day $day of period';
  }

  @override
  String memberStatusUpcoming(int days) {
    return '$days days to next';
  }

  @override
  String memberStatusLate(int days) {
    return '$days days late';
  }

  @override
  String get memberStatusNoRecords => 'No records yet';

  @override
  String get periodAddTitle => 'Add period';

  @override
  String get periodEditTitle => 'Edit period';

  @override
  String get periodStartLabel => 'Start date';

  @override
  String get periodEndLabel => 'End date (optional)';

  @override
  String get periodStartRequired => 'Choose a start date';

  @override
  String get periodEndBeforeStart =>
      'End date cannot be earlier than start date';

  @override
  String get unitCm => 'cm';

  @override
  String get unitKg => 'kg';

  @override
  String unitDay(int days) {
    return '$days days';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsDebugDatabase => 'Database file';

  @override
  String get settingsDebugRows => 'Table rows';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsReminderLead => 'Global lead days';

  @override
  String get settingsReminderHideNames => 'Hide names in notifications';

  @override
  String get settingsReminderPermission => 'Permissions';

  @override
  String get settingsReminderNotifications => 'Notification permission';

  @override
  String get settingsReminderExactAlarms => 'Exact alarms';

  @override
  String get settingsReminderBattery => 'Battery optimization';

  @override
  String get settingsReminderBatteryHint =>
      'If reminders are late, allow the app to run in the background';

  @override
  String get settingsReminderAutostartHint =>
      'Some systems need autostart enabled for reminders to survive a reboot';

  @override
  String get settingsReminderWindowsHint =>
      'Reminders stop when the app is closed';

  @override
  String get settingsReminderAllowed => 'Allowed';

  @override
  String get settingsReminderNotAllowed => 'Not allowed';

  @override
  String get settingsReminderNone => 'No members to remind';

  @override
  String get commonOn => 'On';

  @override
  String get commonOff => 'Off';

  @override
  String get lockUnlockTitle => 'Unlock';

  @override
  String get lockEnterPin => 'Enter your 6-digit PIN';

  @override
  String get lockWrongPin => 'Wrong PIN';

  @override
  String lockCooldown(int seconds) {
    return 'Try again in $seconds seconds';
  }

  @override
  String get lockUseBiometrics => 'Unlock with biometrics';

  @override
  String get lockLocked => 'Locked';

  @override
  String get lockSetPin => 'Choose a 6-digit PIN';

  @override
  String get lockConfirmPin => 'Enter it again';

  @override
  String get lockPinMismatch => 'PINs do not match';

  @override
  String get lockChangePin => 'Change PIN';

  @override
  String get lockDisable => 'Turn off app lock';

  @override
  String get lockDisableConfirm => 'The app will open without unlocking.';

  @override
  String get lockHintImmediate =>
      'The app locks and hides content when it goes to the background';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get settingsAppLock => 'App lock';

  @override
  String get settingsBiometric => 'Biometric unlock';

  @override
  String get settingsGeneral => 'General';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsThemeMode => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeColor => 'Accent color';

  @override
  String get settingsBlur => 'Interface blur';

  @override
  String get settingsBlurHint => 'Turn off on low-end devices';

  @override
  String get settingsPrediction => 'Prediction';

  @override
  String get settingsPredictionWindow => 'Records averaged';

  @override
  String get settingsPredictionFallbackCycle => 'Default cycle length';

  @override
  String get settingsPredictionFallbackPeriod => 'Default period length';

  @override
  String get settingsPredictionOvulationOffset => 'Ovulation offset';

  @override
  String get settingsPredictionFertileBefore => 'Fertile window before';

  @override
  String get settingsPredictionFertileAfter => 'Fertile window after';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsLicense => 'License';

  @override
  String get settingsRepository => 'Repository';

  @override
  String get settingsDisclaimer =>
      'Predictions are estimates only and must not be used as contraception or medical advice.';

  @override
  String get settingsWindows => 'Windows';

  @override
  String get settingsAutostart => 'Launch at startup';

  @override
  String get settingsCloseToTray => 'Close to tray';

  @override
  String get settingsUpdate => 'Updates';

  @override
  String get settingsAutoCheckUpdate => 'Check for updates on start';

  @override
  String get settingsCheckUpdate => 'Check now';

  @override
  String settingsUpdateAvailable(String version) {
    return 'Version $version is available';
  }

  @override
  String get settingsUpToDate => 'You are up to date';

  @override
  String get settingsUpdateFailed => 'Could not check for updates';

  @override
  String get settingsUpdateOpen => 'Open download page';

  @override
  String get settingsData => 'Data';

  @override
  String get settingsImportExport => 'Import and export';

  @override
  String get accentRose => 'Rose';

  @override
  String get accentPeach => 'Peach';

  @override
  String get accentAmber => 'Amber';

  @override
  String get accentMoss => 'Moss';

  @override
  String get accentMint => 'Mint';

  @override
  String get accentMist => 'Mist';

  @override
  String get accentLavender => 'Lavender';

  @override
  String get accentGraphite => 'Graphite';

  @override
  String get dataExportJson => 'Export data (JSON)';

  @override
  String get dataExportCsv => 'Export periods (CSV)';

  @override
  String get dataImport => 'Import data';

  @override
  String get dataExportCancelled => 'Cancelled';

  @override
  String dataExportedMembers(int count) {
    return 'Exported $count members';
  }

  @override
  String dataExportedPeriods(int count) {
    return 'Exported $count records';
  }

  @override
  String dataImportedRecords(int count) {
    return 'Imported $count records';
  }

  @override
  String get dataExportFailed => 'Export failed';

  @override
  String get dataImportFailed => 'Import failed';

  @override
  String get syncTitle => 'Cloud sync';

  @override
  String get syncEnabled => 'Enable sync';

  @override
  String get syncBackend => 'Backend';

  @override
  String get syncBackendWebdav => 'WebDAV';

  @override
  String get syncBackendRelay => 'Relay service';

  @override
  String get syncWebdavUrl => 'Server URL';

  @override
  String get syncWebdavUser => 'Username';

  @override
  String get syncWebdavPassword => 'Password';

  @override
  String get syncWebdavDir => 'Folder';

  @override
  String get syncRelayUrl => 'Server URL';

  @override
  String get syncNamespace => 'Sync ID';

  @override
  String get syncPassphrase => 'Passphrase';

  @override
  String get syncPassphraseSet => 'Set passphrase';

  @override
  String get syncPassphraseWarn =>
      'The passphrase stays on this device and is never uploaded. If it is lost, the uploaded data cannot be decrypted or recovered.';

  @override
  String get syncNow => 'Sync now';

  @override
  String get syncLastAt => 'Last sync';

  @override
  String get syncNever => 'Never synced';

  @override
  String get syncReset => 'Reset sync';

  @override
  String get syncResetConfirm =>
      'This clears remote data and the local key; you must set the passphrase again.';
}
