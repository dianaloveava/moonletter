import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';
import '../data/db/database.dart';
import '../domain/prediction/cycle_predictor.dart';
import 'member_avatar.dart';

/// 日历 tab 的日期格：数字（经期开始日描红圈）+ 当天成员头像行。
class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    super.key,
    required this.dayNumber,
    required this.inMonth,
    required this.isToday,
    required this.isSelected,
    required this.isPeriodStart,
    required this.members,
    required this.label,
    this.onTap,
  });

  final int dayNumber;

  /// 无障碍读出的整格描述（例如「10 月 5 日，小月经期第 1 天」）
  final String label;

  /// 当月之外的补位格
  final bool inMonth;
  final bool isToday;
  final bool isSelected;

  /// 当天有人开始经期：数字描红圈
  final bool isPeriodStart;

  /// 当天处于经期（实际或预测）的成员，最多渲染 3 个头像，超出显示 +N
  final List<Member> members;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final double opacity = inMonth ? 1 : 0.35;
    final Color numberColor = isPeriodStart
        ? colors.periodRed
        : (inMonth ? colors.text : colors.textSecondary);

    final Border? ring;
    if (isPeriodStart) {
      ring = Border.all(color: colors.periodRed, width: 1.5);
    } else if (isToday) {
      ring = Border.all(color: colors.accent, width: 1.5);
    } else {
      ring = null;
    }

    final Widget number = Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: ring,
        color: isSelected ? colors.accent : null,
      ),
      child: Text(
        '$dayNumber',
        style: AppType.bodySmall.copyWith(
          color: isSelected ? colors.onAccent : numberColor,
          fontWeight: isPeriodStart || isSelected
              ? FontWeight.w600
              : FontWeight.w400,
        ),
      ),
    );

    final List<Widget> avatarRow = <Widget>[];
    final int shown = members.length > 3 ? 3 : members.length;
    for (int i = 0; i < shown; i++) {
      avatarRow.add(
        Padding(
          padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
          child: MemberAvatar(member: members[i], size: 16),
        ),
      );
    }
    if (members.length > 3) {
      avatarRow.add(
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            '+${members.length - 3}',
            style: AppType.caption.copyWith(color: colors.textSecondary),
          ),
        ),
      );
    }

    return Semantics(
      container: true,
      button: onTap != null,
      excludeSemantics: true,
      onTap: onTap,
      label: label,
      child: Opacity(
        opacity: opacity,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.chip),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                number,
                SizedBox(
                  height: 18,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: avatarRow,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 个人日历的日期格：圆底表示经期/排卵/危险期/安全期。
class PersonalDayCell extends StatelessWidget {
  const PersonalDayCell({
    super.key,
    required this.dayNumber,
    required this.kind,
    required this.inMonth,
    required this.isToday,
    required this.isSelected,
    required this.label,
    this.onTap,
  });

  final int dayNumber;
  final DayKind kind;
  final bool inMonth;
  final bool isToday;
  final bool isSelected;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    Color? fill;
    Color? border;
    Color text = colors.text;
    double borderWidth = 0;

    switch (kind) {
      case DayKind.period:
        fill = colors.periodRed;
        text = colors.onAccent;
      case DayKind.predictedPeriod:
        fill = colors.periodRedSoft;
        text = colors.periodRed;
      case DayKind.ovulation:
        fill = colors.ovulationFill;
        border = colors.fertilePink;
        borderWidth = 1.5;
      case DayKind.fertile:
        border = colors.fertilePink;
        borderWidth = 1;
      case DayKind.safe:
        fill = colors.safeFill;
      case DayKind.unknown:
        text = colors.textSecondary;
    }

    if (isSelected) {
      fill = switch (kind) {
        DayKind.period => colors.periodRed,
        DayKind.ovulation || DayKind.fertile => colors.fertilePink,
        DayKind.safe => colors.safeStrong,
        DayKind.predictedPeriod || DayKind.unknown => colors.accent,
      };
      border = null;
      borderWidth = 0;
      text = colors.onAccent;
    } else if (border == null && isToday) {
      border = colors.accent;
      borderWidth = 1.5;
    }

    return Semantics(
      container: true,
      button: onTap != null,
      excludeSemantics: true,
      onTap: onTap,
      label: label,
      child: Opacity(
        opacity: inMonth ? 1 : 0.35,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fill,
                  border: border != null
                      ? Border.all(color: border, width: borderWidth)
                      : null,
                ),
                child: Text(
                  '$dayNumber',
                  style: AppType.bodySmall.copyWith(
                    color: text,
                    fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
