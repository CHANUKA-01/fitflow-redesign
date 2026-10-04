# FitFlow release notes

## 1.1.0 (build 2) — Focus Flow redesign · 4 October 2026

### Google Play "What's new" (≤ 500 characters)

```
FitFlow has been redesigned around one clear workout a day.
• Today's plan waits on your home screen. Start it in one tap.
• See why every exercise is there, then shorten it, swap moves or regenerate.
• Log a set with a single tap: last time's weights are already filled in.
• Snap your meal: food is recognised on your phone and you check it before saving.
• Private circles: every post shows exactly who can see it.
Your data stays on your device.
```

### App Store "What's New" (≤ 4000 characters)

```
Welcome to the new FitFlow, rebuilt around one clear workout a day.

TODAY'S FOCUS
Your workout is waiting on the home screen, adjusted to your time, equipment and how much energy you have today. Start it with one tap.

A PLAN THAT EXPLAINS ITSELF
Tap "Why this workout?" to see what the planner used. Change the length or difficulty, swap an exercise, or get a fresh plan.

ONE-TAP LOGGING
Weights and reps from your last session are filled in for you, and the rest timer starts on its own. New personal bests are celebrated when you finish.

SNAP YOUR MEAL
Photograph your plate and FitFlow recognises the food on your phone, shows how sure it is, and lets you fix portions before saving. Photos are deleted straight away.

PRIVATE CIRCLES
Share with a small group of training partners. New posts are private by default and always say who can see them.

PROGRESS IN PLAIN WORDS
One headline number and a simple sentence about your week. Missed a few days? Your streak can recover.

YOUR DATA, YOUR CALL
Everything stays on your device. Export or delete it all from Settings.
```

### Full change list (for the team and the lab report)

| Area | Change | Requirement |
|---|---|---|
| Onboarding | Three short, skippable steps; explicit health-data consent; medical disclaimer | R02, GDPR Art. 9 |
| Home | Focus Flow card with today's plan, its two strongest reasons, energy check-in, quick log, weekly stats | R01, R14, U04 |
| Planner | On-device planner using goal, level, time, energy, equipment, injuries and last session; reasons on demand; adjust duration/difficulty; swap; regenerate | R03–R05, R15 |
| Logger | Pre-filled sets, one-tap logging, automatic rest timer, undo, personal bests and weekly goal on finish | R06, R07, R12, NFR1 |
| Nutrition | Camera-first logging, on-device recognition with confidence per item, editable portions, manual food search incl. Sri Lankan dishes; photo deleted after review | R08, R09, U08, ADR-003 |
| Circles | Private by default; audience label on every post and in the composer; report and delete | R11, U01 |
| Progress | Headline metric and plain-language sentence that follow the week/month toggle; streak recovery | R10, R13, U06 |
| Privacy | Data export, delete all data, withdraw consent, privacy policy link; no network permission | NFR5 |
| Accessibility | 48 dp minimum touch targets, dynamic text, screen-reader labels, readable width on tablets | NFR4 |
| Platform | New icon and splash; Android 7.0+ / iOS 15+; R8 shrinking; signed with the FitFlow upload key | Activity 1 |

### Known issues

- Food recognition uses a demonstration model: results depend on the photo and must be checked.
- Circles are stored on the device only; posts are not yet delivered to other members.
- Start-up time target (2 s) still to be measured on a physical device.

### Legal

FitFlow provides general fitness and nutrition information and is not a medical device. See the
[privacy policy](05-privacy-policy.md). Support: support@fitflow.example *(placeholder)*.

## Update history

| Version | Build | Date | Summary |
|---|---|---|---|
| 1.1.0 | 2 | 2026-10-04 | Focus Flow redesign (this release) |
| 1.0.0 | 1 | — | Template baseline, never distributed |
