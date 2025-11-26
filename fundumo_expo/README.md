# Fundumo (Expo)

Fundumo’s mobile experience has been rewritten with Expo Router so it can be built and deployed through [Expo Application Services (EAS)](https://expo.dev/eas). The Event Summary Maker, Memory Lane resurfacing, and Anonymous Feedback flows from the Flutter build have been ported natively to React Native.

## Feature set

| Area | Capabilities |
| --- | --- |
| Event Summary Maker | Title/description/media count capture, multiline highlights, tag clouds, deletion + trend insights. |
| Memory Lane | 120-entry archive with resurfacing window (±21 days) and manual refresh, tag + mood support. |
| Anonymous Feedback | Local inbox with anonymous tracking codes, resolution workflow, and backlog metrics. |
| Command Center | Home dashboard summarizing recaps, resurfaced memories, tag momentum, and unresolved feedback. |

All state is stored offline via `@react-native-async-storage/async-storage` and modeled with Zustand persistence so that every feature works without a backend.

## Layout

```
fundumo_expo/
├─ app/(tabs)              # Home, Event Summary, Memory Lane, Feedback screens (Expo Router)
├─ components/             # Themed primitives from create-expo-app
├─ src/
│  ├─ state/               # Zustand stores + domain logic
│  ├─ storage.ts           # AsyncStorage helpers
│  └─ types.ts             # Shared models
├─ app.json                # Bundle IDs, icons, splash, experiments
├─ eas.json                # Preview/Staging/Production build profiles
└─ README.md
```

## Run locally

```bash
cd Fundumo/fundumo_expo
npm install
npx expo start
```

Other useful commands:

| Command | Description |
| --- | --- |
| `npm run android` | Launch the Android emulator/device with Metro already running. |
| `npm run ios` | Launch the iOS simulator (requires macOS). |
| `npm run web` | Start the responsive PWA build. |

Expo Router handles navigation via the filesystem, so adding a tab or stack route is as simple as creating a new file under `app/`.

## Persistent stores

| Store | Key | Notes |
| --- | --- | --- |
| Event summaries | `event-summaries` | Max 50 entries, highlight text trimmed and capped, tag cloud rebuilt on hydrate. |
| Memory Lane | `memory-lane` | Max 120 entries, resurfacing window ±21 days, refresh button triggers recompute. |
| Feedback inbox | `feedback` | Anonymous code `FUN-XXXXXXXXXX`, resolution timestamps + backlog counter. |

Each store uses `createJSONStorage(() => AsyncStorage)` to guarantee deterministic persistence across platforms.

## Building with EAS

`eas.json` ships with three profiles:

| Profile | Purpose | Command |
| --- | --- | --- |
| `preview` | Dev client / internal QA builds | `eas build --profile preview --platform all` |
| `staging` | TestFlight / Play Internal track | `eas build --profile staging --platform all` |
| `production` | Public App Store / Play Store | `eas build --profile production --platform all` |

Before kicking off builds, authenticate and link the Expo project:

```bash
eas login
eas init --id <your-expo-project-id>   # populates extra.eas.projectId inside app.json
```

Provision credentials once per target:

```bash
eas credentials --platform ios --profile production
eas credentials --platform android --profile production
```

Deploy to the stores with:

```bash
eas submit --platform ios --profile production
eas submit --platform android --profile production
```

## QA checklist

1. Add, edit, and delete event summaries—confirm tag cloud updates instantly.
2. Store at least three memories with different dates, then tap “Refresh” to verify resurfacing respects the ±21-day window.
3. Submit anonymous feedback, mark it resolved, and confirm counts update on the home dashboard.
4. Run `npx expo start --web` to ensure layout parity in browsers.

## Next steps

- Hook Supabase (or another backend) into the stores if cloud sync is required.
- Wire Expo Push Notifications to proactively alert users when memories resurface.
- After running `eas init`, commit the generated `extra.eas.projectId` so CI/CD can reuse the project ID.
