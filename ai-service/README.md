# FitFlow AI inference service — FastAPI + Celery

Kept separate from the core API so that CPU-bound inference never runs in the API event loop.

```
app/
├─ main.py
├─ planner/    workout plan generation, ranked reasons, confidence
├─ vision/     server-side food recognition fallback (ADR-003)
├─ registry/   model version loading, signature verification, rollback pointer
└─ workers/    Celery tasks for long inference, image scanning, batch jobs
```

## Contract

Every response carries:

- `model_version` — which model produced it
- `reasons[]` — ranked, human-readable, shown to the user (R04)
- `confidence` — per plan, or per recognised food item (R09)

## Boundaries

- Receives the **minimum necessary** feature set, never a full user profile.
- Produces no diagnosis and no medical advice.
- Model logs are redacted; meal images are never persisted by this service.

## Run

```bash
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt -r requirements-dev.txt
uvicorn app.main:app --reload --port 8001
celery -A app.workers worker -l info
```
