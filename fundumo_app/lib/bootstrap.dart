import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'services/auth_service.dart';
import 'services/local_notification_service.dart';
import 'services/receipt_scanning_service.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Sentry for error tracking
  if (AppConfig.enableCrashReporting && AppConfig.sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = AppConfig.sentryDsn;
        options.tracesSampleRate = 0.2; // 20% of transactions
        options.environment = 'production';
      },
      appRunner: () => _runApp(),
    );
  } else {
    await _runApp();
  }
}

Future<void> _runApp() async {
  runZonedGuarded(
    () async {
      // Initialize Supabase
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );

      final supabase = Supabase.instance.client;

      // Initialize notification service
      final notificationService = LocalNotificationService();
      await notificationService.initialize();

      // Initialize receipt scanning service
      final receiptScanningService = ReceiptScanningService();
      await receiptScanningService.initialize();

      runApp(
        ProviderScope(
          overrides: [
            localNotificationServiceProvider.overrideWithValue(
              notificationService,
            ),
            supabaseClientProvider.overrideWithValue(supabase),
            receiptScanningServiceProvider.overrideWithValue(
              receiptScanningService,
            ),
          ],
          child: const FundumoApp(),
        ),
      );
    },
    (error, stackTrace) {
      // Report to Sentry if enabled
      if (AppConfig.enableCrashReporting && AppConfig.sentryDsn.isNotEmpty) {
        Sentry.captureException(error, stackTrace: stackTrace);
      } else {
        // Fallback to console logging
        // ignore: avoid_print
        debugPrint('Uncaught bootstrap error: $error\n$stackTrace');
      }
    },
  );
}

