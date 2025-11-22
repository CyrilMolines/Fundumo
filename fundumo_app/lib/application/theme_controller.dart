import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/theme_service.dart';

final themeServiceProvider = Provider<ThemeService>((ref) {
  return ThemeService();
});

final themeControllerProvider =
    AsyncNotifierProvider<ThemeController, ThemeMode>(ThemeController.new);

class ThemeController extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() async {
    final service = ref.read(themeServiceProvider);
    return service.loadTheme();
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = AsyncData(mode);
    final service = ref.read(themeServiceProvider);
    await service.saveTheme(mode);
  }
}

