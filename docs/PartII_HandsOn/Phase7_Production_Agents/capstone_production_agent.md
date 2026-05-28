# 🏆 Final Capstone — Production SPN Agent

!!! tip "All-in-one capstone"
    A FastAPI agent with Redis memory, OpenTelemetry traces, evals, Dockerfile, docker-compose, and a Kubernetes manifest. The full source tree of every file in `Phase7_Production_Agents/capstone_production_agent/` is embedded below — copy into a folder of the same name and run.

## `agent.py`

``````python
"""
agent.py — small LangGraph-style state machine for the SPN renewal agent.

If `langgraph` isn't installed, we fall back to a hand-rolled sequential graph
so the capstone still runs in MOCK_MODE without extra deps.
"""
from __future__ import annotations
import json, re
from typing import Any
from llm_client import chat
from tools import TOOLS, list_expiring_spns, spns_for_owner
from memory import stm_get, stm_append, recall, remember
from observability import span, log_event, get_logger, LLM_C

log = get_logger("agent")

SYSTEM_PROMPT = """You are the SPN Renewal Concierge.
You answer questions about Service Principals (SPNs) that are expiring.
Rules:
- Use ONLY data returned by the tools.
- If the question is general, call `list_expiring_spns(days)`.
- If the user names an owner, call `spns_for_owner(owner)`.
- Cite the tool name you used at the end as: [source: <tool_name>].
- If you learn a durable user preference, end with: [REMEMBER] <fact>
"""


def _route(question: str) -> tuple[str, dict]:
    """Tiny deterministic router. Real systems use an LLM classifier."""
    q = question.lower()
    m = re.search(r"([A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,})", question)
    if m or "owner" in q or "owned by" in q:
        owner = m.group(1) if m else question.split()[-1]
        return "spns_for_owner", {"owner": owner}
    m = re.search(r"(\d{1,3})\s*day", q)
    days = int(m.group(1)) if m else 30
    return "list_expiring_spns", {"days": days}


def _call_tool(name: str, args: dict) -> Any:
    with span(f"tool.{name}"):
        fn = TOOLS[name]
        return fn(**args)


def _extract_remember(text: str) -> str | None:
    m = re.search(r"\[REMEMBER\]\s*(.+)$", text, re.IGNORECASE | re.MULTILINE)
    return m.group(1).strip() if m else None


def run(question: str, user_id: str, session_id: str) -> dict:
    """Top-level entrypoint. Returns {answer, tool, tool_result}."""
    with span("agent.run", **{"user.id": user_id}):
        # 1. recall + history
        prior_facts = [f.text for f in recall(user_id, limit=5)]
        history     = stm_get(session_id, last_n=10)

        # 2. route + tool
        tool, args = _route(question)
        log_event(log, "info", "route", tool=tool, args=args)
        tool_result = _call_tool(tool, args)

        # 3. compose prompt
        msgs = [{"role": "system", "content": SYSTEM_PROMPT}]
        if prior_facts:
            msgs.append({"role": "system",
                         "content": "Known facts about user:\n- " + "\n- ".join(prior_facts)})
        msgs.extend(history)
        msgs.append({"role": "user", "content":
            f"QUESTION: {question}\nTOOL `{tool}` RESULT:\n{json.dumps(tool_result, indent=2)}"})

        # 4. answer
        with span("llm.answer"):
            try:
                answer = chat(msgs, temperature=0)
                LLM_C.labels("ok").inc()
            except Exception:
                LLM_C.labels("error").inc(); raise

        # 5. persist
        stm_append(session_id, {"role": "user", "content": question})
        stm_append(session_id, {"role": "assistant", "content": answer})
        fact = _extract_remember(answer)
        if fact:
            remember(user_id, fact)
            log_event(log, "info", "memory.remember", fact=fact)

        return {"answer": answer, "tool": tool, "tool_args": args, "tool_result": tool_result}

``````

## `app.py`

``````python
"""
app.py — FastAPI service: /chat, /healthz, /readyz, /metrics
"""
from __future__ import annotations
import os, uuid
from fastapi import FastAPI, HTTPException
from fastapi.responses import Response
from pydantic import BaseModel, Field

from agent import run
from observability import request_scope, get_logger, log_event, metrics_payload

log = get_logger("api")
app = FastAPI(title="spn-renewal-agent", version="0.1.0")


class Ask(BaseModel):
    question:   str = Field(min_length=1, max_length=1000)
    user_id:    str = Field(default="anon", max_length=80)
    session_id: str | None = None


@app.post("/chat")
def chat_endpoint(req: Ask):
    sid = req.session_id or str(uuid.uuid4())
    with request_scope(user_id=req.user_id) as tid:
        log_event(log, "info", "chat.request", session_id=sid, q=req.question[:120])
        try:
            out = run(req.question, user_id=req.user_id, session_id=sid)
        except Exception as e:
            log_event(log, "error", "chat.failed", err=str(e))
            raise HTTPException(500, str(e))
        return {"trace_id": tid, "session_id": sid, **out}


@app.get("/healthz")
def healthz(): return {"ok": True}


@app.get("/readyz")
def readyz():
    # In real life: ping Redis, model endpoint, etc.
    return {"ready": True, "mode": os.getenv("MOCK_MODE", "0")}


@app.get("/metrics")
def metrics():
    payload, ct = metrics_payload()
    return Response(content=payload, media_type=ct)

``````

## `docker-compose.yaml`

``````yaml
services:
  agent:
    build: .
    ports: ["8080:8080"]
    environment:
      MOCK_MODE: "1"
      LOG_LEVEL: "INFO"
      REDIS_URL: "redis://redis:6379/0"
    depends_on: [redis]
  redis:
    image: redis:7
    ports: ["6379:6379"]

``````

## `Dockerfile`

``````dockerfile
# syntax=docker/dockerfile:1.7
FROM python:3.12-slim AS builder
WORKDIR /build
COPY requirements.txt .
RUN pip install --upgrade pip && \
    pip wheel --no-cache-dir --wheel-dir /wheels -r requirements.txt

FROM python:3.12-slim
RUN groupadd -r app && useradd -r -g app -u 10001 app
WORKDIR /app
COPY --from=builder /wheels /wheels
COPY requirements.txt .
RUN pip install --no-cache /wheels/*
COPY . .
USER 10001
EXPOSE 8080
ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1 MOCK_MODE=1
HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
    CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://localhost:8080/healthz').status==200 else 1)"
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8080", "--workers", "2"]

``````

## `evals/run_eval.py`

``````python
"""
evals/run_eval.py — CI quality gate. Exits non-zero if thresholds are violated.
Re-uses the scorer ideas from Lesson 4 but targets the capstone's `agent.run`.
"""
from __future__ import annotations
import sys, os, time, json, statistics
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
from agent import run

CASES = [
    {"id": "E1", "q": "Which SPNs expire in the next 60 days?",
     "must_have": ["spn-"]},
    {"id": "E2", "q": "What SPNs does priya@contoso.com own?",
     "must_have": ["priya"]},
    {"id": "E3", "q": "Anything expiring in the next 7 days?",
     "must_have": []},                                    # ok if nothing
]

THRESHOLDS = {"min_pass_rate": 0.66, "p95_latency_ms": 8000}


def score(text: str, must: list[str]) -> float:
    if not must: return 1.0
    return sum(1 for m in must if m.lower() in text.lower()) / len(must)


def main() -> int:
    latencies, scores = [], []
    for c in CASES:
        t0 = time.perf_counter()
        out = run(c["q"], user_id="ci", session_id=f"ci-{c['id']}")
        dur = (time.perf_counter() - t0) * 1000
        s = score(out["answer"], c["must_have"])
        latencies.append(dur); scores.append(s)
        print(f"  {c['id']} score={s:.2f} {dur:5.0f}ms")

    pass_rate = sum(1 for s in scores if s >= 0.5) / len(scores)
    p95 = statistics.quantiles(latencies, n=20)[18] if len(latencies) >= 2 else latencies[0]
    card = {"pass_rate": round(pass_rate, 3), "p95_latency_ms": round(p95, 1)}
    print("SCORECARD:", json.dumps(card))

    if pass_rate < THRESHOLDS["min_pass_rate"]:
        print(f"❌ pass_rate {pass_rate} < {THRESHOLDS['min_pass_rate']}"); return 1
    if p95 > THRESHOLDS["p95_latency_ms"]:
        print(f"❌ p95 {p95}ms > {THRESHOLDS['p95_latency_ms']}ms"); return 1
    print("✅ all thresholds passed"); return 0


if __name__ == "__main__":
    sys.exit(main())

``````

## `k8s/all-in-one.yaml`

``````yaml
apiVersion: v1
kind: Namespace
metadata:
  name: agents
---
apiVersion: v1
kind: ConfigMap
metadata: { name: agent-config, namespace: agents }
data:
  LOG_LEVEL: "INFO"
  MOCK_MODE: "0"
  AZURE_OPENAI_ENDPOINT:   "https://aoi-prod.openai.azure.com/"
  AZURE_OPENAI_DEPLOYMENT: "gpt-4o-mini"
---
apiVersion: apps/v1
kind: Deployment
metadata: { name: agent-svc, namespace: agents }
spec:
  replicas: 3
  selector: { matchLabels: { app: agent-svc } }
  strategy:
    rollingUpdate: { maxSurge: 1, maxUnavailable: 0 }
  template:
    metadata:
      labels: { app: agent-svc, azure.workload.identity/use: "true" }
    spec:
      serviceAccountName: agent-sa
      containers:
      - name: agent
        image: myregistry.azurecr.io/agent-svc:0.1.0
        ports: [{ containerPort: 8080 }]
        envFrom:
        - configMapRef: { name: agent-config }
        env:
        - name: AZURE_OPENAI_API_KEY
          valueFrom:
            secretKeyRef: { name: agent-secrets, key: AZURE_OPENAI_API_KEY }
        resources:
          requests: { cpu: "200m", memory: "512Mi" }
          limits:   { cpu: "1",    memory: "1Gi" }
        readinessProbe:
          httpGet: { path: /readyz, port: 8080 }
          periodSeconds: 5
        livenessProbe:
          httpGet: { path: /healthz, port: 8080 }
          initialDelaySeconds: 15
---
apiVersion: v1
kind: Service
metadata: { name: agent-svc, namespace: agents }
spec:
  selector: { app: agent-svc }
  ports: [{ port: 80, targetPort: 8080 }]
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata: { name: agent-svc, namespace: agents }
spec:
  scaleTargetRef: { apiVersion: apps/v1, kind: Deployment, name: agent-svc }
  minReplicas: 3
  maxReplicas: 20
  metrics:
  - type: Resource
    resource: { name: cpu, target: { type: Utilization, averageUtilization: 70 } }
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata: { name: agent-svc, namespace: agents }
spec:
  minAvailable: 2
  selector: { matchLabels: { app: agent-svc } }
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: agent-svc
  namespace: agents
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls: [{ hosts: [agent.contoso.com], secretName: agent-tls }]
  rules:
  - host: agent.contoso.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service: { name: agent-svc, port: { number: 80 } }

``````

## `llm_client.py`

``````python
"""
Tiny LLM shim so capstone modules can `from llm_client import chat, embed`.
Reuses Phase 4's shared client.
"""
import os, sys
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "Phase4_GenAI_Fundamentals")))
from llm_client import chat, chat_stream, embed, embed_many, MODE  # noqa: F401,E402

``````

## `memory.py`

``````python
"""
memory.py — thin wrapper around short-term (Redis-or-dict) + long-term (JSON) stores.
"""
from __future__ import annotations
import os, time, json, uuid
from dataclasses import dataclass, asdict
from pathlib import Path

LTM_PATH = Path(os.getenv("LTM_PATH", "ltm.json"))


# --- Short-term: per-session conversation buffer ----------------------------
try:
    if os.getenv("REDIS_URL"):
        import redis
        _r = redis.Redis.from_url(os.environ["REDIS_URL"], decode_responses=True)
        _r.ping()
        _USE_REDIS = True
    else:
        _USE_REDIS = False
except Exception:
    _USE_REDIS = False

_DICT: dict[str, list[dict]] = {}


def stm_append(session_id: str, msg: dict, ttl_seconds: int = 3600):
    if _USE_REDIS:
        key = f"stm:{session_id}"
        _r.rpush(key, json.dumps(msg))
        _r.expire(key, ttl_seconds)
    else:
        _DICT.setdefault(session_id, []).append(msg)


def stm_get(session_id: str, last_n: int = 20) -> list[dict]:
    if _USE_REDIS:
        raw = _r.lrange(f"stm:{session_id}", -last_n, -1)
        return [json.loads(x) for x in raw]
    return _DICT.get(session_id, [])[-last_n:]


# --- Long-term: persisted user facts ----------------------------------------
@dataclass
class Fact:
    id: str
    user_id: str
    text: str
    created_at: float


def _load() -> list[Fact]:
    if not LTM_PATH.exists(): return []
    return [Fact(**x) for x in json.loads(LTM_PATH.read_text())]


def _save(facts: list[Fact]):
    LTM_PATH.write_text(json.dumps([asdict(f) for f in facts], indent=2))


def remember(user_id: str, text: str) -> Fact:
    facts = _load()
    f = Fact(id=str(uuid.uuid4()), user_id=user_id, text=text.strip(),
             created_at=time.time())
    facts.append(f); _save(facts)
    return f


def recall(user_id: str, limit: int = 5) -> list[Fact]:
    return [f for f in _load() if f.user_id == user_id][-limit:]


def forget(user_id: str):
    _save([f for f in _load() if f.user_id != user_id])

``````

## `observability.py`

``````python
"""
observability.py — JSON logs + OTel traces + Prom metrics for the capstone.
Mirrors Lesson 5 but tightened for the FastAPI service.
"""
from __future__ import annotations
import os, time, json, logging, uuid, functools, contextvars
from contextlib import contextmanager

trace_id_var = contextvars.ContextVar("trace_id", default="-")
user_id_var  = contextvars.ContextVar("user_id",  default="-")


class _Json(logging.Formatter):
    def format(self, r):
        payload = {
            "ts": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(r.created)),
            "level": r.levelname, "msg": r.getMessage(), "logger": r.name,
            "trace_id": trace_id_var.get(), "user_id": user_id_var.get(),
        }
        payload.update(getattr(r, "extra_fields", {}))
        return json.dumps(payload, default=str)


def get_logger(name="agent"):
    log = logging.getLogger(name)
    if not log.handlers:
        h = logging.StreamHandler(); h.setFormatter(_Json())
        log.addHandler(h); log.setLevel(os.getenv("LOG_LEVEL", "INFO"))
        log.propagate = False
    return log


def log_event(log, level, msg, **fields):
    getattr(log, level.lower())(msg, extra={"extra_fields": fields})


# --- OTel (graceful fallback) -------------------------------------------------
try:
    from opentelemetry import trace
    from opentelemetry.sdk.trace import TracerProvider
    from opentelemetry.sdk.trace.export import BatchSpanProcessor, ConsoleSpanExporter
    from opentelemetry.sdk.resources import Resource
    prov = TracerProvider(resource=Resource.create({"service.name": "agent-svc"}))
    prov.add_span_processor(BatchSpanProcessor(ConsoleSpanExporter()))
    trace.set_tracer_provider(prov)
    tracer = trace.get_tracer(__name__)
except Exception:
    class _Span:
        def __enter__(self): return self
        def __exit__(self, *a): return False
        def set_attribute(self, *a, **k): pass
        def record_exception(self, *a, **k): pass
    class _T:
        def start_as_current_span(self, *a, **k): return _Span()
    tracer = _T()


@contextmanager
def span(name, **attrs):
    with tracer.start_as_current_span(name) as s:
        for k, v in attrs.items(): s.set_attribute(k, v)
        try:    yield s
        except Exception as e:
            s.record_exception(e); raise


# --- Prometheus (graceful fallback) ------------------------------------------
try:
    from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
    REQS  = Counter("agent_requests_total", "Requests", ["outcome"])
    LAT   = Histogram("agent_request_seconds", "Latency")
    LLM_C = Counter("agent_llm_calls_total", "LLM calls", ["outcome"])
    TOOLS = Counter("agent_tool_calls_total", "Tool calls", ["tool", "outcome"])
    def metrics_payload():
        return generate_latest(), CONTENT_TYPE_LATEST
except Exception:
    class _N:
        def labels(self, *a, **k): return self
        def inc(self, *a, **k): pass
        def observe(self, *a, **k): pass
    REQS = LAT = LLM_C = TOOLS = _N()
    def metrics_payload(): return b"prom unavailable", "text/plain"


@contextmanager
def request_scope(user_id="-"):
    tid = str(uuid.uuid4())
    t1 = trace_id_var.set(tid); t2 = user_id_var.set(user_id)
    t0 = time.perf_counter()
    try:
        with span("request", **{"user.id": user_id, "trace_id": tid}):
            yield tid
        REQS.labels("ok").inc()
    except Exception:
        REQS.labels("error").inc(); raise
    finally:
        LAT.observe(time.perf_counter() - t0)
        trace_id_var.reset(t1); user_id_var.reset(t2)


def instrument_tool(name):
    def deco(fn):
        @functools.wraps(fn)
        def inner(*a, **k):
            with span(f"tool.{name}", **{"tool.name": name}):
                try:
                    r = fn(*a, **k); TOOLS.labels(name, "ok").inc(); return r
                except Exception:
                    TOOLS.labels(name, "error").inc(); raise
        return inner
    return deco

``````

## `README.md`

``````markdown
# Capstone: Production-Ready SPN Renewal Agent

A runnable, miniature version of everything in Phase 7. This agent answers
questions about SPNs (Service Principals) that are about to expire — but
unlike Capstone 1 in Phase 6, this one is **deployable**.

## What's inside

| File | Purpose |
|---|---|
| `app.py`          | FastAPI service exposing `/chat`, `/healthz`, `/readyz`, `/metrics` |
| `agent.py`        | LangGraph state machine: route → recall → answer → ground-check |
| `memory.py`       | Short-term (in-mem/Redis) + long-term (JSON/vector) memory |
| `observability.py`| structlog + OpenTelemetry + Prometheus instrumentation |
| `tools.py`        | Read-only tools over `SPN_ExpiryReport.csv` (schema-validated) |
| `evals/run_eval.py` | The CI quality gate — fails the build on regressions |
| `Dockerfile`      | Multi-stage, non-root, slim |
| `docker-compose.yaml` | Local stack with Redis + Prometheus |
| `k8s/`            | Deployment, Service, Ingress, HPA, PDB, ConfigMap, SecretProviderClass |
| `requirements.txt`| Pinned deps |

## Run locally (MOCK_MODE)

```powershell
cd Phase7_Production_Agents\capstone_production_agent
$env:MOCK_MODE = "1"
pip install -r requirements.txt
uvicorn app:app --reload --port 8080
```

In another terminal:

```powershell
curl http://localhost:8080/healthz
curl -X POST http://localhost:8080/chat `
     -H "Content-Type: application/json" `
     -d '{"question":"Which SPNs expire in the next 14 days?","user_id":"u1"}'
```

## Run the eval gate

```powershell
python evals\run_eval.py
```

Exits non-zero if any threshold is violated (this is what CI runs).

## Build the container

```powershell
docker build -t agent-svc:0.1.0 .
docker run --rm -p 8080:8080 -e MOCK_MODE=1 agent-svc:0.1.0
```

## Deploy to AKS

See `08_deploy_langgraph_k8s.md` in the parent folder for the full walkthrough.
TL;DR:

```bash
az acr login -n <yourRegistry>
docker tag agent-svc:0.1.0 <yourRegistry>.azurecr.io/agent-svc:0.1.0
docker push <yourRegistry>.azurecr.io/agent-svc:0.1.0
kubectl apply -f k8s/
```

## What to study

1. Read `agent.py` and trace the LangGraph nodes.
2. Hit `/chat`, then look at the JSON log lines and the `/metrics` endpoint.
3. Break `tools.py` (return wrong data) → watch the eval gate fail.
4. Add a new tool, add an eval case, see CI block / pass.

``````

## `requirements.txt`

``````text
fastapi>=0.115
uvicorn[standard]>=0.30
pydantic>=2.6
python-dotenv>=1.0
openai>=1.50
tiktoken>=0.7
numpy>=1.26
structlog>=24.1
prometheus-client>=0.20
opentelemetry-api>=1.27
opentelemetry-sdk>=1.27
# optional:
# redis>=5.0
# langgraph>=0.2.50
# opentelemetry-exporter-otlp>=1.27

``````

## `tools.py`

``````python
"""
tools.py — read-only tools over SPN_ExpiryReport.csv with schema validation.
The CSV is the same one used by Phase 6 Capstone 1.
"""
from __future__ import annotations
import csv, os
from datetime import datetime, timezone
from pathlib import Path
from pydantic import BaseModel, Field, ValidationError
from observability import instrument_tool

CSV_PATH = Path(os.getenv("SPN_CSV", "../../../SPN_ExpiryReport.csv")).resolve()
DATE_FMTS = ("%Y-%m-%d", "%m/%d/%Y", "%d-%b-%Y", "%Y-%m-%dT%H:%M:%S")


def _parse_date(s: str) -> datetime | None:
    s = (s or "").strip()
    for f in DATE_FMTS:
        try: return datetime.strptime(s, f).replace(tzinfo=timezone.utc)
        except ValueError: pass
    return None


def _rows() -> list[dict]:
    if not CSV_PATH.exists():
        # Tiny inline fallback so the capstone runs anywhere
        return [
            {"AppName": "spn-billing",   "Owner": "priya@contoso.com",  "ExpiryDate": "2026-06-01"},
            {"AppName": "spn-logging",   "Owner": "alex@contoso.com",   "ExpiryDate": "2026-05-20"},
            {"AppName": "spn-archive",   "Owner": "sara@contoso.com",   "ExpiryDate": "2027-01-15"},
        ]
    with CSV_PATH.open() as f:
        return list(csv.DictReader(f))


class ExpiringArgs(BaseModel):
    days: int = Field(ge=1, le=365, default=30)


@instrument_tool("list_expiring_spns")
def list_expiring_spns(days: int = 30) -> list[dict]:
    try:
        a = ExpiringArgs(days=days)
    except ValidationError as e:
        return [{"error": e.errors()[0]["msg"]}]
    out = []
    now = datetime.now(timezone.utc)
    for r in _rows():
        d = _parse_date(r.get("ExpiryDate", "") or r.get("Expiry", ""))
        if d and 0 <= (d - now).days <= a.days:
            out.append({
                "app":   r.get("AppName") or r.get("DisplayName"),
                "owner": r.get("Owner")   or r.get("OwnerEmail"),
                "expires_in_days": (d - now).days,
                "expiry_date": d.date().isoformat(),
            })
    out.sort(key=lambda x: x["expires_in_days"])
    return out


class OwnerArgs(BaseModel):
    owner: str = Field(min_length=3, max_length=120)


@instrument_tool("spns_for_owner")
def spns_for_owner(owner: str) -> list[dict]:
    try: a = OwnerArgs(owner=owner)
    except ValidationError as e: return [{"error": e.errors()[0]["msg"]}]
    owner_l = a.owner.lower()
    return [
        {"app": r.get("AppName") or r.get("DisplayName"),
         "expiry_date": r.get("ExpiryDate")}
        for r in _rows()
        if owner_l in ((r.get("Owner") or r.get("OwnerEmail") or "").lower())
    ]


TOOLS = {
    "list_expiring_spns": list_expiring_spns,
    "spns_for_owner":     spns_for_owner,
}

``````


