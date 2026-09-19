# FitFlow mobile client — Flutter

iOS and Android client implementing the "Focus Flow" direction selected in Lab 03.

```
lib/
├─ core/        theming, routing, design tokens shared with the web client
├─ data/        API client generated from the OpenAPI contract, offline store (Drift), sync queue
└─ features/
   ├─ home/         Focus Flow home card (R01, R14)
   ├─ planner/      AI planner, reasons, adjust / swap / regenerate (R03–R05)
   ├─ logging/      set logger with pre-fill and rest timer (R06, R07, NFR1)
   ├─ progress/     headline metric, plain-language sentence, detail (R10, R12, R13)
   ├─ community/    circles, challenges, audience selector (R11, U01)
   └─ nutrition/    camera capture, on-device recognition, review step (R08, R09)
```

## Run

```bash
flutter pub get
flutter run
flutter analyze && flutter test
```

## Notes

- Offline writes carry an idempotency key; never retry without one (NFR2).
- The audience label shown on any social screen is the one the API returned — do not construct it
  client-side (ADR-004).
- Accessibility: 48 dp targets, dynamic text sizing, contrast checked against WCAG 2.1 AA (NFR4).
