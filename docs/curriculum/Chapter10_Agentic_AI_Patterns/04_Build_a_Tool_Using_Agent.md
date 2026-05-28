# Module 5 · Lesson 4 — Build a Tool-Using Agent from scratch

## 🍭 Imagine this…

A **handyman** with a tool belt: hammer, screwdriver, level, drill. He looks at the job, **picks the right tool**, uses it, looks at the result, picks the next one, until the shelf is up.

A **tool-using agent** does exactly that — picks the right Python function for each step toward the goal.

---

## 🧠 The real concept

### Three layers

1. **Tools** = plain Python functions with a name, description, and typed inputs.
2. **LLM** = decides which tool to call (or to answer).
3. **Executor** (the loop) = runs the chosen tool and feeds the result back.

We've used `create_react_agent` before. Now we build the loop **from scratch** so you fully understand it.

### Why this matters
You'll often run into:
- Frameworks that don't have a prebuilt agent.
- A need for **custom tool routing**, **caching**, **per-tool retries**, **audit logs**.

A from-scratch loop is ~80 lines and gives you total control.

---

## 🌍 Real-world scenario — Personal data agent

You ask: *"How many CSV files are in C:\Reports, and what's the total row count across them?"*

The agent must:
1. List files in a folder (`list_files`).
2. For each CSV, count rows (`count_csv_rows`).
3. Sum + return.

This is the kind of agent that automates real ops work.

---

## 💻 The code — a hand-rolled tool agent

```python
# tool_agent.py
import os, csv, json, glob, inspect
from pathlib import Path
from typing import Any, Callable
from openai import OpenAI
from dotenv import load_dotenv

load_dotenv()
client = OpenAI()

# ──────────────────────────────────────────────────────────
# 1️⃣  Tool registry — a dict name → callable + schema
# ──────────────────────────────────────────────────────────
TOOLS: dict[str, dict] = {}

def tool(description: str):
    """Decorator: register a Python function as an LLM tool."""
    def wrap(fn: Callable):
        sig = inspect.signature(fn)
        params = {
            "type": "object",
            "properties": {
                name: {"type": _py_to_json(p.annotation), "description": ""}
                for name, p in sig.parameters.items()
            },
            "required": [name for name, p in sig.parameters.items()
                         if p.default is inspect._empty],
        }
        TOOLS[fn.__name__] = {
            "fn": fn,
            "schema": {
                "type": "function",
                "function": {
                    "name": fn.__name__,
                    "description": description,
                    "parameters": params,
                },
            },
        }
        return fn
    return wrap

def _py_to_json(t):
    return {int: "integer", float: "number", str: "string",
            bool: "boolean", list: "array", dict: "object"}.get(t, "string")

# ──────────────────────────────────────────────────────────
# 2️⃣  Our tools
# ──────────────────────────────────────────────────────────
@tool("List files in a folder matching a glob pattern (e.g. '*.csv').")
def list_files(folder: str, pattern: str = "*") -> list:
    p = Path(folder).expanduser()
    if not p.exists():
        return [f"ERROR: folder not found: {p}"]
    return [str(f) for f in p.glob(pattern)]

@tool("Count rows in a CSV file (excluding header).")
def count_csv_rows(path: str) -> int:
    with open(path, encoding="utf-8", newline="") as f:
        return sum(1 for _ in csv.reader(f)) - 1   # minus header

@tool("Add a list of numbers.")
def sum_numbers(numbers: list) -> float:
    return float(sum(numbers))

# ──────────────────────────────────────────────────────────
# 3️⃣  The agent loop
# ──────────────────────────────────────────────────────────
SYSTEM = (
    "You are a careful data ops agent. "
    "Use the provided tools to answer questions about local files. "
    "ALWAYS verify your answer with a tool before responding. "
    "If a tool fails, explain why instead of guessing."
)

def run_agent(user_msg: str, max_steps: int = 8) -> str:
    msgs = [
        {"role": "system", "content": SYSTEM},
        {"role": "user",   "content": user_msg},
    ]
    schemas = [t["schema"] for t in TOOLS.values()]

    for step in range(max_steps):
        resp = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=msgs,
            tools=schemas,
            temperature=0,
        )
        choice = resp.choices[0].message
        msgs.append(choice)

        # No tool call → final answer
        if not choice.tool_calls:
            return choice.content

        # Otherwise — execute each requested tool
        for call in choice.tool_calls:
            name = call.function.name
            try:
                args = json.loads(call.function.arguments or "{}")
                fn = TOOLS[name]["fn"]
                result = fn(**args)
            except Exception as e:
                result = f"ERROR running {name}: {e}"

            print(f"  🔧 {name}({args}) → {str(result)[:100]}")
            msgs.append({
                "role": "tool",
                "tool_call_id": call.id,
                "content": json.dumps(result, default=str),
            })

    return "(max steps reached without final answer)"

# ──────────────────────────────────────────────────────────
# 4️⃣  Use it
# ──────────────────────────────────────────────────────────
if __name__ == "__main__":
    answer = run_agent(
        "How many CSV files are in the current folder and what is the total row count?"
    )
    print("\n=== FINAL ===\n", answer)
```

### What just happened (loop, in toddler-speak)
1. We **describe** every tool to the model (name + params + description).
2. We **ask** the model.
3. The model either:
   - 🎯 Gives a final answer — we return it.
   - 🛠 Asks for a tool call — we **run the tool**, append the result, ask again.
4. We cap at `max_steps` so the model can't loop forever.

The `🔧` print line shows you exactly which tools fire — perfect for debugging.

---

## 🧠 Best practices for tool agents

| Practice | Why |
|---|---|
| **Tiny, single-purpose tools** | Better routing; fewer "let me write a thousand-line wrapper" hallucinations. |
| **Clear descriptions** | The description is the *only* manual the model has. |
| **Typed arguments + validation** | Catches the LLM hallucinating an integer as a string. |
| **Stable error shape** | Tools return `{"ok": False, "error": "…"}` instead of crashing. |
| **Idempotent + side-effect-aware** | Mark DELETE/WRITE tools so an outer policy can require approval. |
| **Per-tool rate limits / caches** | Avoid hammering external APIs. |
| **Audit log** | Save every tool call to a JSONL file for review. |

### Add an audit log in 3 lines

```python
import json, datetime
def audit(name, args, result):
    with open("audit.jsonl", "a", encoding="utf-8") as f:
        f.write(json.dumps({"t": datetime.datetime.utcnow().isoformat(),
                            "tool": name, "args": args, "result": str(result)[:500]}) + "\n")
```

Call `audit(name, args, result)` after every tool execution.

---

## 🧠 Adding a tool the agent should **ask permission** for

```python
SENSITIVE = {"delete_file", "send_email"}

# inside the loop, before executing a tool:
if name in SENSITIVE:
    confirm = input(f"🛑 About to run {name}({args}). Approve? [y/N] ")
    if confirm.lower() != "y":
        result = "User denied execution."
```

This is a **manual** human-in-the-loop. For LangGraph use `interrupt_before`.

---

## 🏋️ Exercises

### Exercise 1 — Add a search tool
Add `search_files(folder, query)` that returns paths of text files containing `query`.

### Exercise 2 — Real API tool
Add a `get_stock_price(ticker)` tool using the free Yahoo Finance unofficial endpoint *or* a stub dict for 3 tickers.

### Exercise 3 — Per-tool retries
Wrap every tool call with up to 3 retries with exponential backoff.

### Exercise 4 — Caching
Cache successful tool calls in a dict keyed by `(name, args)` so identical calls return instantly.

### Exercise 5 — Multi-question
Build a CLI: in a loop ask the user a question, run the agent, print the answer. Quit on `q`.

---

## ✅ Solutions

### Solution 1
```python
@tool("Search text files in a folder for a query string. Returns matching paths.")
def search_files(folder: str, query: str) -> list:
    matches = []
    for path in Path(folder).rglob("*.txt"):
        try:
            if query.lower() in path.read_text(encoding="utf-8", errors="ignore").lower():
                matches.append(str(path))
        except Exception:
            pass
    return matches
```

### Solution 2
```python
@tool("Get the latest stock price for a ticker symbol.")
def get_stock_price(ticker: str) -> str:
    stub = {"AAPL": 224.5, "MSFT": 432.1, "GOOG": 178.4}
    return f"{ticker.upper()}: ${stub.get(ticker.upper(), 'unknown')}"
```

### Solution 3
```python
import time, random
def call_with_retry(fn, **args):
    for attempt in range(3):
        try:
            return fn(**args)
        except Exception as e:
            if attempt == 2: raise
            time.sleep((2 ** attempt) + random.random())
# In the loop replace: result = fn(**args)
# with:                result = call_with_retry(fn, **args)
```

### Solution 4
```python
CACHE = {}
key = (name, json.dumps(args, sort_keys=True))
if key in CACHE:
    result = CACHE[key]
else:
    result = fn(**args)
    CACHE[key] = result
```

### Solution 5
```python
print("Type 'q' to quit.")
while True:
    q = input("\nYou: ").strip()
    if q.lower() in ("q", "quit", "exit"): break
    print("Agent:", run_agent(q))
```

---

## 🎯 What you should now be able to do

- [x] Hand-roll the ReAct loop with function-calling
- [x] Define tools as plain Python functions + decorator
- [x] Add safety (sensitive-tool approval), audit log, retries, cache
- [x] Build a multi-turn CLI agent

➡️ Next: **[Lesson 5 — Build a Planning Agent](05_Build_a_Planning_Agent.md)**
