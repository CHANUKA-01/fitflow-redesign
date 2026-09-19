# Activity 3 — Weighted technology decision matrix

## Scoring rubric

| Score | Meaning |
|---|---|
| 5 | Strong fit; satisfied by the stack's normal way of working, few expected obstacles |
| 4 | Strong fit; satisfied with ordinary engineering effort |
| 3 | Workable, with a trade-off that must be actively managed |
| 2 | Workable only with significant extra cost, staffing or parallel work |
| 1 | Poor fit; not met without changing the stack |

Score = Σ(weight × rating) ÷ 100, giving a weighted average on the same 1–5 scale — the method used for the
interface comparison in Lab 03, so the two decisions read together.

## Criteria and weights

| ID | Criterion | Weight | Why for FitFlow |
|---|---|---|---|
| C1 | Security and privacy readiness | 18% | Weight, body and eating data; Lab 04's only Critical issue was a privacy one |
| C2 | Interaction and real-time performance | 15% | Value concentrated in the logger, the rest timer and live challenges |
| C3 | AI and ML fit | 14% | The personalisation gap and camera-first nutrition are what the redesign is for |
| C4 | Development speed | 13% | The rating has already fallen; a late fix is worth much less |
| C5 | Maintainability for a mid-sized team | 12% | A stack needing four specialisms stops being maintained |
| C6 | Scalability | 10% | Necessary, but retention is the problem, not volume |
| C7 | Cross-platform reach | 8% | Required, but satisfiable by more than one arrangement |
| C8 | Lifecycle cost | 6% | Real, but differences between managed offerings are smaller |
| C9 | Accessibility and web quality | 4% | Mostly settled client-side in Activity 1; NFR4 is mandatory regardless |

## Candidate stacks

| ID | Stack | Composition |
|---|---|---|
| S1 | Flutter + Next.js / FastAPI / PostgreSQL | Flutter mobile, Next.js web, FastAPI core and AI services, PostgreSQL, Redis, Supabase Auth, object storage |
| S2 | React Native / NestJS / PostgreSQL | RN + Expo, NestJS core, a Python inference service, PostgreSQL, Redis, Cognito |
| S3 | Flutter / Firebase | Flutter mobile and web, Cloud Functions, Firestore, Firebase Auth, Cloud Storage |
| S4 | Native / Go / DynamoDB | Swift and Kotlin clients, React web, Go services, DynamoDB, Auth0 |

## The matrix

| Criterion | Wt | S1 | S1 wtd | S2 | S2 wtd | S3 | S3 wtd | S4 | S4 wtd |
|---|---|---|---|---|---|---|---|---|---|
| C1 Security and privacy | 18 | 4 | 72 | 4 | 72 | 3 | 54 | 4 | 72 |
| C2 Interaction and real-time | 15 | 5 | 75 | 4 | 60 | 5 | 75 | 5 | 75 |
| C3 AI and ML fit | 14 | 5 | 70 | 3 | 42 | 3 | 42 | 2 | 28 |
| C4 Development speed | 13 | 4 | 52 | 5 | 65 | 5 | 65 | 2 | 26 |
| C5 Maintainability | 12 | 4 | 48 | 4 | 48 | 3 | 36 | 2 | 24 |
| C6 Scalability | 10 | 4 | 40 | 4 | 40 | 4 | 40 | 5 | 50 |
| C7 Cross-platform reach | 8 | 4 | 32 | 5 | 40 | 4 | 32 | 2 | 16 |
| C8 Lifecycle cost | 6 | 4 | 24 | 4 | 24 | 3 | 18 | 2 | 12 |
| C9 Accessibility and web | 4 | 5 | 20 | 4 | 16 | 3 | 12 | 3 | 12 |
| **Total** | **100** | | **433** | | **407** | | **374** | | **315** |
| **Score / 5** | | | **4.33** | | **4.07** | | **3.74** | | **3.15** |
| **Rank** | | | **1st** | | 2nd | | 3rd | | 4th |

### Worked calculation — S1

```
S1 = (18×4 + 15×5 + 14×5 + 13×4 + 12×4 + 10×4 + 8×4 + 6×4 + 4×5) / 100
   = ( 72  +  75  +  70  +  52  +  48  +  40  + 32  + 24  + 20 ) / 100
   = 433 / 100
   = 4.33 out of 5
```

## Sensitivity analysis

| Scenario | S1 | S2 | S3 | S4 | Reading |
|---|---|---|---|---|---|
| Base weights | 4.33 | 4.07 | 3.74 | 3.15 | S1 leads clearly |
| A — cost dominant (C8 6→18, taken from C2 and C3) | 4.21 | 4.13 | 3.62 | 2.97 | S1 leads narrowly; margin falls to 0.08 |
| B — no new hiring or training (S1 loses a point on C4 and C5) | 4.08 | 4.07 | 3.74 | 3.15 | Indistinguishable |

Two conclusions. The ranking of S3 and S4 is stable under every assumption tested, so both can be set
aside with confidence. The choice between S1 and S2 is **not** decided by the matrix — it is decided by
whether FitFlow will invest in Dart and Python skills. Settle it with a two-week spike run by the people who would
actually build the product, not with this table.

## Recommendation

**S1.** It scores highest on the three most heavily weighted criteria, is the only candidate that puts the
API and the models in one ecosystem, the only one that reaches on-device inference through a single
integration, and it stores FitFlow's records in a system that can express a transaction.

**Reconciliation with the incumbent stack.** The case study runs React Native, Node and Firebase, and this
changes all three — a real cost. Three points make it defensible: the abandonment figure is already forcing
a rewrite of most client surfaces, so the marginal cost of changing framework now is far lower than in
steady state; Firestore's per-read pricing works against the live leaderboard the community features need,
and its rule system duplicates an authorisation model the API must own after U01; and the personalisation
gap cannot be closed without a serious model path.

If FitFlow will not invest in new language skills, choose **S2** — it delivers the same relational and
authorisation benefits without a client rewrite. What should not be chosen is S3, which keeps the two
properties of the current platform that are working against the redesign.
