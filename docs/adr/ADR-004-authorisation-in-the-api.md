# ADR-004 — Authorisation is enforced in the API; RLS is defence in depth

- **Status:** Proposed · **Date:** 18 September 2026

## Context

U01, the only Critical issue in Lab 04, was a participant joining a challenge without being told who would
see it. Two lapsed participants named that concern as their reason for stopping. Identity providers answer
*who is calling*; they do not answer *who may see this*.

## Decision

All authorisation — ownership, circle membership, trainer grants, moderator rights, audience visibility —
is enforced in the FastAPI core API on every read and every write. PostgreSQL Row-Level Security is
configured as a second line of defence, not as the rule system. The interface renders the audience
statement returned by the API rather than constructing it locally.

## Reasons

A privacy rule expressed in only one place will eventually be lost. Two independent rule systems — API
guards plus database-level rules maintained separately, as in the Firestore arrangement — is how it gets
lost twice, because each is assumed to be covering the other.

## Consequences

Every endpoint needs an explicit authorisation test, and that test becomes part of the definition of done
and a required CI job. The interface cannot invent an audience label; it displays the one the server
returned with the content.
