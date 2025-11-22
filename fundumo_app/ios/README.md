# iOS Build Setup

This directory contains the iOS-specific configuration for the Fundumo app.

## Quick Start

### 1. Install Dependencies

```bash
# Install CocoaPods dependencies
pod install

# Install Fastlane dependencies (if using Fastlane)
bundle install
```

### 2. Build Options

#### Using Flutter CLI (Simple)
```bash
cd ..  # Go to fundumo_app root
flutter build ios --release
```

#### Using Fastlane (Recommended for CI/CD)
```bash
# Development build
fastlane build_dev

# TestFlight build
fastlane beta

# App Store build
fastlane release
```

#### Using Xcode (Manual)
1. Open `Runner.xcworkspace` (not `.xcodeproj`)
2. Select your target device
3. Product → Archive
4. Distribute App

## Configuration Files

- `Fastfile` - Fastlane build automation
- `Appfile` - App configuration (bundle ID, Apple ID)
- `Matchfile` - Code signing configuration
- `Gemfile` - Ruby dependencies
- `build-config.sh` - Build configuration script

## Environment Variables

Set these before building:

```bash
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_ANON_KEY="your-anon-key"
export SENTRY_DSN="https://your-dsn@sentry.io/project-id"
```

## Code Signing

### Automatic (Development)
- Open Xcode → Runner target → Signing & Capabilities
- Enable "Automatically manage signing"
- Select your Team

### Match (Production/CI)
```bash
fastlane match appstore
```

## Troubleshooting

### Pod Install Issues
```bash
pod deintegrate
pod install
```

### Build Errors
```bash
cd ..
flutter clean
cd ios
pod install
```

### Xcode Version
Ensure you're using a compatible Xcode version:
```bash
xcodebuild -version
```

## More Information

See `EAS_BUILD_GUIDE.md` in the project root for detailed instructions.

