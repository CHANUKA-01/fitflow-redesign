# Requirements traceability — Labs 03–05

Closes the loop opened in Lab 03: every requirement points at the component that implements it.

## Functional requirements

| ID | Requirement (abbreviated) | Implementing components |
|---|---|---|
| R01 | Reach and start a recommended workout from the home screen with no configuration | Flutter home · core API plans router · Redis home-card cache |
| R02 | Onboarding limited to three skippable steps | Flutter onboarding · core API accounts router |
| R03 | Session derived from objective, ability, minutes, energy, equipment, injury | AI inference service · core API plans router |
| R04 | Every AI recommendation carries an on-demand explanation | AI inference service (ranked reasons) · Flutter and Next.js plan card |
| R05 | Adjust duration and difficulty, swap an exercise, regenerate the plan | Flutter planner · core API plans router |
| R06 | Logging a completed set takes a single tap on pre-filled values | Flutter logger · core API sessions router · offline sync queue |
| R07 | Set values pre-populated from the most recent matching session | Core API sessions router · PostgreSQL |
| R08 | Camera capture as the primary nutrition path | Flutter nutrition feature · on-device model · object storage (fallback) |
| R09 | Recognised items reviewed with editable portions and a confidence indicator | On-device model · AI vision fallback · core API nutrition router |
| R10 | Progress led by one headline metric and a plain-language sentence | Core API progress router · PostgreSQL window queries · both clients |
| R11 | Social spaces default to a private circle; every post carries an audience selector | Core API community router (authority) · realtime gateway audience filter |
| R12 | Personal bests and weekly goal completion recognised at session end | Core API progress router · realtime gateway |
| R13 | A missed session is handled with recovery rather than lost progress | Core API progress router · async workers (nightly aggregates) |
| R14 | Quick-log control reachable from the home screen | Flutter home · core API sessions and nutrition routers |
| R15 | Beginner-readable labels; state what an AI feature reads and where it runs | Both clients · AI service model card surfaced in the UI |
| R16 | Architecture leaves room for gym-partner integrations and anonymised trend reporting | Versioned public API · feature store (pseudonymised) |

## Non-functional requirements

| ID | Requirement | Implementing components | Verification |
|---|---|---|---|
| NFR1 | One set logged in ≤2 taps, one-handed | Flutter logger layout and gesture targets | Usability re-test; interaction count |
| NFR2 | Offline logging with automatic sync | Flutter offline store · idempotent sync endpoints · async workers | Airplane-mode and duplicate-replay tests |
| NFR3 | Home screen renders its recommendation within 2 s | Redis home-card cache · trimmed payloads · Flutter start-up budget | p95 measurement on a mid-range Android device |
| NFR4 | WCAG 2.1 AA, dynamic text, 44×44 px targets | Next.js semantic HTML · Flutter accessibility APIs | Screen-reader pass; contrast audit |
| NFR5 | GDPR/CCPA-aligned handling; on-device processing preferred for food photos | On-device model · signed short-lived URLs · retention worker · consent ledger | Privacy assessment; retention job verification |

## Usability issues from Lab 04 addressed by the architecture

| Issue | Severity | How the architecture addresses it |
|---|---|---|
| U01 | Critical | Audience statement returned with the content (Flow B step 1); membership verified server-side (step 2); ADR-004 |
| U04 | Major | Ranked reasons returned by the AI service so the two strongest can appear on the home card |
| U05 | Major | Plan draft marked out of date server-side once inputs change |
| U06 | Major | Period carried in the progress response so the sentence follows the toggle |
| U07 | Major | Community structure derived from audience recorded on the record itself |
| U08 | Medium | Per-item confidence returned with each recognised food item |
