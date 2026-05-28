# Lesson 8: Deploy a LangGraph Agent to Kubernetes (AKS)

End-to-end guide: code → container → AKS → traffic.

We deploy a FastAPI app that wraps a LangGraph agent. You'll get:
- a multi-stage **Dockerfile**
- Kubernetes **manifests** (Deployment, Service, Ingress, HPA, PDB, ConfigMap, Secret-CSI)
- a **Helm-style** `values.yaml` snippet
- a **GitHub Actions** pipeline that gates deploys with the eval harness from Lesson 4

> Works on any K8s, but the Azure-specific bits assume AKS + Azure Key Vault + Azure OpenAI.

---

## 1. The minimal FastAPI + LangGraph app

```python
# app/main.py
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from langgraph.graph import StateGraph, END
from openai import AzureOpenAI
import os, time, uuid, logging

app = FastAPI(title="agent-svc")
log = logging.getLogger("agent")

client = AzureOpenAI(
    azure_endpoint=os.environ["AZURE_OPENAI_ENDPOINT"],
    api_key=os.environ["AZURE_OPENAI_API_KEY"],
    api_version="2024-10-21",
)

class State(dict): ...

def node_answer(state: State) -> State:
    r = client.chat.completions.create(
        model=os.environ["AZURE_OPENAI_DEPLOYMENT"],
        messages=[{"role": "user", "content": state["question"]}],
        temperature=0,
    )
    state["answer"] = r.choices[0].message.content
    return state

g = StateGraph(State)
g.add_node("answer", node_answer)
g.set_entry_point("answer")
g.add_edge("answer", END)
agent = g.compile()

class Ask(BaseModel):
    question: str

@app.post("/chat")
def chat(req: Ask):
    trace_id = str(uuid.uuid4())
    t0 = time.perf_counter()
    try:
        out = agent.invoke({"question": req.question})
        log.info("chat ok trace=%s ms=%.0f", trace_id, (time.perf_counter()-t0)*1000)
        return {"trace_id": trace_id, "answer": out["answer"]}
    except Exception as e:
        log.exception("chat failed trace=%s", trace_id)
        raise HTTPException(500, str(e))

@app.get("/healthz")
def healthz(): return {"ok": True}

@app.get("/readyz")
def readyz():
    # cheap dependency probe
    return {"ready": bool(os.environ.get("AZURE_OPENAI_ENDPOINT"))}
```

---

## 2. Dockerfile (multi-stage, non-root, small)

```dockerfile
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
COPY app/ ./app/
USER 10001
EXPOSE 8080
ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080", "--workers", "2"]
```

`requirements.txt`:

```
fastapi>=0.115
uvicorn[standard]>=0.30
langgraph>=0.2.50
openai>=1.50
pydantic>=2.6
opentelemetry-api
opentelemetry-sdk
opentelemetry-exporter-otlp
prometheus-client
structlog
```

Build & push:

```bash
az acr login -n myregistry
docker build -t myregistry.azurecr.io/agent-svc:0.1.0 .
docker push    myregistry.azurecr.io/agent-svc:0.1.0
```

---

## 3. Kubernetes manifests

### `k8s/namespace.yaml`
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: agents
  labels: { name: agents }
```

### `k8s/deployment.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: agent-svc
  namespace: agents
spec:
  replicas: 3
  strategy:
    rollingUpdate: { maxSurge: 1, maxUnavailable: 0 }
  selector:
    matchLabels: { app: agent-svc }
  template:
    metadata:
      labels: { app: agent-svc, azure.workload.identity/use: "true" }
    spec:
      serviceAccountName: agent-sa             # bound to a managed identity
      containers:
      - name: agent-svc
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
        volumeMounts:
        - name: secrets-store
          mountPath: /mnt/secrets
          readOnly: true
      volumes:
      - name: secrets-store
        csi:
          driver: secrets-store.csi.k8s.io
          readOnly: true
          volumeAttributes: { secretProviderClass: agent-akv }
```

### `k8s/service.yaml`
```yaml
apiVersion: v1
kind: Service
metadata: { name: agent-svc, namespace: agents }
spec:
  selector: { app: agent-svc }
  ports: [{ port: 80, targetPort: 8080 }]
```

### `k8s/ingress.yaml`
```yaml
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
```

### `k8s/hpa.yaml`
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata: { name: agent-svc, namespace: agents }
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: agent-svc
  minReplicas: 3
  maxReplicas: 20
  metrics:
  - type: Resource
    resource: { name: cpu, target: { type: Utilization, averageUtilization: 70 } }
```

### `k8s/pdb.yaml`
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata: { name: agent-svc, namespace: agents }
spec:
  minAvailable: 2
  selector: { matchLabels: { app: agent-svc } }
```

### `k8s/secret-provider.yaml` (Azure Key Vault → CSI)
```yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata: { name: agent-akv, namespace: agents }
spec:
  provider: azure
  parameters:
    usePodIdentity: "false"
    useVMManagedIdentity: "false"
    clientID: "<workload-identity-client-id>"
    keyvaultName: "kv-agent-prod"
    tenantId: "<tenant-id>"
    objects: |
      array:
        - |
          objectName: AZURE-OPENAI-API-KEY
          objectType: secret
  secretObjects:
  - secretName: agent-secrets
    type: Opaque
    data:
    - objectName: AZURE-OPENAI-API-KEY
      key: AZURE_OPENAI_API_KEY
```

### `k8s/configmap.yaml`
```yaml
apiVersion: v1
kind: ConfigMap
metadata: { name: agent-config, namespace: agents }
data:
  AZURE_OPENAI_ENDPOINT:   "https://aoi-prod.openai.azure.com/"
  AZURE_OPENAI_DEPLOYMENT: "gpt-4o-mini"
  LOG_LEVEL:               "INFO"
  OTEL_EXPORTER_OTLP_ENDPOINT: "http://otel-collector.observability:4317"
```

Apply:

```bash
kubectl apply -f k8s/
```

---

## 4. Helm-style `values.yaml` (for templated deploys)

```yaml
image:
  repository: myregistry.azurecr.io/agent-svc
  tag: 0.1.0
replicaCount: 3
autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 20
  targetCPU: 70
resources:
  requests: { cpu: 200m, memory: 512Mi }
  limits:   { cpu: 1,    memory: 1Gi  }
azure:
  workloadIdentityClientId: <client-id>
  keyVaultName: kv-agent-prod
  openAi:
    endpoint:   https://aoi-prod.openai.azure.com/
    deployment: gpt-4o-mini
ingress:
  host: agent.contoso.com
  tlsSecret: agent-tls
```

---

## 5. GitHub Actions: lint → test → **eval gate** → build → deploy

```yaml
# .github/workflows/deploy.yml
name: deploy-agent
on:
  push: { branches: [main] }

jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-python@v5
      with: { python-version: '3.12' }
    - run: pip install -r requirements.txt
    - run: ruff check .
    - run: pytest -q

    # ---- Quality gate: run eval harness from Lesson 4 ----
    - name: Agent evals
      env:
        AZURE_OPENAI_API_KEY:  ${{ secrets.AZURE_OPENAI_API_KEY }}
        AZURE_OPENAI_ENDPOINT: ${{ secrets.AZURE_OPENAI_ENDPOINT }}
        AZURE_OPENAI_DEPLOYMENT: gpt-4o-mini
      run: python evals/run_eval.py    # exits non-zero on threshold violation

  build:
    needs: ci
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - uses: azure/login@v2
      with: { creds: ${{ secrets.AZURE_CREDENTIALS }} }
    - run: az acr login -n myregistry
    - run: docker build -t myregistry.azurecr.io/agent-svc:${{ github.sha }} .
    - run: docker push    myregistry.azurecr.io/agent-svc:${{ github.sha }}

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment: production    # requires manual approval if set
    steps:
    - uses: actions/checkout@v4
    - uses: azure/login@v2
      with: { creds: ${{ secrets.AZURE_CREDENTIALS }} }
    - uses: azure/aks-set-context@v4
      with: { resource-group: rg-agents, cluster-name: aks-agents }
    - run: |
        kubectl -n agents set image deploy/agent-svc \
          agent-svc=myregistry.azurecr.io/agent-svc:${{ github.sha }}
        kubectl -n agents rollout status deploy/agent-svc --timeout=5m
```

---

## 6. AKS-specific must-dos

- **Workload Identity** enabled on the cluster; bind the `ServiceAccount` to the managed identity that has `Cognitive Services User` on Azure OpenAI.
- **Azure Monitor for containers** add-on → logs and metrics to App Insights.
- **Azure AI Search private endpoint** if you use RAG (the agent should NOT reach the index over public internet).
- **AGIC or NGINX ingress** + **cert-manager** for TLS.
- **KEDA** if you want to scale on queue depth (Service Bus) instead of CPU.
- **Defender for Containers** for runtime security.

---

## 7. Local dev with Docker Compose

```yaml
# docker-compose.yaml
services:
  agent:
    build: .
    ports: ["8080:8080"]
    environment:
      AZURE_OPENAI_ENDPOINT: ${AZURE_OPENAI_ENDPOINT}
      AZURE_OPENAI_API_KEY:  ${AZURE_OPENAI_API_KEY}
      AZURE_OPENAI_DEPLOYMENT: gpt-4o-mini
  redis:
    image: redis:7
    ports: ["6379:6379"]
  prom:
    image: prom/prometheus
    volumes: ["./prometheus.yml:/etc/prometheus/prometheus.yml"]
    ports: ["9090:9090"]
```

`curl http://localhost:8080/chat -d '{"question":"hi"}' -H "Content-Type: application/json"`

---

## 8. Day-2 ops

| Concern | Tool / pattern |
|---|---|
| Cost spike alert | Prometheus alert on `agent_llm_cost_usd_total` rate |
| Hallucination drift | Weekly cron job runs eval harness; export scorecard to Grafana |
| Hot prompt change | Versioned prompt file in git; canary 10% via feature flag |
| Outage of model region | Two Azure OpenAI deployments; client-side failover |
| Bad release | `kubectl rollout undo deploy/agent-svc -n agents` |

Continue to **`capstone_production_agent/`** — a runnable mini-version of everything above.

