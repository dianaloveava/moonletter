import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/platform/android_platform.dart';
import '../../data/data_providers.dart';
import '../../data/db/tables.dart';
import 'lock_service.dart';

final Provider<LockService> lockServiceProvider = Provider<LockService>(
  (Ref ref) => LockService(
    secure: ref.watch(secureStoreProvider),
    settings: ref.watch(settingsRepositoryProvider),
  ),
);

/// 应用锁状态。[locked] 为 true 时显示解锁页。
class AppLockController extends Notifier<bool> {
  @override
  bool build() {
    final String kind = switch (ref.watch(settingsProvider)) {
      AsyncData<Map<String, String>>(value: final Map<String, String> v) =>
        v[SettingKeys.lockKind] ?? 'none',
      _ => 'none',
    };
    _applySecureFlag(kind != 'none');
    return kind != 'none';
  }

  /// 解锁成功。
  void unlock() {
    if (state) {
      state = false;
      _applySecureFlag(false);
    }
  }

  /// 切到后台或启动时上锁。
  void lock() {
    final String kind = switch (ref.read(settingsProvider)) {
      AsyncData<Map<String, String>>(value: final Map<String, String> v) =>
        v[SettingKeys.lockKind] ?? 'none',
      _ => 'none',
    };
    if (kind == 'none') {
      state = false;
      _applySecureFlag(false);
      return;
    }
    state = true;
    _applySecureFlag(true);
  }

  /// Android 上开启锁时挡住最近任务缩略图与截屏。
  void _applySecureFlag(bool enabled) {
    if (!AndroidPlatform.isAndroid) {
      return;
    }
    // 不同步等待：这里只是尽力而为，失败也不影响解锁流程。
    AndroidPlatform.setSecureFlag(enabled);
  }
}

final appLockProvider = NotifierProvider<AppLockController, bool>(
  AppLockController.new,
);

/// 当前设备是否可用生物识别（Android 指纹/面容、Windows Hello）。
final FutureProvider<bool> biometricAvailableProvider = FutureProvider<bool>((
  Ref ref,
) async {
  if (!Platform.isAndroid && !Platform.isWindows) {
    return false;
  }
  try {
    final LocalAuthentication auth = LocalAuthentication();
    final bool supported = await auth.isDeviceSupported();
    final bool canCheck = await auth.canCheckBiometrics;
    return supported && canCheck;
  } catch (_) {
    return false;
  }
});
