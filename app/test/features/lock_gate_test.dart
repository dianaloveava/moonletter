import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

/// 组件测试只关心解锁流程的接线：真正的 Argon2id 校验由 lock_service_test.dart 覆盖，
/// 放在 widget test 里会卡在假时钟上（cryptography 内部用 Future.delayed 分片）。
class _FakeLockService extends LockService {
  _FakeLockService({required super.secure, required super.settings});

  static const String pin = '123456';

  @override
  Future<bool> verifyPin(String value) async => value == pin;
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

  /// 卸载组件树并冲掉 drift 取消订阅时的零延时定时器，否则测试收尾会报 pending timer。
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  }

  Future<Widget> buildGate({required bool locked}) async {
    final SettingsRepository settings = SettingsRepository(db);
    await settings.set(SettingKeys.lockKind, locked ? 'pin' : 'none');
    if (locked) {
      // 真正写一次 PIN 记录，让 hasPin / lockKind 走真实路径。
      await LockService(secure: secure, settings: settings).setPin(
        _FakeLockService.pin,
      );
    }
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        appPathsProvider.overrideWithValue(AppPaths.forTesting(dir)),
        secureStoreProvider.overrideWithValue(secure),
        lockServiceProvider.overrideWithValue(
          _FakeLockService(secure: secure, settings: SettingsRepository(db)),
        ),
        biometricAvailableProvider.overrideWith((Ref ref) async => false),
      ],
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (BuildContext context, Widget? child) =>
            LockGate(child: child ?? const SizedBox.shrink()),
        home: const Scaffold(body: Center(child: Text('内容页'))),
      ),
    );
  }

  /// 语义树里是否暴露了这段文字：锁屏/遮罩期间必须看不到（读屏也不能念出来）。
  bool semanticsExposes(WidgetTester tester, String text) {
    // 语义树挂在 RenderView 的 pipeline owner 上；ExcludeSemantics 会把子树摘掉。
    SemanticsNode? root;
    for (final RenderView view in tester.binding.renderViews) {
      root = view.owner?.semanticsOwner?.rootSemanticsNode;
      if (root != null) {
        break;
      }
    }
    if (root == null) {
      return false;
    }
    bool visit(SemanticsNode node) {
      if (node.label.contains(text)) {
        return true;
      }
      bool found = false;
      node.visitChildren((SemanticsNode child) {
        found = found || visit(child);
        return !found;
      });
      return found;
    }

    return visit(root);
  }

  testWidgets('开启应用锁：先显示解锁页，输入正确 PIN 后进入应用', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();

    // 建库、写设置、算 Argon2id 都是真实异步，必须放在 runAsync 里。
    final Widget gate =
        await tester.runAsync(() => buildGate(locked: true)) ??
        const SizedBox.shrink();
    await tester.pumpWidget(gate);
    await tester.pumpAndSettle();

    expect(
      semanticsExposes(tester, '内容页'),
      isFalse,
      reason: '锁着的时候不暴露内容',
    );
    expect(tester.takeException(), isNull, reason: '解锁页不该抛异常');
    expect(find.bySemanticsLabel('1'), findsOneWidget, reason: '数字键盘已渲染');

    for (final String digit in <String>['1', '2', '3', '4', '5', '6']) {
      await tester.tap(find.bySemanticsLabel(digit).first);
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('内容页'), findsOneWidget, reason: 'PIN 正确后解锁');
    expect(
      semanticsExposes(tester, '内容页'),
      isTrue,
      reason: '解锁后内容可读',
    );
    handle.dispose();
    await unmount(tester);
  });

  testWidgets('PIN 错误时留在解锁页并提示', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();

    final Widget gate =
        await tester.runAsync(() => buildGate(locked: true)) ??
        const SizedBox.shrink();
    await tester.pumpWidget(gate);
    await tester.pumpAndSettle();

    for (final String digit in <String>['0', '0', '0', '0', '0', '0']) {
      await tester.tap(find.bySemanticsLabel(digit).first);
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();

    expect(semanticsExposes(tester, '内容页'), isFalse);
    expect(find.text('PIN 不正确'), findsOneWidget, reason: '提示密码错误');
    expect(tester.takeException(), isNull);

    handle.dispose();
    await unmount(tester);
  });

  testWidgets('未开启应用锁时直接显示内容', (WidgetTester tester) async {
    final Widget gate =
        await tester.runAsync(() => buildGate(locked: false)) ??
        const SizedBox.shrink();
    await tester.pumpWidget(gate);
    await tester.pumpAndSettle();

    expect(find.text('内容页'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await unmount(tester);
  });

  testWidgets('切后台只盖遮罩，不销毁页面状态', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    final Widget gate =
        await tester.runAsync(() => buildGate(locked: false)) ??
        const SizedBox.shrink();
    await tester.pumpWidget(gate);
    await tester.pumpAndSettle();
    final Element before = tester.element(find.text('内容页'));

    // 系统文件选择器一类的后台往返：inactive → resumed。
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pumpAndSettle();
    expect(find.text('已锁定'), findsOneWidget, reason: '后台显示隐私遮罩');
    expect(
      semanticsExposes(tester, '内容页'),
      isFalse,
      reason: '遮罩期间不暴露内容',
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('已锁定'), findsNothing, reason: '回前台撤掉遮罩');
    expect(
      tester.element(find.text('内容页')),
      same(before),
      reason: '页面 Element 复用，正在进行的异步操作不会中断',
    );
    expect(tester.takeException(), isNull);

    handle.dispose();
    await unmount(tester);
  });
}
