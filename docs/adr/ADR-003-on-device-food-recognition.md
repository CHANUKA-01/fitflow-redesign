# ADR-003 — Food recognition runs on the device by default

- **Status:** Proposed · **Date:** 18 September 2026

## Context

NFR5 states a preference for on-device processing of food photographs. PP3 recorded that nutrition logging
was "particularly tedious", and upload latency is part of that. R09 requires a confidence indicator and an
editable correction step before anything is saved.

## Decision

A quantised TensorFlow Lite model runs on the device as the default path. The server-side model in the AI
inference service is the fallback, used when the device model is unavailable or its confidence is below
threshold.

## Reasons

- Keeps the common case entirely on the phone, which makes the NFR5 preference more than a policy
  statement.
- Removes upload latency from the most-complained-about flow.
- Flutter reaches TFLite through a single integration serving both platforms.

## Consequences

Two inference paths to maintain and evaluate, and a model-size ceiling on the mobile client. Model updates
must be versioned and shipped to devices, so the registry records which app versions carry which model.
Corrections made by the user are the training signal for the next version and must be captured without
storing the image itself.
