import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'windows_app.dart';

/// Windows 桌面端行为（托盘/自启/关闭到托盘）。
/// 启动时在 `main.dart` 里 `overrideWithValue` 注入；非 Windows 平台为 null。
final Provider<WindowsApp?> windowsAppProvider = Provider<WindowsApp?>(
  (Ref ref) => null,
);
