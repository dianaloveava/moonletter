import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../core/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/dates.dart';
import '../../data/data_providers.dart';
import '../../data/db/database.dart';
import '../../domain/prediction/cycle_predictor.dart';
import '../../domain/prediction/prediction_config.dart';
import '../../domain/prediction/prediction_providers.dart';
import '../../widgets/day_cell.dart';
import '../../widgets/member_avatar.dart';
import '../../widgets/month_calendar.dart';
import '../../widgets/page_frame.dart';
import '../../widgets/squircle.dart';
import 'calendar_providers.dart';

/// 日历页：月历只标经期开始日，点某天在下方列出当天处于经期的成员。
class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  late String _month = LocalDate.monthKey(LocalDate.today());
  late String _selected = LocalDate.today();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppColors colors = context.colors;

    final List<Member> members = switch (ref.watch(membersProvider)) {
      AsyncData<List<Member>>(value: final List<Member> v) => v,
      _ => const <Member>[],
    };
    final Map<String, List<Period>> byMember = switch (ref.watch(
      periodsByMemberProvider,
    )) {
      AsyncData<Map<String, List<Period>>>(
        value: final Map<String, List<Period>> v,
      ) =>
        v,
      _ => const <String, List<Period>>{},
    };
    final List<Period> monthPeriods = switch (ref.watch(
      periodsInMonthProvider(_month),
    )) {
      AsyncData<List<Period>>(value: final List<Period> v) => v,
      _ => const <Period>[],
    };
    final Map<String, Prediction?> predictions = ref.watch(predictionsProvider);
    final PredictionConfig config = ref.watch(predictionConfigProvider);

    final Map<String, List<Member>> startingByDate = <String, List<Member>>{};
    for (final Period period in monthPeriods) {
      final Member? member = _memberOf(members, period.memberId);
      if (member == null) {
        continue;
      }
      startingByDate
          .putIfAbsent(period.startDate, () => <Member>[])
          .add(member);
    }

    return PageFrame(
      title: l10n.tabCalendar,
      child: Padding(
        // 日期面板贴底：把底栏占的高度让出来，别让它压在底栏下面。
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: MonthCalendar(
                initialMonth: _month,
                onMonthChanged: (String month) =>
                    setState(() => _month = month),
                cellBuilder: (BuildContext context, String date, bool inMonth) {
                  final List<Member> starting =
                      startingByDate[date] ?? const <Member>[];
                  return CalendarDayCell(
                    dayNumber: int.parse(date.substring(8, 10)),
                    inMonth: inMonth,
                    isToday: date == LocalDate.today(),
                    isSelected: date == _selected,
                    isPeriodStart: starting.isNotEmpty,
                    members: starting,
                    label: _cellLabel(l10n, date, starting),
                    onTap: () {
                      Motion.tap();
                      setState(() => _selected = date);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.x2),
            if (monthPeriods.isEmpty) ...<Widget>[
              Text(
                l10n.calendarEmptyMonth,
                style: AppType.bodySmall.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.x1),
            ],
            _DayPanel(
              date: _selected,
              members: members,
              periodsByMember: byMember,
              predictions: predictions,
              config: config,
            ),
          ],
        ),
      ),
    );
  }

  static String _cellLabel(
    AppLocalizations l10n,
    String date,
    List<Member> starting,
  ) {
    final String day = date.substring(5).replaceAll('-', '/');
    if (starting.isEmpty) {
      return day;
    }
    final String names = starting.map((Member member) => member.name).join('、');
    return '$day，$names ${l10n.dayKindPeriod}';
  }

  static Member? _memberOf(List<Member> members, String id) {
    for (final Member member in members) {
      if (member.id == id) {
        return member;
      }
    }
    return null;
  }
}

/// 选中日期的成员面板：列出当天处于经期（实际或预测）的成员。
class _DayPanel extends StatelessWidget {
  const _DayPanel({
    required this.date,
    required this.members,
    required this.periodsByMember,
    required this.predictions,
    required this.config,
  });

  final String date;
  final List<Member> members;
  final Map<String, List<Period>> periodsByMember;
  final Map<String, Prediction?> predictions;
  final PredictionConfig config;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppColors colors = context.colors;

    final List<Widget> rows = <Widget>[];
    for (final Member member in members) {
      final List<Period> periods =
          periodsByMember[member.id] ?? const <Period>[];
      final Prediction? prediction = predictions[member.id];
      final int? dayIndex = periodDayIndex(date, periods, prediction);
      if (dayIndex == null) {
        continue;
      }
      final bool actual = dayKind(date, periods, prediction) == DayKind.period;
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.x1),
          child: Row(
            children: <Widget>[
              MemberAvatar(member: member, size: 28),
              const SizedBox(width: AppSpacing.x2),
              Expanded(
                child: Text(
                  member.name,
                  style: AppType.body.copyWith(color: colors.text),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                actual
                    ? l10n.dayPeriodDay(dayIndex)
                    : l10n.dayPredictedPeriodDay(dayIndex),
                style: AppType.bodySmall.copyWith(
                  color: actual ? colors.periodRed : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x2,
        vertical: AppSpacing.x2,
      ),
      decoration: ShapeDecoration(
        color: colors.surface,
        shape: SquircleBorder(
          radius: AppRadii.card,
          side: BorderSide(color: colors.separator, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '${date.substring(5).replaceAll('-', '/')}'
            '${date == LocalDate.today() ? ' · ${l10n.calendarToday}' : ''}',
            style: AppType.caption.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.x1),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.x2),
              child: Text(
                l10n.calendarDayEmpty,
                style: AppType.bodySmall.copyWith(color: colors.textSecondary),
              ),
            )
          else
            Flexible(child: ListView(children: rows)),
        ],
      ),
    );
  }
}
