# Activity 4 — App Store Connect and TestFlight configuration

Lab Exercise 06 · IT3060 · FitFlow 1.1.0 (build 2) · bundle ID `io.fitflow.app`

**Status: configuration prepared and the iOS app built and run on simulators; not uploaded.** An
Apple Developer Program membership (US$99/year) is required to create the App Store Connect record,
sign for distribution and use TestFlight, and none was available. The iOS app itself builds with
Xcode 27 and runs on the iPhone 18 Pro Max and iPad Pro 13-inch simulators (iOS 27) — those runs
produced the App Store screenshots and app preview in Activity 2.

## 1. Prerequisites (one-time)

| Item | Value |
|---|---|
| Apple Developer Program | Individual or organisation membership |
| Bundle ID (Certificates, Identifiers & Profiles) | `io.fitflow.app`, explicit; capabilities: none required in 1.1.0 |
| Signing | Xcode automatic signing, team set in `ios/Runner.xcodeproj` |
| Version / build | `CFBundleShortVersionString` 1.1.0, `CFBundleVersion` 2 (both from `pubspec.yaml`) |
| Minimum iOS | 15.0 |
| Devices | iPhone and iPad |

## 2. App record (App Store Connect → Apps → +)

| Field | Value |
|---|---|
| Platform | iOS |
| Name (30) | FitFlow: Workouts & Nutrition |
| Primary language | English (U.K.) |
| Bundle ID | io.fitflow.app |
| SKU | FITFLOW-IOS-001 |
| User access | Full access |

### App information
| Field | Value / file |
|---|---|
| Subtitle (30) | `store-assets/listing/app-store/subtitle.txt` — "Workouts planned for you" |
| Category | Primary **Health & Fitness**, secondary Food & Drink |
| Content rights | Does not contain third-party content |
| Age rating | **4+** questionnaire: no objectionable content; *User-generated content: Yes* (circles) with report/delete in-app; *Medical/treatment information: None*. Apple may assign a higher rating because of user-generated content — accepted |
| Privacy policy URL | `https://chanuka-01.github.io/fitflow-redesign/privacy-policy/` |
| Support URL | `https://github.com/CHANUKA-01/fitflow-redesign` (until a support site exists) |

### Version 1.1.0 page
| Field | Value / file |
|---|---|
| Promotional text (170) | `promotional-text.txt` (144) — editable without review |
| Description | `description.txt` |
| Keywords (100) | `keywords.txt` — `workout,planner,gym,fitness,strength,nutrition,calorie,meal,tracker,dumbbell,exercise,habit,streak` (98) |
| What's New | `docs/lab06/05-release-notes.md`, "App Store" section |
| iPhone 6.9" screenshots | `store-assets/ios/screenshots/iphone-6.9in/` — 8 × 1320×2868 (Apple scales these for smaller iPhones) |
| iPad 13" screenshots | `store-assets/ios/screenshots/ipad-13in/` — 8 × 2064×2752 |
| App preview | `store-assets/ios/previews/ff_ios_iphone69_app-preview_886x1920.mp4` — 23 s, real footage, poster frame at 5 s (home card) |
| Copyright | 2026 FitFlow |

## 3. App Privacy ("nutrition labels")

Answered for 1.1.0, which has no network access:

| Question | Answer |
|---|---|
| Do you or your third-party partners collect data from this app? | **No, we do not collect data from this app** |

Resulting label: **"Data Not Collected."** Apple defines "collect" as transmitting data off the device
in a way that allows access beyond real-time servicing; FitFlow keeps all data on the device.

Prepared answers for the release that adds the backend and Firebase Crashlytics (Activity 6), so the
label is updated in the same submission:

| Data type | Linked to user | Used for tracking | Purpose |
|---|---|---|---|
| Health & Fitness → Fitness | Yes | No | App functionality |
| Contact info → Name, email | Yes | No | App functionality (account) |
| User content → Other user content (posts) | Yes | No | App functionality |
| Diagnostics → Crash data, performance data | No | No | App functionality |
| Photos | Not collected — on-device analysis (ADR-003) | — | — |

No App Tracking Transparency prompt is needed: FitFlow does not track users across other companies'
apps or websites.

## 4. Upload the build

Commands (macOS, from `frontend/mobile`) once signing is configured:

```bash
flutter build ipa --release --obfuscate --split-debug-info=build/debug-info
# → build/ios/ipa/FitFlow.ipa ; then either:
xcrun altool --upload-app -f build/ios/ipa/*.ipa -t ios --apiKey <KEY_ID> --apiIssuer <ISSUER_ID>
# or open build/ios/archive/Runner.xcarchive in Xcode Organizer → Distribute App → App Store Connect
```

Export compliance: FitFlow uses no encryption beyond Apple's own (HTTPS via the OS in later
releases). Set `ITSAppUsesNonExemptEncryption = NO` in `Info.plist` so every build skips the
question.

Evidence available without an account: `flutter build ios --simulator` succeeds and the app runs on
both simulators (Activity 2 §2.1). The build exposed one environment defect — iCloud Drive tagging
build files so `codesign` refused them — fixed by moving build output out of the synced Desktop
(Activity 1 §3.3).

## 5. TestFlight

### 5.1 Groups

| Group | Type | Members | Builds | Review |
|---|---|---|---|---|
| **FitFlow Team** | Internal | Up to 100 App Store Connect users (developers, designer, QA) | Every build, automatically | None |
| **FitFlow Beta – Campus** | External | Invited by email; target 20–30 SLIIT students who train regularly | Selected builds | First build of each version needs **Beta App Review** (usually ≤ 24 h) |
| **FitFlow Beta – Public link** | External | Public link capped at 100 testers | After the campus group signs off | Beta App Review |

### 5.2 Test information (required for external testing)
| Field | Value |
|---|---|
| Beta app description | "FitFlow 1.1.0 is the Focus Flow redesign: a daily plan on the home screen, one-tap set logging, on-device meal photos and private circles. Data stays on your device." |
| What to test | "1) Complete onboarding and start today's workout from Home. 2) Log at least three sets and finish. 3) Snap a meal and correct one item. 4) Post to your private circle and check the audience label. 5) Report anything confusing via TestFlight feedback (screenshot + comment)." |
| Feedback email | `support@fitflow.example` *(placeholder)* |
| Sign-in required | No |

### 5.3 Build expiry and cadence

- Every TestFlight build **expires 90 days** after upload; testers can no longer open it.
- Policy: upload a new build at least every 60 days during beta, or immediately after any critical
  fix (Activity 6), and *expire* superseded builds manually so testers are never on an old build.
- Build numbers increase by one for every upload (2, 3, 4…); the version stays 1.1.0 until release.
- Tester feedback (screenshots and crash reports from TestFlight) is triaged into the Activity 6 bug
  log within two working days.

## 6. App Review compliance — health features

| Guideline | Requirement | FitFlow 1.1.0 |
|---|---|---|
| 1.4.1 Physical harm | Health apps must not give potentially harmful, inaccurate guidance; disclose methodology | Planner reasons shown for every plan ("Why this workout?"); conservative volume; disclaimer to consult a professional |
| 1.2 User-generated content | Filter, report, block, and published contact for UGC | Report and delete on every post; private-by-default circles; contact email in listing *(block-user is a known gap, logged for 1.2)* |
| 2.3 Accurate metadata | Screenshots show the real app; no misleading claims | Screenshots captured from the app; "smart planner", not "AI" (Activity 2 §4) |
| 2.5.1 / HealthKit | HealthKit data only for health purposes, never ads or data mining; no health data in iCloud | HealthKit not used in 1.1.0. If added: purpose strings, read-only scopes, no iCloud storage of HealthKit data |
| 5.1.1 Data collection | Privacy policy, consent, account deletion in-app | Policy linked in app and listing; explicit health-data consent at onboarding; *Delete all my data* in Settings |
| 5.1.2 Data use | No sharing of health data with third parties | None shared |
| 5.1.3 Health research | Consent for research use | Not applicable — no research use |
| Camera purpose string | Required for camera access | `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` explain on-device analysis and no upload |

### App Review notes (to paste into "Notes")
> FitFlow requires no login. All features work offline; data stays on the device. To see the main
> flows: complete the 3 onboarding steps (tick the consent box on step 3), then tap *Start workout*.
> Meal recognition is simulated on-device in this version and asks the reviewer to confirm items
> before saving. FitFlow offers general fitness information and is not a medical device.

## 7. Checklist before "Submit for Review"

- [ ] Developer Program membership active; bundle ID registered
- [x] `ITSAppUsesNonExemptEncryption = NO` added (done in `ios/Runner/Info.plist`)
- [ ] Build uploaded and processed; internal group installed it
- [ ] App Privacy answered; privacy policy URL live
- [ ] Screenshots (6.9", 13") and preview uploaded
- [ ] External beta approved and Activity 6 sign-off recorded
