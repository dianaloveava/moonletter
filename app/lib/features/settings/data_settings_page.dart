import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../core/theme/tokens.dart';
import '../../data/data_providers.dart';
import '../../data/db/database.dart';
import '../../data/db/tables.dart';
import '../../data/repo/member_repository.dart';
import '../../domain/backup/backup_csv.dart';
import '../../domain/backup/backup_json.dart';
import '../../domain/sync/sync_codec.dart';
import '../../domain/sync/sync_merge.dart';
import '../../widgets/grouped_list.dart';
import '../../widgets/page_frame.dart';

/// 设置 → 数据：导出 JSON / 导出 CSV / 导入。
class DataSettingsPage extends ConsumerStatefulWidget {
  const DataSettingsPage({super.key});

  @override
  ConsumerState<DataSettingsPage> createState() => _DataSettingsPageState();
}

class _DataSettingsPageState extends ConsumerState<DataSettingsPage> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppColors colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bg,
      body: PageFrame(
        title: l10n.settingsData,
        actions: <Widget>[
          IconButton(
            onPressed: () => context.go('/settings'),
            icon: const Icon(Icons.close),
            color: colors.textSecondary,
          ),
        ],
        child: ListView(
          padding: EdgeInsets.only(
            bottom: AppSpacing.x4 + MediaQuery.paddingOf(context).bottom,
          ),
          children: <Widget>[
            GroupedList(
              sections: <Widget>[
                GroupSection(
                  title: l10n.settingsImportExport,
                  rows: <Widget>[
                    GroupRow(
                      label: l10n.dataExport,
                      value: 'JSON',
                      onTap: _busy ? null : _exportJson,
                    ),
                    GroupRow(
                      label: l10n.dataExport,
                      value: 'CSV',
                      onTap: _busy ? null : _exportCsv,
                    ),
                    GroupRow(
                      label: l10n.dataImport,
                      onTap: _busy ? null : _import,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _toast(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _exportJson() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final records = await ref.read(syncRepositoryProvider).collectRecords();
      final int memberCount = records
          .where(
            (SyncRecord record) =>
                record.t == RecordType.member && !record.deleted,
          )
          .length;
      final String text = encodeBackupJson(records);
      final String name =
          'moonletter-${DateTime.now().toIso8601String().substring(0, 10)}.json';
      final String? path = await FilePicker.saveFile(
        fileName: name,
        type: FileType.custom,
        allowedExtensions: <String>['json'],
        bytes: Uint8List.fromList(utf8.encode(text)),
      );
      _toast(
        path == null
            ? l10n.dataExportCancelled
            : l10n.dataExportedMembers(memberCount),
      );
    } catch (error) {
      _toast(l10n.dataExportFailed);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _exportCsv() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final List<Period> periods = await ref
          .read(periodRepositoryProvider)
          .listAllLive();
      final List<Member> members = await ref
          .read(memberRepositoryProvider)
          .listAll();
      final Map<String, String> names = <String, String>{
        for (final Member member in members) member.id: member.name,
      };
      final String csv = encodePeriodsCsv(periods, names);
      final String? path = await FilePicker.saveFile(
        fileName: 'moonletter-periods.csv',
        type: FileType.custom,
        allowedExtensions: <String>['csv'],
        bytes: Uint8List.fromList(utf8.encode(csv)),
      );
      _toast(
        path == null
            ? l10n.dataExportCancelled
            : l10n.dataExportedPeriods(periods.length),
      );
    } catch (error) {
      _toast(l10n.dataExportFailed);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _import() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>['json', 'csv'],
        withData: true,
      );
      final PlatformFile? file = result?.files.single;
      final Uint8List? bytes = file?.bytes;
      if (file == null || bytes == null) {
        return;
      }
      final String text = utf8.decode(bytes);
      final int applied = file.extension?.toLowerCase() == 'csv'
          ? await _importCsv(text)
          : await _importJson(text);
      _toast(l10n.dataImportedRecords(applied));
    } on FormatException catch (error) {
      _toast(error.message);
    } catch (_) {
      _toast(l10n.dataImportFailed);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  /// JSON 备份：按记录恢复。文件里的存活记录会覆盖本地墓碑（用户主动恢复），
  /// 其余按时间戳取新，不覆盖更新的本地记录。
  Future<int> _importJson(String text) async {
    final List<SyncRecord> incoming = decodeBackupJson(text);
    final repository = ref.read(syncRepositoryProvider);
    final List<SyncRecord> local = await repository.collectRecords(
      includeAvatars: false,
    );
    final List<SyncRecord> toApply = recordsToRestore(
      local,
      incoming,
      deviceId: await ref.read(deviceIdProvider.future),
      now: DateTime.now(),
    );
    final int applied = await repository.applyRecords(toApply);
    await _markImportedMembersDirty(toApply);
    return applied;
  }

  /// CSV：按昵称匹配成员（忽略大小写与首尾空格），不存在就新建。
  Future<int> _importCsv(String text) async {
    final List<CsvPeriodRow> rows = decodePeriodsCsv(text);
    final AppDatabase db = ref.read(databaseProvider);
    final List<Member> members = await ref
        .read(memberRepositoryProvider)
        .listAll();
    final Map<String, String> byName = <String, String>{
      for (final Member member in members)
        member.name.trim().toLowerCase(): member.id,
    };
    final periodRepository = ref.read(periodRepositoryProvider);

    int applied = 0;
    for (final CsvPeriodRow row in rows) {
      if (!_isValidDate(row.start) ||
          (row.end != null && !_isValidDate(row.end!))) {
        continue;
      }
      String? memberId = byName[row.member.trim().toLowerCase()];
      if (memberId == null) {
        memberId = await ref
            .read(memberRepositoryProvider)
            .create(MemberInput(name: row.member.trim()));
        byName[row.member.trim().toLowerCase()] = memberId;
      }
      final Period? clash = await db.periodDao.liveOfDate(memberId, row.start);
      if (clash == null) {
        await periodRepository.add(memberId, row.start, endDate: row.end);
      } else if (clash.endDate != row.end) {
        await periodRepository.setEnd(clash.id, row.end);
      }
      applied++;
    }
    return applied;
  }

  static bool _isValidDate(String value) =>
      RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value);

  /// 导入的成员记录需要参与下一次同步上传。
  Future<void> _markImportedMembersDirty(List<SyncRecord> records) async {
    final AppDatabase db = ref.read(databaseProvider);
    for (final SyncRecord record in records) {
      if (record.t == RecordType.member || record.t == RecordType.period) {
        await db.pendingChangesDao.mark(record.t, record.id);
      }
    }
  }
}
