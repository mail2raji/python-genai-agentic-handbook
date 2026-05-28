# 📘 Python for GenAI & Agentic AI — Handbook

> *A hands-on book that takes you from your first line of Python to a production-ready agent running on Kubernetes.*

This is the **front page of the book**. Read it like a Table of Contents.
Click any chapter to open it. Each chapter is a runnable `.py` file or a concept `.md`.

When you're ready to **do** rather than read, jump to **[`LAB_MENU.md`](LAB_MENU.md)** — every hands-on exercise in the book, in one checklist.

---

## How to use this handbook

1. **Set up once** (5 minutes) — follow [`QUICKSTART.md`](QUICKSTART.md).
2. **Pick a phase** below, then read the lessons in order.
3. After each lesson, do its corresponding lab in [`LAB_MENU.md`](LAB_MENU.md).
4. Tick the box ✅. Move on.

> 💡 Most lessons run **offline** in `MOCK_MODE=1` — no API key required.
> Add a real OpenAI / Azure OpenAI key in `.env` only when you want real-LLM output.

---

## 🗺️ Book Map

| Part | Phase | Theme | Lessons | Project |
|---|---|---|---|---|
| **I** | [Phase 1](Phase1_Python_Fundamentals/00_START_HERE.md) | Python Fundamentals | 10 | Log Analyzer |
| **II** | [Phase 2](Phase2_Intermediate_Python/00_START_HERE.md) | Intermediate Python | 8 | Weather Chatbot |
| **III** | [Phase 3](Phase3_Python_for_AI/00_START_HERE.md) | Python for AI & Data | 4 | CSV Analyst |
| **IV** | [Phase 4](Phase4_GenAI_Fundamentals/00_START_HERE.md) | GenAI Fundamentals | 7 | Doc Q&A (RAG) |
| **V** | [Phase 5](Phase5_Agentic_AI/00_START_HERE.md) | Agentic AI | 7 | IT Triage Agent |
| **VI** | [Phase 6](Phase6_Capstone_Projects/00_START_HERE.md) | Capstone Projects | — | 3 capstones |
| **VII** | [Phase 7](Phase7_Production_Agents/00_START_HERE.md) | Production Agents | 8 | SPN Renewal Agent (FastAPI + K8s) |

---

# Part I — Python Fundamentals

> **Goal:** Write small Python scripts confidently.

| # | Chapter | Open |
|---|---|---|
| 1.1 | Hello World | [01_hello_world.py](Phase1_Python_Fundamentals/01_hello_world.md) |
| 1.2 | Variables and Types | [02_variables_and_types.py](Phase1_Python_Fundamentals/02_variables_and_types.md) |
| 1.3 | Strings | [03_strings.py](Phase1_Python_Fundamentals/03_strings.md) |
| 1.4 | Numbers and Math | [04_numbers_and_math.py](Phase1_Python_Fundamentals/04_numbers_and_math.md) |
| 1.5 | Lists | [05_lists.py](Phase1_Python_Fundamentals/05_lists.md) |
| 1.6 | Dictionaries | [06_dictionaries.py](Phase1_Python_Fundamentals/06_dictionaries.md) |
| 1.7 | Conditionals | [07_conditionals.py](Phase1_Python_Fundamentals/07_conditionals.md) |
| 1.8 | Loops | [08_loops.py](Phase1_Python_Fundamentals/08_loops.md) |
| 1.9 | Functions | [09_functions.py](Phase1_Python_Fundamentals/09_functions.md) |
| 1.10 | Files | [10_files.py](Phase1_Python_Fundamentals/10_files.md) |
| 🛠️ | Mini-Project: Log Analyzer | [mini_project_log_analyzer.py](Phase1_Python_Fundamentals/mini_project_log_analyzer.md) |

# Part II — Intermediate Python

> **Goal:** Write Python like a software engineer.

| # | Chapter | Open |
|---|---|---|
| 2.1 | Modules | [01_modules.py](Phase2_Intermediate_Python/01_modules.md) |
| 2.2 | venv and pip | [02_venv_and_pip.md](Phase2_Intermediate_Python/02_venv_and_pip.md) |
| 2.3 | Error Handling | [03_error_handling.py](Phase2_Intermediate_Python/03_error_handling.md) |
| 2.4 | Classes | [04_classes.py](Phase2_Intermediate_Python/04_classes.md) |
| 2.5 | Type Hints | [05_type_hints.py](Phase2_Intermediate_Python/05_type_hints.md) |
| 2.6 | APIs with `requests` | [06_apis_requests.py](Phase2_Intermediate_Python/06_apis_requests.md) |
| 2.7 | Async I/O | [07_async.py](Phase2_Intermediate_Python/07_async.md) |
| 2.8 | Env & Secrets | [08_env_secrets.py](Phase2_Intermediate_Python/08_env_secrets.md) |
| 🛠️ | Mini-Project: Weather Chatbot | [mini_project_weather_chatbot.py](Phase2_Intermediate_Python/mini_project_weather_chatbot.md) |

# Part III — Python for AI & Data

> **Goal:** Know the math/data layer beneath every AI library.

| # | Chapter | Open |
|---|---|---|
| 3.1 | NumPy | [01_numpy.py](Phase3_Python_for_AI/01_numpy.md) |
| 3.2 | Pandas | [02_pandas.py](Phase3_Python_for_AI/02_pandas.md) |
| 3.3 | Cosine Similarity | [03_cosine_similarity.py](Phase3_Python_for_AI/03_cosine_similarity.md) |
| 3.4 | Tokenization | [04_tokenization.py](Phase3_Python_for_AI/04_tokenization.md) |
| 🛠️ | Mini-Project: CSV Analyst | [mini_project_csv_analyst.py](Phase3_Python_for_AI/mini_project_csv_analyst.md) |

# Part IV — GenAI Fundamentals

> **Goal:** Understand LLMs, prompts, embeddings, and Retrieval-Augmented Generation.

| # | Chapter | Open |
|---|---|---|
| 4.1 | What is an LLM? | [01_what_is_llm.md](Phase4_GenAI_Fundamentals/01_what_is_llm.md) |
| 4.2 | Your First LLM Call | [02_first_llm_call.py](Phase4_GenAI_Fundamentals/02_first_llm_call.md) |
| 4.3 | Prompt Engineering | [03_prompt_engineering.py](Phase4_GenAI_Fundamentals/03_prompt_engineering.md) |
| 4.4 | Structured Outputs (JSON) | [04_structured_outputs.py](Phase4_GenAI_Fundamentals/04_structured_outputs.md) |
| 4.5 | Streaming | [05_streaming.py](Phase4_GenAI_Fundamentals/05_streaming.md) |
| 4.6 | Embeddings | [06_embeddings.py](Phase4_GenAI_Fundamentals/06_embeddings.md) |
| 4.7 | RAG System (from scratch) | [07_rag_system.py](Phase4_GenAI_Fundamentals/07_rag_system.md) |
| 🧰 | Shared LLM Client | [llm_client.py](Phase4_GenAI_Fundamentals/llm_client.md) |
| 🛠️ | Mini-Project: Doc Q&A | [mini_project_doc_qa.py](Phase4_GenAI_Fundamentals/mini_project_doc_qa.md) |

# Part V — Agentic AI

> **Goal:** Build LLMs that *act* — tools, reasoning loops, multi-agent teams.

| # | Chapter | Open |
|---|---|---|
| 5.1 | What is an Agent? | [01_what_is_agent.md](Phase5_Agentic_AI/01_what_is_agent.md) |
| 5.2 | Function Calling | [02_function_calling.py](Phase5_Agentic_AI/02_function_calling.md) |
| 5.3 | ReAct Agent | [03_react_agent.py](Phase5_Agentic_AI/03_react_agent.md) |
| 5.4 | Agent Memory | [04_memory.py](Phase5_Agentic_AI/04_memory.md) |
| 5.5 | Guardrails | [05_guardrails.py](Phase5_Agentic_AI/05_guardrails.md) |
| 5.6 | Multi-Agent Pipelines | [06_multi_agent.py](Phase5_Agentic_AI/06_multi_agent.md) |
| 5.7 | LangGraph Intro | [07_langgraph_intro.py](Phase5_Agentic_AI/07_langgraph_intro.md) |
| 🛠️ | Mini-Project: IT Triage Agent | [mini_project_it_triage_agent.py](Phase5_Agentic_AI/mini_project_it_triage_agent.md) |

# Part VI — Capstone Projects

> **Goal:** Ship three real projects tied to your existing IT-ops world.

| # | Capstone | Open |
|---|---|---|
| 6.1 | SPN Renewal Concierge | [capstone1_spn_renewal_concierge.py](Phase6_Capstone_Projects/capstone1_spn_renewal_concierge.md) |
| 6.2 | PowerShell Doc Buddy | [capstone2_powershell_doc_buddy.py](Phase6_Capstone_Projects/capstone2_powershell_doc_buddy.md) |
| 6.3 | Incident Reporter | [capstone3_incident_reporter.py](Phase6_Capstone_Projects/capstone3_incident_reporter.md) |

# Part VII — Production Agents

> **Goal:** Make your agent safe, observable, testable, and deployable.

| # | Chapter | Open |
|---|---|---|
| 7.1 | MCP — Model Context Protocol | [01_mcp.md](Phase7_Production_Agents/01_mcp.md) |
| 7.2 | MCP Server + Client | [02_mcp_server_and_client.py](Phase7_Production_Agents/02_mcp_server_and_client.md) |
| 7.3 | Production Memory (Redis + Vector) | [03_memory_production.py](Phase7_Production_Agents/03_memory_production.md) |
| 7.4 | Evaluating Agents | [04_evaluation.py](Phase7_Production_Agents/04_evaluation.md) |
| 7.5 | Observability — logs, traces, metrics | [05_observability.py](Phase7_Production_Agents/05_observability.md) |
| 7.6 | Failure Modes & Defenses | [06_failure_modes.py](Phase7_Production_Agents/06_failure_modes.md) |
| 7.7 | Production Architecture | [07_architecture.md](Phase7_Production_Agents/07_architecture.md) |
| 7.8 | Deploy LangGraph on Kubernetes | [08_deploy_langgraph_k8s.md](Phase7_Production_Agents/08_deploy_langgraph_k8s.md) |
| 🏆 | Final Capstone: Production SPN Agent | [capstone_production_agent/README.md](Phase7_Production_Agents/capstone_production_agent.md) |

---

## 📝 Conventions in this book

- 📖 **Concept** — short paragraph at the top of each `.py` lesson
- 💡 **Analogy** — every concept tied to something you already know
- 🧪 **Run it** — the bottom of the file has a `if __name__ == "__main__"` you can run
- ✏️ **Exercise** — challenge prompt with hidden solution
- ✅ **Takeaway box** — the one thing to remember

---

## 🔁 Reading order suggestions

- **Total beginner** → Part I → II → III → IV → V → VI → VII (full path)
- **Already know Python** → Skim I & II, do III, then dive into IV onward
- **Already know GenAI** → Start at Part V or Part VII
- **DevOps / SRE focus** → Part VII alone is a complete "production agents" guide

---

## 🧰 Toolbox shared across the book

- [`llm_client.py`](Phase4_GenAI_Fundamentals/llm_client.md) — the one LLM client used everywhere. Auto-switches between OpenAI / Azure OpenAI / Mock.
- [`requirements.txt`](https://github.com/mail2raji/python-genai-agentic-handbook/blob/main/PythonGenAI_Learning/requirements.txt) — pinned dependencies.
- [`.env.example`](https://github.com/mail2raji/python-genai-agentic-handbook/blob/main/PythonGenAI_Learning/.env.example) — copy to `.env` and fill in your keys.

---

## 📜 License & contributions

This handbook is shared for learning. Contributions and corrections welcome via Pull Request.

---

**▶️ Ready? Open** [`QUICKSTART.md`](QUICKSTART.md) **first, then** [`LAB_MENU.md`](LAB_MENU.md).

