# 📖 Curriculum overview — the 23-chapter single flow

> *A hands-on book that takes you from your first line of Python to a production-ready agent on Kubernetes — and the GitHub + Copilot + GHAS toolchain you'll use to ship it.*

This is the **table of contents** for the entire curriculum.
Every chapter is a clickable lesson set with concept → analogy → annotated code → exercises → solutions.

When you're ready to **do** rather than read, jump to **[`LAB_MENU.md`](LAB_MENU.md)** — every hands-on exercise in the book, in one checklist.

---

## How to use this overview

1. **Set up once** (5 minutes) — follow [`QUICKSTART.md`](QUICKSTART.md).
2. **Pick a stage** below (A through F), then read the chapters in order.
3. After each chapter, do its corresponding lab in [`LAB_MENU.md`](LAB_MENU.md).
4. Tick the box ✅. Move on to the next chapter.

> 💡 Most Python lessons run **offline** in `MOCK_MODE=1` — no API key required.
> Add a real OpenAI / Azure OpenAI key in `.env` only when you want real-LLM output.

---

## 🗺️ The 23-chapter flow at a glance

| # | Stage | Chapter | One-line outcome |
|---:|---|---|---|
| | **🐍 Stage A — Python foundations** | | |
| 1 | A | [Python Fundamentals](Phase1_Python_Fundamentals/00_START_HERE.md) | Variables → loops → functions → files (+ Log Analyzer). |
| 2 | A | [Intermediate Python](Phase2_Intermediate_Python/00_START_HERE.md) | Modules, classes, type hints, async, secrets (+ Weather Chatbot). |
| 3 | A | [Python for AI & Data](Phase3_Python_for_AI/00_START_HERE.md) | NumPy, Pandas, cosine sim, tokenisation (+ CSV Analyst). |
| 4 | A | [Python for GenAI · deep dive](../Module2_Python_for_GenAI/01_Intro_to_Python.md) | Files + DBs + APIs + first LLM call (+ Invoice → Insights lab). |
| | **🤖 Stage B — GenAI core** | | |
| 5 | B | [GenAI Fundamentals · hands-on](Phase4_GenAI_Fundamentals/00_START_HERE.md) | Prompts, structured outputs, streaming, embeddings, RAG (+ Doc Q&A). |
| 6 | B | [GenAI Foundations · deep dive](../Module1_GenAI_Foundations/01_Introduction_to_GenAI.md) | The vocabulary everyone uses (+ Support Triage Assistant lab). |
| 7 | B | [LangChain Core](../Module3_LangChain/01_Introduction_to_LangChain.md) | LCEL, runnables, prompts, I/O (+ Onboarding Wizard lab). |
| | **🔍 Stage C — RAG** | | |
| 8 | C | [RAG Systems & Frameworks](../Module4_RAG_and_Frameworks/01_RAG_System_Essentials.md) | LangChain vs LangGraph vs CrewAI (+ Legal RAG with Reranker). |
| | **🧠 Stage D — Agentic AI** | | |
| 9 | D | [Agentic AI · hands-on](Phase5_Agentic_AI/00_START_HERE.md) | Tools, ReAct, memory, multi-agent, LangGraph (+ IT Triage Agent). |
| 10 | D | [Agentic AI Patterns · deep dive](../Module5_Agentic_AI/01_Agentic_Design_Patterns.md) | Reflection, tool use, planning, crews (+ Engineering Crew lab). |
| 11 | D | [Capstone Projects (IT-ops)](Phase6_Capstone_Projects/00_START_HERE.md) | 3 capstones: SPN renewal • PowerShell doc buddy • Incident reporter. |
| | **🚀 Stage E — Production** | | |
| 12 | E | [Production Agents](Phase7_Production_Agents/00_START_HERE.md) | MCP, eval, observability, AKS deploy (+ Production SPN Agent). |
| | **🛠️ Stage F — Git / GitHub / Copilot / Security** | | |
| 13 | F | [GitHub Setup](Phase8_GitHub_Setup/index.md) | Account, SSH, `gh` CLI, identity. |
| 14 | F | [Git Fundamentals · 12 labs + capstone](Phase9_Git_Fundamentals/exercises.md) | init → add -p → branches → conflicts → reflog → cherry-pick → rebase. |
| 15 | F | [GitHub Basics · 12 labs + capstone](Phase10_GitHub_Basics/exercises.md) | PRs, reviews, issue forms, releases, Projects v2, CODEOWNERS, forks. |
| 16 | F | [Intermediate Git](Phase11_Intermediate_Git/index.md) | Rebase, bisect, worktrees, submodules, partial clones. |
| 17 | F | [GitHub Actions](Phase12_GitHub_Actions/index.md) | YAML, triggers, matrix, secrets, reusable workflows. |
| 18 | F | [Copilot + GenAI](Phase13_Copilot_GenAI/index.md) | Pair-programming, prompting Copilot, custom instructions. |
| 19 | F | [Copilot CLI](Phase14_Copilot_CLI/index.md) | Terminal-first AI coding. |
| 20 | F | [Agentic AI with Copilot](Phase15_Agentic_AI_Copilot/index.md) | Copilot in agent mode + tools + MCP. |
| 21 | F | [GHAS Admin & Security](Phase16_GHAS_Admin/index.md) | Secret scanning, CodeQL, Dependabot, policies. |
| 22 | F | [Exam Prep](Phase17_ExamPrep/index.md) | GitHub Advanced Security cert-ready review. |
| 23 | F | [Final Capstone](Phase18_Capstone/index.md) | Production-grade project that brings everything together. |

---

## 🐍 Stage A — Python foundations

> **Goal:** Become fluent enough in Python to confidently follow every later chapter.

### Chapter 1 — Python Fundamentals

| # | Lesson | Open |
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

### Chapter 2 — Intermediate Python

| # | Lesson | Open |
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

### Chapter 3 — Python for AI & Data

| # | Lesson | Open |
|---|---|---|
| 3.1 | NumPy | [01_numpy.py](Phase3_Python_for_AI/01_numpy.md) |
| 3.2 | Pandas | [02_pandas.py](Phase3_Python_for_AI/02_pandas.md) |
| 3.3 | Cosine Similarity | [03_cosine_similarity.py](Phase3_Python_for_AI/03_cosine_similarity.md) |
| 3.4 | Tokenization | [04_tokenization.py](Phase3_Python_for_AI/04_tokenization.md) |
| 🛠️ | Mini-Project: CSV Analyst | [mini_project_csv_analyst.py](Phase3_Python_for_AI/mini_project_csv_analyst.md) |

### Chapter 4 — Python for GenAI · deep dive

| # | Lesson | Open |
|---|---|---|
| 4.1 | Intro to Python (recap) | [01_Intro_to_Python.md](../Module2_Python_for_GenAI/01_Intro_to_Python.md) |
| 4.2 | Files & Databases | [02_Files_and_Databases.md](../Module2_Python_for_GenAI/02_Files_and_Databases.md) |
| 4.3 | Working with APIs | [03_Working_with_APIs.md](../Module2_Python_for_GenAI/03_Working_with_APIs.md) |
| 4.4 | Working with LLMs | [04_Working_with_LLMs.md](../Module2_Python_for_GenAI/04_Working_with_LLMs.md) |
| 🧪 | Advanced Lab — Invoice → Insights CLI | [99_Advanced_Lab_Invoice_Pipeline.md](../Module2_Python_for_GenAI/99_Advanced_Lab_Invoice_Pipeline.md) |

---

## 🤖 Stage B — GenAI core

> **Goal:** Understand LLMs, prompts, embeddings, and the LangChain toolkit deeply enough to compose your own pipelines.

### Chapter 5 — GenAI Fundamentals · hands-on

| # | Lesson | Open |
|---|---|---|
| 5.1 | What is an LLM? | [01_what_is_llm.md](Phase4_GenAI_Fundamentals/01_what_is_llm.md) |
| 5.2 | Your First LLM Call | [02_first_llm_call.py](Phase4_GenAI_Fundamentals/02_first_llm_call.md) |
| 5.3 | Prompt Engineering | [03_prompt_engineering.py](Phase4_GenAI_Fundamentals/03_prompt_engineering.md) |
| 5.4 | Structured Outputs (JSON) | [04_structured_outputs.py](Phase4_GenAI_Fundamentals/04_structured_outputs.md) |
| 5.5 | Streaming | [05_streaming.py](Phase4_GenAI_Fundamentals/05_streaming.md) |
| 5.6 | Embeddings | [06_embeddings.py](Phase4_GenAI_Fundamentals/06_embeddings.md) |
| 5.7 | RAG System (from scratch) | [07_rag_system.py](Phase4_GenAI_Fundamentals/07_rag_system.md) |
| 🧰 | Shared LLM Client | [llm_client.py](Phase4_GenAI_Fundamentals/llm_client.md) |
| 🛠️ | Mini-Project: Doc Q&A | [mini_project_doc_qa.py](Phase4_GenAI_Fundamentals/mini_project_doc_qa.md) |

### Chapter 6 — GenAI Foundations · deep dive

| # | Lesson | Open |
|---|---|---|
| 6.1 | Introduction to GenAI | [01_Introduction_to_GenAI.md](../Module1_GenAI_Foundations/01_Introduction_to_GenAI.md) |
| 6.2 | Prompt Engineering | [02_Prompt_Engineering.md](../Module1_GenAI_Foundations/02_Prompt_Engineering.md) |
| 6.3 | Fine-Tuning, RAG & Agents | [03_FineTuning_RAG_Agents.md](../Module1_GenAI_Foundations/03_FineTuning_RAG_Agents.md) |
| 🧪 | Advanced Lab — Support Triage Assistant | [99_Advanced_Lab_Support_Triage.md](../Module1_GenAI_Foundations/99_Advanced_Lab_Support_Triage.md) |

### Chapter 7 — LangChain Core

| # | Lesson | Open |
|---|---|---|
| 7.1 | Introduction to LangChain | [01_Introduction_to_LangChain.md](../Module3_LangChain/01_Introduction_to_LangChain.md) |
| 7.2 | LCEL Essentials | [02_LCEL_Essentials.md](../Module3_LangChain/02_LCEL_Essentials.md) |
| 7.3 | Managing LLM I/O | [03_Managing_LLM_IO.md](../Module3_LangChain/03_Managing_LLM_IO.md) |
| 7.4 | Prompt Engineering with LangChain | [04_Prompt_Engineering_with_LangChain.md](../Module3_LangChain/04_Prompt_Engineering_with_LangChain.md) |
| 🧪 | Advanced Lab — Onboarding Wizard | [99_Advanced_Lab_Onboarding_Wizard.md](../Module3_LangChain/99_Advanced_Lab_Onboarding_Wizard.md) |

---

## 🔍 Stage C — RAG

> **Goal:** Make AI answer from *your* data — and pick the right framework for the job.

### Chapter 8 — RAG Systems & Frameworks

| # | Lesson | Open |
|---|---|---|
| 8.1 | RAG System Essentials | [01_RAG_System_Essentials.md](../Module4_RAG_and_Frameworks/01_RAG_System_Essentials.md) |
| 8.2 | LangChain · LangGraph · CrewAI | [02_LangChain_LangGraph_CrewAI.md](../Module4_RAG_and_Frameworks/02_LangChain_LangGraph_CrewAI.md) |
| 🧪 | Advanced Lab — Legal RAG with Reranker | [99_Advanced_Lab_Legal_RAG.md](../Module4_RAG_and_Frameworks/99_Advanced_Lab_Legal_RAG.md) |

---

## 🧠 Stage D — Agentic AI

> **Goal:** Build LLMs that *act* — with tools, reasoning loops, memory, multi-agent teams, and real IT-ops capstones.

### Chapter 9 — Agentic AI · hands-on

| # | Lesson | Open |
|---|---|---|
| 9.1 | What is an Agent? | [01_what_is_agent.md](Phase5_Agentic_AI/01_what_is_agent.md) |
| 9.2 | Function Calling | [02_function_calling.py](Phase5_Agentic_AI/02_function_calling.md) |
| 9.3 | ReAct Agent | [03_react_agent.py](Phase5_Agentic_AI/03_react_agent.md) |
| 9.4 | Agent Memory | [04_memory.py](Phase5_Agentic_AI/04_memory.md) |
| 9.5 | Guardrails | [05_guardrails.py](Phase5_Agentic_AI/05_guardrails.md) |
| 9.6 | Multi-Agent Pipelines | [06_multi_agent.py](Phase5_Agentic_AI/06_multi_agent.md) |
| 9.7 | LangGraph Intro | [07_langgraph_intro.py](Phase5_Agentic_AI/07_langgraph_intro.md) |
| 🛠️ | Mini-Project: IT Triage Agent | [mini_project_it_triage_agent.py](Phase5_Agentic_AI/mini_project_it_triage_agent.md) |

### Chapter 10 — Agentic AI Patterns · deep dive

| # | Lesson | Open |
|---|---|---|
| 10.1 | Agentic Design Patterns | [01_Agentic_Design_Patterns.md](../Module5_Agentic_AI/01_Agentic_Design_Patterns.md) |
| 10.2 | Introduction to AI Agents | [02_Introduction_to_AI_Agents.md](../Module5_Agentic_AI/02_Introduction_to_AI_Agents.md) |
| 10.3 | Build a Reflection Agent | [03_Build_a_Reflection_Agent.md](../Module5_Agentic_AI/03_Build_a_Reflection_Agent.md) |
| 10.4 | Build a Tool-Using Agent | [04_Build_a_Tool_Using_Agent.md](../Module5_Agentic_AI/04_Build_a_Tool_Using_Agent.md) |
| 10.5 | Build a Planning Agent | [05_Build_a_Planning_Agent.md](../Module5_Agentic_AI/05_Build_a_Planning_Agent.md) |
| 10.6 | Build a Multi-Agent System | [06_Build_a_Multi_Agent_System.md](../Module5_Agentic_AI/06_Build_a_Multi_Agent_System.md) |
| 🧪 | Advanced Lab — Friday Ship Engineering Crew | [99_Advanced_Lab_Engineering_Crew.md](../Module5_Agentic_AI/99_Advanced_Lab_Engineering_Crew.md) |

### Chapter 11 — Capstone Projects (IT-ops)

| # | Capstone | Open |
|---|---|---|
| 11.1 | SPN Renewal Concierge | [capstone1_spn_renewal_concierge.py](Phase6_Capstone_Projects/capstone1_spn_renewal_concierge.md) |
| 11.2 | PowerShell Doc Buddy | [capstone2_powershell_doc_buddy.py](Phase6_Capstone_Projects/capstone2_powershell_doc_buddy.md) |
| 11.3 | Incident Reporter | [capstone3_incident_reporter.py](Phase6_Capstone_Projects/capstone3_incident_reporter.md) |

---

## 🚀 Stage E — Production

> **Goal:** Take an agent from notebook to Kubernetes — safe, observable, testable, deployable.

### Chapter 12 — Production Agents

| # | Lesson | Open |
|---|---|---|
| 12.1 | MCP — Model Context Protocol | [01_mcp.md](Phase7_Production_Agents/01_mcp.md) |
| 12.2 | MCP Server + Client | [02_mcp_server_and_client.py](Phase7_Production_Agents/02_mcp_server_and_client.md) |
| 12.3 | Production Memory (Redis + Vector) | [03_memory_production.py](Phase7_Production_Agents/03_memory_production.md) |
| 12.4 | Evaluating Agents | [04_evaluation.py](Phase7_Production_Agents/04_evaluation.md) |
| 12.5 | Observability — logs, traces, metrics | [05_observability.py](Phase7_Production_Agents/05_observability.md) |
| 12.6 | Failure Modes & Defenses | [06_failure_modes.py](Phase7_Production_Agents/06_failure_modes.md) |
| 12.7 | Production Architecture | [07_architecture.md](Phase7_Production_Agents/07_architecture.md) |
| 12.8 | Deploy LangGraph on Kubernetes | [08_deploy_langgraph_k8s.md](Phase7_Production_Agents/08_deploy_langgraph_k8s.md) |
| 🏆 | Final Capstone: Production SPN Agent | [capstone_production_agent/README.md](Phase7_Production_Agents/capstone_production_agent.md) |

---

## 🛠️ Stage F — Git / GitHub / Copilot / Security

> **Goal:** Master the professional toolchain that wraps every chapter above — version control, collaboration, automation, AI pair-programming, and security.

| # | Chapter | Open |
|---|---|---|
| 13 | GitHub Setup | [Phase8_GitHub_Setup/index.md](Phase8_GitHub_Setup/index.md) |
| 14 | Git Fundamentals (12 labs + capstone) | [Phase9_Git_Fundamentals/exercises.md](Phase9_Git_Fundamentals/exercises.md) |
| 15 | GitHub Basics (12 labs + capstone) | [Phase10_GitHub_Basics/exercises.md](Phase10_GitHub_Basics/exercises.md) |
| 16 | Intermediate Git | [Phase11_Intermediate_Git/index.md](Phase11_Intermediate_Git/index.md) |
| 17 | GitHub Actions | [Phase12_GitHub_Actions/index.md](Phase12_GitHub_Actions/index.md) |
| 18 | Copilot + GenAI | [Phase13_Copilot_GenAI/index.md](Phase13_Copilot_GenAI/index.md) |
| 19 | Copilot CLI | [Phase14_Copilot_CLI/index.md](Phase14_Copilot_CLI/index.md) |
| 20 | Agentic AI with Copilot | [Phase15_Agentic_AI_Copilot/index.md](Phase15_Agentic_AI_Copilot/index.md) |
| 21 | GHAS Admin & Security | [Phase16_GHAS_Admin/index.md](Phase16_GHAS_Admin/index.md) |
| 22 | Exam Prep | [Phase17_ExamPrep/index.md](Phase17_ExamPrep/index.md) |
| 23 | Final Capstone | [Phase18_Capstone/index.md](Phase18_Capstone/index.md) |

> Each Stage-F chapter follows the same **🎯 Why this matters → ▶️ Annotated steps → ✅ Expected output → 🧠 Use case in the wild → ⚠️ Gotchas** template. Chapters 14 and 15 ship as **12-lab + capstone** rich packs.

---

## 📝 Conventions used throughout

- 📖 **Concept** — short paragraph at the top of each `.py` or `.md` lesson
- 💡 **Analogy** — every concept tied to something you already know
- 🧪 **Run it** — every Python lesson has a runnable `if __name__ == "__main__"` block
- ✏️ **Exercise** — challenge prompt with hidden solution
- ✅ **Takeaway box** — the one thing to remember

---

## 🔁 Reading-order suggestions

- **Total beginner** → Chapters 1 → 23 in order (the full single flow).
- **Already know Python** → Skim Chapters 1–4, dive into Chapter 5 onward.
- **Already know GenAI** → Start at Chapter 9 (Agentic) or Chapter 12 (Production).
- **DevOps / SRE focus** → Chapter 12 + Stage F (Chapters 13–23) is a complete "ship it" guide.
- **GitHub Advanced Security cert** → Stage F end-to-end, especially Chapters 21–22.

---

## 🧰 Toolbox shared across the book

- [`llm_client.py`](Phase4_GenAI_Fundamentals/llm_client.md) — the one LLM client used everywhere. Auto-switches between OpenAI / Azure OpenAI / Mock.
- [`requirements.txt`](https://github.com/mail2raji/genai-agentic-ai-handbook/blob/main/PythonGenAI_Learning/requirements.txt) — pinned dependencies.
- [`.env.example`](https://github.com/mail2raji/genai-agentic-ai-handbook/blob/main/PythonGenAI_Learning/.env.example) — copy to `.env` and fill in your keys.

---

## 📜 License & contributions

This handbook is shared for learning. Contributions and corrections welcome via Pull Request.

---

**▶️ Ready? Open** [`QUICKSTART.md`](QUICKSTART.md) **first, then** [`LAB_MENU.md`](LAB_MENU.md), then start at **[Chapter 1 — Python Fundamentals](Phase1_Python_Fundamentals/00_START_HERE.md)**.
