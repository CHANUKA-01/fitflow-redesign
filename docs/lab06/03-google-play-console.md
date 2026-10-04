# Activity 3 — Google Play Console configuration

Lab Exercise 06 · IT3060 · FitFlow 1.1.0 (versionCode 2) · package `io.fitflow.app`

**Status: configuration fully prepared; not submitted.** No Google Play developer account (US$25,
identity verification) was available for this coursework. Every value below is ready to paste into
Play Console, and every file it references exists in the repository. The steps are written in the
order Play Console asks for them.

## 1. Create the app

| Field | Value |
|---|---|
| App name | FitFlow: Workouts & Nutrition |
| Default language | English (United Kingdom) – en-GB |
| App or game | App |
| Free or paid | **Free** (no in-app purchases in 1.1.0) |
| Declarations | Developer Program Policies ✔, US export laws ✔ |

## 2. Store listing (Grow → Store presence → Main store listing)

| Field | Value / file |
|---|---|
| App name (30) | `store-assets/listing/google-play/title.txt` — "FitFlow: Workouts & Nutrition" (29) |
| Short description (80) | `short-description.txt` — "Workouts planned for your time and energy, meal photos analysed on your phone." (78) |
| Full description (4000) | `full-description.txt` (≈2 360 chars) |
| App icon | `store-assets/android/icon/ff_android_icon_512.png` |
| Feature graphic | `store-assets/android/feature-graphic/ff_android_feature-graphic_1024x500.png` |
| Phone screenshots | `store-assets/android/screenshots/phone/` — 8, upload in 01→08 order |
| 7-inch tablet screenshots | `tablet-7in/` — 8 portrait + 8 landscape (Play allows 8 per type; upload landscape first) |
| 10-inch tablet screenshots | `tablet-10in/` — same |
| Video | YouTube (unlisted) upload of `store-assets/promo/video/ff_promo_android-phone_1080x1920.mp4` |
| App category | **Health & Fitness** |
| Tags | Workout, Fitness tracking, Nutrition |
| Contact email | `support@fitflow.example` *(placeholder — replace with the team's real support address)* |
| Privacy policy URL | `https://chanuka-01.github.io/fitflow-redesign/privacy-policy/` (Activity 5) |

## 3. App content (Policy → App content)

### 3.1 Privacy policy
URL above. Must be public, non-PDF, and name FitFlow — see Activity 5.

### 3.2 App access
"All functionality is available without special access." (No login in 1.1.0.)

### 3.3 Ads
"No, my app does not contain ads."

### 3.4 Content rating (IARC questionnaire)

| Question | Answer |
|---|---|
| App category in questionnaire | All other app types |
| Violence, fear, sexuality, gambling, drugs, crude humour | No |
| Users can interact or exchange content | **Yes** — circles (user posts) |
| Shares user's current physical location | No |
| Allows purchases of digital goods | No |
| Unrestricted internet access / web browser | No |

Expected result: **PEGI 3 / ESRB Everyone / IARC 3+**, with the interactive element
"Users interact". Moderation basis for the "Yes": every post shows its audience; users can report
and delete posts (implemented in the Circles screen).

### 3.5 Target audience and content
| Field | Value |
|---|---|
| Target age groups | **18 and over** (and 16–17 selectable) — not designed for children |
| Appeals to children | No |
| Reason | Health data and training guidance are intended for adults; excluding under-13s keeps FitFlow outside the Families policy and COPPA |

### 3.6 Data safety form

FitFlow 1.1.0 stores everything on the device and has no network access (the manifest requests no
`INTERNET` permission — Activity 1 §5.3). Under Play's definitions, data processed only on the
device is **not "collected"**.

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **No** |
| Is all user data encrypted in transit? | Not applicable — no data leaves the device |
| Do you provide a way for users to request deletion? | Yes — Settings → *Delete all my data* (in-app) |

Planned answers once the cloud backend (Lab 05 architecture) ships — prepared now so the form is
updated with the release that adds it:

| Data type | Collected | Shared | Purpose | Optional |
|---|---|---|---|---|
| Health info / Fitness info (workouts, body metrics) | Yes | No | App functionality, personalisation | No |
| Name, email | Yes | No | Account management | No |
| Photos (meal photos) | No — analysed on device (ADR-003) | No | — | — |
| User-generated content (posts) | Yes | Shared with chosen circle only | App functionality | Yes |
| App interactions, crash logs | Yes (Firebase Crashlytics, Activity 6) | No | Analytics, diagnostics | Yes |

### 3.7 Health apps declaration
| Field | Value |
|---|---|
| Health features | Activity & fitness tracking; Nutrition & weight management |
| Medical device / regulated features | **None** — FitFlow does not diagnose, treat or monitor a medical condition |
| Health Connect | Not used in 1.1.0 |
| Disclaimer | Shown in onboarding, Settings and the store description |

### 3.8 Other declarations
Government app: No · Financial features: None · News app: No · COVID-19 app: No ·
Uses Advertising ID: **No** (no ads, no ad SDKs).

## 4. Release setup

### 4.1 Play App Signing
Choose **"Use Google-generated key"** (recommended). The first upload of the AAB, signed with the
FitFlow upload key, registers it:

```
Upload certificate SHA-256
93:B8:CF:64:31:72:92:77:8C:DA:A9:3D:ED:CB:96:90:67:EB:08:FA:3C:78:4D:4E:93:5D:29:8B:38:BA:57:51
```

Google keeps the app signing key; the team keeps only the upload key (Activity 1 §3.1). If the upload
key is ever lost, App integrity → *Request upload key reset*.

### 4.2 Testing tracks

| Track | Purpose | Testers | Review |
|---|---|---|---|
| **Internal testing** (first) | Team smoke test of each build | Up to 100, email list "FitFlow team" | None — available within minutes |
| Closed testing | External beta (Activity 6 exit) | Google Group `fitflow-beta` | Yes |
| Production | Public release | — | Yes |

Note: new **personal** developer accounts must run a closed test with at least 12 testers for 14
days before production access is granted; an **organisation** account (e.g. the university) is
exempt. This is planned into the release timeline.

### 4.3 Create the internal release
1. Testing → Internal testing → Create new release.
2. Upload `frontend/mobile/build/app/outputs/bundle/release/app-release.aab`
   (versionCode 2, versionName 1.1.0).
3. Upload `mapping.txt` (R8) and the native debug symbols are already inside the bundle.
4. Release name: `1.1.0 (2) Focus Flow redesign`.
5. Release notes (en-GB): from `docs/lab06/05-release-notes.md`, "Play" section (≤500 chars).
6. Save → Review release → Start rollout to Internal testing.

### 4.4 Countries, pricing and devices

| Setting | Value | Reason |
|---|---|---|
| Price | Free | — |
| Countries | **Sri Lanka** first (internal/closed); then Sri Lanka, India, United Kingdom, Australia, Singapore for production | Matches FitFlow's food database (Sri Lankan dishes) and English-language UI |
| Excluded | Countries outside the list until localisation | Avoids poor reviews from unsupported locales |
| Device catalogue exclusions | **None required**: minSdk 24 already excludes Android < 7.0; no hardware features are required (camera is optional — photos come through the system camera/picker) | Keeps reach maximal |
| Form factors | Phone, tablet (7"/10" screenshots supplied), Chromebook (x86_64 ABI included) | — |

## 5. Pre-launch report

Play runs the AAB automatically on real devices in Firebase Test Lab after each testing-track
upload. What we expect and how it was pre-empted locally:

| Pre-launch check | Expected | Local evidence |
|---|---|---|
| Stability (crashes, ANRs) | None | Release build installed from the AAB and exercised on emulator (Activity 1 §5.3); 9-screen integration test passed on 7 device configurations (Activity 2) |
| Accessibility | Possible "touch target size" / "contrast" suggestions | 48 dp minimum targets in theme; full contrast audit is an open item |
| Security | No warnings expected: no cleartext traffic, no exported components besides the launcher activity | aapt2 manifest dump (Activity 1 evidence) |
| Performance | Start-up time measured on real devices | NFR3 deferred to physical device (Activity 1 §5.4) |
| Screenshots of each screen | Provided by the robo crawler | — |

Process: open *Release → Testing → Pre-launch report*, fix any **error**-level issue before
promoting the build, log warnings in the bug log (Activity 6).

## 6. Store listing experiments (A/B tests)

Run under *Grow → Store listing experiments* once the app has enough store visitors (production).
Prepared experiments, one at a time, 50/50 split, en-GB, run for at least 7 days:

| # | Hypothesis | Control | Variant | Primary metric |
|---|---|---|---|---|
| E1 | Leading with the explained plan converts better than leading with the home card, because "explains itself" is the differentiator | Screenshot order 01-02-03 | Order 02-01-03 | Retained first-time installers (1 day) |
| E2 | A privacy-first short description attracts users who stay | Current short description | "Private fitness planner: workouts that explain themselves, data stays on your phone." | Retained installers |
| E3 | Showing food recognition in the feature graphic lifts installs from nutrition searches | Current feature graphic | Meal-review phone in the centre | First-time installers |

Decision rule: apply the variant only if Play reports it better at the 90 % confidence level; E1
runs first because screenshots carry the most weight in conversion.

## 7. Checklist before pressing "Send for review"

- [ ] Developer account verified
- [ ] Store listing complete, all images uploaded in order
- [ ] All App content sections green (privacy policy, ads, rating, audience, data safety, health declaration)
- [ ] Internal testing release rolled out and installed by the team
- [ ] Pre-launch report: no errors
- [ ] Activity 6 approval record signed
