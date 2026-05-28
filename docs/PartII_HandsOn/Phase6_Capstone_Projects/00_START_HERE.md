# Phase 6 — Capstone Projects

You've learned the building blocks. Now build something **real**.

Pick ONE (or all) of these capstones. Each combines everything from Phases 1–5.

## 🎯 Capstone Ideas

### 1. **SPN Renewal Concierge**
Combines: RAG + Agent + Real workspace data.
- Reads your `SPN_ExpiryReport.csv`
- For each owner expiring soon, drafts a personalized email using an LLM
- Hands the draft to `Send-EscalationEmail.ps1` (your existing PowerShell)
- File: `capstone1_spn_renewal_concierge.py`

### 2. **PowerShell Doc Buddy**
Combines: RAG over your real workspace.
- Indexes all `.ps1` and `.md` files
- Acts as a chat assistant: "How do I run Export-PurviewRoles?"
- Cites the exact lines/files used
- File: `capstone2_powershell_doc_buddy.py`

### 3. **Multi-Agent Incident Reporter**
Combines: Multi-agent + Tools + Memory.
- Agents: LogAnalyst → RootCauseFinder → ReportWriter → Reviewer
- Input: a server log file
- Output: a Markdown incident report
- File: `capstone3_incident_reporter.py`

## 🧰 Production-readiness checklist

When promoting any capstone to production, ensure:

- [ ] Secrets in Azure Key Vault (or env vars), not in code
- [ ] Cost tracking & per-day budget cap
- [ ] Audit log of every LLM/tool call
- [ ] Retries with exponential backoff for API failures
- [ ] Prompt-injection guards for any user-supplied input
- [ ] PII scrubbing in logs
- [ ] Human-in-the-loop for destructive tools (send email, delete, etc.)
- [ ] Unit tests for every tool
- [ ] Evals: a fixed test set of Q&A pairs to detect regression
- [ ] Observability: log token usage and latency to Azure Monitor / App Insights

## 📈 Where to go next

| Topic | Resource |
|---|---|
| Frameworks | LangChain, LangGraph, LlamaIndex, Semantic Kernel |
| Vector DBs | Azure AI Search, Chroma, Qdrant, Pinecone |
| Multi-agent | AutoGen, CrewAI |
| Evaluation | Ragas, DeepEval, LangSmith |
| MLOps | MLflow, Weights & Biases |
| Local LLMs | Ollama, LM Studio |
| Fine-tuning | OpenAI fine-tune API, Hugging Face TRL |

🎉 Good luck on your GenAI journey!

