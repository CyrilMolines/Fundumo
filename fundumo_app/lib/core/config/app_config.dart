/// Application configuration and environment variables
class AppConfig {
  // Supabase configuration
  // TODO: Replace with your Supabase project URL and anon key
  // Get these from: https://app.supabase.com/project/_/settings/api
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key-here',
  );

  // Sentry configuration
  // TODO: Replace with your Sentry DSN
  // Get this from: https://sentry.io/settings/projects/
  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );

  // App configuration
  static const String appName = 'Fundumo';
  static const String appVersion = '1.0.0';
  
  // Feature flags
  static const bool enableBiometricAuth = true;
  static const bool enableCloudSync = true;
  static const bool enableCrashReporting = true;
  
  // Sync configuration
  static const Duration syncInterval = Duration(minutes: 15);
  static const int maxRetryAttempts = 3;
  static const Duration retryBackoff = Duration(seconds: 5);
}

