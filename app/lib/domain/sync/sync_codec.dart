import 'dart:convert';

import '../../data/db/database.dart';
import '../../data/db/tables.dart';

/// 同步/备份里的最小记录单位（§8.2）：按 `(t, id)` 唯一，用 `(updatedAt, updatedBy)` 比新旧。
class SyncRecord {
  const SyncRecord({
    required this.t,
    required this.id,
    required this.updatedAt,
    required this.updatedBy,
    this.deleted = false,
    this.data,
  });

  /// [RecordType] 之一：member / period / avatar
  final String t;
  final String id;
  final int updatedAt;
  final String updatedBy;
  final bool deleted;

  /// 字段与数据库列同名；删除记录为 null。
  final Map<String, Object?>? data;

  static SyncRecord fromMember(Member member) => SyncRecord(
    t: RecordType.member,
    id: member.id,
    updatedAt: member.updatedAt,
    updatedBy: member.updatedBy,
    deleted: member.deletedAt != null,
    data: member.deletedAt != null
        ? null
        : <String, Object?>{
            'name': member.name,
            'age': member.age,
            'heightCm': member.heightCm,
            'weightKg': member.weightKg,
            'note': member.note,
            'avatarHash': member.avatarHash,
            'colorIndex': member.colorIndex,
            'defaultCycleDays': member.defaultCycleDays,
            'defaultPeriodDays': member.defaultPeriodDays,
            'reminderLeadDays': member.reminderLeadDays,
            'sortOrder': member.sortOrder,
            'createdAt': member.createdAt,
          },
  );

  static SyncRecord fromPeriod(Period period) => SyncRecord(
    t: RecordType.period,
    id: period.id,
    updatedAt: period.updatedAt,
    updatedBy: period.updatedBy,
    deleted: period.deletedAt != null,
    data: period.deletedAt != null
        ? null
        : <String, Object?>{
            'memberId': period.memberId,
            'start': period.startDate,
            'end': period.endDate,
          },
  );

  static SyncRecord fromAvatar({
    required String hash,
    required String base64Png,
  }) => SyncRecord(
    t: RecordType.avatar,
    id: hash,
    updatedAt: 0,
    updatedBy: '',
    data: <String, Object?>{'png': base64Png},
  );

  Map<String, Object?> toJson() => <String, Object?>{
    't': t,
    'id': id,
    'ua': updatedAt,
    'ub': updatedBy,
    'del': deleted,
    if (data != null) 'd': data,
  };

  static SyncRecord fromJson(Map<String, Object?> json) => SyncRecord(
    t: json['t']! as String,
    id: json['id']! as String,
    updatedAt: (json['ua'] as num?)?.toInt() ?? 0,
    updatedBy: json['ub'] as String? ?? '',
    deleted: json['del'] as bool? ?? false,
    data: (json['d'] as Map<Object?, Object?>?)?.cast<String, Object?>(),
  );

  /// 排序键：先比时间，再比设备 id（保证跨设备一致）。
  bool isNewerThan(SyncRecord other) {
    if (updatedAt != other.updatedAt) {
      return updatedAt > other.updatedAt;
    }
    return updatedBy.compareTo(other.updatedBy) > 0;
  }

  @override
  String toString() => 'SyncRecord($t/$id, ua=$updatedAt, del=$deleted)';
}

/// 记录列表 ⇄ JSON 文本。
String encodeRecords(Iterable<SyncRecord> records) =>
    jsonEncode(<String, Object?>{
      'v': 1,
      'records': records.map((SyncRecord r) => r.toJson()).toList(),
    });

List<SyncRecord> decodeRecords(String json) {
  final Map<String, Object?> root = jsonDecode(json) as Map<String, Object?>;
  final List<Object?> raw = root['records'] as List<Object?>? ?? <Object?>[];
  return raw
      .map(
        (Object? item) => SyncRecord.fromJson(
          (item! as Map<Object?, Object?>).cast<String, Object?>(),
        ),
      )
      .toList(growable: false);
}
