# 🎓 GenAI & Agentic AI — Beginner to Advanced Handbook

> **Who is this for?** A complete beginner with **zero** prior knowledge of AI, LangChain, agents, or Git — but who is willing to type code and run exercises.
>
> **Promise:** By the end you will be able to (1) version code with Git + GitHub, (2) ship CI/CD with GitHub Actions, (3) pair with GitHub Copilot at every layer, (4) talk to LLMs from Python, (5) build a RAG pipeline over your own documents, (6) build single and multi-agent systems with LangChain / LangGraph / CrewAI, and (7) ship a production agent to Kubernetes — with GHAS security on top.

!!! success "📦 One repo, one continuous flow — 23 chapters in six stages"
    Everything — Python, GenAI, Agents, **and** Git/GitHub/Copilot/GHAS — lives in **one** repository as **one** numbered curriculum: **[mail2raji/genai-agentic-ai-handbook](https://github.com/mail2raji/genai-agentic-ai-handbook)**.

    No more juggling "Part I phase X" vs "Part II module Y" — just **Chapter 1 → Chapter 23**. Read it cover-to-cover, or jump to any chapter and the table-of-contents shows you exactly where you are in the journey.

    `git clone https://github.com/mail2raji/genai-agentic-ai-handbook.git` gives you the whole library — code samples, exercises, capstones, the MkDocs source for this site, and the workflows that build it.

---

## 🗺️ The one-flow curriculum — 23 chapters in six stages

Read top-to-bottom. Each chapter is self-contained but assumes the previous one.

| # | Stage | Chapter | What you'll learn / build |
|---:|---|---|---|
| | **🐍 Stage A — Python foundations** | | *Get fluent in the language we'll use for everything.* |
| 1 | A | **[Python Fundamentals](PartI_HandsOn/Phase1_Python_Fundamentals/00_START_HERE.md)** | Variables, lists, dicts, conditionals, loops, functions, files — + **Log Analyzer** mini-project. |
| 2 | A | **[Intermediate Python](PartI_HandsOn/Phase2_Intermediate_Python/00_START_HERE.md)** | Modules, `venv`+pip, errors, classes, type hints, `requests`, async, secrets — + **Weather Chatbot**. |
| 3 | A | **[Python for AI & Data](PartI_HandsOn/Phase3_Python_for_AI/00_START_HERE.md)** | NumPy, Pandas, cosine similarity, tokenisation — + **CSV Analyst**. |
| 4 | A | **[Python for GenAI · deep dive](Module2_Python_for_GenAI/01_Intro_to_Python.md)** | Files + databases, APIs, calling LLMs end-to-end — + **Invoice → Insights** advanced lab. |
| | **🤖 Stage B — GenAI core** | | *From "what is a token?" to running real RAG.* |
| 5 | B | **[GenAI Fundamentals · hands-on](PartI_HandsOn/Phase4_GenAI_Fundamentals/00_START_HERE.md)** | LLMs, prompts, structured outputs, streaming, embeddings, RAG from scratch — + **Doc Q&A** mini-project. |
| 6 | B | **[GenAI Foundations · deep dive](Module1_GenAI_Foundations/01_Introduction_to_GenAI.md)** | The vocabulary everyone uses: prompts, fine-tuning, RAG, agents — + **Support Triage Assistant** lab. |
| 7 | B | **[LangChain Core](Module3_LangChain/01_Introduction_to_LangChain.md)** | LCEL, runnables, I/O management, prompt engineering with LangChain — + **Onboarding Wizard** lab. |
| | **🔍 Stage C — RAG** | | *Make AI answer from **your** data.* |
| 8 | C | **[RAG Systems & Frameworks](Module4_RAG_and_Frameworks/01_RAG_System_Essentials.md)** | RAG essentials, LangChain vs LangGraph vs CrewAI — + **Legal RAG with Reranker** lab. |
| | **🧠 Stage D — Agentic AI** | | *Make AI do things, not just answer.* |
| 9 | D | **[Agentic AI · hands-on](PartI_HandsOn/Phase5_Agentic_AI/00_START_HERE.md)** | Function calling, ReAct, memory, guardrails, multi-agent, LangGraph — + **IT Triage Agent**. |
| 10 | D | **[Agentic AI Patterns · deep dive](Module5_Agentic_AI/01_Agentic_Design_Patterns.md)** | Reflection, tool use, planning, multi-agent crews — + **Engineering Crew** capstone lab. |
| 11 | D | **[Capstone Projects (IT-ops)](PartI_HandsOn/Phase6_Capstone_Projects/00_START_HERE.md)** | 3 full projects: SPN renewal concierge • PowerShell doc buddy • Incident reporter. |
| | **🚀 Stage E — Production** | | *Take an agent from notebook to Kubernetes.* |
| 12 | E | **[Production Agents](PartI_HandsOn/Phase7_Production_Agents/00_START_HERE.md)** | MCP, evaluation, observability, failure modes, architecture, AKS deploy — + **Production SPN Agent**. |
| | **🛠️ Stage F — Git / GitHub / Copilot / Security** | | *The professional toolchain you'll use forever.* |
| 13 | F | **[GitHub Setup](PartI_HandsOn/Phase8_GitHub_Setup/index.md)** | Account, SSH keys, `gh` CLI, identity. |
| 14 | F | **[Git Fundamentals · 12 labs + capstone](PartI_HandsOn/Phase9_Git_Fundamentals/exercises.md)** | init, add -p, branches, merge, conflicts, stash, amend/revert, reflog, .gitignore, tags, cherry-pick, interactive rebase. |
| 15 | F | **[GitHub Basics · 12 labs + capstone](PartI_HandsOn/Phase10_GitHub_Basics/exercises.md)** | PRs, reviews, issue forms, releases, projects v2, branch protection, CODEOWNERS, forks, discussions, labels, linking. |
| 16 | F | **[Intermediate Git](PartI_HandsOn/Phase11_Intermediate_Git/index.md)** | Rebase, bisect, worktrees, submodules, partial clones. |
| 17 | F | **[GitHub Actions](PartI_HandsOn/Phase12_GitHub_Actions/index.md)** | YAML, triggers, matrix builds, secrets, reusable workflows. |
| 18 | F | **[Copilot + GenAI](PartI_HandsOn/Phase13_Copilot_GenAI/index.md)** | Pair-programming, prompting Copilot, custom instructions. |
| 19 | F | **[Copilot CLI](PartI_HandsOn/Phase14_Copilot_CLI/index.md)** | Terminal-first AI coding. |
| 20 | F | **[Agentic AI with Copilot](PartI_HandsOn/Phase15_Agentic_AI_Copilot/index.md)** | Copilot in agent mode + tools + MCP. |
| 21 | F | **[GHAS Admin & Security](PartI_HandsOn/Phase16_GHAS_Admin/index.md)** | Secret scanning, code scanning (CodeQL), Dependabot, security policies. |
| 22 | F | **[Exam Prep](PartI_HandsOn/Phase17_ExamPrep/index.md)** | GitHub Advanced Security certification-ready review. |
| 23 | F | **[Final Capstone](PartI_HandsOn/Phase18_Capstone/index.md)** | Bring it all together in a single production-grade project. |

> 💡 **Index of every exercise** → [Lab menu](PartI_HandsOn/LAB_MENU.md). **Setup first** → [SETUP](SETUP.md).
>
> 📥 **Prefer offline?** Each push builds a downloadable **[PDF + DOCX export](https://github.com/mail2raji/genai-agentic-ai-handbook/actions/workflows/export.yml)** of the entire book — grab the artifact from the latest workflow run.

---

## 🎯 Three honest paths through the 23 chapters

Not everyone needs to read cover-to-cover. Pick the path that matches your goal:

=== "🐍 I'm here to learn GenAI / Agentic AI"
    **Chapters 1 → 12** is the full GenAI engineering path. Add Chapters 14–15 (Git/GitHub) before Chapter 11 (capstones) so you can ship your work properly.

    Time-box: **6–8 weeks** part-time.

=== "🛠️ I'm here to master GitHub + Copilot + GHAS"
    **Chapters 13 → 23** is the full GitHub track. Skim Chapter 5 (GenAI Fundamentals) before Chapter 18 (Copilot + GenAI) so the AI parts make sense.

    Time-box: **3–4 weeks** part-time.

=== "🚀 I want both — the long path"
    Read **Chapter 1 → 23 in order**. The chapters are arranged so each one unlocks the next. You'll graduate able to ship a production AI agent **and** the CI/CD pipeline + security scans around it.

    Time-box: **3 months** part-time, **6 weeks** full-time.

---

## 🧒 How each lesson is written

Every lesson (and lab) uses **the same beats** so your brain knows what to expect:

1. **🍭 Imagine this…** — a tiny story to explain the idea (5-year-old level)
2. **🧠 The real concept** — the technical bit, in plain English
3. **🌍 Real-world scenario** — where you'd actually use it (IT support, banking, healthcare, etc.)
4. **💻 The code** — copy-paste ready, *with every line explained*
5. **🏋️ Exercises** — 3 to 5 challenges that grow in difficulty
6. **✅ Solutions** — complete, working answers with explanation

The Git/GitHub labs (Chapters 14–15) add a **🎯 Why this matters → ▶️ Annotated steps → ✅ Expected output → 🧠 Use case in the wild → ⚠️ Gotchas** beat on top — see the rich lab packs for examples.

---

## 🚀 How to use this handbook

1. **Start with [SETUP](SETUP.md)** — install Python, Git, an editor, and (optionally) get an API key.
2. **Pick a path** above (GenAI track, GitHub track, or the full 23).
3. **Type the code yourself.** Don't just copy. Your fingers learn what your eyes can't.
4. **Do every exercise** before peeking at the solution.
5. **Build one tiny project** at the end of each stage — even just a 20-line one.

---

## 🛠️ Tools we'll use

- **Python 3.10+** — the language
- **Git + GitHub CLI (`gh`)** — version control and collaboration
- **GitHub Copilot** + **Copilot CLI** — your AI pair-programmer
- **GitHub Actions** + **GHAS** — CI/CD and security scanning
- **OpenAI SDK** *or* **Azure OpenAI** — to call GPT-4o / GPT-4o-mini
- **LangChain + LangGraph** — orchestration framework
- **CrewAI** — multi-agent framework
- **ChromaDB / FAISS** — vector databases for RAG
- **VS Code** — your IDE

---

## 💸 Will this cost money?

- LLM API calls cost cents. A whole chapter rarely costs more than **$1**.
- You can swap in **free local models** (Ollama + Llama 3) — instructions are in [SETUP](SETUP.md).
- All Git/GitHub/Actions/Copilot Free-tier features work; GHAS features require a public repo (free) or a paid org.

---

## 🏁 Where to go after Chapter 23

- Build a **portfolio project** (e.g., *"Personal finance Q&A agent over my bank statements"*).
- Add **evaluation** (Ragas, DeepEval) and **observability** (LangSmith, Langfuse).
- Explore production deployment on **Azure AI Foundry** or **AWS Bedrock**.
- Earn the **GitHub Advanced Security** certification — Chapter 22 prepares you.

---

Happy learning! 🎉 Open **[SETUP](SETUP.md)** to begin, or jump straight into **[Chapter 1 — Hello World](PartI_HandsOn/Phase1_Python_Fundamentals/01_hello_world.md)**.
