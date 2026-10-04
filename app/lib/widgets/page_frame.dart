import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';

/// 页面外框：响应式左右内边距 + 大标题 + 可选右上操作。
class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.title,
    required this.child,
    this.actions = const <Widget>[],
  });

  final String title;
  final List<Widget> actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final double horizontal = width >= AppSpacing.breakpoint
        ? AppSpacing.pageDesktop
        : AppSpacing.pageMobile;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(horizontal, AppSpacing.x1, horizontal, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.x2),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      title,
                      style: AppType.display.copyWith(
                        color: context.colors.text,
                      ),
                    ),
                  ),
                  ...actions,
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
