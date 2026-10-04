import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moonletter/app.dart';
import 'package:moonletter/core/app_paths.dart';
import 'package:moonletter/core/router/app_router.dart';
import 'package:moonletter/data/data_providers.dart';
import 'package:moonletter/data/db/database.dart';
import 'package:moonletter/domain/lock/lock_providers.dart';
import 'package:moonletter/features/profiles/profiles_page.dart';
import 'package:moonletter/features/settings/settings_page.dart';

void main() {
  late AppDatabase db;
  late Directory dir;

  setUp(() {
    db = AppDatabase.memory();
    dir = Directory.systemTemp.createTempSync('moonletter-shell-test');
  });

  tearDown(() async {
    await db.close();
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  /// drift 的流在 provider 销毁时会排一个零延时定时器，测试里要让它跑完。
  Future<void> disposeUi(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  }

  testWidgets('宽屏显示侧边栏，点击分支切换路由', (WidgetTester tester) async {
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

    // 默认测试视口 800×600 ≥ 720，走侧边栏分支
    expect(find.text('Calendar'), findsWidgets);
    expect(find.text('Profiles'), findsWidgets);

    await tester.tap(find.text('Profiles').first);
    await tester.pumpAndSettle();

    expect(
      container
          .read(routerProvider)
          .routerDelegate
          .currentConfiguration
          .uri
          .path,
      '/profiles',
    );
    expect(find.byType(ProfilesPage), findsWidgets);

    await disposeUi(tester);
  });

  testWidgets('窄屏显示底部导航', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          appPathsProvider.overrideWithValue(AppPaths.forTesting(dir)),
          appVersionProvider.overrideWith((Ref ref) async => '0.1.0-test'),
          biometricAvailableProvider.overrideWith((Ref ref) async => false),
        ],
        child: const MoonletterApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.calendar_month), findsOneWidget);
    expect(find.byIcon(Icons.people_outline), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

    await disposeUi(tester);
  });
}
