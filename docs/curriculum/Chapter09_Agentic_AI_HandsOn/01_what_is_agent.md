# Lesson 1: What is an Agent?

## 🤖 Plain-English definition

> An **agent** is an LLM that decides what to do, takes actions, observes the result, and repeats — until a goal is met.

A pure LLM **talks**. An agent **does things**.

---

## 🎯 The 4 pillars of any agent

| Pillar | What it is | Example |
|---|---|---|
| **Brain** (LLM) | Makes decisions, plans, reasons | GPT-4o |
| **Tools** | Things it can call | `search_web()`, `send_email()`, `query_db()` |
| **Memory** | What it remembers | Last 10 messages, vector store |
| **Loop** | Repeats think→act→observe | Until goal done or step limit hit |

---

## 🆚 LLM vs Agent

| | LLM call | Agent |
|---|---|---|
| Input | A prompt | A goal |
| Output | Text | Actions + final answer |
| State | Stateless | Maintains state |
| Side effects | None | Can change the world |
| Example | "Summarize this email" | "Triage this ticket: search the KB, create a Jira issue, email the user" |

---

## 🧩 Patterns you'll learn

1. **Tool-using agent** — pick from a toolbox.
2. **ReAct** (Reason + Act) — interleave thinking and acting.
3. **Planner-Executor** — one LLM plans, another executes steps.
4. **Multi-agent** — specialists collaborate (researcher → writer → critic).
5. **Hierarchical** — manager agent delegates to worker agents.

---

## ⚠️ Real-world risks (we'll handle each)

- **Loops** → cap max steps
- **Cost explosion** → token & call limits
- **Hallucinated tool args** → strict schema validation
- **Unsafe actions** → human-in-the-loop for destructive ops
- **Prompt injection** → delimit untrusted content

Continue to `02_function_calling.py`.

