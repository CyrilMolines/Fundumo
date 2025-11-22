import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/models.dart';
import '../services/backup_service.dart';
import 'local_fundumo_store.dart';

class FundumoRepository {
  FundumoRepository({
    required this.store,
    this.assetPath = 'assets/data/seed.json',
  });

  final LocalFundumoStore store;
  final String assetPath;

  Future<FundumoData> load() async {
    try {
      final cached = await store.read();
      if (cached != null) {
        return FundumoData.fromJson(cached);
      }
    } catch (error, stackTrace) {
      debugPrint('FundumoRepository.load cache error: $error\n$stackTrace');
    }

    final seed = await FundumoData.fromAsset(assetPath);
    await save(seed);
    return seed;
  }

  Future<void> save(FundumoData data) async {
    await store.write(data.toJson());
  }

  Future<FundumoData> loadSeed() => FundumoData.fromAsset(assetPath);
}

final localFundumoStoreProvider = Provider<LocalFundumoStore>((ref) {
  return LocalFundumoStore();
});

final fundumoRepositoryProvider = Provider<FundumoRepository>((ref) {
  final store = ref.watch(localFundumoStoreProvider);
  return FundumoRepository(store: store);
});

final backupServiceProvider = Provider<BackupService>((ref) {
  final repository = ref.watch(fundumoRepositoryProvider);
  return BackupService(repository);
});

