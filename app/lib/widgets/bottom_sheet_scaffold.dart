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
    // 挂在根 Navigator 上：弹层要盖住底栏，背板也要能盖住整屏
    // （分支 Navigator 在底栏下面，弹层会被底栏压住）。
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black26,
    builder: (BuildContext sheetContext) {
      // 弹层最多占屏高 86%：剩下的部分留作可点的背板，点它即关闭
      // （长表单里也能直接点空白处退出，不用先滚回顶部找「取消」）。
      final double maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.86;
      final AppLocalizations l10n = AppLocalizations.of(sheetContext);
      final AppColors colors = sheetContext.colors;

      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          // heightFactor 1：让弹层外框只有内容那么高。不写这个的话 Align
          // 会撑满整屏，Flutter 给弹层套的拖拽手势层也跟着铺满，于是
          // 背板上的点按全被它吃掉——点空白处关不掉。
          heightFactor: 1,
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
