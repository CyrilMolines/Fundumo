import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../data/fundumo_repository.dart';
import '../domain/models/models.dart';

typedef DirectoryResolver = Future<Directory> Function();

class BackupService {
  BackupService(
    this._repository, {
    DirectoryResolver? directoryResolver,
  }) : _directoryResolver =
            directoryResolver ?? getApplicationDocumentsDirectory;

  final FundumoRepository _repository;
  final DirectoryResolver _directoryResolver;

  Future<File> exportBackup() async {
    final data = await _repository.load();
    final directory = await _directoryResolver();
    final file = File('${directory.path}/fundumo_backup.json');
    await file.writeAsString(jsonEncode(data.toJson()), flush: true);
    return file;
  }

  Future<FundumoData> importBackup() async {
    final directory = await _directoryResolver();
    final file = File('${directory.path}/fundumo_backup.json');
    if (!await file.exists()) {
      throw const FileSystemException('No backup found');
    }
    final contents = await file.readAsString();
    final decoded = jsonDecode(contents) as Map<String, dynamic>;
    final data = FundumoData.fromJson(decoded);
    await _repository.save(data);
    return data;
  }
}
