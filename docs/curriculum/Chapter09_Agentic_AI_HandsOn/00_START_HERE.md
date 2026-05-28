# Phase 5 — Agentic AI

**Goal:** Build LLM-powered agents that can **decide**, **call tools**, and **collaborate**.

## 🤖 What is an Agent?

An **agent** is an LLM that, given a goal, can:
1. **Reason** about what to do next
2. **Choose & call tools** (Python functions, APIs, databases)
3. **Observe the result** and update its plan
4. **Loop** until the goal is reached

```
USER GOAL
   ↓
[LLM: think]  ←──┐
   ↓             │
[LLM: pick tool] │
   ↓             │ (observe and continue)
[tool runs]      │
   ↓             │
[result]  ───────┘
   ↓
[LLM: final answer]
```

## 📦 Install
```powershell
pip install openai pydantic
# Later lessons (optional):
pip install langchain langgraph crewai
```

## 📚 Lessons

| # | Lesson | File |
|---|--------|------|
| 1 | What is an agent? | `01_what_is_agent.md` |
| 2 | Function calling (the agent's hands) | `02_function_calling.py` |
| 3 | The ReAct loop (think → act → observe) | `03_react_agent.py` |
| 4 | Memory: short-term & long-term | `04_memory.py` |
| 5 | Safety, guardrails & cost limits | `05_guardrails.py` |
| 6 | Multi-agent collaboration | `06_multi_agent.py` |
| 7 | Using LangGraph (framework intro) | `07_langgraph_intro.py` |

## 🏆 Mini-project
**`mini_project_it_triage_agent.py`** — An agent that triages IT tickets, searches a KB, and decides whether to escalate or auto-resolve.

