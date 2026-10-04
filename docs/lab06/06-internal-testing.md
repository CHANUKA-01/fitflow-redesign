# Activity 6 — Internal testing deployment

Lab Exercise 06 · IT3060 · FitFlow 1.1.0 (build 2)

**Status:** internal testing carried out on the signed release build and on seven emulator/simulator
configurations; store-track distribution (Play Internal Testing, TestFlight) prepared but not run
because no store accounts were available. Results below are only what was actually observed; items
not yet done are marked **Pending**.

## 1. Deployment

| Channel | Status | Detail |
|---|---|---|
| Google Play Internal Testing | Prepared — needs Play account | Steps in Activity 3 §4.3; AAB `app-release.aab` (versionCode 2) ready |
| Apple TestFlight (internal group) | Prepared — needs Apple Developer account | Steps in Activity 4 §5 |
| Direct install of signed build | **Done** | Release AAB → device APKs with `bundletool install-apks`, installed on Pixel 9a emulator (Android 16) |
| Firebase App Distribution (free alternative) | Planned | Universal signed APK `app-release.apk` can be distributed to testers by email without a store account |

## 2. Test plan

| Area | What is tested | Method |
|---|---|---|
| New features | Onboarding, home plan, planner adjust/swap/regenerate, logger, meal photo review, nutrition, circles, progress, privacy controls | Manual walkthrough + automated integration test |
| Planner logic | Injuries respected, only available equipment used, reasons always present, low energy reduces volume | Unit tests (`test/widget_test.dart`) |
| Cross-device | Phone, 7" and 10" tablets in both orientations, iPhone 6.9", iPad 13" | Integration test on 7 configurations |
| Release build integrity | Signature, version, permissions, size | `scripts/release_android.sh` evidence log |
| Performance | Cold start (NFR3), frame smoothness in logger | `am start -W`; physical device pending |
| Battery | Drain during a 30-min session | Pending — needs physical device (`adb shell dumpsys batterystats`) |
| Privacy | No network permission, photo deleted after review, export and delete work | Manifest dump; manual check |

## 3. Results

### 3.1 Automated tests

| Suite | Result |
|---|---|
| Static analysis (`flutter analyze`) | **No issues** |
| Unit + widget tests (`flutter test`) | **5 / 5 passed** — planner respects injuries, uses only available equipment, explains itself, low energy reduces volume; onboarding has 3 skippable steps with a mandatory consent step |
| Integration test (`integration_test/screenshots_test.dart`, 9 screens) | **Passed on all 7 configurations** (Android phone; 7" and 10" tablet portrait + landscape; iPhone 18 Pro Max; iPad Pro 13") |

### 3.2 Manual walkthrough (Pixel 9a emulator)

| # | Test | Expected | Result |
|---|---|---|---|
| T01 | First launch | Welcome screen | Pass |
| T02 | Onboarding consent | "Build my first plan" disabled until consent ticked | Pass |
| T03 | Injury respected | Knee injury → no squats/lunges in plan | Pass |
| T04 | Start workout from Home | One tap opens logger | Pass |
| T05 | Log a set | One tap, rest timer starts, undo available | Pass |
| T06 | Finish workout | Summary with weekly goal | Pass |
| T07 | Snap a meal (emulator camera) | Analysing → review with confidence per item → save | Pass |
| T08 | Post to circle | Audience label shown in full | Pass after fix of B01 |
| T09 | Release build install from AAB | Installs, version 1.1.0 (2), no permission prompts | Pass |

### 3.3 Performance

| Measure | Result | Verdict |
|---|---|---|
| Cold start, release build, emulator (6 runs) | 3.8–7.5 s | Not valid for NFR3: Android Settings app took 2.5–5.5 s on the same emulator (control) |
| Cold start on mid-range physical phone | — | **Pending** |
| Play download size (arm64) | ≈ 8.0 MB | Good |

### 3.4 Crash analytics

No crashes occurred in any automated or manual run (logcat checked for `FATAL EXCEPTION`). Firebase
Crashlytics is **not yet integrated**: it needs a Firebase project and adds the `INTERNET` permission,
which changes the privacy policy and store data-safety answers — so it is planned together with the
backend release rather than added silently.

## 4. Bug log

All found during this lab's testing and fixed.

| ID | Severity | Found in | Description | Fix | Status |
|---|---|---|---|---|---|
| B01 | **Major** (privacy) | Circles, phone | Audience label truncated to "Visible to 5 mem…" — reintroduced the Lab 04 critical issue U01 | Label given its own flexible space, no ellipsis | Fixed, verified in screenshots |
| B02 | Minor | Circles | Selected circle chip showed checkmark over lock icon | `showCheckmark: false` | Fixed |
| B03 | Major (usability) | All screens, tablets | Content stretched across 2560 px screens | Content capped at centred 720 dp column | Fixed, verified on 7"/10" |
| B04 | Major | Release links | Privacy policy and support links would silently fail on Android 11+ (package visibility) | `<queries>` for https and mailto added to manifest | Fixed |
| B05 | Critical (build) | Android build | iCloud Drive created duplicate "… 2" files → build failed | Build output moved out of synced Desktop | Fixed |
| B06 | Critical (build) | iOS build | `codesign` rejected Flutter framework tagged by iCloud | Same as B05 | Fixed, iOS builds and runs |
| B07 | Major (security) | Signing | `key.properties` (signing passwords) inside iCloud-synced folder | Moved to `~/.fitflow-signing/`, symlinked | Fixed |
| B08 | Minor | Test tooling | Screenshot taken before last frame presented (wrong screen, missing photo) | Settle delay, image pre-cache | Fixed |
| B09 | Minor | Test tooling | Emulator slept during long run, app backgrounded | Stay-awake in capture script | Fixed |

Open (not bugs, tracked for next build): block-user in circles (App Review 1.2); contrast audit
(WCAG 2.1 AA); physical-device start-up and battery measurement.

## 5. Tester feedback

**Pending.** No external testers have used the build yet. Feedback will be collected from 3–5
classmates using the form below, after they install the signed APK.

| Tester | Device / OS | Task completed (1–5 in TestFlight "What to test") | Rating 1–5 | Comment |
|---|---|---|---|---|
| | | | | |
| | | | | |
| | | | | |

## 6. Approval record

Criteria to advance to external beta: no open Critical/Major bugs ✔; automated tests pass ✔;
release build verified ✔; physical-device start-up ≤ 2 s ☐; tester feedback reviewed ☐.

| Role | Name | Decision (Approve / Reject) | Signature | Date |
|---|---|---|---|---|
| Developer | Jayawardhana O K T C (IT23230774) | | | |
| Reviewer / team lead | | | | |
| Lecturer / supervisor | | | | |
