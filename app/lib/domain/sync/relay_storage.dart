import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'remote_storage.dart';

/// 中转服务后端（Cloudflare Worker + R2，接口见 §8.5）。
class RelayStorage implements RemoteStorage {
  RelayStorage({
    required String baseUrl,
    required String namespace,
    http.Client? client,
  }) : _baseUrl = baseUrl.endsWith('/')
           ? baseUrl.substring(0, baseUrl.length - 1)
           : baseUrl,
       // 私有字段不能作为命名参数直接初始化。
       // ignore: prefer_initializing_formals
       _namespace = namespace,
       _client = client ?? http.Client();
  final String _baseUrl;
  final String _namespace;
  final http.Client _client;

  Map<String, String> get _headers => <String, String>{
    'Authorization': 'Bearer $_namespace',
  };

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  @override
  Future<void> ensureDir(String path) async {
    // 对象存储没有目录概念。
  }

  @override
  Future<List<RemoteObject>> list(String prefix) async {
    final http.Response response = await _client.get(
      _uri('/v1/list/$_namespace?prefix=${Uri.encodeQueryComponent(prefix)}'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      return const <RemoteObject>[];
    }
    final Map<String, dynamic> json =
        jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> files = json['files'] as List<dynamic>? ?? <dynamic>[];
    return files
        .map((dynamic item) {
          final Map<String, dynamic> file = item as Map<String, dynamic>;
          return RemoteObject(
            path: file['path'] as String? ?? '',
            size: (file['size'] as num?)?.toInt(),
            etag: file['etag'] as String?,
            modified: DateTime.tryParse(file['modified'] as String? ?? ''),
          );
        })
        .where((RemoteObject file) => file.path.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<Uint8List?> get(String path) async {
    final http.Response response = await _client.get(
      _uri('/v1/o/$_namespace/$path'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      return null;
    }
    return response.bodyBytes;
  }

  @override
  Future<void> put(String path, Uint8List bytes) async {
    final http.Response response = await _client.put(
      _uri('/v1/o/$_namespace/$path'),
      headers: _headers,
      body: bytes,
    );
    if (response.statusCode == 409) {
      throw AlreadyExistsException(path);
    }
    if (response.statusCode >= 300) {
      throw http.ClientException(
        '中转服务返回 ${response.statusCode}',
        _uri('/v1/o/$_namespace/$path'),
      );
    }
  }

  @override
  Future<void> delete(String path) async {
    await _client.delete(_uri('/v1/o/$_namespace/$path'), headers: _headers);
  }
}
