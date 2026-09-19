# ADR-002 — PostgreSQL replaces Firestore as the source of truth

- **Status:** Proposed · **Date:** 18 September 2026

## Context

The case study runs Cloud Firestore. FitFlow's records are strongly relational — a session belongs to a
plan, contains sets, produces progress and may update a challenge — and the progress screens required by
R10 are cross-document reporting, which is Firestore's weakest area. Firestore bills per read, write and
listener, and a live challenge leaderboard is exactly that pattern.

## Decision

Managed PostgreSQL becomes the source of truth, with Row-Level Security as defence in depth and JSONB for
plan payloads and AI reasons. A **dedicated WebSocket gateway backed by Redis pub/sub** takes over live
delivery, which Firestore previously provided for free.

## Reasons

- A session, its sets and the progress derived from them are one transaction (B7); a partial write leaves
  the user looking at a progress figure that contradicts their own workout.
- Per-read billing penalises the live social features the redesign depends on.
- Firestore security rules are a second authorisation system running beside the API's — see ADR-004.

## Consequences

Real-time delivery becomes a component the team operates rather than a database feature they receive.
Migrations, connection pooling and backups become the team's responsibility. Firestore remains the better
answer to B5 considered alone, which is why the architecture keeps a dedicated real-time path instead of
pretending one store does everything.
