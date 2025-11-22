import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class LocalFundumoStore {
  LocalFundumoStore({this.fileName = 'fundumo_data.json'});

  final String fileName;

  Future<Directory> _resolveDirectory() async {
    try {
      return await getApplicationSupportDirectory();
    } on MissingPluginException {
      final fallback =
          Directory('${Directory.systemTemp.path}/fundumo_app_fallback');
      if (!await fallback.exists()) {
        await fallback.create(recursive: true);
      }
      return fallback;
    }
  }

  Future<File> _resolveFile() async {
    final directory = await _resolveDirectory();
    final file = File('${directory.path}/$fileName');
    if (!await file.exists()) {
      await file.create(recursive: true);
    }
    return file;
  }

  Future<Map<String, dynamic>?> read() async {
    try {
      final file = await _resolveFile();
      final contents = await file.readAsString();
      if (contents.trim().isEmpty) {
        return null;
      }
      final decoded = jsonDecode(contents);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } on FileSystemException {
      return null;
    } catch (error, stackTrace) {
      debugPrint('LocalFundumoStore.read error: $error\n$stackTrace');
      return null;
    }
  }

  Future<void> write(Map<String, dynamic> data) async {
    final file = await _resolveFile();
    await file.writeAsString(
      jsonEncode(data),
      flush: true,
    );
  }
}

