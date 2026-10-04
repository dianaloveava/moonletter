import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// 同步加密（§7、§8.2）：
/// 口令 --Argon2id--> 主密钥 --HKDF(info=kind)--> 文件密钥，文件用 AES-256-GCM 加密。
/// 服务端只保存密文；`kdf.json` 明文保存 salt 与参数，用于校验口令是否正确。
abstract final class SyncCrypto {
  /// 文件头魔数（8 字节）
  static const String magic = 'MNLTR001';

  static const int saltLength = 16;
  static const int nonceLength = 12;
  static const int macLength = 16;

  /// OWASP 推荐的 Argon2id 参数（约 19 MiB / 2 轮）。
  static const int defaultMemoryKb = 19456;
  static const int defaultIterations = 2;
  static const int defaultParallelism = 1;
  static const int keyLength = 32;

  static const List<String> kinds = <String>['log', 'snapshot', 'avatar'];

  static List<int> randomBytes(int length) {
    final Random random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  /// 从口令派生主密钥。
  static Future<SecretKey> deriveMasterKey(
    String passphrase, {
    required List<int> salt,
    int memoryKb = defaultMemoryKb,
    int iterations = defaultIterations,
    int parallelism = defaultParallelism,
  }) {
    final Argon2id argon2 = Argon2id(
      memory: memoryKb,
      iterations: iterations,
      parallelism: parallelism,
      hashLength: keyLength,
    );
    return argon2.deriveKeyFromPassword(password: passphrase, nonce: salt);
  }

  /// 按用途派生子密钥。
  static Future<SecretKey> fileKey(SecretKey master, String kind) {
    final Hkdf hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: keyLength);
    return hkdf.deriveKey(
      secretKey: master,
      nonce: utf8.encode('moonletter/$kind'),
    );
  }

  /// 加密成自描述文件（魔数 + kind + nonce + 密文 + GCM tag）。
  static Future<Uint8List> encrypt({
    required SecretKey key,
    required String kind,
    required List<int> clear,
  }) async {
    final List<int> nonce = randomBytes(nonceLength);
    final SecretBox box = await AesGcm.with256bits().encrypt(
      clear,
      secretKey: key,
      nonce: nonce,
    );
    final List<int> kindBytes = utf8.encode(kind);
    return Uint8List.fromList(<int>[
      ...utf8.encode(magic),
      kindBytes.length,
      ...kindBytes,
      ...box.nonce,
      ...box.cipherText,
      ...box.mac.bytes,
    ]);
  }

  /// 解密；口令/密钥不对或文件损坏时抛 [FormatException]。
  static Future<List<int>> decrypt({
    required SecretKey key,
    required List<int> file,
  }) async {
    final Uint8List bytes = Uint8List.fromList(file);
    if (bytes.length < magic.length + 1 + nonceLength + macLength) {
      throw const FormatException('同步文件损坏');
    }
    final String header = utf8.decode(bytes.sublist(0, magic.length));
    if (header != magic) {
      throw const FormatException('不是月信的同步文件');
    }
    final int kindLength = bytes[magic.length];
    final int kindEnd = magic.length + 1 + kindLength;
    final int bodyStart = kindEnd + nonceLength;
    final int bodyEnd = bytes.length - macLength;
    if (bodyEnd < bodyStart) {
      throw const FormatException('同步文件损坏');
    }
    final SecretBox box = SecretBox(
      bytes.sublist(bodyStart, bodyEnd),
      nonce: bytes.sublist(kindEnd, bodyStart),
      mac: Mac(bytes.sublist(bodyEnd)),
    );
    try {
      return await AesGcm.with256bits().decrypt(box, secretKey: key);
    } on SecretBoxAuthenticationError {
      throw const FormatException('口令不正确');
    }
  }

  /// 读取文件里的用途标记（不校验密钥）。
  static String kindOf(List<int> file) {
    final Uint8List bytes = Uint8List.fromList(file);
    final int kindLength = bytes[magic.length];
    return utf8.decode(
      bytes.sublist(magic.length + 1, magic.length + 1 + kindLength),
    );
  }

  /// 生成明文 `kdf.json`（含参数、salt 和一段校验密文）。
  static Future<String> buildKdfJson(
    String passphrase, {
    int memoryKb = defaultMemoryKb,
    int iterations = defaultIterations,
    int parallelism = defaultParallelism,
  }) async {
    final List<int> salt = randomBytes(saltLength);
    final SecretKey master = await deriveMasterKey(
      passphrase,
      salt: salt,
      memoryKb: memoryKb,
      iterations: iterations,
      parallelism: parallelism,
    );
    final SecretKey checkKey = await fileKey(master, 'check');
    final Uint8List check = await encrypt(
      key: checkKey,
      kind: 'check',
      clear: utf8.encode('moonletter'),
    );
    return jsonEncode(<String, Object?>{
      'v': 1,
      'alg': 'argon2id',
      'mem': memoryKb,
      'iter': iterations,
      'par': parallelism,
      'salt': base64Encode(salt),
      'check': base64Encode(check),
    });
  }

  /// 用口令解 `kdf.json`：成功返回主密钥，口令不对返回 null。
  static Future<SecretKey?> unlockWithKdf(
    String passphrase,
    String kdfJson,
  ) async {
    final Map<String, Object?> json =
        jsonDecode(kdfJson) as Map<String, Object?>;
    final List<int> salt = base64Decode(json['salt']! as String);
    final SecretKey master = await deriveMasterKey(
      passphrase,
      salt: salt,
      memoryKb: (json['mem'] as num?)?.toInt() ?? defaultMemoryKb,
      iterations: (json['iter'] as num?)?.toInt() ?? defaultIterations,
      parallelism: (json['par'] as num?)?.toInt() ?? defaultParallelism,
    );
    final String? check = json['check'] as String?;
    if (check == null) {
      return master;
    }
    try {
      final SecretKey checkKey = await fileKey(master, 'check');
      await decrypt(key: checkKey, file: base64Decode(check));
      return master;
    } on FormatException {
      return null;
    }
  }

  /// 导出主密钥（base64），存进系统安全存储。
  static Future<String> exportKey(SecretKey key) async =>
      base64Encode(await key.extractBytes());

  static Future<SecretKey> importKey(String base64Key) async =>
      SecretKey(base64Decode(base64Key));
}
