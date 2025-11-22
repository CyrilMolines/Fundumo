# GitHub Actions iOS Build Setup

## ✅ Workflow Already Configured!

Your GitHub Actions workflow is already set up at `.github/workflows/ios-build.yml`. You just need to configure the secrets.

## 🔐 Required Secrets

Go to: **Repository → Settings → Secrets and variables → Actions**

Add these secrets:

### 1. Apple Developer Secrets

- **`APPLE_ID`** - Your Apple ID email (e.g., `your-email@example.com`)
- **`APPLE_APP_SPECIFIC_PASSWORD`** - App-specific password from [appleid.apple.com](https://appleid.apple.com)
- **`MATCH_PASSWORD`** - Password for Fastlane Match (create a secure password)

### 2. App Credentials (Optional but Recommended)

- **`SUPABASE_URL`** - Your Supabase project URL
- **`SUPABASE_ANON_KEY`** - Your Supabase anon key
- **`SENTRY_DSN`** - Your Sentry DSN (optional)

## 📋 Step-by-Step Setup

### Step 1: Create App-Specific Password

1. Go to [appleid.apple.com](https://appleid.apple.com)
2. Sign in with your Apple ID
3. Security → App-Specific Passwords
4. Generate new password → Copy it
5. Add as secret: `APPLE_APP_SPECIFIC_PASSWORD`

### Step 2: Set Up Fastlane Match

1. Create a private GitHub repository for certificates (e.g., `fundumo-certificates`)
2. Update `fundumo_app/ios/fastlane/Matchfile`:
   ```ruby
   git_url("https://github.com/your-username/fundumo-certificates")
   username("your-apple-id@example.com")
   ```
3. Create a secure password for Match
4. Add as secret: `MATCH_PASSWORD`

### Step 3: Initialize Match (First Time Only)

Run locally (Mac required):
```bash
cd fundumo_app/ios
bundle install
bundle exec fastlane match appstore
```

This will:
- Create certificates
- Store them in your certificates repo
- Set up provisioning profiles

### Step 4: Add Secrets to GitHub

1. Go to: `https://github.com/CyrilMolines/Fundumo/settings/secrets/actions`
2. Click "New repository secret"
3. Add each secret:
   - `APPLE_ID`
   - `APPLE_APP_SPECIFIC_PASSWORD`
   - `MATCH_PASSWORD`
   - `SUPABASE_URL` (optional)
   - `SUPABASE_ANON_KEY` (optional)
   - `SENTRY_DSN` (optional)

### Step 5: Trigger Build

**Option A: Manual Trigger**
1. Go to Actions tab
2. Select "iOS Build" workflow
3. Click "Run workflow"
4. Choose build type: `testflight` or `appstore`
5. Click "Run workflow"

**Option B: Automatic (on push)**
- Push to `main` branch
- Build runs automatically

## 🎯 Build Types

- **`testflight`** - Builds and uploads to TestFlight
- **`appstore`** - Builds for App Store submission

## 📱 What Happens After Build?

1. **Builds iOS app** (~10-15 minutes)
2. **Signs automatically** using Match
3. **Uploads to TestFlight** (if testflight build)
4. **Creates artifact** (IPA file downloadable)

## 🐛 Troubleshooting

### Build Fails: "Match password incorrect"
- Verify `MATCH_PASSWORD` secret is correct
- Ensure Match was initialized with same password

### Build Fails: "No certificates found"
- Run `fastlane match appstore` locally first
- Ensure certificates repo exists and is accessible

### Build Fails: "Apple ID authentication failed"
- Verify `APPLE_ID` is correct
- Generate new app-specific password
- Ensure 2FA is enabled on Apple ID

### Build Fails: "Missing secrets"
- Check all required secrets are added
- Verify secret names match exactly (case-sensitive)

## ✅ Quick Checklist

- [ ] App-specific password created
- [ ] Certificates repository created
- [ ] Match initialized locally (first time)
- [ ] All secrets added to GitHub
- [ ] `Matchfile` updated with certificates repo URL
- [ ] Build triggered!

## 🚀 Next Steps

1. **Set up secrets** (5 minutes)
2. **Initialize Match** (if first time, requires Mac)
3. **Trigger build** from Actions tab
4. **Wait ~15 minutes**
5. **Check TestFlight** for your build!

## 📚 Resources

- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Fastlane Match](https://docs.fastlane.tools/actions/match/)
- [App-Specific Passwords](https://support.apple.com/en-us/102654)

---

**Your workflow is ready!** Just add the secrets and trigger a build. 🎉

