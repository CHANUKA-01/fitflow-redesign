# Contributing

## Traceability

Every change points back to a requirement. Branch names use the identifier:

```
feat/R08-camera-first-nutrition
fix/U01-audience-before-join
docs/ADR-003-on-device-recognition
```

`R01–R16` user requirements · `NFR1–NFR5` non-functional requirements ·
`U01–U14` usability issues from Lab 04. See `docs/05-requirements-trace.md`.

## Definition of done

1. The requirement or issue ID is named in the pull request.
2. Tests cover the change, including an **authorisation test** for any endpoint that reads or writes
   data belonging to a user, a circle or a challenge (ADR-004).
3. Accessibility is considered: contrast, dynamic text, 48 dp targets (NFR4).
4. No secret, key or real user data appears in code, fixtures, logs or test output.
5. CI is green.

## Commit style

```
<type>(<scope>): <summary>

feat(nutrition): on-device recognition with confidence per item (R09)
fix(community): enforce audience server-side on challenge join (U01)
```

## Code style

- **Python** — ruff, black, type hints on public functions, Pydantic models at every boundary.
- **Dart** — `dart format`, `flutter analyze` clean, feature-first folder structure.
- **TypeScript** — ESLint, strict mode, server components by default.
