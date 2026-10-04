import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

import '../../data/db/tables.dart';
import '../../data/repo/settings_repository.dart';
import '../../data/secure/secure_store.dart';

/// 应用锁：6 位 PIN 用 Argon2id 派生后存系统安全存储（§7）。
/// 连续输错 5 次后每次追加 30 秒等待（只记在内存里）。
class LockService {
  LockService({required this.secure, required this.settings});

  static const int pinLength = 6;
  static const int _memoryKb = 19456;
  static const int _iterations = 2;
  static const int _parallelism = 1;
  static const int _hashLength = 32;
  static const int _saltLength = 16;
  static const int maxAttemptsBeforeCooldown = 5;
  static const Duration cooldownStep = Duration(seconds: 30);

  final SecureStore secure;
  final SettingsRepository settings;

  int _failures = 0;
  DateTime? _blockedUntil;

  /// 是否已经设置过 PIN。
  Future<bool> hasPin() async =>
      (await secure.read(SecureStore.keyPinHash)) != null;

  /// 应用锁开关：`none` / `pin` / `pin_bio`。
  Future<String> lockKind() async =>
      await settings.string(SettingKeys.lockKind, fallback: 'none');

  Future<bool> isLockEnabled() async => (await lockKind()) != 'none';

  Future<bool> isBiometricEnabled() async => (await lockKind()) == 'pin_bio';

  Future<void> setLockKind(String kind) =>
      settings.set(SettingKeys.lockKind, kind);

  /// 剩余等待时间（不在冷却中返回零）。
  Duration get cooldownRemaining {
    final DateTime? until = _blockedUntil;
    if (until == null) {
      return Duration.zero;
    }
    final Duration left = until.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  /// 设置（或修改）PIN。
  Future<void> setPin(String pin) async {
    final List<int> salt = _randomBytes(_saltLength);
    final SecretKey key = await _derive(pin, salt);
    final List<int> bytes = await key.extractBytes();
    await secure.write(SecureStore.keyPinSalt, _base64(salt));
    await secure.write(SecureStore.keyPinHash, _base64(bytes));
    _failures = 0;
    _blockedUntil = null;
  }

  /// 校验 PIN：冷却中直接返回 false。
  Future<bool> verifyPin(String pin) async {
    if (cooldownRemaining > Duration.zero) {
      return false;
    }
    final String? saltB64 = await secure.read(SecureStore.keyPinSalt);
    final String? hashB64 = await secure.read(SecureStore.keyPinHash);
    if (saltB64 == null || hashB64 == null) {
      return false;
    }
    final SecretKey key = await _derive(pin, _fromBase64(saltB64));
    final List<int> actual = await key.extractBytes();
    final bool ok = _constantTimeEquals(actual, _fromBase64(hashB64));
    if (ok) {
      _failures = 0;
      _blockedUntil = null;
    } else {
      _failures += 1;
      if (_failures >= maxAttemptsBeforeCooldown) {
        final int over = _failures - maxAttemptsBeforeCooldown + 1;
        _blockedUntil = DateTime.now().add(cooldownStep * over);
      }
    }
    return ok;
  }

  /// 关闭应用锁：清掉 PIN 与开关。
  Future<void> clearPin() async {
    await secure.delete(SecureStore.keyPinHash);
    await secure.delete(SecureStore.keyPinSalt);
    await setLockKind('none');
    _failures = 0;
    _blockedUntil = null;
  }

  Future<SecretKey> _derive(String pin, List<int> salt) {
    final Argon2id argon2 = Argon2id(
      memory: _memoryKb,
      iterations: _iterations,
      parallelism: _parallelism,
      hashLength: _hashLength,
    );
    return argon2.deriveKeyFromPassword(password: pin, nonce: salt);
  }

  static List<int> _randomBytes(int length) {
    final Random random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }
    int diff = 0;
    for (int i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  static String _base64(List<int> bytes) => base64Encode(bytes);

  static List<int> _fromBase64(String value) => base64Decode(value);
}
