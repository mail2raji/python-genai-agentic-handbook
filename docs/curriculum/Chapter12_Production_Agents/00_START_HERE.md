# Phase 7 — Production-Ready Agentic AI

**Goal:** Move beyond demos. Build agents that are **safe**, **observable**, **testable**, **cost-controlled**, and **deployable** in real production environments.

By the end of this phase, you'll know how to:
- Connect agents to external systems via **MCP (Model Context Protocol)**
- Manage **short-term & long-term memory** like a real product
- **Evaluate** agents for accuracy, hallucination, latency, and cost
- Add **observability** — structured logs, tracing, metrics
- Diagnose and prevent **common agentic failure modes**
- Design a **production architecture** (queues, workers, state stores, vector DB)
- **Deploy** a LangGraph agent on **Kubernetes** (AKS)

---

## 📦 Install
```powershell
pip install -r requirements.txt
pip install mcp langgraph langchain-openai opentelemetry-api opentelemetry-sdk opentelemetry-exporter-otlp opentelemetry-instrumentation-requests structlog ragas rapidfuzz fastapi uvicorn redis prometheus-client
```
> The MCP package requires Python 3.10+.

---

## 📚 Lessons

| # | Lesson | File |
|---|--------|------|
| 1 | MCP — connect agents to anything | `01_mcp.md` |
| 2 | MCP server + client in Python | `02_mcp_server_and_client.py` |
| 3 | Production-grade memory (Redis + vector store) | `03_memory_production.py` |
| 4 | Evaluating agents (accuracy, hallucination, cost) | `04_evaluation.py` |
| 5 | Observability: logs, traces, metrics | `05_observability.py` |
| 6 | Common failure modes & defensive patterns | `06_failure_modes.py` |
| 7 | Production agent architecture (the big picture) | `07_architecture.md` |
| 8 | Deploying LangGraph on Kubernetes (AKS) | `08_deploy_langgraph_k8s.md` |

## 🏆 Capstone
**`capstone_production_agent/`** — a small FastAPI service wrapping a LangGraph agent with:
- Structured logging + OpenTelemetry traces
- Prometheus metrics
- Redis-backed short-term memory + vector store for long-term
- Eval harness (CI-runnable)
- Dockerfile + Kubernetes manifests + Helm-style values

---

## 🧭 How to read this phase

1. Skim each `.md` for concepts.
2. Run each `.py` (works in MOCK_MODE without API keys for most lessons).
3. Then read the capstone and trace the code end-to-end.
4. Use the **production checklist** at the bottom of `07_architecture.md` whenever you ship an agent.

