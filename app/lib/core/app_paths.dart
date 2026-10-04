import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 应用数据目录：数据库与头像文件都放在 `getApplicationSupportDirectory()` 下。
class AppPaths {
  AppPaths._(this.supportDir);

  final Directory supportDir;

  static AppPaths? _current;

  /// 当前实例必须在启动时通过 [resolve] 建立。
  static AppPaths get current {
    final AppPaths? instance = _current;
    if (instance == null) {
      throw StateError('AppPaths.resolve() 尚未调用');
    }
    return instance;
  }

  static Future<AppPaths> resolve() async {
    final Directory dir = await getApplicationSupportDirectory();
    final AppPaths paths = AppPaths._(dir);
    await paths.avatarsDir.create(recursive: true);
    _current = paths;
    return paths;
  }

  /// 测试用：直接指向某个目录，不依赖 path_provider。
  factory AppPaths.forTesting(Directory dir) => AppPaths._(dir);

  File get databaseFile => File(p.join(supportDir.path, 'moonletter.db'));

  Directory get avatarsDir => Directory(p.join(supportDir.path, 'avatars'));

  /// 内容寻址的头像文件路径：`avatars/<sha256>.png`。
  File avatarFile(String hash) => File(p.join(avatarsDir.path, '$hash.png'));
}
