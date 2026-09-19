# Activity 4 — High-level architecture

![FitFlow high-level architecture](diagrams/architecture.png)

*Arrows show planned data and control paths, not deployed connections.*

Two properties were treated as non-negotiable. **Authorisation happens in one place** — the core API —
and every other component delegates to it or sits behind it. **The meal photograph has the shortest life
of anything in the system.**

The layers also express a rule about blast radius: the client holds no secret and no authority; the edge
decides whether a request may exist at all; the application layer decides what the caller may see; the
data layer holds the record and enforces ownership a second time; the cross-cutting layer observes all of
it without recording anything that is itself sensitive.

## Component responsibilities

| Component | Responsibility | Data boundary and scaling |
|---|---|---|
| Flutter mobile app | Focus Flow home, planner, logger, progress, community, nutrition; on-device recognition; local draft and sync queue | No service secret; encrypted local store cleared on sign-out; offline writes carry idempotency keys |
| Next.js web client | Trainer console, progress review, moderation, public pages, server-rendered | Session cookie only; no direct database access; audited against WCAG 2.1 AA |
| Supabase Auth | Sign-in, MFA, JWT issuance and refresh rotation, session expiry, device revocation | Establishes identity only; never decides what a caller may see |
| CDN / API gateway / WAF | TLS termination, JWT verification, rate limits, size caps, static cache, audit logging | The only public entry point |
| FastAPI core API | Validates payloads, enforces authorisation, coordinates domain modules, applies safety rules to AI drafts, writes the audit trail | Stateless workers behind an autoscaler; pooled database access |
| Realtime gateway | WebSocket fan-out with the audience filter applied per subscriber before delivery | Stateless and horizontally scalable; no durable state |
| AI inference service | Plan drafts with ranked reasons and confidence; server-side recognition fallback; model version on every result | Minimum necessary features; results expire; no diagnosis |
| Async workers | Long inference, malware scanning, notification fan-out, nightly aggregates, retention deletions | Idempotent task keys make replay safe; retry with backoff |
| Managed PostgreSQL | Source of truth for users, plans, sessions, sets, meals, circles, challenges, consents, audit | Private subnet, encryption at rest, PITR, RLS behind the API's checks |
| Managed Redis | Home-card and session cache, rate-limit counters, Celery broker, pub/sub | Short TTL; no durable health history cached |
| Model registry / feature store | Versioned models, pseudonymised features, per-version metrics, rollback pointer | Minimised training data; signed artefacts |
| Private object storage | Meal photos, avatars, export archives | Short-lived signed URLs, scan on write, lifecycle deletion |

## Flow A — personalised workout planning (R01, R03, R04, R05)

1. The user opens the app, or adjusts goal, minutes, energy, equipment and limitations in the planner.
2. The client sends its JWT; the gateway verifies signature and expiry and applies the rate limit; the API
   confirms the caller owns the profile.
3. The API reads only the training history the plan needs — not the whole profile.
4. That minimal feature set and a model version go to the AI service, which returns a candidate plan,
   ranked reasons and a confidence value (R04).
5. The API applies deterministic safety rules — progression limits, contraindicated movements against a
   declared injury, session-length bounds — before the user sees anything.
6. The draft is stored and returned; the home card shows the session, its length and its two strongest
   reasons, with Adjust and Regenerate available (R05).
7. Nothing starts until the user accepts. Sets are written transactionally with the session and derived
   progress; offline sets replay through the same idempotent endpoint (NFR2).

A cached home card in Redis is what lets step 7's screen render inside the NFR3 budget when the plan has
not changed. No part of this flow produces medical advice.

## Flow B — private social sharing and challenges (R11, R12; closes U01)

1. On opening a circle or challenge, the API returns the **audience statement with the content**, so the
   interface can state who will see a join *before* the button is pressed.
2. On a join or a post, the API verifies circle membership and invitation state server-side. The audience
   selector is an input to that check, never a substitute for it.
3. The accepted event is published to Redis; the gateway fans it out, filtering per subscriber against the
   audience recorded with the event.
4. Moderator actions travel the same authorisation path and are written to the audit trail.
5. Only necessary engagement data is stored; progress and health history are never published by default.

Step 2 is load-bearing. Lab 04 showed what happens when a privacy rule lives only in the interface.

## Flow C — nutrition tracking with on-device recognition (R08, R09, NFR5)

1. The user taps *Snap a meal*; the on-device model runs locally and in the normal case the image never
   leaves the phone.
2. Items, portions and a per-item confidence value are shown for review, with the least certain row called
   out in plain language rather than a bare percentage (U08).
3. The user corrects labels and quantities. Nothing is saved until they confirm (R09).
4. Only the confirmed nutrition record reaches the API, together with the fact that a correction was made
   — the signal a later model version is trained on.
5. If the device model is unavailable or too uncertain, the client requests a short-lived signed upload
   URL; the image is scanned, passed to the server model, and the same review step follows.
6. A server-side image is deleted on schedule by a worker; export and erasure requests remove it at once.

## Cross-cutting controls

| Concern | Control | Verification before production |
|---|---|---|
| Authorisation | One authority in the API; ownership and membership checked on every read and write; RLS as a second line; immutable audit | Test suite attempting cross-user and cross-circle access; endpoint review against requirements |
| Data protection | TLS, encryption at rest, minimum-necessary features to the AI service, redacted logs, short photo retention, managed secrets | Threat model; privacy assessment; confirm no health detail reaches logs |
| Availability and scale | Stateless API and gateway, managed database with replicas, bounded cache TTL, backpressure and job timeouts | Load test at challenge-launch fan-out; failover exercise; restore drill |
| Performance | Cached home card, indexed progress paths, trimmed payloads | p95 first render on a mid-range Android device against NFR3 |
| AI safety | Deterministic rules after inference, reasons and confidence shown, human correction always available, model version recorded, rollback pointer | Offline evaluation per version; trainer review; bias check across age and ability |
| Accessibility | Semantic HTML on web, platform APIs on mobile, dynamic text, 48 dp targets | Screen-reader pass on both clients; contrast audit; re-test with U09/U10 participants |
| Offline consistency | Local drafts, idempotent sync, explicit conflict rules | Airplane-mode scenarios; deliberate duplicate replay |
| Integration | Versioned HTTPS API generated from the FastAPI contract; schema-validated events | Contract tests in CI; token expiry and refresh scenarios |

## Decision records

See [`adr/`](adr/): ADR-001 the stack, ADR-002 PostgreSQL as source of truth, ADR-003 on-device food
recognition, ADR-004 authorisation in the API.
