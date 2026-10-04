import 'dart:io';

import 'package:flutter/services.dart';

/// Android 侧的平台能力，方法在 `MainActivity.kt` 的 `moonletter/platform` 通道里实现。
abstract final class AndroidPlatform {
  static const MethodChannel _channel = MethodChannel('moonletter/platform');

  static bool get isAndroid => Platform.isAndroid;

  /// 应用锁开启时挡住最近任务缩略图与截屏（FLAG_SECURE）。
  static Future<void> setSecureFlag(bool enabled) async {
    if (!isAndroid) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('setSecureFlag', <String, dynamic>{
        'enabled': enabled,
      });
    } on PlatformException {
      // 通道不可用时静默降级，不影响其它功能。
    }
  }

  /// 打开系统的电池优化设置页（不申请白名单权限，避免商店政策问题）。
  static Future<void> openBatteryOptimizationSettings() async {
    if (!isAndroid) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('openBatteryOptimizationSettings');
    } on PlatformException {
      // 忽略：部分定制系统没有这个页面。
    }
  }
}
