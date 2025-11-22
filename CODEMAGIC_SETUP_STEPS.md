# Codemagic iOS Build Setup - Step by Step

## 🎯 Goal: Build Fundumo iOS app and upload to TestFlight

## Step 1: Sign Up with GitHub ✅

1. Click "Sign up with GitHub" on Codemagic
2. Authorize Codemagic to access your GitHub account
3. Select repository access (or all repositories)

## Step 2: Add Application

1. After signing in, click **"Add application"** or **"Start building"**
2. Select **GitHub** as your Git provider
3. Find and select **`CyrilMolines/Fundumo`** repository
4. Click **"Add application"**

Codemagic will automatically detect:
- ✅ Flutter project
- ✅ `codemagic.yaml` configuration file

## Step 3: Configure Code Signing (iOS)

### 3.1 Get App Store Connect API Key

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Sign in with your Apple ID
3. Navigate to **Users and Access** → **Keys** → **App Store Connect API**
4. Click **"Generate API Key"** or use existing key
5. Download the `.p8` key file
6. Note the **Key ID** and **Issuer ID**

### 3.2 Upload to Codemagic

1. In Codemagic app settings, go to **Code signing** → **iOS**
2. Click **"Add key"** or **"Upload"**
3. Upload your `.p8` file
4. Enter:
   - **Key ID** (from App Store Connect)
   - **Issuer ID** (from App Store Connect)
5. Save

## Step 4: Set Environment Variables

1. In Codemagic app settings, go to **Environment variables**
2. Click **"Add variable"**
3. Add these variables:

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
SENTRY_DSN=https://your-dsn@sentry.io/project-id
```

**Note**: If you don't have Supabase/Sentry set up yet, you can skip these or use placeholder values.

## Step 5: Update codemagic.yaml

1. In Codemagic, go to **Configuration** tab
2. Edit `codemagic.yaml`:
   - Line 20: Change `APP_ID` to your bundle ID (e.g., `com.yourcompany.fundumo`)
   - Line 21: Change `BUNDLE_ID` to your bundle ID
   - Line 45: Update email recipients
   - Line 35: Update `PACKAGE_NAME` for Android (if building Android)

Or edit locally and push to GitHub:
```bash
cd fundumo_app
# Edit codemagic.yaml
git add codemagic.yaml
git commit -m "Update Codemagic config with bundle ID"
git push
```

## Step 6: Start Your First Build! 🚀

1. In Codemagic dashboard, click **"Start new build"**
2. Select workflow: **`ios-workflow`**
3. Select branch: **`main`**
4. Click **"Start build"**

### What Happens Next:

1. **Build starts** (~10-15 minutes)
   - Installs dependencies
   - Builds Flutter app
   - Signs with your certificates
   - Creates IPA file

2. **Automatic upload** to TestFlight
   - IPA is uploaded to App Store Connect
   - Available in TestFlight within minutes

3. **Email notification**
   - You'll receive an email when build completes
   - Includes download link and TestFlight info

## Step 7: Check TestFlight

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to **My Apps** → **Fundumo** → **TestFlight**
3. Your build should appear within 5-10 minutes
4. Add testers and distribute!

## ✅ Checklist

- [ ] Signed up with GitHub on Codemagic
- [ ] Added Fundumo repository
- [ ] Created App Store Connect API key
- [ ] Uploaded `.p8` file to Codemagic
- [ ] Entered Key ID and Issuer ID
- [ ] Set environment variables (optional)
- [ ] Updated `codemagic.yaml` with bundle ID
- [ ] Started first build
- [ ] Checked TestFlight for build

## 🐛 Troubleshooting

### Build Fails: "Code signing error"
- Verify API key has correct permissions (Admin or App Manager)
- Check Key ID and Issuer ID are correct
- Ensure bundle ID matches in Xcode project

### Build Fails: "Missing environment variables"
- Add variables in Codemagic app settings
- Or update `codemagic.yaml` to use defaults

### Build Fails: "Flutter version mismatch"
- Update Flutter version in `codemagic.yaml` if needed
- Codemagic uses Flutter stable by default

### TestFlight Upload Fails
- Verify API key has App Store Connect access
- Check app exists in App Store Connect
- Ensure bundle ID matches exactly

## 📚 Resources

- [Codemagic iOS Setup](https://docs.codemagic.io/yaml-quick-start/building-a-flutter-app/)
- [App Store Connect API Keys](https://developer.apple.com/documentation/appstoreconnectapi/creating_api_keys_for_app_store_connect_api)
- [TestFlight Guide](https://developer.apple.com/testflight/)

## 🎉 Success!

Once your first build completes:
- ✅ IPA file available for download
- ✅ Automatically uploaded to TestFlight
- ✅ Ready for testing!

---

**Ready to start?** Follow steps 1-6 above and you'll have an iOS build in ~15 minutes! 🚀

