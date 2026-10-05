import 'dart:typed_data';

import 'package:webdav_client/webdav_client.dart' as webdav;

import 'remote_storage.dart';

/// WebDAV 后端（Nextcloud / 坚果云等）。目录结构见 §8.1。
class WebDavStorage implements RemoteStorage {
  WebDavStorage({
    required String baseUrl,
    required String user,
    required String password,
    String directory = 'moonletter',
    webdav.Client? client,
  }) : _base = _normalize(directory),
       _client =
           client ?? webdav.newClient(baseUrl, user: user, password: password);

  final String _base;
  final webdav.Client _client;

  static String _normalize(String directory) {
    final String trimmed = directory.trim();
    if (trimmed.isEmpty || trimmed == '/') {
      return '';
    }
    final String withoutLeading = trimmed.startsWith('/')
        ? trimmed.substring(1)
        : trimmed;
    return withoutLeading.endsWith('/')
        ? withoutLeading.substring(0, withoutLeading.length - 1)
        : withoutLeading;
  }

  /// 远端完整路径（`moonletter/logs/xxx.bin`）。
  String pathOf(String relative) =>
      _base.isEmpty ? relative : '$_base/$relative';

  @override
  Future<void> ensureDir(String path) async {
    final String full = pathOf(path);
    try {
      await _client.mkdirAll(full);
    } catch (_) {
      // 已存在或服务端不支持 MKCOL 时忽略；后续写入会给出真实错误。
    }
  }

  @override
  Future<List<RemoteObject>> list(String prefix) async {
    final String full = pathOf(prefix);
    try {
      final List<webdav.File> files = await _client.readDir(full);
      return files
          .where((webdav.File file) => file.isDir != true && file.name != null)
          .map(
            (webdav.File file) => RemoteObject(
              path: '${prefix.endsWith('/') ? prefix : '$prefix/'}${file.name}',
              size: file.size,
              etag: file.eTag,
              modified: file.mTime,
            ),
          )
          .toList(growable: false);
    } catch (_) {
      return const <RemoteObject>[];
    }
  }

  @override
  Future<Uint8List?> get(String path) async {
    try {
      final List<int> bytes = await _client.read(pathOf(path));
      return Uint8List.fromList(bytes);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> put(String path, Uint8List bytes) async {
    final String full = pathOf(path);
    final List<RemoteObject> existing = await list(_prefixOf(path));
    if (existing.any((RemoteObject file) => file.path == path)) {
      throw AlreadyExistsException(path);
    }
    // webdav_client 在写之前会先对目标路径发 OPTIONS，父目录不存在时该请求
    // 返回 404 而直接失败，所以先递归建目录。
    await ensureDir(_prefixOf(path));
    await _client.write(full, bytes);
  }

  @override
  Future<void> delete(String path) async {
    try {
      await _client.remove(pathOf(path));
    } catch (_) {
      // 已经不存在就当删除成功。
    }
  }

  static String _prefixOf(String path) {
    final int index = path.lastIndexOf('/');
    return index <= 0 ? '' : path.substring(0, index + 1);
  }
}
