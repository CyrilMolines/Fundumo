# iOS Build Guide for Fundumo

This guide explains how to build the Fundumo iOS app using Fastlane (Flutter's equivalent to EAS Build).

## Prerequisites

1. **macOS** (required for iOS builds)
2. **Xcode** (latest version recommended)
3. **Flutter SDK** 3.9.2+
4. **CocoaPods** (`sudo gem install cocoapods`)
5. **Fastlane** (`sudo gem install fastlane` or via Bundler)
6. **Apple Developer Account** (for App Store/TestFlight)

## Quick Start

### 1. Install Dependencies

```bash
cd fundumo_app/ios

# Install Ruby dependencies (Fastlane)
bundle install

# Install CocoaPods dependencies
pod install
```

### 2. Configure Code Signing

#### Option A: Automatic Signing (Recommended for development)

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner target
3. Go to "Signing & Capabilities"
4. Enable "Automatically manage signing"
5. Select your Team

#### Option B: Match (Recommended for CI/CD)

1. Update `ios/fastlane/Matchfile` with your details:
   ```ruby
   git_url("https://github.com/your-org/fundumo-certificates")
   app_identifier("com.yourcompany.fundumo")
   username("your-apple-id@example.com")
   ```

2. Setup Match:
   ```bash
   cd ios
   fastlane match appstore
   ```

### 3. Configure Environment Variables

Set these before building:

```bash
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_ANON_KEY="your-anon-key"
export SENTRY_DSN="https://your-dsn@sentry.io/project-id"  # Optional
```

Or create a `.env` file in `fundumo_app/ios/`:
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SENTRY_DSN=https://your-dsn@sentry.io/project-id
```

### 4. Build Commands

#### Development Build
```bash
cd fundumo_app/ios
fastlane build_dev
```

#### Ad-Hoc Build (for testing)
```bash
cd fundumo_app/ios
fastlane build_adhoc
```

#### TestFlight Build
```bash
cd fundumo_app/ios
fastlane beta
```

#### App Store Build
```bash
cd fundumo_app/ios
fastlane release
```

## Using GitHub Actions (CI/CD)

The project includes a GitHub Actions workflow (`.github/workflows/ios-build.yml`) that automatically builds and uploads to TestFlight.

### Setup GitHub Secrets

Add these secrets to your GitHub repository:

1. `APPLE_ID` - Your Apple ID email
2. `APPLE_APP_SPECIFIC_PASSWORD` - App-specific password (generate at appleid.apple.com)
3. `MATCH_PASSWORD` - Password for Match certificate repository
4. `SUPABASE_URL` - Your Supabase project URL
5. `SUPABASE_ANON_KEY` - Your Supabase anon key
6. `SENTRY_DSN` - Your Sentry DSN (optional)

### Trigger Builds

- **Automatic**: Push to `main` or `develop` branches
- **Manual**: Go to Actions → iOS Build → Run workflow

## Manual Build Steps

If you prefer to build manually without Fastlane:

### 1. Build Flutter App

```bash
cd fundumo_app

# Debug build
flutter build ios --debug

# Release build
flutter build ios --release --no-codesign
```

### 2. Build in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select your target device or simulator
3. Product → Archive (for release builds)
4. Distribute App → TestFlight or App Store

## Build Configuration

### Build Types

- **Debug**: Development builds with debugging enabled
- **Profile**: Performance profiling builds
- **Release**: Production builds for App Store/TestFlight

### Build Settings

Key settings in `ios/Runner.xcodeproj`:
- **Bundle Identifier**: `com.yourcompany.fundumo`
- **Version**: Managed by Flutter (`pubspec.yaml`)
- **Build Number**: Auto-incremented by Fastlane

## Troubleshooting

### "No such module" errors

```bash
cd ios
pod deintegrate
pod install
```

### Code signing issues

1. Check your Apple Developer account
2. Verify certificates in Keychain Access
3. Update provisioning profiles in Xcode

### Build failures

1. Clean build folder: `flutter clean`
2. Reinstall pods: `cd ios && pod install`
3. Check Xcode version compatibility
4. Verify Flutter version: `flutter doctor`

### Fastlane errors

```bash
cd ios
bundle update
bundle exec fastlane [lane_name]
```

## Environment-Specific Builds

### Development
```bash
flutter build ios --debug --dart-define=ENV=dev
```

### Staging
```bash
flutter build ios --release --dart-define=ENV=staging
```

### Production
```bash
flutter build ios --release --dart-define=ENV=prod
```

## Version Management

Versions are managed in `pubspec.yaml`:
```yaml
version: 1.0.0+1  # version+build_number
```

Fastlane automatically increments build numbers for TestFlight/App Store builds.

## Testing

### Run tests before building
```bash
cd fundumo_app
flutter test
cd ios
fastlane test
```

### TestFlight Testing

1. Build and upload: `fastlane beta`
2. Wait for processing (check App Store Connect)
3. Add internal/external testers
4. Testers receive email invitation

## App Store Submission

1. Build: `fastlane release`
2. Go to App Store Connect
3. Select your build
4. Fill in app information
5. Submit for review

## Security Notes

- Never commit certificates or provisioning profiles
- Use Match for certificate management
- Store secrets in GitHub Secrets (for CI/CD)
- Use app-specific passwords for Apple ID

## Additional Resources

- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)
- [Fastlane Documentation](https://docs.fastlane.tools)
- [Apple Developer Documentation](https://developer.apple.com/documentation)

## Support

For issues:
1. Check Flutter doctor: `flutter doctor -v`
2. Check Xcode logs: Window → Devices and Simulators → View Device Logs
3. Check Fastlane logs: `ios/fastlane/report.xml`

