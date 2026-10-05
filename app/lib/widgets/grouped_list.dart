import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';
import 'squircle.dart';

/// iOS 风格分组列表：若干 [GroupSection] 之间留 [AppSpacing.groupGap]。
class GroupedList extends StatelessWidget {
  const GroupedList({super.key, required this.sections});

  final List<Widget> sections;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < sections.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: AppSpacing.groupGap),
          sections[i],
        ],
      ],
    );
  }
}

/// 一个分组：可选组标题 + `surface` 底圆角卡片，行之间自动插分隔线。
class GroupSection extends StatelessWidget {
  const GroupSection({
    super.key,
    this.title,
    this.footer,
    required this.rows,
    this.separatorIndent = AppSpacing.x2,
  });

  final String? title;
  final String? footer;
  final List<Widget> rows;
  final double separatorIndent;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.x1,
              bottom: AppSpacing.x1,
            ),
            child: Text(
              title!,
              style: AppType.caption.copyWith(color: colors.textSecondary),
            ),
          ),
        DecoratedBox(
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
              for (int i = 0; i < rows.length; i++) ...<Widget>[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: separatorIndent,
                    color: colors.separator,
                  ),
                rows[i],
              ],
            ],
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.x1,
              top: AppSpacing.x1,
            ),
            child: Text(
              footer!,
              style: AppType.caption.copyWith(color: colors.textSecondary),
            ),
          ),
      ],
    );
  }
}

/// 分组内的一行：左标签 + 右侧内容（值 / 开关 / 箭头）。
class GroupRow extends StatelessWidget {
  const GroupRow({
    super.key,
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final Color labelColor = destructive ? colors.periodRed : colors.text;

    final Widget content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x2,
        vertical: 14,
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // 值最多占行宽的 62%：过长的地址换行，而不是把左边的标签挤到没有宽度。
          final double maxValueWidth = constraints.maxWidth * 0.62;
          return Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.body.copyWith(color: labelColor),
                ),
              ),
              if (value != null) ...<Widget>[
                const SizedBox(width: AppSpacing.x1),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxValueWidth),
                  child: Text(
                    value!,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.body.copyWith(color: colors.textSecondary),
                  ),
                ),
              ],
              if (trailing != null) ...<Widget>[
                const SizedBox(width: AppSpacing.x1),
                trailing!,
              ],
              if (onTap != null) ...<Widget>[
                const SizedBox(width: AppSpacing.x1),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: colors.textSecondary,
                ),
              ],
            ],
          );
        },
      ),
    );

    if (onTap == null) {
      return content;
    }
    return Semantics(
      container: true,
      button: true,
      excludeSemantics: true,
      onTap: onTap,
      label: value == null ? label : '$label $value',
      child: InkWell(onTap: onTap, child: content),
    );
  }
}
