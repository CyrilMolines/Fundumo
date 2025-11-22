# Fundumo Setup Guide

This guide will help you set up the Fundumo app for production deployment.

## Prerequisites

- Flutter SDK 3.9.2 or higher
- Android Studio / Xcode (for mobile builds)
- Supabase account (free tier available)
- Sentry account (optional, for error tracking)

## Step 1: Install Dependencies

```bash
cd fundumo_app
flutter pub get
```

## Step 2: Configure Supabase

### 2.1 Create Supabase Project

1. Go to [https://app.supabase.com](https://app.supabase.com)
2. Create a new project
3. Note your project URL and anon key from Settings > API

### 2.2 Set Up Database Schema

Run the following SQL in your Supabase SQL Editor:

```sql
-- User profiles table
CREATE TABLE IF NOT EXISTS user_profiles (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT,
  currency_code TEXT DEFAULT 'USD',
  monthly_take_home DECIMAL,
  notification_email TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Fixed expenses table
CREATE TABLE IF NOT EXISTS fixed_expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  amount DECIMAL NOT NULL,
  frequency TEXT NOT NULL,
  next_due TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Subscriptions table
CREATE TABLE IF NOT EXISTS subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  monthly_cost DECIMAL NOT NULL,
  renewal_cycle TEXT NOT NULL,
  next_renewal TIMESTAMPTZ NOT NULL,
  category TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Envelopes table
CREATE TABLE IF NOT EXISTS envelopes (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  allocation DECIMAL NOT NULL,
  rollover BOOLEAN DEFAULT FALSE,
  color_hex TEXT DEFAULT '#005F73',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Transactions table
CREATE TABLE IF NOT EXISTS transactions (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  envelope_id TEXT NOT NULL,
  amount DECIMAL NOT NULL,
  timestamp TIMESTAMPTZ NOT NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Side gigs table
CREATE TABLE IF NOT EXISTS side_gigs (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  hourly_rate DECIMAL NOT NULL,
  tax_rate DECIMAL DEFAULT 0.25,
  entries JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Saving goals table
CREATE TABLE IF NOT EXISTS saving_goals (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  target_amount DECIMAL NOT NULL,
  target_date TIMESTAMPTZ NOT NULL,
  theme TEXT DEFAULT 'default',
  contributions JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Shared bill groups table
CREATE TABLE IF NOT EXISTS shared_bill_groups (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  participants JSONB DEFAULT '[]'::jsonb,
  expenses JSONB DEFAULT '[]'::jsonb,
  settlements JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Receipts table
CREATE TABLE IF NOT EXISTS receipts (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  category TEXT,
  purchase_date TIMESTAMPTZ NOT NULL,
  warranty_expiry TIMESTAMPTZ NOT NULL,
  image_path TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Sync metadata table
CREATE TABLE IF NOT EXISTS user_sync_metadata (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  last_sync_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE fixed_expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE envelopes ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE side_gigs ENABLE ROW LEVEL SECURITY;
ALTER TABLE saving_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared_bill_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_sync_metadata ENABLE ROW LEVEL SECURITY;

-- Create RLS policies (users can only access their own data)
CREATE POLICY "Users can view own profile" ON user_profiles
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own profile" ON user_profiles
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own profile" ON user_profiles
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Similar policies for other tables
CREATE POLICY "Users can manage own fixed_expenses" ON fixed_expenses
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own subscriptions" ON subscriptions
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own envelopes" ON envelopes
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own transactions" ON transactions
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own side_gigs" ON side_gigs
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own saving_goals" ON saving_goals
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own shared_bill_groups" ON shared_bill_groups
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own receipts" ON receipts
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own sync_metadata" ON user_sync_metadata
  FOR ALL USING (auth.uid() = user_id);
```

### 2.3 Configure App Config

Update `lib/core/config/app_config.dart` with your Supabase credentials:

```dart
static const String supabaseUrl = 'https://your-project.supabase.co';
static const String supabaseAnonKey = 'your-anon-key-here';
```

**OR** set environment variables when building:

```bash
flutter build apk --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-key
```

## Step 3: Configure Sentry (Optional)

1. Create account at [https://sentry.io](https://sentry.io)
2. Create a new Flutter project
3. Copy your DSN
4. Update `lib/core/config/app_config.dart`:

```dart
static const String sentryDsn = 'https://your-dsn@sentry.io/project-id';
```

**OR** set environment variable:

```bash
flutter build apk --dart-define=SENTRY_DSN=https://your-dsn@sentry.io/project-id
```

## Step 4: Android Configuration

### 4.1 Update AndroidManifest.xml

Permissions are already configured. Verify in `android/app/src/main/AndroidManifest.xml`:

- Camera permission
- Storage permissions
- Internet permission
- Notification permission

### 4.2 Configure ProGuard (for release builds)

Add to `android/app/proguard-rules.pro`:

```
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
```

## Step 5: iOS Configuration

### 5.1 Update Info.plist

Permissions are already configured. Verify in `ios/Runner/Info.plist`:

- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`
- `NSPhotoLibraryAddUsageDescription`

### 5.2 Configure Signing

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner target
3. Go to Signing & Capabilities
4. Select your team and enable automatic signing

## Step 6: Build and Test

### Development Build

```bash
flutter run
```

### Release Build (Android)

```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### Release Build (iOS)

```bash
flutter build ios --release
# Then open Xcode and archive
```

## Step 7: Testing Checklist

- [ ] User can sign up with email/password
- [ ] User can sign in
- [ ] Biometric authentication works (if available)
- [ ] Data syncs to Supabase
- [ ] Data loads from Supabase on login
- [ ] Receipt scanning works (camera permission)
- [ ] Notifications work
- [ ] Export/import works
- [ ] Theme switching works
- [ ] All features work offline (local storage)

## Troubleshooting

### Dependencies not installing

```bash
flutter clean
flutter pub get
```

### Supabase connection errors

- Verify your URL and anon key
- Check Supabase project is active
- Verify RLS policies are set up correctly
- Check network connectivity

### Camera not working

- Verify permissions in AndroidManifest.xml / Info.plist
- Check device has camera
- Test on physical device (emulators may not have camera)

### Build errors

- Run `flutter doctor` to check setup
- Ensure all dependencies are compatible
- Check Flutter SDK version matches requirements

## Next Steps

1. Set up CI/CD pipeline (GitHub Actions / Codemagic)
2. Configure app store listings
3. Set up analytics (Plausible / Snowplow)
4. Create privacy policy and terms of service
5. Set up beta testing (TestFlight / Firebase App Distribution)

## Security Notes

- Never commit Supabase keys or Sentry DSN to version control
- Use environment variables or secure config files
- Enable 2FA on Supabase account
- Regularly rotate API keys
- Monitor Sentry for security-related errors

## Support

For issues or questions, refer to:
- [Flutter Documentation](https://flutter.dev/docs)
- [Supabase Documentation](https://supabase.com/docs)
- [Sentry Documentation](https://docs.sentry.io/platforms/flutter/)

