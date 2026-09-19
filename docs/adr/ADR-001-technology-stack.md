# ADR-001 — FitFlow redesign technology stack

- **Status:** Proposed (coursework)
- **Date:** 18 September 2026
- **Deciders:** O K T C Jayawardhana (IT23230774)

## Context

FitFlow's rating fell from 4.6 to 3.8 and 68% of users abandoned the app shortly after onboarding. Labs
02–04 produced sixteen user requirements, five non-functional requirements and a usability issue log whose
only Critical entry (U01) was a privacy failure. The redesign depends on AI personalisation, camera-first
nutrition logging and private social features, and must run on iOS, Android and the web with a mid-sized
team.

## Decision

Adopt stack **S1**:

- **Flutter** for iOS and Android; **Next.js / React** for web
- **FastAPI** for the core API and for a separate **AI inference service**
- **Celery workers** on **Redis** for long-running jobs
- **Managed PostgreSQL** with Row-Level Security as the source of truth
- **Managed Redis** for cache, rate limiting and pub/sub
- **Supabase Auth** for identity, with authorisation enforced in the API
- **Private object storage** with short-lived signed URLs for meal photographs

## Alternatives considered

| | Score | Why not |
|---|---|---|
| S2 React Native / NestJS / PostgreSQL | 4.07 | Strongest alternative; loses on AI fit and needs a second backend language anyway. **Choose this instead if no Dart/Python investment is made** |
| S3 Flutter / Firebase | 3.74 | Keeps the two properties of the current platform working against the redesign: per-read billing and a duplicated authorisation system |
| S4 Native / Go / DynamoDB | 3.15 | Three client codebases; weakest AI fit; slowest to ship |

## Reasons

S1 scores highest on the three most heavily weighted criteria — C1 security and privacy, C2 interaction
and real-time, C3 AI fit. It reaches on-device inference through a single integration, keeps API and
models in one language, and stores FitFlow's records in a system that supports the transactional
consistency R10, R12 and R13 depend on.

## Consequences

- The team must learn Dart and Python.
- Two client codebases are maintained instead of one.
- An AI service, a realtime gateway and a worker pool must be deployed and observed — more operational
  surface than an all-Firebase approach.
- In exchange, authorisation lives in one place and per-read billing is removed from live social features.

## Risks and controls

| Risk | Control |
|---|---|
| Language ramp-up | Two-week Dart and FastAPI spike before committing |
| On-device inference accuracy | The server fallback in Flow C is designed in from the start |
| Compliance | Confirm GDPR and CCPA obligations with qualified advice; sign BAAs only if PHI is genuinely in scope |
| Cost | Build the usage-based model before choosing a vendor |

## Revisit trigger

The spike overruns; the accessibility audit fails on either client; measured p95 first render exceeds the
NFR3 budget; inference cost per generated plan proves unsustainable; or the compliance position changes.
