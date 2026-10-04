import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../core/theme/tokens.dart';
import '../../data/data_providers.dart';
import '../../domain/lock/lock_providers.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/grouped_list.dart';
import '../../widgets/page_frame.dart';
import '../../widgets/squircle.dart';
import 'pin_pad.dart';

/// 隐私：应用锁（PIN / 生物识别）。切后台立即锁定 + 隐藏预览由 [LockGate] 负责。
class LockSettingsPage extends ConsumerWidget {
  const LockSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppColors colors = context.colors;
    final bool biometricEnabled =
        ref.watch(biometricAvailableProvider).value ?? false;
    final AsyncValue<String> lockKindAsync = ref.watch(lockKindProvider);
    final String lockKind = switch (lockKindAsync) {
      AsyncData<String>(value: final String value) => value,
      _ => 'none',
    };
    final bool enabled = lockKind != 'none';

    return Scaffold(
      backgroundColor: colors.bg,
      body: PageFrame(
        title: l10n.settingsPrivacy,
        actions: <Widget>[
          IconButton(
            onPressed: () => context.go('/settings'),
            icon: const Icon(Icons.close),
            color: colors.textSecondary,
          ),
        ],
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.x4),
          children: <Widget>[
            GroupedList(
              sections: <Widget>[
                GroupSection(
                  title: l10n.settingsPrivacy,
                  footer: l10n.lockHintImmediate,
                  rows: <Widget>[
                    GroupRow(
                      label: l10n.settingsAppLock,
                      value: enabled ? l10n.commonOn : l10n.commonOff,
                      onTap: () => _configure(context, ref, lockKind),
                    ),
                    if (biometricEnabled)
                      GroupRow(
                        label: l10n.settingsBiometric,
                        trailing: Switch(
                          value: lockKind == 'pin_bio',
                          activeThumbColor: colors.accent,
                          onChanged: enabled
                              ? (bool value) => ref
                                    .read(lockServiceProvider)
                                    .setLockKind(value ? 'pin_bio' : 'pin')
                              : null,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _configure(
    BuildContext context,
    WidgetRef ref,
    String lockKind,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (lockKind == 'none') {
      final String? pin = await showPinSetupSheet(
        context: context,
        title: l10n.lockSetPin,
        confirmTitle: l10n.lockConfirmPin,
        mismatchMessage: l10n.lockPinMismatch,
        cancelLabel: l10n.commonCancel,
      );
      if (pin == null) {
        return;
      }
      await ref.read(lockServiceProvider).setPin(pin);
      await ref.read(lockServiceProvider).setLockKind('pin');
      return;
    }

    final String? action = await showModalBottomSheet<String>(
      context: context,
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                GroupRow(
                  label: l10n.lockChangePin,
                  onTap: () => Navigator.of(sheetContext).pop('change'),
                ),
                GroupRow(
                  label: l10n.lockDisable,
                  destructive: true,
                  onTap: () => Navigator.of(sheetContext).pop('disable'),
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
    if (!context.mounted) {
      return;
    }

    switch (action) {
      case 'change':
        final String? pin = await showPinSetupSheet(
          context: context,
          title: l10n.lockSetPin,
          confirmTitle: l10n.lockConfirmPin,
          mismatchMessage: l10n.lockPinMismatch,
          cancelLabel: l10n.commonCancel,
        );
        if (pin != null) {
          await ref.read(lockServiceProvider).setPin(pin);
        }
      case 'disable':
        final bool ok = await showConfirmDialog(
          context: context,
          title: l10n.lockDisable,
          message: l10n.lockDisableConfirm,
          confirmLabel: l10n.lockDisable,
        );
        if (ok) {
          await ref.read(lockServiceProvider).clearPin();
          ref.invalidate(lockKindProvider);
        }
    }
  }
}

/// 当前的应用锁开关（`none` / `pin` / `pin_bio`），跟随设置表变化。
final FutureProvider<String> lockKindProvider = FutureProvider<String>((
  Ref ref,
) async {
  // 依赖设置流，设置变化时重新读取。
  ref.watch(settingsProvider);
  return ref.watch(lockServiceProvider).lockKind();
});
