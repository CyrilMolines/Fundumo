# Build iOS Now - Step by Step

## ⚠️ Important: EAS Doesn't Work with Flutter

**EAS Build is for Expo/React Native only.** Fundumo is Flutter, so we use **Codemagic** (cloud builds) or **Fastlane** (local builds).

## 🚀 Option 1: Codemagic (Cloud - Recommended)

**No Mac required!** Build in the cloud and upload to TestFlight automatically.

### Quick Steps:

1. **Go to Codemagic**: https://codemagic.io
2. **Sign up** with GitHub
3. **Add application** → Select `CyrilMolines/Fundumo`
4. **Configure code signing**:
   - App settings → Code signing → iOS
   - Upload App Store Connect API key (`.p8` file)
   - Enter Key ID and Issuer ID
5. **Set environment variables**:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
6. **Update `codemagic.yaml`**:
   - Change `APP_ID` and `BUNDLE_ID` to your bundle ID
   - Update email recipients
7. **Click "Start new build"** → Select `ios-workflow`

**That's it!** Build takes ~10-15 minutes, then automatically uploads to TestFlight.

## 💻 Option 2: Fastlane (Local - Mac Required)

If you have a Mac, build locally:

```bash
cd fundumo_app/ios

# First time setup
bundle install

# Configure (edit Appfile and Matchfile first)
fastlane match appstore

# Build for TestFlight
fastlane beta
```

## 📋 Pre-Build Checklist

Before building, make sure you have:

- [ ] Apple Developer account ($99/year)
- [ ] App Store Connect API key (`.p8` file)
- [ ] Bundle ID configured (e.g., `com.yourcompany.fundumo`)
- [ ] Supabase credentials (if using cloud sync)
- [ ] Code signing set up (Codemagic or Fastlane Match)

## 🎯 Recommended: Use Codemagic

**Why Codemagic?**
- ✅ No Mac required
- ✅ Automatic code signing
- ✅ TestFlight uploads
- ✅ Free tier (500 min/month)
- ✅ Same functionality as EAS Build

**Setup time**: ~10 minutes  
**Build time**: ~10-15 minutes  
**Total**: ~25 minutes to TestFlight!

## 📚 Documentation

- **Quick guide**: `QUICK_BUILD_IOS.md`
- **Detailed guide**: `EAS_BUILD_INSTRUCTIONS.md`
- **Codemagic setup**: `CODEMAGIC_SETUP.md`
- **Fastlane guide**: `EAS_BUILD_GUIDE.md`

## 🆘 Need Help?

1. Check `QUICK_BUILD_IOS.md` for step-by-step instructions
2. Review `CODEMAGIC_SETUP.md` for detailed Codemagic setup
3. See `EAS_BUILD_INSTRUCTIONS.md` for all build options

---

**Ready?** Start with Codemagic - it's the fastest way to get an iOS build! 🚀

