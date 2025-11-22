import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'application/theme_controller.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_screen.dart';
import 'features/home/home_shell.dart';
import 'services/auth_service.dart';

class FundumoApp extends ConsumerWidget {
  const FundumoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeControllerProvider).maybeWhen(
          data: (mode) => mode,
          orElse: () => ThemeMode.system,
        );
    
    // Check authentication state
    final authService = ref.watch(authServiceProvider);
    final isAuthenticated = authService.isAuthenticated;
    
    return MaterialApp(
      title: 'Fundumo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: AppConfig.enableCloudSync && !isAuthenticated
          ? const AuthScreen()
          : const HomeShell(),
    );
  }
}

