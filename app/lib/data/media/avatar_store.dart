import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:image/image.dart' as img;

import '../../core/app_paths.dart';

/// 头像文件仓库：PNG 字节按 sha256 内容寻址存成 `avatars/<hash>.png`。
/// 相同内容只写一次；未被引用的文件不主动删除（墓碑成员可能仍需要它）。
class AvatarStore {
  AvatarStore(this._paths);

  final AppPaths _paths;

  static final HashAlgorithm _sha256 = Sha256();

  static Future<String> hashOf(Uint8List bytes) async {
    final Hash hash = await _sha256.hash(bytes);
    return _hex(hash.bytes);
  }

  /// 保存 PNG 字节，返回内容 hash。
  Future<String> save(Uint8List bytes) async {
    final String hash = await hashOf(bytes);
    final File file = _paths.avatarFile(hash);
    if (!await file.exists()) {
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
    }
    return hash;
  }

  /// 把用户选的图片（任意常见格式）缩到最长边 [maxSize] 并转成 PNG 后保存。
  Future<String> saveFromImage(Uint8List raw, {int maxSize = 512}) async {
    final img.Image? decoded = img.decodeImage(raw);
    if (decoded == null) {
      throw const FormatException('无法解析所选图片');
    }
    img.Image result = decoded;
    if (decoded.width > maxSize || decoded.height > maxSize) {
      result = decoded.width >= decoded.height
          ? img.copyResize(
              decoded,
              width: maxSize,
              interpolation: img.Interpolation.average,
            )
          : img.copyResize(
              decoded,
              height: maxSize,
              interpolation: img.Interpolation.average,
            );
    }
    return save(Uint8List.fromList(img.encodePng(result, level: 6)));
  }

  Future<Uint8List?> read(String hash) async {
    final File file = _paths.avatarFile(hash);
    if (!await file.exists()) {
      return null;
    }
    return file.readAsBytes();
  }

  Future<bool> exists(String hash) => _paths.avatarFile(hash).exists();

  /// 未被任何成员引用的头像 hash（仅用于统计与后续清理入口）。
  Future<List<String>> unusedHashes(Iterable<String> referenced) async {
    final Set<String> keep = referenced.toSet();
    final Directory dir = _paths.avatarsDir;
    if (!await dir.exists()) {
      return const <String>[];
    }
    final List<String> stale = <String>[];
    await for (final FileSystemEntity entity in dir.list()) {
      if (entity is! File) {
        continue;
      }
      final String name = entity.uri.pathSegments.last;
      if (!name.endsWith('.png')) {
        continue;
      }
      final String hash = name.substring(0, name.length - 4);
      if (!keep.contains(hash)) {
        stale.add(hash);
      }
    }
    return stale;
  }

  static String _hex(List<int> bytes) {
    final StringBuffer buffer = StringBuffer();
    for (final int byte in bytes) {
      buffer.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}
