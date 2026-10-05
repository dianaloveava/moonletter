import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moonletter/app.dart';
import 'package:moonletter/core/app_paths.dart';
import 'package:moonletter/data/data_providers.dart';
import 'package:moonletter/data/db/database.dart';
import 'package:moonletter/domain/lock/lock_providers.dart';
import 'package:moonletter/features/settings/settings_page.dart';

void main() {
  late AppDatabase db;
  late Directory dir;

  setUp(() {
    db = AppDatabase.memory();
    dir = Directory.systemTemp.createTempSync('moonletter-sheet-test');
  });

  tearDown(() async {
    await db.close();
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  /// 新增/编辑成员弹层：点弹层外的背板要能关掉。
  /// 弹层外框必须只有内容那么高；一旦被撑满整屏，Flutter 给弹层套的拖拽
  /// 手势层会铺满屏幕，背板的点按全被吃掉，用户会觉得「点空白处没反应」。
  testWidgets('点背板关闭弹层', (WidgetTester tester) async {
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

    await tester.tap(find.text('Profiles').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add member').first);
    await tester.pumpAndSettle();
    // 弹层标题 + 页面上的按钮各一个
    expect(find.text('Add member'), findsNWidgets(2));

    final Size size = tester.view.physicalSize / tester.view.devicePixelRatio;
    final double sheetTop = tester.getRect(find.text('Cancel')).top;
    expect(sheetTop, greaterThan(0), reason: '弹层上方要留出可点的背板');

    await tester.tapAt(Offset(size.width / 2, sheetTop / 2));
    await tester.pumpAndSettle();
    expect(
      find.text('Add member'),
      findsOneWidget,
      reason: '点背板后弹层应关闭，只剩页面上的按钮',
    );
  });
}
