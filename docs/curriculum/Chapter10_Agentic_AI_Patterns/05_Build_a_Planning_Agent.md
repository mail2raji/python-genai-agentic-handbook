# Module 5 · Lesson 5 — Build a Planning Agent from scratch

## 🍭 Imagine this…

You're going on a school field trip:
1. **First** the teacher writes a **plan** on the whiteboard: *"9 am leave, 10 am museum, 12 noon lunch, 3 pm back."*
2. **Then** you **execute** each step in order, ticking them off.
3. If something breaks (rain at lunch), you **re-plan**.

A **Planning Agent** copies this. It uses one LLM call to make a numbered plan, then runs each step (often with tools), and re-plans if needed.

This pattern dramatically outperforms ReAct on multi-step tasks (≥4 actions).

---

## 🧠 The real concept

### The classic recipe: **Plan-and-Execute**

```
                  ┌──────────────┐
   Goal ────────► │   Planner    │   ◄────── (re-plan if blocked)
                  └──────┬───────┘
                         ▼ list of steps
                  ┌──────────────┐
                  │   Executor   │  ◄── tools
                  └──────┬───────┘
                         ▼ partial results
                  ┌──────────────┐
                  │ Replan check │ ── done? ──► Final answer
                  └──────────────┘
```

### Variants you'll meet

| Pattern | Idea |
|---|---|
| **Plan-and-Execute** | Plan once, execute many. Simple, fast. |
| **ReWOO** | Plan with `#E1`, `#E2` placeholders. Tools fill them in. Saves tokens. |
| **LLMCompiler** | Plan as a DAG; run independent steps in parallel. |
| **Tree of Thoughts** | Explore multiple branches and pick best. |
| **Reflexion** | Plan → execute → reflect on the trajectory → re-plan with lesson learned. |

We'll build Plan-and-Execute, the most common.

---

## 🌍 Real-world scenario — "Plan my Saturday"

You ask: *"It's Saturday. I want to (a) work out, (b) cook lunch, (c) finish my Python project, and (d) call Mom. Plan it for me with times."*

A 1-shot LLM gives a vague paragraph. A planning agent yields a numbered, time-stamped plan — and can call a `check_calendar()` tool to avoid clashes.

---

## 💻 The code — Plan-and-Execute agent

```python
# planning_agent.py
from typing import TypedDict, Annotated
from operator import add
from langgraph.graph import StateGraph, START, END
from langchain_openai import ChatOpenAI
from langchain_core.messages import SystemMessage, HumanMessage
from pydantic import BaseModel, Field
from dotenv import load_dotenv

load_dotenv()
llm = ChatOpenAI(model="gpt-4o-mini", temperature=0.2)

# ──────────────────────────────────────────────────────────
# 1️⃣  Strict shape for the plan (Pydantic)
# ──────────────────────────────────────────────────────────
class Plan(BaseModel):
    steps: list[str] = Field(min_length=1, max_length=10,
                             description="Ordered short imperative steps")

# ──────────────────────────────────────────────────────────
# 2️⃣  Shared state
# ──────────────────────────────────────────────────────────
class PlannerState(TypedDict):
    goal: str
    plan: list[str]
    executed: Annotated[list[str], add]     # log of step outputs
    final: str

# ──────────────────────────────────────────────────────────
# 3️⃣  Toy tools
# ──────────────────────────────────────────────────────────
def check_calendar(time: str) -> str:
    # pretend look-up — 11 am is busy
    busy = {"11:00", "11:30"}
    return f"busy" if time in busy else "free"

def get_recipe(name: str) -> str:
    return f"Recipe for {name}: ingredients + 15 min steps."

TOOLS = {"check_calendar": check_calendar, "get_recipe": get_recipe}

# ──────────────────────────────────────────────────────────
# 4️⃣  Nodes
# ──────────────────────────────────────────────────────────
PLANNER_SYS = (
    "You are a meticulous planner. Break the user's goal into a SHORT ordered list "
    "of imperative steps (max 8). Each step must be concrete & actionable."
)

def plan_node(state: PlannerState) -> dict:
    structured_llm = llm.with_structured_output(Plan)
    plan: Plan = structured_llm.invoke([
        SystemMessage(content=PLANNER_SYS),
        HumanMessage(content=f"Goal: {state['goal']}"),
    ])
    return {"plan": plan.steps}

EXECUTOR_SYS = (
    "You are an executor. For the CURRENT step, either: "
    "(A) call a tool by replying 'TOOL <name> <arg>' "
    "or (B) reply 'DONE <result>' if no tool is needed."
)

def execute_node(state: PlannerState) -> dict:
    step = state["plan"][len(state["executed"])]
    msg = llm.invoke([
        SystemMessage(content=EXECUTOR_SYS),
        HumanMessage(content=(
            f"Goal: {state['goal']}\n"
            f"Done so far: {state['executed']}\n"
            f"Current step: {step}\n"
            f"Available tools: check_calendar(time), get_recipe(name)"
        )),
    ]).content.strip()

    if msg.startswith("TOOL"):
        # e.g. "TOOL check_calendar 11:00"
        _, name, arg = msg.split(maxsplit=2)
        result = TOOLS[name](arg)
        log = f"Step '{step}' → tool {name}({arg}) → {result}"
    else:
        log = f"Step '{step}' → {msg[5:]}"   # strip "DONE "
    return {"executed": [log]}

def finalize_node(state: PlannerState) -> dict:
    summary = llm.invoke([
        SystemMessage(content="Summarize the execution into a clean Saturday plan."),
        HumanMessage(content=f"Goal: {state['goal']}\n\nLog:\n" + "\n".join(state["executed"])),
    ]).content
    return {"final": summary}

# ──────────────────────────────────────────────────────────
# 5️⃣  Control flow
# ──────────────────────────────────────────────────────────
def more_steps(state: PlannerState):
    return "execute" if len(state["executed"]) < len(state["plan"]) else "finalize"

graph = StateGraph(PlannerState)
graph.add_node("plan",     plan_node)
graph.add_node("execute",  execute_node)
graph.add_node("finalize", finalize_node)
graph.add_edge(START, "plan")
graph.add_edge("plan", "execute")
graph.add_conditional_edges("execute", more_steps)
graph.add_edge("finalize", END)

app = graph.compile()

# ──────────────────────────────────────────────────────────
# 6️⃣  Run it
# ──────────────────────────────────────────────────────────
result = app.invoke({
    "goal": ("It's Saturday. I want to (a) work out 45 min, (b) cook pasta lunch, "
             "(c) do 2 hours of Python project, (d) call Mom. Avoid 11:00 (busy). "
             "Give me a time-stamped plan."),
    "executed": [],
})

print("PLAN:")
for s in result["plan"]:
    print("  •", s)
print("\nLOG:")
for l in result["executed"]:
    print("  -", l)
print("\nFINAL:\n", result["final"])
```

### Toddler-level walkthrough
1. **plan_node** asks the LLM for a *Pydantic-validated* list of steps.
2. **execute_node** runs one step at a time; the LLM either calls a tool or marks the step done.
3. **finalize_node** writes a clean Saturday plan from the log.
4. The graph stays in `execute` until all steps are processed, then jumps to `finalize`.

---

## 🧠 Re-planning when reality bites

Sometimes a step fails (busy calendar, missing recipe). Add a `replan` node:

```python
def maybe_replan(state):
    last = state["executed"][-1].lower()
    if "busy" in last or "fail" in last:
        return "plan"            # redo the plan with new info
    return "execute"
```

Add the conditional edge from `execute` to either `execute` (continue) or `plan` (rebuild). LangGraph cleanly supports cycles.

---

## 🧠 ReWOO in 30 seconds

ReWOO writes the **whole plan first** with placeholder variables, then tools fill them:

```
1. price = get_stock("AAPL")
2. eur   = convert(#1, "USD", "EUR")
3. say   = format("AAPL is {#1} USD ≈ {#2} EUR")
```

Pros: one LLM call decides the **structure**, then tools run cheaply.
Cons: hard to react to surprises mid-plan.

---

## 🏋️ Exercises

### Exercise 1 — Real calendar
Replace `check_calendar` with one that reads a JSON file `events.json` of busy slots.

### Exercise 2 — Add `cook` and `notify` tools
Add tools `start_timer(minutes)` and `send_text(person, msg)` (just print). Adjust the plan so the executor uses them.

### Exercise 3 — Step-level retry
If a step's tool call fails (returns `ERROR`), retry the step up to 2 times before giving up.

### Exercise 4 — Plan validation
After planning, run a check: does the plan contain at least one step per *(workout, cook, code, call)*? If not, force a re-plan.

### Exercise 5 — Time-budgeted execution
Add a `time_left` counter (in minutes) to state. After each step, the executor must announce remaining time. Stop early if 0.

---

## ✅ Solutions

### Solution 1
```python
import json
def check_calendar(time: str) -> str:
    busy = set(json.loads(open("events.json").read()))
    return "busy" if time in busy else "free"
```

### Solution 2
```python
import time as _time
def start_timer(minutes: str) -> str:
    return f"⏲ Timer set for {minutes} minutes."
def send_text(person: str, msg: str) -> str:
    return f"📱 To {person}: {msg}"

TOOLS.update({"start_timer": start_timer, "send_text": send_text})
# update tools list in the executor system prompt accordingly
```

### Solution 3
```python
def execute_node(state):
    step = state["plan"][len(state["executed"])]
    for attempt in range(3):
        log = _execute_once(state, step)
        if "ERROR" not in log.upper():
            return {"executed": [log]}
    return {"executed": [f"❌ giving up on step '{step}' after 3 tries"]}
```

### Solution 4
```python
def is_complete_plan(plan: list[str]) -> bool:
    p = "\n".join(plan).lower()
    return all(k in p for k in ("workout", "cook", "python", "mom"))

def plan_node(state):
    for _ in range(3):
        plan = llm.with_structured_output(Plan).invoke([...])
        if is_complete_plan(plan.steps):
            return {"plan": plan.steps}
    raise RuntimeError("Planner failed to cover all 4 tasks.")
```

### Solution 5
```python
class PlannerState(TypedDict):
    goal: str
    plan: list[str]
    executed: Annotated[list[str], add]
    time_left: int                                 # minutes

# In execute_node:
spent = 15                                          # naive: assume each step ~15 min
new_left = max(state["time_left"] - spent, 0)
return {"executed": [f"({new_left} min left) " + log],
        "time_left": new_left}  # update reducer manually

# In more_steps:
def more_steps(state):
    if state["time_left"] <= 0: return "finalize"
    if len(state["executed"]) < len(state["plan"]): return "execute"
    return "finalize"
```

---

## 🎯 What you should now be able to do

- [x] Build a Plan-and-Execute agent in LangGraph
- [x] Force the plan into a Pydantic shape
- [x] Add re-planning, retries, and validation
- [x] Reason about ReWOO and LLMCompiler at a high level

➡️ Next: **[Lesson 6 — Build a Multi-Agent System](06_Build_a_Multi_Agent_System.md)**
