import 'package:flutter/material.dart';

import '../core/l10n/gen/app_localizations.dart';
import '../core/theme/tokens.dart';
import 'glass_bar.dart';
import 'squircle.dart';

/// 打开新增/编辑底部弹层：顶部拖拽条 + 标题 + 右上「取消」，
/// 内容区可滚动，键盘弹起时整体上移。
Future<void> showAppSheet({
  required BuildContext context,
  required String title,
  required Widget child,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black26,
    builder: (BuildContext sheetContext) {
      final double maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.92;
      final AppLocalizations l10n = AppLocalizations.of(sheetContext);
      final AppColors colors = sheetContext.colors;

      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: GlassBar(
              shape: const TopSquircleBorder(),
              opacity: 0.94,
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.only(top: AppSpacing.x1),
                      child: _SheetHandle(),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.x3,
                        AppSpacing.x1,
                        AppSpacing.x2,
                        AppSpacing.x1,
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              title,
                              style: AppType.headline.copyWith(
                                color: colors.text,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.of(sheetContext).maybePop(),
                            child: Text(l10n.commonCancel),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.x3,
                          AppSpacing.x1,
                          AppSpacing.x3,
                          AppSpacing.x3,
                        ),
                        child: child,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 5,
        decoration: BoxDecoration(
          color: context.colors.separator,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}
