import 'package:flutter/material.dart';

import '../core/l10n/gen/app_localizations.dart';
import '../core/theme/tokens.dart';
import 'squircle.dart';

/// 二次确认弹窗，确认返回 true。
Future<bool> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String? confirmLabel,
  bool destructive = true,
}) async {
  final AppLocalizations l10n = AppLocalizations.of(context);
  final AppColors colors = context.colors;
  final bool? result = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      backgroundColor: dialogContext.colors.surface,
      shape: const SquircleBorder(radius: AppRadii.card),
      title: Text(title, style: AppType.headline.copyWith(color: colors.text)),
      content: Text(
        message,
        style: AppType.body.copyWith(color: colors.textSecondary),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(
            confirmLabel ?? l10n.commonDelete,
            style: TextStyle(
              color: destructive ? colors.periodRed : colors.accent,
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
