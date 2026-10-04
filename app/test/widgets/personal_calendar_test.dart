import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moonletter/core/l10n/gen/app_localizations.dart';
import 'package:moonletter/core/theme/app_theme.dart';
import 'package:moonletter/core/theme/tokens.dart';
import 'package:moonletter/data/db/database.dart';
import 'package:moonletter/domain/prediction/cycle_predictor.dart';
import 'package:moonletter/domain/prediction/prediction_config.dart';
import 'package:moonletter/widgets/day_cell.dart';
import 'package:moonletter/widgets/month_calendar.dart';

Member _member() => const Member(
  id: 'm1',
  name: '小月',
  colorIndex: 0,
  defaultCycleDays: 28,
  defaultPeriodDays: 4,
  sortOrder: 0,
  createdAt: 1,
  updatedAt: 1,
  updatedBy: 'test',
);

Period _period(String start, {String? end, String id = 'p1'}) => Period(
  id: id,
  memberId: 'm1',
  startDate: start,
  endDate: end,
  createdAt: 1,
  updatedAt: 1,
  updatedBy: 'test',
);

BoxDecoration _decorationOf(WidgetTester tester, String labelPrefix) {
  final Finder cell = find.byWidgetPredicate(
    (Widget widget) =>
        widget is PersonalDayCell && widget.label.startsWith(labelPrefix),
  );
  expect(cell, findsOneWidget, reason: '找不到日期格 $labelPrefix');
  final Finder container = find
      .descendant(of: cell, matching: find.byType(Container))
      .first;
  return tester.widget<Container>(container).decoration! as BoxDecoration;
}

void main() {
  const AppColors colors = AppColors.light;

  testWidgets('个人日历按 dayKind 上色：经期实心红、排卵描边、安全期淡底、预测经期浅红', (
    WidgetTester tester,
  ) async {
    final List<Period> periods = <Period>[
      _period('2026-09-03', end: '2026-09-06', id: 'p0'),
      _period('2026-10-01', end: '2026-10-04'),
    ];
    final Prediction prediction = predict(
      _member(),
      periods,
      const PredictionConfig(),
      today: '2026-10-04',
    )!;
    expect(prediction.nextStart, '2026-10-29');
    expect(prediction.ovulation, '2026-10-15');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(
          brightness: Brightness.light,
          accent: AppAccent.rose,
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            height: 520,
            child: MonthCalendar(
              initialMonth: '2026-10',
              cellBuilder: (BuildContext context, String date, bool inMonth) {
                final DayKind kind = dayKind(date, periods, prediction);
                return PersonalDayCell(
                  dayNumber: int.parse(date.substring(8, 10)),
                  kind: kind,
                  inMonth: inMonth,
                  isToday: date == '2026-10-04',
                  isSelected: false,
                  label:
                      '${date.substring(5).replaceAll('-', '/')} '
                      '${dayKindLabelForTest(kind)}',
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 经期：实心 periodRed
    final BoxDecoration periodDay = _decorationOf(tester, '10/01');
    expect(periodDay.color, colors.periodRed);
    expect(periodDay.border, isNull);

    // 预测经期：实心 periodRedSoft
    final BoxDecoration predicted = _decorationOf(tester, '10/29');
    expect(predicted.color, colors.periodRedSoft);

    // 排卵日：ovulationFill 底 + fertilePink 描边
    final BoxDecoration ovulation = _decorationOf(tester, '10/15');
    expect(ovulation.color, colors.ovulationFill);
    expect(ovulation.border!.top.color, colors.fertilePink);
    expect(ovulation.border!.top.width, 1.5);

    // 危险期：无底 + 1dp fertilePink 描边
    final BoxDecoration fertile = _decorationOf(tester, '10/10');
    expect(fertile.color, isNull);
    expect(fertile.border!.top.color, colors.fertilePink);
    expect(fertile.border!.top.width, 1);

    // 安全期：safeFill 淡底、无描边
    final BoxDecoration safe = _decorationOf(tester, '10/20');
    expect(safe.color, colors.safeFill);
    expect(safe.border, isNull);

    // 今天：外圈 accent 描边（该日是安全期，本身没有描边）
    final BoxDecoration today = _decorationOf(tester, '10/04');
    expect(today.border!.top.color, colors.accent);
    expect(today.color, colors.periodRed, reason: '10-04 是经期最后一天');
  });

  testWidgets('最早记录之前的日子是无记录状态', (WidgetTester tester) async {
    final List<Period> periods = <Period>[
      _period('2026-10-01', end: '2026-10-04'),
    ];
    final Prediction prediction = predict(
      _member(),
      periods,
      const PredictionConfig(),
      today: '2026-10-04',
    )!;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(
          brightness: Brightness.light,
          accent: AppAccent.rose,
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            height: 520,
            child: MonthCalendar(
              initialMonth: '2026-09',
              cellBuilder: (BuildContext context, String date, bool inMonth) =>
                  PersonalDayCell(
                    dayNumber: int.parse(date.substring(8, 10)),
                    kind: dayKind(
                      date,
                      periods,
                      prediction,
                      today: '2026-10-04',
                    ),
                    inMonth: inMonth,
                    isToday: false,
                    isSelected: false,
                    label: date,
                  ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final BoxDecoration before = _decorationOf(tester, '2026-09-02');
    expect(before.color, isNull);
    expect(before.border, isNull);
  });
}

/// 测试里不需要本地化文案，给个占位。
String dayKindLabelForTest(DayKind kind) => kind.name;
