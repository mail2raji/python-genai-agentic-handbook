# Lesson 7: Production Agent Architecture (Beyond Demos)

This is the architecture you reach for when an agent must serve real users at scale.

## 🗺️ Reference architecture

```
                       ┌────────────────────────┐
   user / Teams / web  │  API Gateway / Front   │  auth (OAuth2 / Entra ID)
   ───────────────────►│  (FastAPI behind APIM) │  rate-limit, WAF
                       └────────────┬───────────┘
                                    │ async REST
                                    ▼
                       ┌────────────────────────┐
                       │   Orchestrator Service │  LangGraph state machine
                       │   (FastAPI + Uvicorn)  │  request scope + tracing
                       └─┬────────┬────────┬────┘
              tools/LLM  │        │        │  events
                         ▼        ▼        ▼
   ┌─────────┐   ┌─────────────┐ ┌──────────┐ ┌──────────────┐
   │ Azure   │   │ MCP servers │ │  Redis   │ │ Service Bus  │
   │ OpenAI  │   │ (filesys,   │ │ short-   │ │ background   │
   │ (model) │   │  github,    │ │ term mem │ │ jobs / DLQ   │
   └─────────┘   │  Jira, ...) │ └──────────┘ └──────┬───────┘
                 └─────────────┘                     │
                         │                           ▼
                 ┌───────▼──────┐            ┌──────────────┐
                 │  Vector DB   │            │  Worker pods │
                 │ (Azure AI    │            │ (eval, batch │
                 │  Search /    │            │  ingestion)  │
                 │  pgvector)   │            └──────────────┘
                 └──────────────┘
                         │
                         ▼
                 ┌──────────────┐    ┌──────────────────────┐
                 │ Object store │    │  Observability stack │
                 │ (Blob / S3)  │    │  OTel → App Insights │
                 │ raw docs     │    │  Prometheus / Grafana│
                 └──────────────┘    └──────────────────────┘
```

## 🧱 Component responsibilities

| Layer | Responsibility | Common choices |
|---|---|---|
| **Gateway** | Auth, rate limit, WAF, mTLS | Azure APIM, NGINX, Kong |
| **Orchestrator** | Run the agent loop, build prompts, call tools | FastAPI + LangGraph |
| **Model provider** | LLM + embeddings | Azure OpenAI (preferred for enterprise) |
| **Tools** | Side-effects, integrations | MCP servers (filesystem, GitHub, Azure, internal APIs) |
| **Short-term memory** | Per-session message history | Redis / Azure Cache for Redis |
| **Long-term memory** | Semantic facts, RAG corpus | Azure AI Search, pgvector, Qdrant |
| **Job queue** | Long-running / async work | Azure Service Bus, RabbitMQ, Kafka |
| **Workers** | Ingestion, batch evals | K8s Jobs / KEDA-scaled |
| **Observability** | Logs, traces, metrics | OpenTelemetry → App Insights / Tempo / Grafana / Prometheus |
| **Secrets** | API keys, conn strings | Azure Key Vault (CSI driver into pods) |
| **Identity** | User & service auth | Entra ID, Workload Identity |
| **Eval harness** | Quality gate in CI/CD | The script from Lesson 4 |

## 🔄 Lifecycle of a single request

1. **Receive** → Gateway authenticates user → forwards to Orchestrator with trace_id.
2. **Scope** → load session from Redis, recall facts from vector DB.
3. **Plan** → LangGraph state machine decides nodes (router / RAG / tool).
4. **Act** → call MCP tools and/or LLM; every call wrapped in OTel span.
5. **Validate** → schema-check tool args, run groundedness on the LLM reply.
6. **Persist** → save turn to Redis (TTL), upsert any new facts to vector DB.
7. **Respond** → stream tokens back; emit metrics; log structured JSON.

## 🧠 12 production patterns to internalize

1. **Stateless app, stateful stores.** Pods can die at any time.
2. **One trace_id per request**, propagated everywhere (logs, spans, downstream calls).
3. **Token budget** at every node (system + history + recalled facts + new input).
4. **Strict tool schemas** validated with Pydantic before execution.
5. **Risk-classified tools**: `read` / `write` / `destructive`. Destructive needs a human.
6. **Idempotent tools.** If a worker retries, don't send the email twice.
7. **Dead-letter queue** for failed requests; replay-safe.
8. **Multi-region failover** for model endpoints (Azure OpenAI deployments in two regions).
9. **Cost guardrails**: per-request budget, per-user daily cap, global circuit breaker.
10. **Eval in CI**: block deploys that regress accuracy or groundedness (Lesson 4).
11. **Shadow mode**: new version processes 10% of traffic in parallel; compare scorecards.
12. **Versioned prompts** in git. Every change → re-run evals.

## 🔐 Security must-haves

- Secrets only via Key Vault / Workload Identity. Never in env files in images.
- `network_policy: deny-by-default` between namespaces.
- mTLS service-to-service (Linkerd / Istio / Dapr).
- Egress restricted to known model endpoints + tool URLs.
- Prompt-injection guard at the orchestrator boundary (Lesson 6).
- PII scrubbing on log/trace exporters.

## 💰 Cost controls

- Smaller routing model decides "should we call the big model?"
- Cache embeddings (text hash → vector).
- Cache final answers for common Qs (1–24h TTL).
- Use streaming so users don't wait for full completion.
- Track `$/conversation` as a primary KPI alongside accuracy.

## 🧪 Quality gate (CI pipeline)

```
git push
  → unit tests
  → tool schema tests
  → eval harness on golden set      ← gate: thresholds in Lesson 4
  → build image
  → deploy to staging
  → smoke tests + shadow traffic 30 min
  → promote to prod (canary 5% → 25% → 100%)
```

## ✅ Pre-prod checklist (print this)

- [ ] Stateless service (no local files for state)
- [ ] OTel traces + structured logs + Prometheus metrics
- [ ] Eval harness in CI with thresholds
- [ ] Cost budget enforced per request and per tenant
- [ ] PII scrubbing in logs & vector store
- [ ] Schema-validated tool args
- [ ] Risk-class gating for write/destructive tools
- [ ] Retries with exponential backoff + jitter
- [ ] Circuit breaker around upstream LLM
- [ ] Health endpoints `/healthz`, `/readyz`
- [ ] Graceful shutdown (drain inflight requests)
- [ ] Resource requests/limits set
- [ ] HPA / KEDA tuned to model latency
- [ ] Key Vault integration via CSI driver
- [ ] Versioned prompts in git
- [ ] Runbook for "agent gives wrong answers" + "cost spike" + "tool outage"

Continue to **`08_deploy_langgraph_k8s.md`** for an end-to-end Kubernetes deployment.

