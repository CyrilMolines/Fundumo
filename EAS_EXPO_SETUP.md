## Expo / EAS Setup Guide

This guide covers linking the `fundumo_expo` project to Expo Application Services (EAS), configuring credentials, and triggering builds or submissions directly from the CLI or GitHub Actions.

### 1. Prerequisites

- Node.js 18+
- Expo CLI (`npm install -g expo-cli` or rely on `npx`)
- Expo account with access to https://expo.dev
- Apple Developer Program membership (for iOS builds)
- Google Play Console account (for Android uploads)

### 2. Authenticate and link the project

```bash
cd Fundumo/fundumo_expo
eas login
eas whoami      # verify session
eas init --id <expo-project-id>
```

`eas init` injects `extra.eas.projectId` into `app.json` so all CI/CD jobs can reuse the same Expo project without interactivity.

### 3. Configure local environment

| Variable | Purpose | Where to set |
| --- | --- | --- |
| `EXPO_TOKEN` | Non-interactive auth for CI (generated at https://expo.dev/accounts/<acct>/settings/access-tokens) | GitHub Secrets / local shell |
| `EAS_PROJECT_ID` | Optional override for workflows; usually auto-read from `app.json` | GitHub Secrets |
| `APPLE_TEAM_ID`, `APPLE_APP_SPECIFIC_PASSWORD`, `APPLE_ID` | Required if not using ASC API keys | GitHub Secrets |
| `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` | Upload once via `eas credentials` or set as secrets for scripted imports | GitHub Secrets |

### 4. Provision credentials

```bash
# iOS
eas credentials --platform ios --profile production

# Android
eas credentials --platform android --profile production
```

EAS stores the signing assets securely. You can later promote them to the `staging` or `preview` profiles with `--profile <name>`.

### 5. Run builds manually

```bash
# Dev client / internal QA
eas build --profile preview --platform all --non-interactive

# TestFlight + Play Internal
eas build --profile staging --platform all --non-interactive

# Production stores
eas build --profile production --platform all --non-interactive
```

Artifacts are visible under https://expo.dev/accounts/<acct>/projects/fundumo/builds.

### 6. Submissions

After a production build finishes you can trigger uploads:

```bash
eas submit --platform ios --profile production --non-interactive
eas submit --platform android --profile production --non-interactive
```

### 7. GitHub Actions integration

The repository includes `.github/workflows/eas-build.yml` which:

1. Installs dependencies in `fundumo_expo`
2. Runs `npm run lint`
3. Executes `eas build --profile preview --platform all --non-interactive`

Required secrets:

- `EXPO_TOKEN`
- `EAS_PROJECT_ID` (optional if already in `app.json`)

### 8. Useful commands

| Command | Description |
| --- | --- |
| `npx expo start --clear` | Start Metro with cache cleared |
| `eas build:list` | Inspect historical builds |
| `eas device:create` | Register real devices for internal distribution |
| `eas channel:create <name>` | Create release channels for OTA updates |

### 9. Troubleshooting

- **Missing project ID**: re-run `eas init` or manually add `"extra": { "eas": { "projectId": "..." } }` to `app.json`.
- **403 during build**: ensure `EXPO_TOKEN` hasn’t expired and the account has access to the project.
- **iOS signing failures**: double-check App Store Connect API key permissions or regenerate certificates via `eas credentials`.

With these steps the Expo implementation can be built and released entirely through EAS, both locally and via CI. Feel free to expand the workflow to cover staging/production promotions or automated submissions.

