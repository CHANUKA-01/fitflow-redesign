# Activity 2 — Backend, database and authentication comparison

## 1. Server-side demands

| ID | Demand | Source |
|---|---|---|
| B1 | Generate a personalised plan from goal, ability, minutes, energy, equipment and injury, and return the reasons with it | R03, R04 |
| B2 | Serve the home recommendation fast enough for a two-second first render | NFR3, R01 |
| B3 | Accept an offline batch of sets without duplicating or losing any | NFR2, R06 |
| B4 | Enforce an audience on every social read and write, not only in the interface | R11, U01 |
| B5 | Deliver circle, challenge and streak events live to the correct members | R11, R12 |
| B6 | Store a confidence value and a correction history for every recognised food item | R09, U08 |
| B7 | Keep transactional consistency across a session, its sets, its plan and the derived progress | R10, R12, R13 |
| B8 | Support GDPR and CCPA export and erasure, consent records and audit, operable by a mid-sized team | NFR5 |

## 2. Backend frameworks

| Framework | Strengths | Trade-offs | Fit |
|---|---|---|---|
| **FastAPI (Python)** | Typed validation, async by default, OpenAPI generated from code, same ecosystem as the models | CPU-bound work must leave the request path; structure must be imposed deliberately | **Strong** — B1 and B6 are the differentiating features and both are model-driven |
| **NestJS (Node/TS)** | Modules, DI, guards, WebSocket gateways; same language as the web client; clean upgrade from Express | ML still crosses into a second language and deployment | Strong for B4, B5, B7; weaker for B1, B6 — which means two backends anyway |
| **Go (Fiber/Echo)** | Compiled, low footprint, excellent concurrency | A third language; thinner ML story; more code for CRUD | Weak here — FitFlow's problem is retention, not throughput |
| **Express (Node)** | Minimal, familiar, the incumbent | Structure and authorisation are conventions, not guarantees | Adequate, not advisable — U01 is what unenforced rules look like |

## 3. Databases

| Database | Scalability | Query fit | Sensitive health data | Cost profile |
|---|---|---|---|---|
| **Managed PostgreSQL** | Vertical + read replicas; partitioning for set and meal tables | Strongest — progress questions are joins and window functions; JSONB holds plan payloads | RLS for per-row ownership behind the API's checks; encryption, PITR, private networking standard | Predictable monthly; needs migrations and pooling owned |
| MongoDB Atlas | Sharding is the most natural of the four | Good for plan documents; cross-session analytics needs aggregation pipelines | BAA pathway where applicable; customer obligations remain | Plan-based; flexible schema permits inconsistency |
| Cloud Firestore | Scales with no operational work; the incumbent | Excellent listeners (B5); weak cross-document reporting, which R10 needs | Rules are a second authorisation system to keep in step | Per read/write/listener — a live leaderboard is the worst case |
| Amazon DynamoDB | The highest ceiling | Needs access patterns known in advance; ad-hoc progress queries need a second store | Fine-grained IAM and encryption; eligibility must be confirmed | Cheap at steady state, punishing when remodelling |

**The decisive point is B7.** A FitFlow session is a plan, a set of logged sets, a progress recalculation,
possibly a personal best and possibly a challenge update. A partial write leaves the user looking at a
progress figure that contradicts their own workout. That is a transaction.

## 4. Identity

| Option | Strengths | Limitations for FitFlow |
|---|---|---|
| **Supabase Auth** | Email/OAuth/MFA, standard JWTs, aligns with PostgreSQL and RLS; generous free tier | Smaller vendor. Where regulated health data is genuinely in scope, Supabase requires a signed BAA, a configured HIPAA project and the hosted platform — self-hosted is excluded |
| Firebase Auth | The incumbent; excellent client SDKs | Identity in one vendor and records in another once the data store moves — a seam where one is least welcome |
| Amazon Cognito | Managed pools, OIDC, MFA, documented compliance posture in AWS | Least pleasant developer experience; worth it only if the whole platform is AWS |
| Auth0 | The most capable for enterprise identity and policy | Priced for capability FitFlow does not yet need |

**Boundary.** None of these answers B4. Identity establishes *who is calling*; U01 was about *who is
allowed to see* a challenge someone joined. That is authorisation, it depends on circle membership and the
selected audience, and it belongs in the API. RLS sits behind it as a second line, not a replacement.

## 5. Assessment across the six dimensions

| Dimension | Position | Still to do |
|---|---|---|
| Security | TLS, managed encryption at rest, JWT verified at the edge, rate limits, least privilege, immutable audit, no health detail in logs | Threat-model the social features; authorisation test suite; quarterly access review; CI dependency scanning |
| Compliance | NFR5 names GDPR and CCPA — lawful basis, export, erasure, consent. HIPAA does **not** automatically apply to a consumer fitness product; where it does, every service in the path needs a BAA, and vendor eligibility ≠ compliance | Confirm jurisdiction and role with qualified advice; consent ledger; retention schedule |
| Real-time | Dedicated WebSocket gateway on Redis pub/sub, audience filtered per subscriber | Load-test fan-out at challenge scale; define reconnection and replay |
| AI integration | Models and API share a language; every result carries model version, ranked reasons and confidence | Offline evaluation per version; safety review with a qualified trainer; rollback pointer |
| Cost | One database, one cache, one object store, two small services — predictable rather than per-read. No monthly figure asserted | Build the usage-based model before committing; budget alerts; cost per plan generated |
| Maintainability | Two languages across the platform and one database technology; the generated contract keeps both clients honest | Hiring or training for Dart and Python; enforce structure FastAPI does not impose; contract tests in CI |

## 6. Recommended combination

| Layer | Recommendation | Primary justification |
|---|---|---|
| Core API | FastAPI, modular routers per domain | API and models in one ecosystem; typed validation and a generated contract (B1, B6) |
| Real-time | WebSocket gateway, Redis pub/sub, per-subscriber audience filter | Live delivery out of the request path; R11 enforced server-side (B4, B5) |
| AI service | Separate FastAPI service; long jobs on Celery | CPU-bound inference out of the event loop; independent scaling and rollback |
| Database | Managed PostgreSQL, RLS, JSONB | Transactional integrity and relational analytics (B3, B7) |
| Cache and queue | Managed Redis | Home-card cache, broker, rate-limit counters (B2) |
| Identity | Supabase Auth, authorisation in the API | Standard JWTs aligned with RLS; the API remains the authority (B4, B8) |
| Media | Private storage, signed short-lived URLs, scan on write, lifecycle deletion | The most sensitive artefact should live the shortest time (NFR5) |
| Hosting | One managed cloud, private networking, IaC | A mid-sized team should operate one platform (B8) |

## Sources

- FastAPI — concurrency: https://fastapi.tiangolo.com/async/
- NestJS — WebSocket gateways: https://docs.nestjs.com/websockets/gateways
- PostgreSQL — Row Security Policies: https://www.postgresql.org/docs/current/ddl-rowsecurity.html
- PostgreSQL — JSON types: https://www.postgresql.org/docs/current/datatype-json.html
- Firebase — Cloud Firestore: https://firebase.google.com/docs/firestore
- MongoDB Atlas — HIPAA: https://www.mongodb.com/docs/atlas/architecture/current/compliance/hipaa/
- AWS — HIPAA eligible services: https://aws.amazon.com/compliance/hipaa-compliance/
- AWS — Amazon Cognito: https://docs.aws.amazon.com/cognito/latest/developerguide/what-is-amazon-cognito.html
- Supabase — HIPAA compliance: https://supabase.com/docs/guides/security/hipaa-compliance
- Google Cloud — HIPAA compliance: https://cloud.google.com/security/compliance/hipaa-compliance
