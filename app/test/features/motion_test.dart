import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moonletter/app.dart';
import 'package:moonletter/core/app_paths.dart';
import 'package:moonletter/data/data_providers.dart';
import 'package:moonletter/data/db/database.dart';
import 'package:moonletter/data/repo/member_repository.dart';
import 'package:moonletter/domain/lock/lock_providers.dart';
import 'package:moonletter/features/profiles/member_detail_page.dart';
import 'package:moonletter/features/settings/settings_page.dart';

/// 过渡动画回归：切底栏分页要有淡入 + 轻微上移；二级页面推入要有整屏横向
/// 滑动且不透明（半透明会让两个页面互相透出、叠在一起）。
/// 动画中途取一帧断言，避免「只有最终状态」这类测不出动画的写法。
void main() {
  late AppDatabase db;
  late Directory dir;

  setUp(() {
    db = AppDatabase.memory();
    dir = Directory.systemTemp.createTempSync('moonletter-motion-test');
  });

  tearDown(() async {
    await db.close();
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  Future<void> pumpApp(WidgetTester tester) async {
    final ProviderContainer container = ProviderContainer.test(
      overrides: [
        databaseProvider.overrideWithValue(db),
        appPathsProvider.overrideWithValue(AppPaths.forTesting(dir)),
        appVersionProvider.overrideWith((Ref ref) async => '0.1.0-test'),
        biometricAvailableProvider.overrideWith((Ref ref) async => false),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MoonletterApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Iterable<FadeTransition> fadesAbove(WidgetTester tester, Finder anchor) =>
      tester.widgetList<FadeTransition>(
        find.ancestor(of: anchor, matching: find.byType(FadeTransition)),
      );

  Iterable<SlideTransition> slidesAbove(WidgetTester tester, Finder anchor) =>
      tester.widgetList<SlideTransition>(
        find.ancestor(of: anchor, matching: find.byType(SlideTransition)),
      );

  testWidgets('切底栏分页：新页面淡入并从下方轻微上移', (WidgetTester tester) async {
    await pumpApp(tester);
    final Finder profiles = find.text('Profiles').first;

    await tester.tap(profiles);
    await tester.pump(const Duration(milliseconds: 60));

    final Finder anchor = find.text('No members yet');
    expect(
      fadesAbove(
        tester,
        anchor,
      ).any((FadeTransition f) => f.opacity.value < 0.99),
      isTrue,
      reason: '切换动画途中应该有还没淡入到 100% 的页面',
    );
    expect(
      slidesAbove(
        tester,
        anchor,
      ).any((SlideTransition s) => s.position.value.dy > 0),
      isTrue,
      reason: '切换动画途中页面应该还在下方一点的位置',
    );

    await tester.pumpAndSettle();
    expect(
      fadesAbove(
        tester,
        anchor,
      ).every((FadeTransition f) => f.opacity.value == 1),
      isTrue,
    );
    expect(
      slidesAbove(
        tester,
        anchor,
      ).every((SlideTransition s) => s.position.value.dy == 0),
      isTrue,
    );
  });

  testWidgets('推入二级页面：新页面从右侧滑入', (WidgetTester tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Settings').first);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Notifications').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notifications').first);
    // 点一下只是发出导航请求，路由要等下一帧才建起来；先过一帧再取动画中途的快照。
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    final Finder anchor = find.text('Global lead days');
    expect(
      slidesAbove(
        tester,
        anchor,
      ).any((SlideTransition s) => s.position.value.dx > 0),
      isTrue,
      reason: '推入途中新页面应该还在右侧一点的位置',
    );
    expect(
      fadesAbove(
        tester,
        anchor,
      ).every((FadeTransition f) => f.opacity.value == 1),
      isTrue,
      reason: '推入途中新页面不能半透明，否则和旧页面叠在一起',
    );
    expect(
      tester
          .widgetList<ColoredBox>(
            find.ancestor(of: anchor, matching: find.byType(ColoredBox)),
          )
          .any((ColoredBox box) => box.color.a == 1),
      isTrue,
      reason: '推入的页面要自带不透明底色，不然会透出下面那个页面',
    );

    await tester.pumpAndSettle();
    expect(
      slidesAbove(
        tester,
        anchor,
      ).every((SlideTransition s) => s.position.value.dx == 0),
      isTrue,
    );
  });

  testWidgets('推入成员详情：新页面从右侧滑入', (WidgetTester tester) async {
    await MemberRepository(db).create(const MemberInput(name: '小月'));

    await pumpApp(tester);
    await tester.tap(find.text('Profiles').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('小月').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    final Finder anchor = find.byType(MemberDetailPage);
    expect(anchor, findsOneWidget);
    expect(
      fadesAbove(
        tester,
        anchor,
      ).every((FadeTransition f) => f.opacity.value == 1),
      isTrue,
      reason: '推入途中新页面不能半透明，否则和旧页面叠在一起',
    );
    expect(
      tester
          .widgetList<ColoredBox>(
            find.ancestor(of: anchor, matching: find.byType(ColoredBox)),
          )
          .any((ColoredBox box) => box.color.a == 1),
      isTrue,
      reason: '推入的页面要自带不透明底色，不然会透出下面那个页面',
    );
    expect(
      slidesAbove(
        tester,
        anchor,
      ).any((SlideTransition s) => s.position.value.dx > 0),
      isTrue,
      reason: '推入途中新页面应该还在右侧一点的位置',
    );

    await tester.pumpAndSettle();
    expect(
      slidesAbove(
        tester,
        anchor,
      ).every((SlideTransition s) => s.position.value.dx == 0),
      isTrue,
    );
  });
}
