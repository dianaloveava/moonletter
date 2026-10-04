// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remote_files_dao.dart';

// ignore_for_file: type=lint
mixin _$RemoteFilesDaoMixin on DatabaseAccessor<AppDatabase> {
  $RemoteFilesTable get remoteFiles => attachedDatabase.remoteFiles;
  RemoteFilesDaoManager get managers => RemoteFilesDaoManager(this);
}

class RemoteFilesDaoManager {
  final _$RemoteFilesDaoMixin _db;
  RemoteFilesDaoManager(this._db);
  $$RemoteFilesTableTableManager get remoteFiles =>
      $$RemoteFilesTableTableManager(_db.attachedDatabase, _db.remoteFiles);
}
