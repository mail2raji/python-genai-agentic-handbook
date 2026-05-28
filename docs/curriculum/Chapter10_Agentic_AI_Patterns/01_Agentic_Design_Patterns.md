# Module 5 · Lesson 1 — Introduction to Agentic Design Patterns

## 🍭 Imagine this…

You have a brilliant intern. You can ask them to do work in **different styles**:

1. *"Write the report, then critique your own work and rewrite it."* → **Reflection**
2. *"Use Excel and the internet to find the answer."* → **Tool use**
3. *"Break the job into a plan and execute step by step."* → **Planning**
4. *"Form a team — researcher, writer, editor — and divide the work."* → **Multi-agent**

These four styles are the **four classic agentic design patterns** (popularised by Andrew Ng in 2024). Every modern agent uses one or more of them.

---

## 🧠 The real concept

| Pattern | One-liner | When |
|---|---|---|
| **Reflection** | Agent grades and rewrites its own output | Writing, code, summaries |
| **Tool use** | Agent calls external functions / APIs | Search, math, DB, send email |
| **Planning** | Agent first creates a step-by-step plan, then executes | Multi-step tasks ("plan my trip") |
| **Multi-agent** | Many specialised agents collaborate | Newsroom, software team |

In real life you **combine** them: e.g. a planning agent that uses tools and reflects after each step.

### Why agentic patterns at all?
A single LLM call is a "1-shot fish". An agent is a **fishing trawler** — it loops, reasons, calls APIs, checks its work. Quality often jumps from "decent" to "production-grade" with the right pattern.

---

## 🌍 Real-world scenarios (one per pattern)

| Pattern | Scenario |
|---|---|
| Reflection | A blog draft → self-critique → improved final |
| Tool use | "What's the weather in Tokyo & convert ¥ to ₹" |
| Planning | "Plan a 10-day Europe trip under €3000" |
| Multi-agent | A software-engineering team: PM → Coder → Reviewer → Tester |

You'll build **one tiny agent for each pattern** in the next lessons.

---

## 💻 A 30-line preview of all four

```python
# ⚠️ Conceptual — full code in Lessons 3-6
from openai import OpenAI
client = OpenAI()

def llm(msg, temp=0):
    return client.chat.completions.create(
        model="gpt-4o-mini", temperature=temp,
        messages=[{"role": "user", "content": msg}],
    ).choices[0].message.content

# 1. REFLECTION
def reflect_and_rewrite(task):
    draft = llm(f"Do this task: {task}")
    critique = llm(f"Critique this draft in 3 bullets:\n{draft}")
    return llm(f"Rewrite considering this critique:\n\nDraft:\n{draft}\n\nCritique:\n{critique}")

# 2. TOOL USE  (toy)
def tool_use(query):
    if "weather" in query.lower():
        return f"It's 22°C in Tokyo."        # pretend API call
    return llm(query)

# 3. PLANNING
def plan_and_execute(goal):
    plan = llm(f"Break this into 5 short steps:\n{goal}")
    results = [llm(f"Do step: {s}") for s in plan.split("\n") if s.strip()]
    return "\n".join(results)

# 4. MULTI-AGENT  (toy)
def newsroom(topic):
    facts  = llm(f"As researcher, list 5 facts about: {topic}")
    draft  = llm(f"As writer, write 200 words using:\n{facts}")
    final  = llm(f"As editor, polish this:\n{draft}")
    return final
```

Each lesson 3–6 will turn one of these stubs into a robust, tool-using, error-handled agent.

---

## 🧠 Design checklist for any agent

| Question | Why |
|---|---|
| **Goal** — what does success look like? | Without it the agent loops forever. |
| **State** — what does it remember between steps? | Drives memory design. |
| **Tools** — what external systems can it touch? | Define inputs/outputs carefully. |
| **Stop conditions** — when does it halt? | "Goal met", "N tries", "human approval". |
| **Safety** — what should it NEVER do? | Sandbox, allow-lists, human-in-the-loop. |
| **Observability** — how do you debug? | LangSmith traces, logs. |
| **Eval** — how do you know it's good? | Golden tasks + automated checks. |

Print this and stick it on your monitor.

---

## 🏋️ Exercises

### Exercise 1 — Spot the pattern
For each app, name the dominant pattern:
1. GitHub Copilot's "Edit & Review" panel.
2. Cursor's "agent mode" that reads a repo and writes code in many files.
3. ChatGPT browsing the web for a question.
4. A "research squad" tool with personas writing a market report.

### Exercise 2 — Tweak the 30-line preview
Run `reflect_and_rewrite("Write a haiku about Mondays")`. Print all three versions.

### Exercise 3 — Sketch your own agent
Pick a problem you face every week and fill out the design checklist above for it.

### Exercise 4 — Risk audit
For an HR agent that can READ employee emails and SCHEDULE meetings, list 3 risks and 3 mitigations.

---

## ✅ Solutions

### Solution 1
1. **Reflection** (drafts + reviews edits).
2. **Planning + Tool use + Multi-agent** (it plans, edits files, runs tests).
3. **Tool use** (browser is the tool).
4. **Multi-agent**.

### Solution 2
```python
draft    = llm("Write a haiku about Mondays")
critique = llm(f"Critique in 3 bullets:\n{draft}")
final    = llm(f"Rewrite using critique:\n\nDraft:\n{draft}\n\nCritique:\n{critique}")
for label, t in [("draft", draft), ("critique", critique), ("final", final)]:
    print(f"\n=== {label} ===\n{t}")
```

### Solution 3
Example for a "weekly status email" agent:
- **Goal**: send a personalised status email to my manager every Friday.
- **State**: this week's commits + Jira tickets + notes.
- **Tools**: GitHub API, Jira API, mailer, calendar.
- **Stop**: email sent, or asks me for clarification.
- **Safety**: requires my approval before send; never read DMs.
- **Observability**: log every prompt & tool call.
- **Eval**: weekly thumbs-up/down + manager survey.

### Solution 4
**Risks**
1. Schedules meeting with wrong person from email confusion.
2. Leaks private email content into prompts.
3. Sends to external addresses by mistake.

**Mitigations**
1. Confirm participants with user before sending invite.
2. Strip PII; never log raw email bodies; pin context window narrow.
3. Allow-list of domains; require human-in-the-loop for first sends.

---

## 🎯 What you should now be able to do

- [x] Name the 4 agentic patterns
- [x] Pick which pattern fits a problem
- [x] Fill the design checklist for a new agent idea

➡️ Next: **[Lesson 2 — Introduction to AI Agents](02_Introduction_to_AI_Agents.md)**
