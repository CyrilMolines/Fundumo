# Fundumo Mobile Application Project Plan

## 1. Vision & Product Overview
Fundumo is a cross-platform personal finance companion that blends budgeting, savings, side-income tracking, and collaborative expense management into a single ultra-efficient mobile app. It consolidates proven money management practices into daily guidance while leveraging open-source infrastructure to minimize operating costs.

## 2. Goals & Success Metrics
- Deliver a production-ready Android and iOS app within 9 months.
- Achieve cold-start times <1s on mid-range Android hardware and <750ms on iPhone SE (3rd gen).
- Maintain sync accuracy with <0.1% reconciliation errors across devices.
- Reach ≥4.5 store rating after the first 1,000 active users.
- Pass SOC 2-aligned security and privacy audits before public launch.

## 3. Target Users & Personas
- **Budget-Constrained Workers**: hourly or gig workers needing fast visibility into remaining funds.
- **Micro-Entrepreneurs**: side-gig operators managing income, expenses, and taxes per job.
- **Shared Living Groups**: roommates or couples sharing recurring bills over time.
- **Savings Enthusiasts**: users tracking short-to-midterm goals who benefit from nudges and visual progress.

## 4. Platform & Technology Strategy
- **Framework**: Flutter 3.x for shared codebase and native performance on Android/iOS.
- **State Management**: Riverpod + Freezed for immutable state and testable business logic.
- **Navigation**: GoRouter for declarative routing and deep link support.
- **Data Layer**: Supabase (open-source Postgres, Auth, Storage, Realtime) with option to self-host.
- **Offline Capability**: Hive (encrypted boxes) with background sync workers and conflict resolution policies.
- **CI/CD**: GitHub Actions for static analysis/tests, Codemagic for signed builds and store deployment.
- **Monitoring**: Sentry (self-host option) for crash analytics; Prometheus/Grafana stack for backend metrics.

## 5. High-Level Architecture
1. **Presentation Layer**: Flutter feature modules (`features/expense_snapshot`, `features/subscription_watchdog`, etc.) using Material 3 adaptive design.
2. **Application Layer**: Use-case services (e.g., `CalculateDailyBudget`, `GenerateProfitSummary`, `ReconcileSharedBalance`).
3. **Domain Layer**: Entities (`Expense`, `Subscription`, `Envelope`, `SideGig`, `SavingGoal`, `SharedBill`, `Receipt`) with validation and currency utilities.
4. **Data Layer**: Repository interfaces bridging Supabase REST/Realtime, local Hive cache, secure storage, and OCR pipeline.
5. **Security Layer**: Device biometrics (local_auth), encrypted secrets (FlutterSecureStorage + platform keystore), role-based access control enforced via Supabase policies.

## 6. Core Data Model (Initial Draft)
- `UserProfile`: currency, locale, notification preferences, linked accounts.
- `ExpenseTemplate`: fixed costs with recurrence schedule, due date, average variance.
- `Envelope`: category, allocation amount, spent amount, rollover rules, visual theme.
- `Transaction`: timestamp, amount, direction, linked envelope, tags, attachments.
- `SideGig`: job metadata, rate, tracked hours, expenses, net profit summary.
- `SavingGoal`: target amount, target date, jar theme, contribution history.
- `SharedBill`: participant list, ledger entries, settlement status, reminders.
- `Receipt`: media reference, OCR text, category, warranty expiry, reminders.

## 7. Feature Breakdown & Delivery Phases
### Phase 0 — Foundation (Weeks 1-6)
- Flutter project scaffolding, linting, localization, theming, design tokens.
- Supabase project bootstrap: schema migrations, row-level security, storage buckets.
- Authentication (email/password + OAuth), session persistence, device biometrics.
- Core dashboard shell with mocked data, offline cache, sync orchestration service, QA baseline tests.

### Phase 1 — Budget Core (Weeks 7-14)
- **Expense Snapshot**: large fixed expense capture, rolling 30-day projections, variance analytics.
- **Cash Envelope Assistant**: envelope CRUD, envelope funding rules, visual progress rings, transaction reconciliation UI.
- **Goal-Based Saving Jar**: jar creation, micro-transfer suggestions, milestone celebrations, savings calendar view.
- Push notifications for budget thresholds and goal milestones.
- Unit, widget, and integration tests targeting financial accuracy and UI flows.

### Phase 2 — Income & Collaboration (Weeks 15-22)
- **Side-Gig Tracker**: hour logging (manual + timer), expense attachment, tax estimation, profit & loss exports (CSV/PDF via `printing`).
- **Bill Splitting Friendlier**: shared ledger, balance settlement suggestions, real-time updates via Supabase Realtime channels, push reminders.
- Multi-currency support with ExchangeRate.host API caching service.
- GDPR tooling: data export/delete, consent management.

### Phase 3 — Automation & Insights (Weeks 23-30)
- **Subscription Watchdog**: subscription registry, renewal reminders, optional bank import via Nordigen/GoCardless free API, churn analytics.
- **Receipt Vault**: mobile scanning pipeline with ML Kit edge detection, Tesseract OCR fallback, warranty expiry alerts.
- Analytics dashboard: monthly insights, envelope health score, savings velocity charts (charts_flutter).
- Private beta release, telemetry instrumentation, feedback loop with targeted cohorts.

### Phase 4 — Launch Hardening (Weeks 31-36)
- Performance profiling (Android Profiler, Xcode Instruments) and optimization (Impeller renderer for charts.)
- Security audit, penetration testing, privacy policy and terms finalization.
- Store asset production, onboarding walkthrough, localization (EN, ES, FR initial set).
- Public launch, marketing integration, post-launch monitoring and hotfix readiness.

## 8. Integrations & Open-Source Dependencies
- Flutter SDK, Dart toolchain, Material Design assets.
- Riverpod, Freezed, json_serializable, Hive, hive_generator.
- Supabase Dart client, PostgREST, Realtime, edge functions.
- ML Kit (device-based), Tesseract OCR, image_picker, camera.
- Sentry (self-host or SaaS), Firebase Cloud Messaging for notifications.
- Plausible Analytics (self-hostable) or Supabase analytics functions for privacy-centric metrics.
- GitHub Actions, Codemagic, Fastlane (for automated store metadata).

## 9. Security, Privacy & Compliance
- Enforce TLS 1.2+ end-to-end, certificate pinning via `http` client middleware.
- Supabase row-level security policies per user, audit logs stored in immutable bucket.
- On-device encryption: Hive secure boxes guarded by platform keychain/keystore.
- Optional biometric unlock, idle session timeout, remote wipe (via Supabase edge function trigger).
- Regular dependency scanning (Dependabot + Flutter `pub outdated --security`).
- SOC 2-aligned controls: access reviews, change management, incident response plan.

## 9.1 Mobile Experience Guardrails (Accessibility, Offline, Trust)
- **Screen-reader labels & focus:** Every budgeting chip, envelope action, quick toggles, and tab icon requires descriptive semantics (“Envelope groceries, 45% remaining”) and a deterministic focus order for TalkBack/VoiceOver/external keyboards. Dialogs (split expense, goal contribution, receipt scan) must trap focus while exposing labelled close buttons so users never get stuck.
- **Contrast, touch targets, feedback:** Budget heatmaps, variant cards, and charts overlaying imagery need scrims to preserve WCAG AA. Keep interactive targets ≥48 dp and pair colored budget statuses with icons/text to avoid color-only cues. Provide haptic/audio confirmations for envelope transfers, reconciliation success, and saving-goal milestones.
- **Captions & transcripts:** Auto-generate transcripts for audio memos or voice-added receipts before syncing so hearing-impaired users can review text.
- **Offline & bad-network:** Cache the last 90 days of transactions, envelopes, goals, and receipts locally (Hive/Drift) to allow budgeting offline. Queue all mutations (expense edits, transfers, bill splits) with deterministic retry/backoff plus inline states (“3 updates pending sync – Retry”). Receipt uploads should support pause/resume; show explicit offline banners with timestamps instead of indefinite spinners.
- **Privacy controls:** Request camera/file/mic permissions at point-of-use with justification (“Needed to capture receipt; stored encrypted”). Provide a Privacy hub to toggle analytics, marketing pushes, geolocation for merchant detection, and AI recommendations. Build functioning “Export my data” (ZIP with CSV/PDF) and “Delete account” flows that don’t bury opt-outs behind confusing colors.
- **Localization & culture:** Support RTL mirroring for expense lists, apply locale-aware currency/decimal/grouping rules everywhere, and respect 12/24 h preferences for reminder timestamps. Provide UI headroom for long German/French strings and run dynamic-type + localization snapshot tests.
- **Onboarding & empty states:** Persist onboarding steps so users can resume after interruptions. Each module should have purposeful empty states (“No savings jars yet—create one for a weekend trip; here’s how it works”) plus microcopy clarifying how data is stored and synced.
- **Error handling & recovery:** Replace “Something went wrong” with actionable hints (“Transfer failed – kept offline, will retry when connected”). Provide inline validation for amount fields, currency selectors, and participant emails; highlight the specific input. Use undo snackbars for destructive actions (“Deleted expense – Undo 8 s”) instead of repeated dialogs.
- **Performance, battery, devices:** Use skeletons for heavy dashboards, optimistic UI on envelope sliders, and 60 fps goals/progress animations. Batch sync + analytics to reduce wakeups, pause GPS or bank polling when battery saver is active, and verify responsive layouts on smaller phones, tablets, and foldables.
- **Notifications:** Ship per-category toggles (budget thresholds, shared bill reminders, subscription warnings, goal nudges, marketing) plus quiet hours and Do-Not-Disturb bridging. Default to essential categories only; promotional pushes require opt-in.
- **Support & trust:** Provide in-app “Report a problem” with optional screenshot/log attachments and maintain a “What’s new / Status” panel summarizing releases, policy shifts, and downtime. Prepend legal docs with plain-language summaries.
- **Session longevity & recovery:** Keep gentle session expiry with inline re-auth prompts so unsent transactions aren’t lost. Document concurrency behaviour for multi-device households, and ensure password reset + recovery code flows (for when email/phone changes) are exercised end-to-end.

## 9.2 Benchmark UX Specification (Inspired by Notion & Headspace)
- **Benchmark apps:** Notion Mobile (4.8⭐ App Store, 4.7⭐ Play) remains the reference for sophisticated yet calm productivity UI, while Headspace (4.9⭐) sets the bar for approachable motion/illustration. Fundumo must inherit their polish.
- **Grid & spacing:** Adopt an 8 pt grid, 24 dp vertical rhythm, 16 dp padding inside expense/envelope cards, and 12 dp corner radii. Tablet layouts add 32 dp gutters and max 760 dp content width.
- **Typography:** Use Inter/SF Pro style pairing—Dashboard title 32 sp/600, section headers 22 sp/600, body text 16 sp/1.45, captions 13 sp/500. Keep 0.5 sp letter spacing on uppercase labels replicating Notion’s hierarchy.
- **Palette & elevation:** Each screen limited to three neutrals plus one accent; Headspace-like gradients require ≥75 % scrim overlays for contrast. Elevation tokens: base 0, cards 2, floating action 6, with 12 % shadow alpha and ≤16 dp blur.
- **Motion & haptics:** Navigation/refresh animations run 180–220 ms cubic-bezier(0.2,0.8,0.2,1). Envelope transfers trigger `mediumImpact()` haptics; toggles and sliders use `lightImpact()`. Savings celebrations play 250 ms spring animations with confetti limited to 400 ms lifetime, mirroring Headspace delight.
- **Micro-interactions:** Progress rings animate from 0→value over 280 ms, ledger rows slide 4 dp with 80 ms delay on swipe to mimic Notion blocks, and “breathing” pulses indicate pending sync states (loop ≤1.5 s, paused for reduce-motion).
- **Illustrations & avatars:** Empty states rely on duotone SVGs (2 px strokes, 8 pt rounding) sized ≤40 % of viewport height; profile avatars maintain 12 dp rounding and 1 px outlines for crispness across light/dark themes.
- **Shared system:** All mobile clients must ship with the shared Kangaroo visual system (palette, typography, icon set, animation presets).

## 10. Team Structure & Governance
- **Product Lead (1)**: backlog ownership, user research, KPI tracking.
- **Tech Lead (1)**: architecture decisions, code review standards, performance profiling.
- **Flutter Engineers (3)**: feature delivery, cross-platform UI, testing.
- **Backend Engineer (1)**: Supabase schemas, edge functions, integrations.
- **Design Lead (1)**: UX flows, design system, accessibility compliance.
- **QA/Automation (1)**: test plan, CI instrumentation, release certification.
- **Data Analyst (fractional)**: telemetry interpretation, cohort analysis.

## 11. Timeline & Milestones (Indicative)
| Phase | Duration | Key Deliverables |
|-------|----------|------------------|
| 0 | Weeks 1-6 | Scaffolding, auth, dashboard shell, CI/CD |
| 1 | Weeks 7-14 | Budget core features, notifications, tests |
| 2 | Weeks 15-22 | Side-gig tracker, bill splitting, multi-currency |
| 3 | Weeks 23-30 | Subscription watchdog, receipt vault, analytics |
| 4 | Weeks 31-36 | Performance hardening, security audit, launch |

## 12. Risk Register & Mitigations
- **Regulatory changes**: monitor financial compliance; engage legal partner early, maintain modular policy screens.
- **Third-party API limits**: build fallback manual flows; cache data; plan for rate limiting.
- **OCR accuracy**: provide manual correction UI and active learning dataset; leverage on-device ML improvements.
- **User adoption**: run continuous beta cohorts, integrate in-app surveys, iterate onboarding flow.
- **Performance regression**: automate performance benchmarks on target devices within CI pipeline.

## 13. Immediate Next Steps
- Finalize Supabase schema draft and security policies.
- Produce low-fidelity UX wireframes for dashboard and key flows.
- Establish design tokens and typography scale in Flutter theme.
- Define budgeting and income calculation formulas with test fixtures.
- Kick off recruitment for Flutter engineers and QA specialist.

## 14. Feature Specifications & Acceptance Criteria
### Expense Snapshot
- Collect recurring fixed-cost templates with amount, frequency, next due date.
- Automatically project daily discretionary budget using last 30 days of transactions plus upcoming fixed costs.
- Display variance indicators (green/yellow/red) based on spend vs projection.
- Acceptance: variance calculation verified against fixture data; daily budget updates within 5 seconds of new transaction sync.

### Subscription Watchdog
- Maintain subscription catalog with renewal cycle, price, payment source, cancellation instructions.
- Auto-compute monthly and annual totals; highlight price changes >5%.
- Reminder engine sends push notification 7 days and 24 hours before renewal unless snoozed.
- Acceptance: reminders fire reliably in device/emulator tests; totals reconcile with database snapshots.

### Cash Envelope Assistant
- Support custom category creation, target allocations, rollover policies per envelope.
- Provide tap-through breakdown of transactions contributing to each envelope.
- Visual progress ring adjusts in real time as transactions post or are edited.
- Acceptance: envelope balances never exceed allocated funds unless rollover enabled; UI updates without app restart after offline sync.

### Side-Gig Tracker
- Allow hour logging via manual entry or active timer with pause/resume.
- Capture income, direct expenses, and tax withholding settings per gig.
- Generate profit summary with gross, expenses, tax estimate, and net income; export via CSV/PDF.
- Acceptance: profit summary variance under 0.5% against accounting benchmark scenarios; exports open correctly on both platforms.

### Goal-Based Saving Jar
- Create multiple jars with target amount, deadline, and visual theme.
- Support recurring and ad-hoc contributions; trigger milestone animations at 25/50/75/100%.
- Provide micro-transfer suggestions based on unused envelope funds.
- Acceptance: contributions sync across devices within 10 seconds; milestone events logged to analytics.

### Bill Splitting Friendlier
- Persistent groups with participant weighting, ledger of shared expenses, settlement proposals.
- Support cash, bank transfer, and PayPal/Venmo links for settlement references.
- Calculate who owes whom, with running balance per participant.
- Acceptance: ledger remains balanced (<$0.01 net) after series of random expense simulations; push reminders delivered on schedule.

### Receipt Vault
- Capture images via camera or gallery; perform edge detection and perspective correction.
- Run on-device OCR, allow manual field correction, tag receipts, store warranty expiry.
- Trigger expiry reminders 30 days and 7 days before warranty end.
- Acceptance: OCR pipeline succeeds on-device without network for resolutions >=720p; reminder job passes integration tests.

## 15. Data Synchronization & Offline Strategy
- Employ Supabase row-level policies to scope data per user or shared group.
- Use `drift` or custom DAO layer to reconcile Hive offline writes with Supabase via change timestamps and conflict resolution rules (last-write-wins for transactions, merge for envelopes).
- Background sync worker (Flutter Workmanager) schedules delta uploads every 15 minutes when online.
- Large media (receipts) uploaded via multipart with retry/backoff; thumbnails cached locally.
- Implement integrity checksums per sync batch; discrepancies trigger alert and re-sync.

## 16. Testing & Quality Strategy
- Unit tests for all domain calculations (budget projections, ledger balances) with golden fixture files.
- Widget tests for complex UI states (envelope dashboards, receipt editor) using Flutter test harness.
- Integration tests on Firebase Test Lab (Android) and Xcode Cloud devices (iOS) covering onboarding, offline sync, receipt capture.
- Contract tests for Supabase edge functions and webhook integrations using Postman/Newman collection in CI.
- Performance tests automated via `flutter drive` scripts capturing frame rendering, memory, and energy usage metrics.

## 17. DevOps, CI/CD & Release Management
- Git strategy: trunk-based with short-lived feature branches, mandatory PR reviews, semantic commit messages.
- CI pipeline stages: lint/format, unit/widget tests, integration tests, security scans (`trivy`, `flutter pub outdated --security`), build artifacts.
- Nightly beta builds distributed through Firebase App Distribution and TestFlight.
- Release checklist includes migration validation, store metadata updates via Fastlane, and staged rollout configuration (10% → 50% → 100%).
- Infrastructure as code for Supabase configuration tracked via Terraform or Supabase CLI migration files in repo.

## 18. Analytics & Metrics
- Core metrics: daily active users, monthly active users, feature adoption per module, retention cohorts, average envelope utilization, net savings delta, subscription churn saves.
- Privacy-first instrumentation using Amplitude-compatible open-source alternative (Snowplow or Plausible events pipeline).
- All analytics events versioned; schema documented in repo to avoid drift.
- In-app feedback module collects NPS, bug reports, feature requests tied to anonymized user IDs.

## 19. Legal, Compliance & Partnerships
- Conduct data protection impact assessment (DPIA) before beta; document data flows and storage locations.
- Establish partnerships with Nordigen/GoCardless for financial data aggregation under appropriate user consent flows.
- Draft and localize terms of service, privacy policy, and subscription cancellation disclosures for supported regions.
- Implement age verification and parental consent workflow if expanding to under-18 users.

## 20. Post-Launch Roadmap Candidates
- AI-powered spend categorization using on-device TensorFlow Lite models trained on anonymized datasets.
- Open banking integrations beyond EU (Plaid, MX) with regional compliance gating.
- Small-business module: inventory tracking, invoicing, tax document export.
- Community-driven savings challenges with leaderboards and shared goal jars.
- Web dashboard companion leveraging Flutter Web for extended access.

## 21. Open Questions & Dependencies
- Final decision on using Supabase self-host vs managed; evaluate cost, compliance, scaling requirements.
- Determine go-to-market budget allocation for paid acquisition vs community partnerships.
- Confirm legal counsel availability for SOC 2 readiness and financial regulation mapping per deployment region.
- Decide on receipt OCR model training ownership (in-house tuning vs third-party service).
- Select localization vendor/tooling for ongoing translation updates (e.g., Lokalise vs open-source alternatives).
