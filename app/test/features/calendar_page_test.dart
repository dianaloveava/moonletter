import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moonletter/core/app_paths.dart';
import 'package:moonletter/core/l10n/gen/app_localizations.dart';
import 'package:moonletter/core/theme/app_theme.dart';
import 'package:moonletter/core/theme/tokens.dart';
import 'package:moonletter/core/utils/dates.dart';
import 'package:moonletter/data/data_providers.dart';
import 'package:moonletter/data/db/database.dart';
import 'package:moonletter/data/repo/member_repository.dart';
import 'package:moonletter/data/repo/period_repository.dart';
import 'package:moonletter/features/calendar/calendar_page.dart';
import 'package:moonletter/widgets/day_cell.dart';

void main() {
  late AppDatabase db;
  late Directory dir;
  late AppPaths paths;
  late String today;

  /// drift 的流在 provider 销毁时会排一个零延时定时器，测试里要让它跑完，
  /// 否则 flutter_test 会因为「A Timer is still pending」失败。
  Future<void> disposeUi(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  }

  setUp(() {
    db = AppDatabase.memory();
    dir = Directory.systemTemp.createTempSync('moonletter-calendar-test');
    paths = AppPaths.forTesting(dir);
    today = LocalDate.today();
  });

  tearDown(() async {
    await db.close();
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  Future<Widget> buildPage() async {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        appPathsProvider.overrideWithValue(paths),
      ],
      child: MaterialApp(
        theme: AppTheme.build(
          brightness: Brightness.light,
          accent: AppAccent.rose,
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: CalendarPage()),
      ),
    );
  }

  testWidgets('同一天 4 人开始经期：显示 3 个头像和 +1，并且日期描红圈', (WidgetTester tester) async {
    final MemberRepository members = MemberRepository(db);
    final PeriodRepository periods = PeriodRepository(db);
    for (int i = 0; i < 4; i++) {
      final String id = await members.create(MemberInput(name: '成员$i'));
      await periods.add(id, today);
    }

    await tester.pumpWidget(await buildPage());
    await tester.pumpAndSettle();

    final Finder cell = find.byWidgetPredicate(
      (Widget widget) => widget is CalendarDayCell && widget.isPeriodStart,
    );
    expect(cell, findsOneWidget, reason: '今天这一格应该是经期开始日');
    expect(tester.widget<CalendarDayCell>(cell).members, hasLength(4));
    expect(find.text('+1'), findsOneWidget, reason: '超出 3 个显示 +N');

    // 点这一天 → 面板列出 4 位成员
    await tester.tap(cell);
    await tester.pumpAndSettle();
    for (int i = 0; i < 4; i++) {
      expect(find.text('成员$i'), findsWidgets);
    }

    await disposeUi(tester);
  });

  testWidgets('这台日历会列出当天处于经期的成员；没有记录时显示空状态', (WidgetTester tester) async {
    await tester.pumpWidget(await buildPage());
    await tester.pumpAndSettle();

    final AppLocalizations l10n = AppLocalizations.of(
      tester.element(find.byType(CalendarPage)),
    );
    expect(find.text(l10n.calendarDayEmpty), findsOneWidget);

    await disposeUi(tester);
  });

  testWidgets('进行中的记录会延伸到今天，面板显示经期第 N 天', (WidgetTester tester) async {
    final MemberRepository members = MemberRepository(db);
    final PeriodRepository periods = PeriodRepository(db);
    final String id = await members.create(const MemberInput(name: '小月'));
    await periods.add(id, LocalDate.addDays(today, -2));

    await tester.pumpWidget(await buildPage());
    await tester.pumpAndSettle();

    final AppLocalizations l10n = AppLocalizations.of(
      tester.element(find.byType(CalendarPage)),
    );
    expect(find.text(l10n.dayPeriodDay(3)), findsOneWidget);

    await disposeUi(tester);
  });
}
