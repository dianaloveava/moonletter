import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';

/// 空状态：一句话说明 + 可选操作按钮。
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message, this.action});

  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppType.body.copyWith(color: context.colors.textSecondary),
            ),
            if (action != null) ...<Widget>[
              const SizedBox(height: AppSpacing.x2),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
