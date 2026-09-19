# Infrastructure

```
infra/
├─ docker-compose.yml    local PostgreSQL, Redis and an object-storage emulator
├─ migrations/           database schema and Row-Level Security policies
└─ terraform/            managed database, cache, object storage, secrets, CDN and WAF
```

## Principles

- Private networking: nothing behind the gateway is reachable from the internet.
- Encryption at rest, point-in-time recovery, and a **tested** restore procedure.
- Secrets live in the managed secret store with a rotation policy; never in source or CI logs.
- A scheduled job enforces the meal-photograph retention period (NFR5).
- Environments are identical apart from scale, so a staging test means something.
