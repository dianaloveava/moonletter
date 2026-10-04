import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moonletter/core/app_paths.dart';
import 'package:moonletter/core/l10n/gen/app_localizations.dart';
import 'package:moonletter/data/data_providers.dart';
import 'package:moonletter/data/db/database.dart';
import 'package:moonletter/data/db/tables.dart';
import 'package:moonletter/data/repo/settings_repository.dart';
import 'package:moonletter/data/secure/secure_store.dart';
import 'package:moonletter/domain/lock/lock_providers.dart';
import 'package:moonletter/domain/lock/lock_service.dart';
import 'package:moonletter/features/lock/lock_gate.dart';

/// 内存版安全存储，避免测试碰平台通道。
class _MemorySecureStore extends SecureStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

void main() {
  late AppDatabase db;
  late Directory dir;
  late _MemorySecureStore secure;

  setUp(() {
    db = AppDatabase.memory();
    dir = Directory.systemTemp.createTempSync('moonletter-lock-gate-test');
    secure = _MemorySecureStore();
  });

  tearDown(() async {
    await db.close();
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  Future<Widget> buildGate({required bool locked}) async {
    final SettingsRepository settings = SettingsRepository(db);
    await settings.set(SettingKeys.lockKind, locked ? 'pin' : 'none');
    if (locked) {
      await LockService(secure: secure, settings: settings).setPin('123456');
    }
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        appPathsProvider.overrideWithValue(AppPaths.forTesting(dir)),
        secureStoreProvider.overrideWithValue(secure),
        biometricAvailableProvider.overrideWith((Ref ref) async => false),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (BuildContext context, Widget? child) =>
            LockGate(child: child ?? const SizedBox.shrink()),
        home: const Scaffold(body: Center(child: Text('内容页'))),
      ),
    );
  }

  testWidgets('开启应用锁：先显示解锁页，输入正确 PIN 后进入应用', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    addTearDown(handle.dispose);

    await tester.pumpWidget(await buildGate(locked: true));
    await tester.pumpAndSettle();

    expect(find.text('内容页'), findsNothing, reason: '锁着的时候不显示内容');
    expect(tester.takeException(), isNull, reason: '解锁页不该抛异常');
    expect(find.bySemanticsLabel('1'), findsOneWidget, reason: '数字键盘已渲染');

    for (final String digit in <String>['1', '2', '3', '4', '5', '6']) {
      await tester.tap(find.bySemanticsLabel(digit).first);
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('内容页'), findsOneWidget, reason: 'PIN 正确后解锁');
  });

  testWidgets('PIN 错误时留在解锁页并提示', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    addTearDown(handle.dispose);

    await tester.pumpWidget(await buildGate(locked: true));
    await tester.pumpAndSettle();

    for (final String digit in <String>['0', '0', '0', '0', '0', '0']) {
      await tester.tap(find.bySemanticsLabel(digit).first);
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();

    expect(find.text('内容页'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('未开启应用锁时直接显示内容', (WidgetTester tester) async {
    await tester.pumpWidget(await buildGate(locked: false));
    await tester.pumpAndSettle();

    expect(find.text('内容页'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
