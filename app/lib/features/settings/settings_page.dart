import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_info.dart';
import '../../core/app_settings_providers.dart';
import '../../core/l10n/gen/app_localizations.dart';
import '../../core/platform/windows_app_providers.dart';
import '../../core/theme/theme_providers.dart';
import '../../core/theme/tokens.dart';
import '../../data/data_providers.dart';
import '../../data/db/tables.dart';
import '../../domain/update/update_checker.dart';
import '../../widgets/grouped_list.dart';
import '../../widgets/page_frame.dart';
import '../../widgets/squircle.dart';

/// 应用版本号（关于页显示）。
final FutureProvider<String> appVersionProvider = FutureProvider<String>((
  Ref ref,
) async {
  final PackageInfo info = await PackageInfo.fromPlatform();
  return info.version;
});

/// 设置页：通用 / 预测规则 / 提醒 / 隐私 / 数据 / 关于 / Windows / 自动更新。
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppColors colors = context.colors;
    final Map<String, String> settings = switch (ref.watch(settingsProvider)) {
      AsyncData<Map<String, String>>(value: final Map<String, String> v) => v,
      _ => const <String, String>{},
    };
    final String version = ref.watch(appVersionProvider).value ?? '—';
    final DbStats? stats = switch (ref.watch(dbStatsProvider)) {
      AsyncData<DbStats>(value: final DbStats value) => value,
      _ => null,
    };

    return PageFrame(
      title: l10n.settingsTitle,
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.x4),
        children: <Widget>[
          GroupedList(
            sections: <Widget>[
              GroupSection(
                title: l10n.settingsGeneral,
                rows: <Widget>[
                  GroupRow(
                    label: l10n.settingsLanguage,
                    value: _languageLabel(l10n, ref.watch(localeProvider)),
                    onTap: () => _pickLanguage(context, ref),
                  ),
                  GroupRow(
                    label: l10n.settingsThemeMode,
                    value: _themeLabel(l10n, ref.watch(themeModeProvider)),
                    onTap: () => _pickThemeMode(context, ref),
                  ),
                  GroupRow(
                    label: l10n.settingsThemeColor,
                    value:
                        _accentNames(l10n)[ref.watch(accentProvider).id] ?? '',
                    trailing: _AccentSwatches(
                      selected: ref.watch(accentProvider),
                      onPick: (AppAccent accent) =>
                          ref.read(accentProvider.notifier).set(accent),
                    ),
                    onTap: () => _pickAccent(context, ref),
                  ),
                  GroupRow(
                    label: l10n.settingsBlur,
                    trailing: Switch(
                      value: ref.watch(blurEnabledProvider),
                      activeThumbColor: colors.accent,
                      onChanged: (bool value) =>
                          ref.read(blurEnabledProvider.notifier).set(value),
                    ),
                  ),
                ],
              ),
              GroupSection(
                title: l10n.settingsPrediction,
                rows: <Widget>[
                  GroupRow(
                    label: l10n.settingsPredictionWindow,
                    value: settings[SettingKeys.predictionWindow] ?? '6',
                    onTap: () => _pickNumber(
                      context,
                      ref,
                      key: SettingKeys.predictionWindow,
                      from: 2,
                      to: 12,
                    ),
                  ),
                  GroupRow(
                    label: l10n.settingsPredictionFallbackCycle,
                    value:
                        settings[SettingKeys.predictionFallbackCycle] ?? '28',
                    onTap: () => _pickNumber(
                      context,
                      ref,
                      key: SettingKeys.predictionFallbackCycle,
                      from: 15,
                      to: 60,
                    ),
                  ),
                  GroupRow(
                    label: l10n.settingsPredictionFallbackPeriod,
                    value:
                        settings[SettingKeys.predictionFallbackPeriod] ?? '5',
                    onTap: () => _pickNumber(
                      context,
                      ref,
                      key: SettingKeys.predictionFallbackPeriod,
                      from: 1,
                      to: 15,
                    ),
                  ),
                  GroupRow(
                    label: l10n.settingsPredictionOvulationOffset,
                    value:
                        settings[SettingKeys.predictionOvulationOffset] ?? '14',
                    onTap: () => _pickNumber(
                      context,
                      ref,
                      key: SettingKeys.predictionOvulationOffset,
                      from: 8,
                      to: 20,
                    ),
                  ),
                  GroupRow(
                    label: l10n.settingsPredictionFertileBefore,
                    value: settings[SettingKeys.predictionFertileBefore] ?? '5',
                    onTap: () => _pickNumber(
                      context,
                      ref,
                      key: SettingKeys.predictionFertileBefore,
                      from: 1,
                      to: 10,
                    ),
                  ),
                  GroupRow(
                    label: l10n.settingsPredictionFertileAfter,
                    value: settings[SettingKeys.predictionFertileAfter] ?? '4',
                    onTap: () => _pickNumber(
                      context,
                      ref,
                      key: SettingKeys.predictionFertileAfter,
                      from: 1,
                      to: 10,
                    ),
                  ),
                ],
                footer: l10n.settingsDisclaimer,
              ),
              GroupSection(
                rows: <Widget>[
                  GroupRow(
                    label: l10n.settingsNotifications,
                    onTap: () => context.go('/settings/notifications'),
                  ),
                  GroupRow(
                    label: l10n.settingsPrivacy,
                    onTap: () => context.go('/settings/lock'),
                  ),
                  GroupRow(
                    label: l10n.settingsData,
                    onTap: () => context.go('/settings/data'),
                  ),
                  GroupRow(
                    label: l10n.syncTitle,
                    onTap: () => context.go('/settings/sync'),
                  ),
                ],
              ),
              GroupSection(
                title: l10n.settingsAbout,
                rows: <Widget>[
                  GroupRow(label: l10n.settingsVersion, value: version),
                  GroupRow(
                    label: l10n.settingsLicense,
                    value: 'MIT',
                    onTap: () => _openUrl(AppInfo.repoUrl),
                  ),
                  GroupRow(
                    label: l10n.settingsRepository,
                    value: AppInfo.repoUrl.replaceFirst('https://', ''),
                    onTap: () => _openUrl(AppInfo.repoUrl),
                  ),
                ],
              ),
              if (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
                GroupSection(
                  title: l10n.settingsWindows,
                  footer: l10n.settingsReminderWindowsHint,
                  rows: <Widget>[
                    GroupRow(
                      label: l10n.settingsAutostart,
                      trailing: Switch(
                        value: ref.watch(autostartProvider),
                        activeThumbColor: colors.accent,
                        onChanged: (bool value) async {
                          await ref.read(autostartProvider.notifier).set(value);
                          await ref
                              .read(windowsAppProvider)
                              ?.setAutostart(value);
                        },
                      ),
                    ),
                    GroupRow(
                      label: l10n.settingsCloseToTray,
                      trailing: Switch(
                        value: ref.watch(closeToTrayProvider),
                        activeThumbColor: colors.accent,
                        onChanged: (bool value) async {
                          await ref
                              .read(closeToTrayProvider.notifier)
                              .set(value);
                          ref.read(windowsAppProvider)?.setCloseToTray(value);
                        },
                      ),
                    ),
                  ],
                ),
              GroupSection(
                title: l10n.settingsUpdate,
                rows: <Widget>[
                  GroupRow(
                    label: l10n.settingsAutoCheckUpdate,
                    trailing: Switch(
                      value: ref.watch(autoCheckUpdateProvider),
                      activeThumbColor: colors.accent,
                      onChanged: (bool value) =>
                          ref.read(autoCheckUpdateProvider.notifier).set(value),
                    ),
                  ),
                  GroupRow(
                    label: l10n.settingsCheckUpdate,
                    value: version,
                    onTap: () => _checkUpdate(context, version),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x2),
          _DebugCard(stats: stats),
        ],
      ),
    );
  }

  static String _languageLabel(AppLocalizations l10n, Locale? locale) {
    if (locale == null) {
      return l10n.settingsLanguageSystem;
    }
    return locale.languageCode == 'zh' ? '中文' : 'English';
  }

  static String _themeLabel(AppLocalizations l10n, ThemeMode mode) =>
      switch (mode) {
        ThemeMode.light => l10n.settingsThemeLight,
        ThemeMode.dark => l10n.settingsThemeDark,
        ThemeMode.system => l10n.settingsThemeSystem,
      };

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String current = ref.read(localeProvider.notifier).id;
    final String? picked = await _pickOption<String>(
      context,
      options: <String, String>{
        'system': l10n.settingsLanguageSystem,
        'zh': '中文',
        'en': 'English',
      },
      current: current,
    );
    if (picked != null) {
      await ref.read(localeProvider.notifier).set(picked);
    }
  }

  Future<void> _pickThemeMode(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeMode current = ref.read(themeModeProvider);
    final String currentKey = switch (current) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    final String? picked = await _pickOption<String>(
      context,
      options: <String, String>{
        'system': l10n.settingsThemeSystem,
        'light': l10n.settingsThemeLight,
        'dark': l10n.settingsThemeDark,
      },
      current: currentKey,
    );
    if (picked == null) {
      return;
    }
    await ref.read(themeModeProvider.notifier).set(switch (picked) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    });
  }

  Future<void> _pickAccent(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppAccent? picked = await _pickOption<AppAccent>(
      context,
      options: <String, String>{
        for (final AppAccent accent in AppAccent.values) accent.id: accent.id,
      },
      current: ref.read(accentProvider).id,
      labels: _accentNames(l10n),
      swatches: true,
    );
    if (picked != null) {
      await ref.read(accentProvider.notifier).set(picked);
    }
  }

  static Map<String, String> _accentNames(AppLocalizations l10n) =>
      <String, String>{
        'rose': l10n.accentRose,
        'peach': l10n.accentPeach,
        'amber': l10n.accentAmber,
        'moss': l10n.accentMoss,
        'mint': l10n.accentMint,
        'mist': l10n.accentMist,
        'lavender': l10n.accentLavender,
        'graphite': l10n.accentGraphite,
      };

  Future<void> _pickNumber(
    BuildContext context,
    WidgetRef ref, {
    required String key,
    required int from,
    required int to,
  }) async {
    final String? current = switch (ref.read(settingsProvider)) {
      AsyncData<Map<String, String>>(value: final Map<String, String> v) =>
        v[key],
      _ => null,
    };
    final String? picked = await _pickOption<String>(
      context,
      options: <String, String>{
        for (int value = from; value <= to; value++) '$value': '$value',
      },
      current: current ?? '',
    );
    if (picked != null) {
      await ref.read(settingsRepositoryProvider).set(key, picked);
    }
  }

  Future<void> _checkUpdate(BuildContext context, String version) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final UpdateInfo? info = await checkForUpdate(currentVersion: version);
    if (!context.mounted) {
      return;
    }
    if (info == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.settingsUpdateFailed)));
      return;
    }
    final bool open = await _confirmDialog(
      context,
      title: l10n.settingsUpdateAvailable(info.version),
      confirmLabel: l10n.settingsUpdateOpen,
    );
    if (open) {
      await _openUrl(info.url);
    }
  }

  static Future<bool> _confirmDialog(
    BuildContext context, {
    required String title,
    required String confirmLabel,
  }) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppColors colors = context.colors;
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: dialogContext.colors.surface,
        shape: const SquircleBorder(radius: AppRadii.card),
        title: Text(
          title,
          style: AppType.headline.copyWith(color: colors.text),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel, style: TextStyle(color: colors.accent)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static Future<void> _openUrl(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}

/// 主题色与数字选项共用的底部选择器。
Future<T?> _pickOption<T>(
  BuildContext context, {
  required Map<String, String> options,
  required String current,
  Map<String, String>? labels,
  bool swatches = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) {
      final AppColors colors = sheetContext.colors;
      final AppLocalizations l10n = AppLocalizations.of(sheetContext);
      List<MapEntry<String, String>> entries = options.entries.toList();
      if (swatches) {
        entries = entries;
      }
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
              for (final MapEntry<String, String> entry in entries)
                GroupRow(
                  label: labels?[entry.key] ?? entry.value,
                  trailing: swatches
                      ? _Swatch(accent: AppAccent.fromId(entry.key))
                      : null,
                  value: entry.key == current ? '✓' : null,
                  onTap: () => Navigator.of(sheetContext).pop(
                    swatches
                        ? AppAccent.fromId(entry.key) as T
                        : entry.key as T,
                  ),
                ),
              GroupRow(
                label: l10n.commonCancel,
                onTap: () => Navigator.of(sheetContext).pop(null),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _AccentSwatches extends StatelessWidget {
  const _AccentSwatches({required this.selected, required this.onPick});

  final AppAccent selected;
  final ValueChanged<AppAccent> onPick;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final AppAccent accent in AppAccent.values)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: _Swatch(
              accent: accent,
              selected: accent == selected,
              onTap: () => onPick(accent),
            ),
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.accent, this.selected = false, this.onTap});

  final AppAccent accent;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final Color color = accent.of(Theme.of(context).brightness);
    return Semantics(
      container: true,
      button: true,
      label: accent.id,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: selected
                ? Border.all(color: colors.text, width: 2)
                : Border.all(color: colors.separator, width: 0.5),
          ),
        ),
      ),
    );
  }
}

/// 数据库调试信息（Step 1 遗留，正式版可以删）。
class _DebugCard extends StatelessWidget {
  const _DebugCard({required this.stats});

  final DbStats? stats;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppColors colors = context.colors;
    final DbStats? data = stats;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x2),
      decoration: ShapeDecoration(
        color: colors.surface,
        shape: SquircleBorder(
          radius: AppRadii.card,
          side: BorderSide(color: colors.separator, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.settingsDebugDatabase,
            style: AppType.bodySmall.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.x1),
          SelectableText(
            data?.path ?? '—',
            style: AppType.caption.copyWith(color: colors.text),
          ),
          const SizedBox(height: AppSpacing.x2),
          Text(
            l10n.settingsDebugRows,
            style: AppType.bodySmall.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.x1),
          if (data != null)
            for (final MapEntry<String, int> row in data.rows.entries)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.x1),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        row.key,
                        style: AppType.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      '${row.value}',
                      style: AppType.caption.copyWith(color: colors.text),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
