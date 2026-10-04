import 'dart:typed_data';

/// 远端文件（列表用）。
class RemoteObject {
  const RemoteObject({required this.path, this.size, this.etag, this.modified});

  final String path;
  final int? size;
  final String? etag;
  final DateTime? modified;
}

/// 同名文件已存在（日志与快照都只写一次，重复写入说明状态不对）。
class AlreadyExistsException implements Exception {
  const AlreadyExistsException(this.path);

  final String path;

  @override
  String toString() => '远端已存在同名文件：$path';
}

/// 同步后端（WebDAV 或中转服务）的统一接口（§8.4）。
abstract class RemoteStorage {
  /// 列出 [prefix] 下的文件（包含该前缀本身是目录的情况）。
  Future<List<RemoteObject>> list(String prefix);

  Future<Uint8List?> get(String path);

  /// 写入新文件；已存在时抛 [AlreadyExistsException]。
  Future<void> put(String path, Uint8List bytes);

  Future<void> delete(String path);

  /// 确保目录存在（WebDAV 需要 MKCOL，中转服务是空操作）。
  Future<void> ensureDir(String path);
}
