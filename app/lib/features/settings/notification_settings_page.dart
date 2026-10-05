import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../core/platform/android_platform.dart';
import '../../core/theme/tokens.dart';
import '../../data/data_providers.dart';
import '../../data/db/tables.dart';
import '../../domain/reminder/reminder_providers.dart';
import '../../widgets/grouped_list.dart';
import '../../widgets/page_frame.dart';
import '../../widgets/squircle.dart';

/// 提醒设置：全局提前天数、隐藏人名开关、Android 权限引导、Windows 说明。
class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends ConsumerState<NotificationSettingsPage> {
  bool _notificationsAllowed = false;
  bool _exactAllowed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final runner = ref.read(reminderRunnerProvider);
    final bool notifications = await runner.requestPermission();
    final bool exact = await runner.requestExactAlarms();
    if (mounted) {
      setState(() {
        _notificationsAllowed = notifications;
        _exactAllowed = exact;
      });
    }
  }

  Future<void> _setLeadDays(int days) async {
    await ref
        .read(settingsRepositoryProvider)
        .setInt(SettingKeys.reminderGlobalLeadDays, days);
    await ref.read(reminderRunnerProvider).rescheduleAll();
  }

  Future<void> _setHideNames(bool value) async {
    await ref
        .read(settingsRepositoryProvider)
        .setBool(SettingKeys.notifyHideNames, value);
    await ref.read(reminderRunnerProvider).rescheduleAll();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppColors colors = context.colors;
    final AsyncValue<Map<String, String>> settingsAsync = ref.watch(
      settingsProvider,
    );
    final Map<String, String> settings = switch (settingsAsync) {
      AsyncData<Map<String, String>>(value: final Map<String, String> v) => v,
      _ => const <String, String>{},
    };
    final int lead =
        int.tryParse(settings[SettingKeys.reminderGlobalLeadDays] ?? '') ?? 3;
    final bool hideNames =
        (settings[SettingKeys.notifyHideNames] ?? 'false') == 'true';

    return Scaffold(
      backgroundColor: colors.bg,
      body: PageFrame(
        title: l10n.settingsNotifications,
        actions: <Widget>[
          IconButton(
            onPressed: () => context.go('/settings'),
            icon: const Icon(Icons.close),
            color: colors.textSecondary,
          ),
        ],
        child: ListView(
          padding: EdgeInsets.only(
            bottom: AppSpacing.x4 + MediaQuery.paddingOf(context).bottom,
          ),
          children: <Widget>[
            GroupedList(
              sections: <Widget>[
                GroupSection(
                  title: l10n.settingsNotifications,
                  rows: <Widget>[
                    GroupRow(
                      label: l10n.settingsReminderLead,
                      value: l10n.unitDay(lead),
                      onTap: () => _pickLeadDays(lead),
                    ),
                    GroupRow(
                      label: l10n.settingsReminderHideNames,
                      trailing: Switch(
                        value: hideNames,
                        activeThumbColor: colors.accent,
                        onChanged: _setHideNames,
                      ),
                    ),
                  ],
                ),
                if (AndroidPlatform.isAndroid)
                  GroupSection(
                    title: l10n.settingsReminderPermission,
                    footer: l10n.settingsReminderAutostartHint,
                    rows: <Widget>[
                      GroupRow(
                        label: l10n.settingsReminderNotifications,
                        value: _notificationsAllowed
                            ? l10n.settingsReminderAllowed
                            : l10n.settingsReminderNotAllowed,
                        onTap: _refresh,
                      ),
                      GroupRow(
                        label: l10n.settingsReminderExactAlarms,
                        value: _exactAllowed
                            ? l10n.settingsReminderAllowed
                            : l10n.settingsReminderNotAllowed,
                        onTap: _refresh,
                      ),
                      GroupRow(
                        label: l10n.settingsReminderBattery,
                        onTap: AndroidPlatform.openBatteryOptimizationSettings,
                      ),
                    ],
                  ),
                if (!AndroidPlatform.isAndroid)
                  GroupSection(
                    title: l10n.settingsReminderPermission,
                    footer: l10n.settingsReminderWindowsHint,
                    rows: <Widget>[
                      GroupRow(
                        label: l10n.settingsReminderNotifications,
                        value: l10n.settingsReminderAllowed,
                      ),
                    ],
                  ),
              ],
            ),
            if (AndroidPlatform.isAndroid) ...<Widget>[
              const SizedBox(height: AppSpacing.x2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x1),
                child: Text(
                  l10n.settingsReminderBatteryHint,
                  style: AppType.caption.copyWith(color: colors.textSecondary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickLeadDays(int current) async {
    final int? picked = await showModalBottomSheet<int>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        final AppColors colors = sheetContext.colors;
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(AppSpacing.x2),
            decoration: ShapeDecoration(
              color: colors.surface,
              shape: const SquircleBorder(radius: AppRadii.card),
            ),
            child: ListView(
              shrinkWrap: true,
              children: <Widget>[
                for (int days = 1; days <= 30; days++)
                  GroupRow(
                    label: '$days',
                    value: days == current ? '✓' : null,
                    onTap: () => Navigator.of(sheetContext).pop(days),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (picked != null) {
      await _setLeadDays(picked);
    }
  }
}
