# Building Fundumo for iOS - EAS Alternative

## ⚠️ Important: EAS vs Flutter Build Systems

**EAS Build is for Expo/React Native only.** Fundumo is a Flutter app, so we use alternative build systems:

- **Codemagic** - Cloud builds (Flutter's equivalent to EAS)
- **Fastlane** - Local builds on macOS
- **GitHub Actions** - CI/CD automation

## Option 1: Codemagic (Recommended - Cloud Builds)

Codemagic is Flutter's equivalent to EAS Build - it provides cloud-based iOS builds without needing a Mac.

### Quick Start

1. **Sign up**: [codemagic.io](https://codemagic.io)
2. **Connect**: Link your GitHub repository (https://github.com/CyrilMolines/Fundumo)
3. **Configure**:
   - Go to App settings → Code signing → iOS
   - Upload App Store Connect API key (`.p8` file)
   - Enter Key ID and Issuer ID
   - Set environment variables:
     - `SUPABASE_URL`
     - `SUPABASE_ANON_KEY`
     - `SENTRY_DSN` (optional)
4. **Build**: Click "Start new build" → Select `ios-workflow`

### Build Commands

The `codemagic.yaml` file is already configured. Just trigger builds from the Codemagic dashboard.

**Workflows available:**
- `ios-workflow` - Build iOS and upload to TestFlight
- `android-workflow` - Build Android
- `ios-android-workflow` - Build both platforms

## Option 2: Fastlane (Local Builds - macOS Required)

If you have a Mac, you can build locally using Fastlane.

### Prerequisites

- macOS with Xcode installed
- Apple Developer account
- Ruby and Bundler installed

### Setup

1. **Install dependencies**:
   ```bash
   cd fundumo_app/ios
   bundle install
   ```

2. **Configure Appfile**:
   Edit `ios/fastlane/Appfile`:
   ```ruby
   app_identifier("com.yourcompany.fundumo") # Your bundle ID
   apple_id("your-apple-id@example.com") # Your Apple ID
   team_id("YOUR_TEAM_ID") # Your Team ID
   ```

3. **Configure Matchfile** (for code signing):
   Edit `ios/fastlane/Matchfile`:
   ```ruby
   git_url("https://github.com/your-org/fundumo-certificates") # Your certs repo
   username("your-apple-id@example.com")
   ```

4. **Set up code signing**:
   ```bash
   fastlane match appstore
   ```

### Build Commands

```bash
cd fundumo_app/ios

# Development build
fastlane build_dev

# Ad-hoc build
fastlane build_adhoc

# TestFlight build
fastlane beta

# App Store build
fastlane release
```

## Option 3: GitHub Actions (Automated)

GitHub Actions workflow is already configured in `.github/workflows/ios-build.yml`.

### Setup

1. **Add secrets to GitHub**:
   - Go to repository → Settings → Secrets and variables → Actions
   - Add:
     - `APP_STORE_CONNECT_API_KEY` (base64 encoded)
     - `APP_STORE_CONNECT_ISSUER_ID`
     - `APP_STORE_CONNECT_KEY_ID`
     - `SUPABASE_URL`
     - `SUPABASE_ANON_KEY`

2. **Trigger build**:
   - Push to `main` branch, or
   - Manually trigger from Actions tab

## Comparison: EAS vs Codemagic vs Fastlane

| Feature | EAS Build | Codemagic | Fastlane |
|---------|-----------|-----------|----------|
| Platform | Expo/RN | Flutter | iOS/Android |
| Cloud Builds | ✅ | ✅ | ❌ (local only) |
| Free Tier | ✅ | ✅ (500 min/month) | ✅ |
| iOS Builds | ✅ | ✅ | ✅ |
| TestFlight Upload | ✅ | ✅ | ✅ |
| Code Signing | Automatic | Automatic | Manual setup |
| Requires Mac | ❌ | ❌ | ✅ |

## Recommended Approach

**For Fundumo (Flutter app):**

1. **Use Codemagic** for cloud builds (like EAS)
   - No Mac required
   - Automatic code signing
   - TestFlight uploads
   - Free tier available

2. **Use Fastlane** if you have a Mac and want local builds
   - More control
   - Faster iteration
   - Requires Mac setup

## Next Steps

1. ✅ Choose your build method (Codemagic recommended)
2. ✅ Set up code signing credentials
3. ✅ Configure environment variables
4. ✅ Start building!

## Troubleshooting

### Codemagic Issues

- **Build fails**: Check logs in Codemagic dashboard
- **Code signing errors**: Verify API key permissions in App Store Connect
- **Environment variables**: Ensure they're set in app settings

### Fastlane Issues

- **Match errors**: Ensure certificates repo exists and is accessible
- **Xcode errors**: Update Xcode and run `xcode-select --switch /Applications/Xcode.app`
- **Permission errors**: Check Apple Developer account access

## Support

- [Codemagic Docs](https://docs.codemagic.io)
- [Fastlane Docs](https://docs.fastlane.tools)
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)

---

**Note**: EAS Build doesn't support Flutter. Use Codemagic (cloud) or Fastlane (local) instead.

