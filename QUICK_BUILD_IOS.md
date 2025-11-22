# Quick iOS Build Guide for Fundumo

## 🚀 Fastest Way to Build iOS (Cloud - No Mac Required)

### Step 1: Codemagic Setup (5 minutes)

1. Go to [codemagic.io](https://codemagic.io)
2. Sign up with GitHub
3. Click "Add application"
4. Select repository: `CyrilMolines/Fundumo`
5. Codemagic auto-detects `codemagic.yaml` ✅

### Step 2: Code Signing (5 minutes)

**iOS App Store Connect API Key:**

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Users and Access → Keys → App Store Connect API
3. Create new key (Admin or App Manager role)
4. Download `.p8` file
5. Note the Key ID and Issuer ID

**In Codemagic:**
1. App settings → Code signing → iOS
2. Upload `.p8` file
3. Enter Key ID
4. Enter Issuer ID

### Step 3: Environment Variables (2 minutes)

In Codemagic app settings → Environment variables, add:

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SENTRY_DSN=https://your-dsn@sentry.io/project-id (optional)
```

### Step 4: Update Configuration (1 minute)

Edit `fundumo_app/codemagic.yaml`:

- Line 15: Change `APP_ID` to your bundle ID
- Line 16: Change `BUNDLE_ID` to your bundle ID
- Line 50: Update email recipients

### Step 5: BUILD! 🎉

1. Click "Start new build"
2. Select workflow: `ios-workflow`
3. Wait ~10-15 minutes
4. App automatically uploads to TestFlight! ✅

## 📱 Alternative: Local Build (Mac Required)

If you have a Mac:

```bash
cd fundumo_app/ios

# Install dependencies
bundle install

# Build for TestFlight
fastlane beta
```

## ⚡ Quick Commands Reference

### Codemagic (Cloud)
- Just click "Start new build" in dashboard
- Select `ios-workflow`

### Fastlane (Local - Mac)
```bash
cd fundumo_app/ios
fastlane beta        # TestFlight
fastlane release     # App Store
```

### GitHub Actions (Automated)
- Push to `main` branch
- Build runs automatically

## 🎯 What Happens After Build?

1. **Codemagic**: 
   - Builds iOS app
   - Signs automatically
   - Uploads to TestFlight
   - Sends email notification

2. **Fastlane**:
   - Builds locally
   - Creates IPA file
   - Uploads to TestFlight (if configured)

## ✅ Checklist

- [ ] Codemagic account created
- [ ] Repository connected
- [ ] Code signing configured (API key uploaded)
- [ ] Environment variables set
- [ ] `codemagic.yaml` updated with your bundle ID
- [ ] Build triggered!

## 🆘 Need Help?

- **Codemagic**: [docs.codemagic.io](https://docs.codemagic.io)
- **Fastlane**: [docs.fastlane.tools](https://docs.fastlane.tools)
- **Flutter iOS**: [docs.flutter.dev/deployment/ios](https://docs.flutter.dev/deployment/ios)

---

**Ready to build?** Follow Step 1-5 above and you'll have an iOS build in ~15 minutes! 🚀

