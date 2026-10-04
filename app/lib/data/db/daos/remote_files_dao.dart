import 'package:drift/drift.dart';

import '../../../core/utils/dates.dart';
import '../database.dart';
import '../tables.dart';

part 'remote_files_dao.g.dart';

/// 已处理的远端文件。同一路径的新 etag 才重新下载与应用。
@DriftAccessor(tables: <Type>[RemoteFiles])
class RemoteFilesDao extends DatabaseAccessor<AppDatabase>
    with _$RemoteFilesDaoMixin {
  RemoteFilesDao(super.db);

  Future<RemoteFile?> byPath(String path) => (select(
    remoteFiles,
  )..where(($RemoteFilesTable t) => t.path.equals(path))).getSingleOrNull();

  /// 该路径是否已用同样的 etag/size 处理过。
  Future<bool> isApplied(String path, {String? etag, int? size}) async {
    final RemoteFile? row = await byPath(path);
    if (row == null) {
      return false;
    }
    if (etag != null && row.etag != null) {
      return row.etag == etag && (size == null || row.size == size);
    }
    return size != null && row.size == size;
  }

  Future<void> mark(String path, {String? etag, int? size}) =>
      into(remoteFiles).insertOnConflictUpdate(
        RemoteFilesCompanion.insert(
          path: path,
          etag: Value<String?>(etag),
          size: Value<int?>(size),
          appliedAt: Timestamps.now(),
        ),
      );

  Future<void> remove(String path) => (delete(
    remoteFiles,
  )..where(($RemoteFilesTable t) => t.path.equals(path))).go();
}
