# FitFlow core API — FastAPI

The authorisation authority for the whole platform (ADR-004) and the coordinator of the domain modules.

```
app/
├─ main.py
├─ auth/       JWT verification, role and ownership dependencies
├─ routers/    accounts · plans · sessions · nutrition · progress · community
├─ models/     Pydantic request and response models
├─ services/   business rules, AI-draft safety rules, audit writer
└─ db/         SQLAlchemy models, migrations, Row-Level Security policies
```

## Run

```bash
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt -r requirements-dev.txt
uvicorn app.main:app --reload        # docs at http://localhost:8000/docs
ruff check . && pytest -q
```

## Rules

1. Every endpoint that touches user, circle or challenge data has an authorisation test. No exceptions.
2. Safety rules are applied to every AI draft **before** it reaches the user (Flow A step 5).
3. Session, sets and derived progress are written in one transaction (B7).
4. Nothing health-related is written to logs or error reports.
