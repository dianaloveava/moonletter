import 'package:flutter_test/flutter_test.dart';
import 'package:moonletter/data/db/database.dart';
import 'package:moonletter/data/repo/settings_repository.dart';
import 'package:moonletter/data/secure/secure_store.dart';
import 'package:moonletter/domain/lock/lock_service.dart';

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
  late _MemorySecureStore secure;
  late LockService lock;

  setUp(() {
    db = AppDatabase.memory();
    secure = _MemorySecureStore();
    lock = LockService(secure: secure, settings: SettingsRepository(db));
  });

  tearDown(() => db.close());

  test('设置 PIN 后能校验通过，错误 PIN 校验失败', () async {
    expect(await lock.hasPin(), isFalse);
    await lock.setPin('123456');
    expect(await lock.hasPin(), isTrue);
    expect(await lock.verifyPin('123456'), isTrue);
    expect(await lock.verifyPin('654321'), isFalse);
  });

  test('PIN 以 Argon2id 派生值存储，不落明文', () async {
    await lock.setPin('123456');
    final String? hash = await secure.read(SecureStore.keyPinHash);
    final String? salt = await secure.read(SecureStore.keyPinSalt);
    expect(hash, isNotNull);
    expect(salt, isNotNull);
    expect(hash!.contains('123456'), isFalse);
    expect(salt!.contains('123456'), isFalse);
  });

  test('试错 5 次后进入冷却，冷却期内正确 PIN 也被拒绝', () async {
    await lock.setPin('123456');
    for (int i = 0; i < LockService.maxAttemptsBeforeCooldown; i++) {
      expect(await lock.verifyPin('000000'), isFalse);
    }
    expect(lock.cooldownRemaining, greaterThan(Duration.zero));
    expect(await lock.verifyPin('123456'), isFalse);
  });

  test('成功后清零失败计数', () async {
    await lock.setPin('123456');
    await lock.verifyPin('000000');
    await lock.verifyPin('000000');
    expect(await lock.verifyPin('123456'), isTrue);
    expect(lock.cooldownRemaining, Duration.zero);
    for (int i = 0; i < LockService.maxAttemptsBeforeCooldown - 1; i++) {
      await lock.verifyPin('000000');
    }
    expect(lock.cooldownRemaining, Duration.zero);
  });

  test('关闭应用锁会清掉 PIN 并把开关设回 none', () async {
    await lock.setPin('123456');
    await lock.setLockKind('pin_bio');
    expect(await lock.isBiometricEnabled(), isTrue);

    await lock.clearPin();
    expect(await lock.hasPin(), isFalse);
    expect(await lock.lockKind(), 'none');
    expect(await lock.isLockEnabled(), isFalse);
    expect(await lock.verifyPin('123456'), isFalse);
  });

  test('锁开关读写', () async {
    expect(await lock.lockKind(), 'none');
    await lock.setLockKind('pin');
    expect(await lock.isLockEnabled(), isTrue);
    expect(await lock.isBiometricEnabled(), isFalse);
  });
}
