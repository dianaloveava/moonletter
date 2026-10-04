// tray_manager 0.7 的主库换成了底层 nativeapi 绑定；这里用官方保留的
// 兼容层（legacy）拿到 setIcon / setContextMenu / TrayListener 这组稳定 API。
// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:path/path.dart' as p;
import 'package:tray_manager/legacy.dart';
import 'package:window_manager/window_manager.dart';

import '../app_paths.dart';

/// Windows 桌面端行为：
/// - 托盘常驻（菜单：打开主界面 / 立即同步 / 退出）
/// - 开机自启（设置里可关，默认开）
/// - 关闭窗口时默认最小化到托盘（可在设置里改成直接退出）
///
/// 通知依赖程序运行，因此托盘常驻 + 自启是提醒能按时出现的前提。
class WindowsApp with TrayListener, WindowListener {
  WindowsApp({
    required this.onOpenRequested,
    required this.onSyncRequested,
    required this.onQuitRequested,
  });

  final void Function() onOpenRequested;
  final void Function() onSyncRequested;
  final void Function() onQuitRequested;

  static const String _trayAsset = 'assets/icon/tray.ico';

  bool _closeToTray = true;
  bool _initialized = false;

  bool get isSupported => Platform.isWindows;

  Future<void> init({
    required bool autostart,
    required bool closeToTray,
  }) async {
    if (!isSupported || _initialized) {
      return;
    }
    _closeToTray = closeToTray;
    _initialized = true;

    trayManager.addListener(this);
    windowManager.addListener(this);
    await windowManager.setPreventClose(true);

    await trayManager.setIcon(await _trayIconPath());
    await trayManager.setToolTip('月信');
    await trayManager.setContextMenu(
      Menu(
        items: <MenuItem>[
          MenuItem(
            key: 'open',
            label: '打开主界面',
            onClick: (_) => onOpenRequested(),
          ),
          MenuItem(
            key: 'sync',
            label: '立即同步',
            onClick: (_) => onSyncRequested(),
          ),
          MenuItem.separator(),
          MenuItem(key: 'quit', label: '退出', onClick: (_) => onQuitRequested()),
        ],
      ),
    );

    await setAutostart(autostart);
  }

  /// 开机自启开关（写入 HKCU 的 Run 项，不需要管理员权限）。
  Future<void> setAutostart(bool enabled) async {
    if (!isSupported) {
      return;
    }
    launchAtStartup.setup(
      appName: 'Moonletter',
      appPath: Platform.resolvedExecutable,
    );
    if (enabled) {
      await launchAtStartup.enable();
    } else {
      await launchAtStartup.disable();
    }
  }

  /// 关闭窗口时是隐藏到托盘还是直接退出。
  void setCloseToTray(bool value) => _closeToTray = value;

  Future<void> dispose() async {
    if (!isSupported) {
      return;
    }
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    await trayManager.destroy();
  }

  Future<void> showWindow() async {
    if (!isSupported) {
      return;
    }
    await windowManager.show();
    await windowManager.focus();
  }

  /// 托盘图标需要真实文件路径，首次运行时从资源里写到支持目录。
  Future<String> _trayIconPath() async {
    final File file = File(
      p.join(AppPaths.current.supportDir.path, 'tray.ico'),
    );
    if (!await file.exists()) {
      final ByteData data = await rootBundle.load(_trayAsset);
      await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
    }
    return file.path;
  }

  @override
  void onTrayIconMouseDown() => onOpenRequested();

  @override
  void onTrayIconRightMouseDown() => trayManager.popUpContextMenu();

  @override
  void onWindowClose() {
    if (!_closeToTray) {
      onQuitRequested();
      return;
    }
    windowManager.hide();
  }
}
