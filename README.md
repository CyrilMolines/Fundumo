# Fundumo 💰

**Fundumo** is a comprehensive personal finance companion app built with Flutter. Manage your budget, track subscriptions, organize envelopes, monitor side gigs, set saving goals, split shared bills, and scan receipts - all in one beautiful, intuitive interface.

> **New:** The roadmap features (Event Summary Maker, Memory Lane, Anonymous Feedback) now have a dedicated Expo implementation under `fundumo_expo/` for teams that prefer Expo.dev + EAS Build. See [Expo Quick Start](#expo-quick-start) for details.

## ✨ Features

### 📊 Dashboard
- **Personalized Summary**: View your financial overview at a glance
- **Smart Insights**: Get actionable financial recommendations
- **Recent Activity**: Chronological feed of all transactions and activities
- **Subscription Watchdog**: Track and manage recurring subscriptions

### 💵 Budgeting & Envelopes
- **Envelope System**: Organize spending by categories
- **Budget Tracking**: Monitor weekly and monthly budgets
- **Overspending Alerts**: Get notified when approaching limits

### 🔔 Subscriptions
- **Recurring Payments**: Track all your subscriptions
- **Renewal Reminders**: Never miss a payment or renewal
- **Cost Analysis**: See total monthly subscription costs

### 💼 Side Gigs
- **Income Tracking**: Log income from side hustles
- **Performance Metrics**: Track earnings over time

### 🎯 Saving Goals
- **Goal Setting**: Create and track saving objectives
- **Progress Monitoring**: Visual progress indicators
- **Contribution Tracking**: Log contributions to goals

### 👥 Shared Bills
- **Bill Splitting**: Split expenses with roommates or partners
- **Owed Tracking**: See who owes what
- **Settlement History**: Track payments and settlements

### 🧾 Receipts
- **Receipt Scanning**: OCR-powered receipt capture
- **Warranty Tracking**: Monitor warranty expiration dates
- **Expense Organization**: Categorize and store receipts

### 🔐 Security & Sync
- **Biometric Authentication**: Secure access with fingerprint/face ID
- **Data Encryption**: All sensitive data encrypted at rest
- **Cloud Sync**: Sync across devices with Supabase
- **Backup & Restore**: Export and import your data

## 🚀 Quick Start

### Prerequisites
- Flutter SDK (3.9.2 or higher)
- Dart SDK
- iOS: Xcode (for iOS builds)
- Android: Android Studio (for Android builds)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/CyrilMolines/Fundumo.git
   cd Fundumo/fundumo_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## 📱 Build & Deploy

### Codemagic (Cloud Builds - Recommended)

Fundumo uses **Codemagic** for cloud-based builds (Flutter's equivalent to EAS Build).

1. **Set up Codemagic**
   - Sign up at [codemagic.io](https://codemagic.io)
   - Connect your GitHub repository
   - Configure code signing (iOS + Android)
   - Set environment variables

2. **Build**
   - Select workflow: `ios-workflow`, `android-workflow`, or `ios-android-workflow`
   - Click "Start new build"

See [CODEMAGIC_SETUP.md](CODEMAGIC_SETUP.md) for detailed instructions.

### Fastlane (Local Builds)

For local iOS builds:

```bash
cd fundumo_app/ios
fastlane beta  # TestFlight
fastlane release  # App Store
```

See [EAS_BUILD_GUIDE.md](EAS_BUILD_GUIDE.md) for Fastlane setup.

### GitHub Actions

Automated builds are configured in `.github/workflows/ios-build.yml`.

## ⚡ Expo Quick Start

If you want to work with the Expo port instead of Flutter:

```bash
cd Fundumo/fundumo_expo
npm install
npx expo start
```

Key docs:

- [`fundumo_expo/README.md`](fundumo_expo/README.md) – feature overview + local workflow
- [`EAS_EXPO_SETUP.md`](EAS_EXPO_SETUP.md) – linking the Expo project to EAS, credentials, CI
- `.github/workflows/eas-build.yml` – runs lint + `eas build --profile preview`

Expo supports the new Event Summary, Memory Lane, and Anonymous Feedback features with Zustand + AsyncStorage persistence and is ready for EAS preview/staging/production profiles.

## 🏗️ Architecture

### Tech Stack
- **Framework**: Flutter 3.9.2+
- **State Management**: Riverpod
- **Design System**: Material 3
- **Backend**: Supabase (authentication, database, storage)
- **Local Storage**: SharedPreferences + Custom file storage
- **Notifications**: flutter_local_notifications
- **OCR**: Google ML Kit
- **Error Tracking**: Sentry

### Project Structure

```
fundumo_app/
├── lib/
│   ├── application/     # State management (Riverpod providers)
│   ├── core/           # Theme, config, utilities
│   ├── data/           # Repositories and data sources
│   ├── domain/         # Domain models
│   ├── features/       # Feature modules (UI)
│   └── services/       # Business logic services
├── ios/                # iOS native code
├── android/            # Android native code
└── test/              # Tests
```

## 🔧 Configuration

### Environment Variables

Set these in your build configuration or Codemagic:

- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_ANON_KEY` - Your Supabase anon key
- `SENTRY_DSN` - Your Sentry DSN (optional)

### Supabase Setup

1. Create a Supabase project
2. Run the SQL schema from [SETUP_GUIDE.md](SETUP_GUIDE.md)
3. Configure authentication providers
4. Set up storage buckets for receipts

See [SETUP_GUIDE.md](SETUP_GUIDE.md) for detailed setup instructions.

## 📚 Documentation

- [BUILD_AND_DEPLOY.md](BUILD_AND_DEPLOY.md) - Build and deployment guide
- [CODEMAGIC_SETUP.md](CODEMAGIC_SETUP.md) - Codemagic configuration
- [EAS_BUILD_GUIDE.md](EAS_BUILD_GUIDE.md) - Fastlane setup
- [PRODUCTION_READINESS_ASSESSMENT.md](PRODUCTION_READINESS_ASSESSMENT.md) - Production checklist
- [SETUP_GUIDE.md](SETUP_GUIDE.md) - Backend and services setup

## 🧪 Testing

Run tests:
```bash
flutter test
```

Run widget tests:
```bash
flutter test test/widget_test.dart
```

## 📄 License

This project is private and proprietary.

## 🤝 Contributing

This is a personal project. Contributions are welcome but please open an issue first to discuss changes.

## 📞 Support

For issues and questions, please open an issue on GitHub.

---

**Built with ❤️ using Flutter**

