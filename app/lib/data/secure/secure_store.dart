import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 密钥与口令只进系统安全存储（Windows DPAPI / Android Keystore），不落 DB。
class SecureStore {
  SecureStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  /// PIN 的 Argon2id 输出（base64）
  static const String keyPinHash = 'pin_hash';

  /// PIN 的 salt（base64）
  static const String keyPinSalt = 'pin_salt';

  /// 同步主密钥（base64，32 字节）
  static const String keySyncKey = 'sync_key';

  /// 同步口令派生参数（JSON：mem/iter/par/salt）
  static const String keySyncKdf = 'sync_kdf';

  /// WebDAV 密码
  static const String keyWebdavPassword = 'webdav_password';

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<bool> has(String key) async => await _storage.read(key: key) != null;
}
