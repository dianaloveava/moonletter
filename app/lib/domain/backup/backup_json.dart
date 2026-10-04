import 'dart:convert';

import '../sync/sync_codec.dart';

/// 备份文件格式标识。
const String kBackupFormat = 'moonletter';
const int kBackupVersion = 1;

/// 导出为 JSON 文本：记录形态与同步一致（§8.2），导入时可以直接复用合并逻辑。
String encodeBackupJson(Iterable<SyncRecord> records, {DateTime? exportedAt}) =>
    const JsonEncoder.withIndent('  ').convert(<String, Object?>{
      'format': kBackupFormat,
      'version': kBackupVersion,
      'exportedAt': (exportedAt ?? DateTime.now()).toIso8601String(),
      'records': records.map((SyncRecord record) => record.toJson()).toList(),
    });

/// 解析备份文件；格式不对时抛 [FormatException]。
List<SyncRecord> decodeBackupJson(String text) {
  final Object? decoded = jsonDecode(text);
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('不是有效的 JSON 对象');
  }
  if (decoded['format'] != kBackupFormat) {
    throw const FormatException('不是月信的备份文件');
  }
  final Object? version = decoded['version'];
  if (version is! int || version > kBackupVersion) {
    throw const FormatException('备份文件版本不受支持');
  }
  final List<Object?> raw = decoded['records'] as List<Object?>? ?? <Object?>[];
  return raw
      .map(
        (Object? item) => SyncRecord.fromJson(
          (item! as Map<Object?, Object?>).cast<String, Object?>(),
        ),
      )
      .toList(growable: false);
}
