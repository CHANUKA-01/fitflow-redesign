# Activity 1 — Frontend framework comparison

Flutter, React Native, Kotlin Multiplatform and Swift/SwiftUI, evaluated for the FitFlow redesign.

Ratings use a 1–5 scale meaning **fit for FitFlow**, not absolute quality, and reflect documented
capability plus the skills of the existing team. They are not benchmark results.

## 1. Client-side demands (the basis for every rating)

| ID | Demand | Source |
|---|---|---|
| D1 | A completed set is logged with one tap on pre-filled values, one-handed, without a dropped frame | R06, R07, NFR1 |
| D2 | Workout logging works offline in a gym and syncs when signal returns | NFR2 |
| D3 | The home card renders its recommendation within two seconds of launch | NFR3 |
| D4 | WCAG 2.1 AA contrast, dynamic text and 44×44 px targets, on mobile and web | NFR4, U09, U10 |
| D5 | Food recognition runs on the device wherever feasible; the server is the fallback | NFR5, R08, R09 |
| D6 | Camera capture is the primary nutrition path, with a confirmation step before saving | R08, R09, U08 |
| D7 | Circle posts, challenge progress and streak events arrive live and respect the audience | R11, R12, U01 |
| D8 | Trainers and lapsed users reach progress, community and plan review through a browser | Case study |

## 2. Strengths and weaknesses

### Flutter (Dart)
**Strengths** — ahead-of-time compilation with its own renderer gives consistent list and animation
behaviour on both platforms (D1, D3). Drift and sqflite provide a mature offline store (D2). One
TensorFlow Lite integration serves both platforms (D5). First-party camera and permission plug-ins (D6).

**Weaknesses** — Dart is a second language for a TypeScript team. The web target renders into a canvas
rather than semantic HTML, which makes D4 and D8 harder, and the WebAssembly path still carries browser
caveats: Flutter's own documentation records blocking issues in Firefox and Safari and notes that Chrome
on iOS cannot run Wasm.

### React Native (TypeScript)
**Strengths** — the team's existing language; the New Architecture has been the default since 0.76 and
removes the old asynchronous bridge; a very large ecosystem; React skills transfer to a semantic web
client (D8).

**Weaknesses** — rendering depends on host components, so cross-device consistency needs more
verification. On-device inference and some camera behaviour reach native modules on each platform — two
integrations rather than one (D5). Offline storage depends on a chosen community library (D2).

### Kotlin Multiplatform with Compose Multiplatform
**Strengths** — business logic shared in Kotlin with genuinely native interop; Android, iOS and desktop
are documented as Stable for both KMP and Compose Multiplatform.

**Weaknesses** — the web target is Beta for both, so D8 still needs a separate web application. It
presumes Kotlin and iOS toolchain skills the team does not have, and asks FitFlow to rebuild at exactly
the moment the business needs the retention fix shipped.

### Swift with SwiftUI
**Strengths** — the best option for iOS alone: deepest platform integration, Core ML, HealthKit, watch
support, the most predictable performance of any candidate.

**Weaknesses** — no Android and no web build, so D8 means three codebases and three release trains. For
a mid-sized team this triples the cost of every requirement in the list.

## 3. Ten-criterion comparison

| Criterion | Flutter | React Native | Kotlin MP | Swift / SwiftUI |
|---|---|---|---|---|
| Development speed | 3 | 5 | 2 | 2 |
| Code reusability | 5 | 4 | 4 | 1 |
| Performance | 5 | 4 | 4 | 5 |
| Ecosystem support | 4 | 5 | 3 | 4 |
| Learning curve | 3 | 5 | 2 | 2 |
| Web compatibility | 3 | 4 | 2 | 1 |
| AI / ML integration | 5 | 3 | 4 | 4 |
| Real-time features | 4 | 4 | 4 | 4 |
| Maintenance cost | 4 | 4 | 3 | 1 |
| Security | 3 | 3 | 4 | 4 |

## 4. Recommendation — a hybrid

**Flutter for iOS and Android; Next.js / React for the web**, sharing the API contract and the design
tokens rather than sharing UI code. Swift and Kotlin stay in the plan only as platform extensions (a watch
companion, a Health integration) written against the same API.

| Decision | Justification | Requirement |
|---|---|---|
| Flutter for mobile | Predictable frame behaviour where the measured pain lives; mature offline store | D1, D2, D3 → R06, R07, NFR1–NFR3 |
| One TFLite integration | Reaches on-device inference once rather than twice | D5 → R08, R09, NFR5 |
| Next.js for web | Server-rendered semantic HTML makes WCAG 2.1 AA achievable | D4, D8 → NFR4, R10, R11 |
| Two clients, one contract | Captures the consistency benefit without paying the accessibility cost | Case study |
| Native as extension only | Keeps a three-codebase cost out of the critical path | R16 |

The qualification: this asks the team to learn Dart, and React Native is rated highest on development
speed precisely because it does not. `03-decision-matrix.md` tests that trade-off numerically and finds it
the closest call in the whole evaluation.

## 5. What would change this decision

| Trigger | Revised choice |
|---|---|
| A two-week spike shows Dart onboarding exceeding the schedule | React Native + Expo for mobile, keeping Next.js for web |
| Flutter's Wasm target reaches full Safari and Firefox support and passes an accessibility audit | Reconsider a single Flutter codebase for all three surfaces |
| On-device inference cannot reach the accuracy R09 assumes | Keep capture on device, move recognition to the server path |
| Product direction shifts decisively to Apple-platform integrations | Add a SwiftUI companion against the same API |

## Sources

- Flutter — Web support: https://docs.flutter.dev/platform-integration/web
- Flutter — WebAssembly support: https://docs.flutter.dev/platform-integration/web/wasm
- React Native — The New Architecture: https://reactnative.dev/architecture/landing-page
- Kotlin Multiplatform — supported platforms and stability: https://kotlinlang.org/docs/multiplatform/supported-platforms.html
- Apple — SwiftUI: https://developer.apple.com/documentation/swiftui
- W3C — WCAG 2.1: https://www.w3.org/TR/WCAG21/
