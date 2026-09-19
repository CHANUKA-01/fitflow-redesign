# FitFlow web client — Next.js

Trainer console, progress review, community moderation and public pages. Server-rendered semantic HTML so
that WCAG 2.1 AA (NFR4) is achievable — the reason the web surface is not a Flutter build.

```
app/
├─ (marketing)/   public pages
├─ dashboard/     trainer console — client list, plan review
├─ progress/      progress review (R10)
└─ community/     moderation queue (R11)
```

## Run

```bash
npm install
npm run dev     # http://localhost:3000
npm run lint && npm run build
```

## Notes

- Server components by default; client components only where interaction requires them.
- The API client is generated from the same OpenAPI document as the mobile client.
- Every page is checked with a screen reader before merge.
