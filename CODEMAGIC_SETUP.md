# Codemagic Setup Guide for Fundumo

Codemagic is Flutter's equivalent to EAS Build - a cloud-based CI/CD service specifically designed for Flutter apps.

## Quick Start

### 1. Create Codemagic Account

1. Go to [codemagic.io](https://codemagic.io)
2. Sign up with GitHub/GitLab/Bitbucket
3. Connect your repository

### 2. Configure Project

1. Click "Add application"
2. Select your repository (Fundumo)
3. Select "Flutter" as the project type
4. Codemagic will detect `codemagic.yaml` automatically

### 3. Set Up Environment Variables

Go to your app settings → Environment variables and add:

- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_ANON_KEY` - Your Supabase anon key
- `SENTRY_DSN` - Your Sentry DSN (optional)

### 4. Set Up Code Signing

#### iOS (App Store Connect API Key)

1. Go to App Store Connect → Users and Access → Keys
2. Create an API key with App Manager or Admin access
3. Download the `.p8` key file
4. Note the Key ID and Issuer ID
5. In Codemagic: App settings → Code signing → iOS
6. Upload the `.p8` file and enter Key ID and Issuer ID

#### Android (Google Play Service Account)

1. Go to Google Play Console → Setup → API access
2. Create a service account
3. Download the JSON key file
4. In Codemagic: App settings → Code signing → Android
5. Upload the JSON key file

### 5. Update Configuration

Edit `codemagic.yaml`:

1. Update `APP_ID` and `BUNDLE_ID` with your actual bundle identifier
2. Update `PACKAGE_NAME` for Android
3. Update email recipients
4. Update TestFlight beta groups (if using)

### 6. Build!

Click "Start new build" and select your workflow:
- `ios-workflow` - iOS only
- `android-workflow` - Android only
- `ios-android-workflow` - Both platforms

## Workflows Explained

### iOS Workflow
- Builds iOS app
- Creates IPA file
- Uploads to TestFlight automatically
- Sends email notification

### Android Workflow
- Builds Android APK and App Bundle
- Uploads to Google Play Internal Testing
- Sends email notification

### iOS + Android Workflow
- Builds both platforms in one run
- Uploads to both stores
- Most efficient for releases

## Build Triggers

By default, builds run manually. To enable automatic builds:

1. Go to App settings → Build triggers
2. Enable:
   - Build on push (select branches)
   - Build on pull request
   - Build on tag

## Environment Groups

Create groups in Codemagic for shared credentials:

### app_store_credentials
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_KEY_IDENTIFIER`
- `APP_STORE_CONNECT_PRIVATE_KEY`

### app_store_connect_api_key
- Same as above (for API key auth)

### keystore_credentials
- `CM_KEYSTORE_PATH`
- `CM_KEYSTORE_PASSWORD`
- `CM_KEY_ALIAS`
- `CM_KEY_PASSWORD`

## Build Status

Monitor builds at:
- Codemagic dashboard
- Email notifications
- GitHub status checks (if enabled)

## Troubleshooting

### Build Fails

1. Check build logs in Codemagic
2. Verify environment variables are set
3. Check code signing configuration
4. Verify Flutter version compatibility

### Code Signing Issues

**iOS:**
- Verify API key has correct permissions
- Check bundle identifier matches
- Ensure certificates are valid

**Android:**
- Verify keystore is uploaded
- Check package name matches
- Ensure keystore password is correct

### Environment Variables Not Found

- Check variable names match exactly
- Verify they're set in app settings
- Check they're included in workflow groups

## Cost

- **Free tier**: 500 build minutes/month
- **Starter**: $75/month - 2,000 minutes
- **Pro**: $149/month - 5,000 minutes

## Alternative: GitHub Actions

If you prefer GitHub Actions (free), use the workflow files in `.github/workflows/`.

## Comparison: EAS vs Codemagic

| Feature | EAS Build | Codemagic |
|---------|-----------|-----------|
| Platform | Expo/React Native | Flutter |
| Free Tier | Yes | Yes (500 min/month) |
| iOS Builds | ✅ | ✅ |
| Android Builds | ✅ | ✅ |
| TestFlight Upload | ✅ | ✅ |
| Google Play Upload | ✅ | ✅ |
| Code Signing | Automatic | Automatic |
| Environment Variables | ✅ | ✅ |

## Next Steps

1. ✅ Create Codemagic account
2. ✅ Connect repository
3. ✅ Configure code signing
4. ✅ Set environment variables
5. ✅ Update `codemagic.yaml` with your details
6. ✅ Start first build!

## Support

- [Codemagic Documentation](https://docs.codemagic.io)
- [Codemagic Community](https://codemagicio.slack.com)
- [Flutter Documentation](https://docs.flutter.dev)

---

**Note**: EAS Build is for Expo/React Native only. Codemagic is the Flutter equivalent and provides the same functionality.



