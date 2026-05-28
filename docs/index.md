# 🎓 GenAI & Agentic AI — Beginner to Advanced Curriculum

> **Who is this for?** A complete beginner with **zero** prior knowledge of AI, LangChain, or agents — but who is willing to type code and run exercises.
>
> **Promise:** By the end you will be able to (1) talk to LLMs from Python, (2) build a RAG pipeline over your own documents, (3) build single and multi-agent systems with LangChain/LangGraph/CrewAI, and (4) ship a production agent to Kubernetes.

---

## 📚 The book has **two tracks** — pick the one that fits how you learn

| Track | Best for | Format |
|---|---|---|
| **[Part I — Concept Curriculum](Module1_GenAI_Foundations/01_Introduction_to_GenAI.md)** | "Teach me the ideas with worked examples + advanced labs" | 5 Modules → 19 lessons + 5 Advanced Labs |
| **[Part II — Hands-On Code Lessons](PartII_HandsOn/index.md)** | "Drop me into runnable `.py` files I can execute today" | 7 Phases → ~45 runnable lessons + 4 capstones + production track |

You can read them in any order. Many people skim Part I first for the vocabulary, then live inside Part II.

---

## 🗺️ Part I — The 5-Module Concept Roadmap

| Module | What you learn | Why it matters | Time |
|---|---|---|---|
| **1. GenAI Foundations** | What LLMs are, prompts, fine-tuning, RAG, agents | The vocabulary everyone uses | 1 week |
| **2. Python for GenAI** | Python basics, files/DBs, APIs, calling LLMs | Without Python you can't build | 2 weeks |
| **3. LangChain Core** | LangChain, LCEL, prompts, I/O | The most-used GenAI framework | 1 week |
| **4. RAG & Frameworks** | RAG pipelines, LangChain vs LangGraph vs CrewAI | Make AI use *your* data | 1 week |
| **5. Agentic AI** | Design patterns + 4 agents you build from scratch | The frontier of AI in 2026 | 2 weeks |

### 🧪 Advanced Labs (one per module)

Every module ends with a **production-flavoured capstone lab** built around a real-world scenario. These are the labs you can actually put in your portfolio.

| Lab | Scenario | What you build |
|---|---|---|
| [M1 — Support Triage Assistant](Module1_GenAI_Foundations/99_Advanced_Lab_Support_Triage.md) | NimbusCloud (SaaS) drowning in tickets | Schema-first JSON triage + audit pass + human-review queue |
| [M2 — Invoice → Insights CLI](Module2_Python_for_GenAI/99_Advanced_Lab_Invoice_Pipeline.md) | PixelLatte CFO needs monthly expense report | 6-stage pipeline: PDF/CSV → SQLite → FX → LLM enrichment → CFO Markdown |
| [M3 — Onboarding Wizard](Module3_LangChain/99_Advanced_Lab_Onboarding_Wizard.md) | AuroraBank HR onboards in 12 countries | LCEL chain with extract → route → parallel plan/video → memory chat |
| [M4 — Legal RAG with Reranker](Module4_RAG_and_Frameworks/99_Advanced_Lab_Legal_RAG.md) | OrbitLegal reviews 200 NDAs/month | Clause-aware chunking + hybrid BM25/vector + cross-encoder + citations |
| [M5 — Friday Ship Engineering Crew](Module5_Agentic_AI/99_Advanced_Lab_Engineering_Crew.md) | NovaDB CEO demands a tool by Monday | 5-agent crew (PM/Architect/Coder/Tester/Reviewer) with RAG + reflection |

---

## 🛠️ Part II — The 7-Phase Hands-On Roadmap

Every lesson is a **runnable `.py` file** with concept → analogy → example → exercise → solution. Most run **offline** in `MOCK_MODE=1` so no API key is needed to start.

| Part | Phase | Theme | Lessons | Project |
|---|---|---|---|---|
| **I** | [Phase 1](PartII_HandsOn/Phase1_Python_Fundamentals/00_START_HERE.md) | Python Fundamentals | 10 | Log Analyzer |
| **II** | [Phase 2](PartII_HandsOn/Phase2_Intermediate_Python/00_START_HERE.md) | Intermediate Python | 8 | Weather Chatbot |
| **III** | [Phase 3](PartII_HandsOn/Phase3_Python_for_AI/00_START_HERE.md) | Python for AI & Data | 4 | CSV Analyst |
| **IV** | [Phase 4](PartII_HandsOn/Phase4_GenAI_Fundamentals/00_START_HERE.md) | GenAI Fundamentals | 7 | Doc Q&A (RAG) |
| **V** | [Phase 5](PartII_HandsOn/Phase5_Agentic_AI/00_START_HERE.md) | Agentic AI | 7 | IT Triage Agent |
| **VI** | [Phase 6](PartII_HandsOn/Phase6_Capstone_Projects/00_START_HERE.md) | Capstone Projects | — | 3 IT-ops capstones |
| **VII** | [Phase 7](PartII_HandsOn/Phase7_Production_Agents/00_START_HERE.md) | Production Agents | 8 | SPN Renewal Agent (FastAPI + K8s) |

> 💡 Jump to the full **[hands-on lab menu](PartII_HandsOn/LAB_MENU.md)** — every exercise in one checklist.

---

## 🧒 How each lesson is written

Every lesson uses **the same 6 sections** so your brain knows what to expect:

1. **🍭 Imagine this…** — a tiny story to explain the idea (5-year-old level)
2. **🧠 The real concept** — the technical bit, in plain English
3. **🌍 Real-world scenario** — where you'd actually use it (IT support, banking, healthcare, etc.)
4. **💻 The code** — copy-paste ready, *with every line explained*
5. **🏋️ Exercises** — 3 to 5 challenges that grow in difficulty
6. **✅ Solutions** — complete, working answers with explanation

---

## 🚀 How to use this curriculum

1. **Start with [SETUP](SETUP.md)** — install Python and get an API key.
2. **Read in order.** Each module assumes the previous ones.
3. **Type the code yourself.** Don't just copy. Your fingers learn what your eyes can't.
4. **Do every exercise** before peeking at the solution.
5. **Build a tiny project** at the end of each module — even just a 20-line one.

---

## 🛠️ Tools we'll use

- **Python 3.10+** — the language
- **OpenAI SDK** *or* **Azure OpenAI** — to call GPT-4o / GPT-4o-mini
- **LangChain + LangGraph** — orchestration framework
- **CrewAI** — multi-agent framework
- **ChromaDB / FAISS** — vector databases for RAG
- **VS Code** + **GitHub Copilot** — your IDE + AI pair-programmer

---

## 💸 Will this cost money?

- LLM API calls cost cents. A whole module rarely costs more than **$1**.
- You can swap in **free local models** (Ollama + Llama 3) — instructions are in [SETUP](SETUP.md).

---

## 🏁 Where to go next

When you finish all 5 modules:

- Build a portfolio project (e.g., *"Personal finance Q&A agent over my bank statements"*).
- Learn **evaluation** (Ragas, DeepEval) and **observability** (LangSmith, Langfuse).
- Explore production deployment on **Azure AI Foundry** or **AWS Bedrock**.

---

Happy learning! 🎉 Open **[SETUP](SETUP.md)** to begin, or jump straight into **[Module 1 — Introduction to GenAI](Module1_GenAI_Foundations/01_Introduction_to_GenAI.md)**.
