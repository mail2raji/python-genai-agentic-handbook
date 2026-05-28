# Module 5 · Lesson 3 — Build a Reflection Agent from scratch

## 🍭 Imagine this…

You wrote an essay at 11 pm. You re-read it next morning, find typos and weak arguments, and rewrite it. The second draft is better. **That self-review-and-rewrite loop is reflection.**

A **Reflection Agent** makes the LLM **its own editor**.

---

## 🧠 The real concept

Two roles in one agent:

| Role | Job | Prompt vibe |
|---|---|---|
| **Generator** | Produce the work | "You are a senior writer. Write …" |
| **Reflector** | Critique it | "You are a strict editor. Find 3 weaknesses." |

Loop until reflector says **OK** *or* you hit a max-iterations cap.

```
Goal → Generator → Reflector → "OK"? ──Yes──► Done
                       │
                       └──No──► Generator (using feedback)
```

### When reflection wins
- **Writing** (essays, emails, blog posts).
- **Code** ("write Python, then review for bugs, then rewrite").
- **Reasoning** chains where the first attempt is often wrong.
- **Long-form summaries** where coverage matters.

Reflection routinely adds **20–40%** quality without changing the model.

---

## 🌍 Real-world scenario — Self-improving Python function generator

You ask the agent: *"Write a Python function that checks if a string is a valid IPv4 address."*

The generator writes code. The reflector checks: edge cases? type-safe? handles "256.0.0.1"? leading zeros? Returns a critique. Generator rewrites. Repeat ≤ 3 times.

---

## 💻 The code — reflection agent in LangGraph

```python
# reflection_agent.py
from typing import TypedDict, Annotated
from operator import add
from langgraph.graph import StateGraph, START, END
from langchain_openai import ChatOpenAI
from langchain_core.messages import SystemMessage, HumanMessage, AIMessage
from dotenv import load_dotenv

load_dotenv()
llm = ChatOpenAI(model="gpt-4o-mini", temperature=0.2)

# ──────────────────────────────────────────────────────────
# 1️⃣  Shared State
# ──────────────────────────────────────────────────────────
class ReflectState(TypedDict):
    task: str
    draft: str
    critique: str
    history: Annotated[list[str], add]      # all drafts, for debug
    iterations: Annotated[int, add]

GENERATOR_SYS = (
    "You are a senior Python developer. "
    "Write CLEAN code that solves the task. Return ONLY the code, no commentary. "
    "If you receive an editor critique, address every point in your rewrite."
)

REFLECTOR_SYS = (
    "You are a STRICT code reviewer. Look for bugs, missing edge cases, "
    "type safety, security, and readability. "
    "If the code is acceptable, reply EXACTLY with 'OK'. "
    "Otherwise list concrete fixes as a bullet list."
)

# ──────────────────────────────────────────────────────────
# 2️⃣  Nodes
# ──────────────────────────────────────────────────────────
def generator(state: ReflectState) -> dict:
    msgs = [SystemMessage(content=GENERATOR_SYS),
            HumanMessage(content=f"Task: {state['task']}")]
    if state.get("critique") and state["critique"].strip().upper() != "OK":
        msgs.append(HumanMessage(content=f"Editor critique:\n{state['critique']}\n"
                                         f"Previous draft:\n{state['draft']}\n"
                                         f"Rewrite addressing every point."))
    draft = llm.invoke(msgs).content
    return {"draft": draft,
            "history": [draft],
            "iterations": 1}

def reflector(state: ReflectState) -> dict:
    review = llm.invoke([
        SystemMessage(content=REFLECTOR_SYS),
        HumanMessage(content=f"Task: {state['task']}\n\nCode:\n{state['draft']}"),
    ]).content
    return {"critique": review}

# ──────────────────────────────────────────────────────────
# 3️⃣  Decision
# ──────────────────────────────────────────────────────────
MAX_ITERS = 3
def should_continue(state: ReflectState):
    if state["iterations"] >= MAX_ITERS:
        return END
    if state["critique"].strip().upper().startswith("OK"):
        return END
    return "generator"

# ──────────────────────────────────────────────────────────
# 4️⃣  Build & run
# ──────────────────────────────────────────────────────────
graph = StateGraph(ReflectState)
graph.add_node("generator", generator)
graph.add_node("reflector", reflector)
graph.add_edge(START, "generator")
graph.add_edge("generator", "reflector")
graph.add_conditional_edges("reflector", should_continue)

app = graph.compile()

result = app.invoke({
    "task": "Write a Python function `is_valid_ipv4(s)` that returns True/False. "
            "Handle leading zeros, out-of-range octets, non-numeric, and edge cases.",
    "iterations": 0,
})

print("=" * 60)
print("FINAL CODE\n")
print(result["draft"])
print("\nIterations:", result["iterations"])
print("\nLast critique:", result["critique"][:300])
```

### Toddler walkthrough
1. `generator` writes the code (and on subsequent calls includes the editor's notes).
2. `reflector` reads the code and writes either `OK` or a fix-list.
3. `should_continue` decides: stop on `OK` or after 3 rounds, otherwise back to the generator.
4. `app.invoke(...)` runs the loop. You get the final code + how many rounds were needed.

---

## 🧠 Anatomy of a *good* reflection prompt

Bad: *"Is this good?"* → the LLM says "yes" 90% of the time.

Good — **make the reflector adversarial** and *specific*:
- "You are a STRICT reviewer. By default, find at least 3 issues."
- Mention concrete concerns: bugs, edge cases, security, performance, readability.
- Require either `OK` or **concrete** bullets (not "could be better").

You can also separate "code reviewer" from "security reviewer" and run both in parallel.

---

## 🧠 Variant — Reflection over text (blog editor)

Swap the system prompts:

```python
GENERATOR_SYS = "You are a senior tech blogger. Write a 250-word post."
REFLECTOR_SYS = ("You are a magazine editor. Critique on (1) hook, (2) clarity, "
                 "(3) flow, (4) call-to-action. Reply 'OK' if all are good.")
```

Same graph. Different domain. **Reflection generalises.**

---

## 🧠 Cost-aware reflection

Reflection multiplies LLM calls by ~2–3×. To control cost:
- Use a **cheaper model** for the reflector (e.g. gpt-4o-mini reviewing gpt-4o output).
- Cap iterations at 2–3.
- Skip reflection on simple tasks (route via a `RunnableBranch`).

---

## 🏋️ Exercises

### Exercise 1 — Reflection over an email
Replace the system prompts to generate and refine a **3-sentence apology email** to a customer whose package was lost.

### Exercise 2 — Force a minimum number of issues
Change the reflector prompt so that on iteration 1 it MUST give 3 issues, on iteration 2 it MUST give 2, etc.

### Exercise 3 — Add automated tests
For code tasks, run the model output through Python's `compile()` to ensure it parses. If it fails, automatically feed the syntax error as a critique.

### Exercise 4 — Two-reviewer panel
Add a second `security_reviewer` node that critiques only for security issues. Merge both critiques before regeneration.

### Exercise 5 — A/B benchmark
Pick 5 coding tasks. Run a 1-shot LLM and the reflection agent. Score correctness with `compile()` and a manual eyeball score.

---

## ✅ Solutions

### Solution 1
```python
GENERATOR_SYS = ("You are a senior customer-care writer. "
                 "Write a 3-sentence apology email. Tone: warm, concrete, professional.")
REFLECTOR_SYS = ("You are a head of customer care. "
                 "Critique on warmth, concreteness, and accountability. "
                 "Reply 'OK' if all good.")

result = app.invoke({"task": "Customer's package was lost. Offer a 20% refund.",
                     "iterations": 0})
```

### Solution 2
```python
def reflector(state):
    n_required = max(3 - state["iterations"], 0)
    sys = (REFLECTOR_SYS +
           (f" You MUST list at least {n_required} issues this round." if n_required > 0
            else " If everything is fine, reply 'OK'."))
    review = llm.invoke([SystemMessage(content=sys),
                         HumanMessage(content=f"Task: {state['task']}\nCode:\n{state['draft']}")]).content
    return {"critique": review}
```

### Solution 3
```python
def compile_check(state):
    try:
        compile(state["draft"], "<draft>", "exec")
        return {}                       # no extra critique
    except SyntaxError as e:
        return {"critique": f"Syntax error: {e}"}
# Add `compile_check` node after generator, before reflector.
```

### Solution 4
```python
SEC_SYS = "You are an OWASP security reviewer. Only list security issues. 'OK' if none."
def security_reviewer(state):
    review = llm.invoke([SystemMessage(content=SEC_SYS),
                         HumanMessage(content=state['draft'])]).content
    merged = state["critique"] + "\n--- Security ---\n" + review
    return {"critique": merged}

graph.add_node("security", security_reviewer)
graph.add_edge("generator", "reflector")
graph.add_edge("reflector", "security")
graph.add_conditional_edges("security", should_continue)
```

### Solution 5
```python
tasks = [
    "Reverse a linked list in Python.",
    "Implement quicksort.",
    "Validate an email with regex.",
    "Read a CSV and return rows where age > 30.",
    "Find the kth largest element.",
]
def one_shot(task):
    return llm.invoke([SystemMessage(content=GENERATOR_SYS),
                       HumanMessage(content=task)]).content

for t in tasks:
    a = one_shot(t)
    b = app.invoke({"task": t, "iterations": 0})["draft"]
    ok_a = ok_b = True
    try: compile(a, "<a>", "exec")
    except: ok_a = False
    try: compile(b, "<b>", "exec")
    except: ok_b = False
    print(t[:30], "| 1-shot OK:", ok_a, "| reflect OK:", ok_b)
```

---

## 🎯 What you should now be able to do

- [x] Build a generator–reflector loop in LangGraph
- [x] Write *adversarial* reflector prompts that don't rubber-stamp
- [x] Add automated checks (compile / lint) into the loop
- [x] Run multi-reviewer reflection

➡️ Next: **[Lesson 4 — Build a Tool-Using Agent](04_Build_a_Tool_Using_Agent.md)**
