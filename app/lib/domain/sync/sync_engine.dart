import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../../data/db/database.dart';
import '../../data/repo/sync_repository.dart';
import '../../data/secure/secure_store.dart';
import 'remote_storage.dart';
import 'sync_codec.dart';
import 'sync_crypto.dart';
import 'sync_merge.dart';

/// 同步失败（网络、服务端等）。
class SyncException implements Exception {
  const SyncException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 口令不对 / 远端口令与本地不一致。
class SyncAuthException extends SyncException {
  const SyncAuthException() : super('口令不正确');
}

/// 需要用户先给口令：远端还没有 kdf.json，或本机没有记住主密钥。
/// 与 [SyncAuthException] 区分开，界面才能当场问口令重试，而不是报「口令不正确」。
class SyncPassphraseNeeded extends SyncException {
  const SyncPassphraseNeeded() : super('需要同步口令');
}

/// 一次同步的结果。
class SyncResult {
  const SyncResult({
    required this.filesRead,
    required this.recordsApplied,
    required this.recordsUploaded,
    required this.compacted,
  });

  final int filesRead;
  final int recordsApplied;
  final int recordsUploaded;
  final bool compacted;
}

/// 同步流程（§8.3）：解密远端日志/快照 → 按记录合并 → 上传本地改动 → 必要时压缩。
class SyncEngine {
  SyncEngine({
    required this.storage,
    required this.repository,
    required this.database,
    required this.secure,
  });

  static const String kdfPath = 'kdf.json';
  static const int compactThreshold = 30;

  final RemoteStorage storage;
  final SyncRepository repository;
  final AppDatabase database;
  final SecureStore secure;

  /// [passphrase] 为空时用安全存储里的主密钥（后台自动同步用）。
  Future<SyncResult> sync({String? passphrase}) async {
    final SecretKey master = await _masterKey(passphrase);

    int filesRead = 0;
    int recordsApplied = 0;

    // 1) 先快照、后日志，逐文件合并（merge 幂等，顺序不影响结果）。
    final List<RemoteObject> files = <RemoteObject>[
      ...await storage.list('snapshots/'),
      ...await storage.list('logs/'),
    ];
    for (final RemoteObject file in files) {
      final bool applied = await database.remoteFilesDao.isApplied(
        file.path,
        etag: file.etag,
        size: file.size,
      );
      if (applied) {
        continue;
      }
      final Uint8List? bytes = await storage.get(file.path);
      if (bytes == null) {
        continue;
      }
      final List<SyncRecord> records = await _decodeFile(master, bytes);
      if (records.isEmpty) {
        await database.remoteFilesDao.mark(
          file.path,
          etag: file.etag,
          size: file.size,
        );
        continue;
      }
      final List<SyncRecord> local = await repository.collectRecords(
        includeAvatars: false,
      );
      recordsApplied += await repository.applyRecords(
        diffToApply(local, mergeRecords(local, records)),
      );
      await database.remoteFilesDao.mark(
        file.path,
        etag: file.etag,
        size: file.size,
      );
      filesRead++;
    }

    // 2) 上传本地待同步记录（一条日志只写一次，不修改）。
    int uploaded = 0;
    final List<PendingChange> pending = await database.pendingChangesDao.all();
    if (pending.isNotEmpty) {
      final List<SyncRecord> records = await repository.collectRecordsByIds(
        pending,
      );
      if (records.isNotEmpty) {
        final path = await _writeLog(master, records);
        if (path != null) {
          uploaded = records.length;
        }
      }
      await database.pendingChangesDao.clearAll(pending);
    }

    // 3) 日志太多时压成一个快照，并删掉已并入的日志。
    bool compacted = false;
    final List<RemoteObject> logs = await storage.list('logs/');
    if (logs.length >= compactThreshold) {
      compacted = await _compact(master, logs);
    }

    return SyncResult(
      filesRead: filesRead,
      recordsApplied: recordsApplied,
      recordsUploaded: uploaded,
      compacted: compacted,
    );
  }

  /// 重置同步：清空远端目录（用于换口令）。
  Future<void> resetRemote() async {
    for (final RemoteObject file in <RemoteObject>[
      ...await storage.list('logs/'),
      ...await storage.list('snapshots/'),
    ]) {
      await storage.delete(file.path);
    }
    await storage.delete(kdfPath);
    await secure.delete(SecureStore.keySyncKey);
    await secure.delete(SecureStore.keySyncKdf);
  }

  Future<SecretKey> _masterKey(String? passphrase) async {
    final Uint8List? kdfBytes = await storage.get(kdfPath);
    if (kdfBytes == null) {
      // 远端还是空的：用当前口令新建 kdf.json。
      final String effective = passphrase ?? '';
      if (effective.isEmpty) {
        throw const SyncPassphraseNeeded();
      }
      final String kdfJson = await SyncCrypto.buildKdfJson(effective);
      await storage.put(kdfPath, Uint8List.fromList(utf8.encode(kdfJson)));
      final SecretKey? master = await SyncCrypto.unlockWithKdf(
        effective,
        kdfJson,
      );
      if (master == null) {
        throw const SyncAuthException();
      }
      await _rememberKey(master, kdfJson);
      return master;
    }

    final String kdfJson = utf8.decode(kdfBytes);
    if (passphrase != null) {
      final SecretKey? master = await SyncCrypto.unlockWithKdf(
        passphrase,
        kdfJson,
      );
      if (master == null) {
        throw const SyncAuthException();
      }
      await _rememberKey(master, kdfJson);
      return master;
    }

    final String? storedKey = await secure.read(SecureStore.keySyncKey);
    if (storedKey != null) {
      return SyncCrypto.importKey(storedKey);
    }
    throw const SyncPassphraseNeeded();
  }

  Future<void> _rememberKey(SecretKey master, String kdfJson) async {
    await secure.write(
      SecureStore.keySyncKey,
      await SyncCrypto.exportKey(master),
    );
    await secure.write(SecureStore.keySyncKdf, kdfJson);
  }

  Future<List<SyncRecord>> _decodeFile(
    SecretKey master,
    Uint8List bytes,
  ) async {
    final String kind = SyncCrypto.kindOf(bytes);
    final SecretKey key = await SyncCrypto.fileKey(master, kind);
    final List<int> clear = await SyncCrypto.decrypt(key: key, file: bytes);
    return decodeRecords(utf8.decode(clear));
  }

  Future<String?> _writeLog(SecretKey master, List<SyncRecord> records) async {
    final String deviceId = await database.kvDao.deviceId();
    final String path =
        'logs/$deviceId-${DateTime.now().millisecondsSinceEpoch}.bin';
    final SecretKey key = await SyncCrypto.fileKey(master, 'log');
    final Uint8List bytes = await SyncCrypto.encrypt(
      key: key,
      kind: 'log',
      clear: utf8.encode(encodeRecords(records)),
    );
    await storage.ensureDir('logs/');
    try {
      await storage.put(path, bytes);
    } on AlreadyExistsException {
      return null;
    }
    await database.remoteFilesDao.mark(path, size: bytes.length);
    return path;
  }

  Future<bool> _compact(SecretKey master, List<RemoteObject> logs) async {
    final List<SyncRecord> records = await repository.collectRecords();
    final String path =
        'snapshots/${DateTime.now().millisecondsSinceEpoch}.bin';
    final String payload = jsonEncode(<String, Object?>{
      'v': 1,
      'kind': 'snapshot',
      'at': DateTime.now().millisecondsSinceEpoch,
      'mergedFiles': logs.map((RemoteObject file) => file.path).toList(),
      'records': records.map((SyncRecord record) => record.toJson()).toList(),
    });
    final SecretKey key = await SyncCrypto.fileKey(master, 'snapshot');
    final Uint8List bytes = await SyncCrypto.encrypt(
      key: key,
      kind: 'snapshot',
      clear: utf8.encode(payload),
    );
    await storage.ensureDir('snapshots/');
    try {
      await storage.put(path, bytes);
    } on AlreadyExistsException {
      return false;
    }
    await database.remoteFilesDao.mark(path, size: bytes.length);
    // 已并入快照的日志可以删掉：读取方以文件名为准，缺失不影响正确性。
    for (final RemoteObject log in logs) {
      await storage.delete(log.path);
    }
    return true;
  }
}
