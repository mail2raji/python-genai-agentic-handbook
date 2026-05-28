# Module 5 · Lesson 2 — Introduction to AI Agents

## 🍭 Imagine this…

A **chatbot** is a goldfish — it answers and forgets.
An **agent** is a **golden retriever** — give it a goal, it runs across the yard, fetches stuff, comes back, drops it at your feet, and waits for the next command.

An **AI Agent** is an LLM in a **loop** with **goals**, **memory**, and **tools**.

---

## 🧠 The real concept

### The agent loop (ReAct: Reason + Act)

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│   Goal ──►  Think  ──►  Act (call tool) ──►  Observe ──┐│
│             ▲                                          ││
│             └──────────────  Repeat  ◄─────────────────┘│
│                                                         │
│                       Final answer ►                    │
└─────────────────────────────────────────────────────────┘
```

This was popularised in the **ReAct paper** (2022). It's the foundation of every modern agent.

### Anatomy of an agent

| Part | Role | Example |
|---|---|---|
| **Goal / instructions** | What success looks like | "Find the cheapest flight Mumbai→Tokyo on May 5." |
| **LLM brain** | Decides next action | GPT-4o-mini |
| **Tools** | Functions the LLM can call | search, calculator, DB, email |
| **Memory** | What it remembers | chat history, scratchpad |
| **Stop condition** | When to halt | "answer the user", "max 10 steps" |
| **Observation** | Result of a tool call | "$420 on ANA" |

### ReAct vs Function Calling
- **ReAct** (older, text-based): the model outputs `Thought: … / Action: … / Action Input: … / Observation: …` and you parse the text.
- **Function calling** (newer, structured JSON): the model returns a clean tool call. **Use this** unless you need ReAct's transparency.

---

## 🌍 Real-world scenario — Mini travel-buddy agent

You ask: *"What's the weather in Tokyo and how do I say 'where is the toilet?' in Japanese?"*

The agent must:
1. **Decide**: I need a weather tool AND a translation tool.
2. **Call** both.
3. **Combine** the results into a single answer.

We'll build this in 80 lines with LangChain's `create_react_agent` (LangGraph under the hood).

---

## 💻 The code — a real working agent

```python
# travel_agent.py
from typing import Annotated
from langchain_core.tools import tool
from langchain_openai import ChatOpenAI
from langgraph.prebuilt import create_react_agent
from dotenv import load_dotenv
import requests

load_dotenv()

# ──────────────────────────────────────────────────────────
# 1️⃣  Define tools — just Python functions with @tool
# ──────────────────────────────────────────────────────────
@tool
def get_weather(city: Annotated[str, "City name in English"]) -> str:
    """Get the current weather for a city."""
    try:
        data = requests.get(f"https://wttr.in/{city}?format=j1", timeout=10).json()
        c = data["current_condition"][0]
        return f"{city}: {c['temp_C']}°C, {c['weatherDesc'][0]['value']}"
    except Exception as e:
        return f"Could not fetch weather: {e}"

@tool
def translate(text: Annotated[str, "Source text"],
              target_language: Annotated[str, "Target language e.g. Japanese"]) -> str:
    """Translate text into the target language."""
    llm = ChatOpenAI(model="gpt-4o-mini", temperature=0)
    return llm.invoke(
        f"Translate to {target_language}. Output ONLY the translation:\n{text}"
    ).content

@tool
def calculator(expression: Annotated[str, "Python math expression e.g. '2+2*3'"]) -> str:
    """Safely evaluate a basic arithmetic expression."""
    # Only allow safe characters
    if not all(c in "0123456789+-*/(). " for c in expression):
        return "Invalid characters."
    try:
        return str(eval(expression, {"__builtins__": {}}, {}))
    except Exception as e:
        return f"Error: {e}"

# ──────────────────────────────────────────────────────────
# 2️⃣  Build the agent
# ──────────────────────────────────────────────────────────
llm = ChatOpenAI(model="gpt-4o-mini", temperature=0)

agent = create_react_agent(
    model=llm,
    tools=[get_weather, translate, calculator],
    prompt=(
        "You are a friendly travel buddy. "
        "Use tools when needed. Always combine multiple results into ONE clear final answer."
    ),
)

# ──────────────────────────────────────────────────────────
# 3️⃣  Talk to it
# ──────────────────────────────────────────────────────────
def chat(user_msg: str):
    print(f"\nYOU: {user_msg}\n")
    state = agent.invoke({"messages": [("user", user_msg)]})
    for m in state["messages"]:
        kind = type(m).__name__
        print(f"[{kind}] {m.content[:200]}")

chat("What's the weather in Tokyo and how do I say 'where is the toilet?' in Japanese?")
chat("If a hotel is ¥18,500 per night for 5 nights, how much in INR (use ¥1 ≈ ₹0.54)?")
```

### Line-by-line in toddler-speak

1. `@tool` turns any function into something the agent can **see** and **call**. The docstring + type hints are its instruction manual.
2. `create_react_agent` builds the agent **loop** for you: think → pick tool → run → observe → repeat.
3. `agent.invoke({"messages": [...]})` runs the loop until the model emits a final answer.
4. The result is a **list of messages**: user → AI thinks → ToolMessage(result) → AI final reply.

---

## 🧠 What's happening behind the scenes

Each turn the agent secretly:
1. Sees: chat history + tool definitions + your message.
2. Returns either a **final answer** OR a **tool call**.
3. If tool call → LangGraph executes the function, appends the result, and re-invokes the LLM.
4. Repeats until a final answer arrives or step limit hits.

If you log the messages you'll see exactly this pattern. **This is the ReAct loop with function calling.**

---

## 🧠 Streaming the agent's "thinking"

```python
for event in agent.stream(
    {"messages": [("user", "Weather in Paris and convert 100 EUR to INR")]}
):
    for k, v in event.items():
        for m in v["messages"]:
            print(f"[{k}] {m.content[:120]}")
```

Streaming lets you build a UI that shows *"🛠 calling get_weather('Paris')…"* live.

---

## 🧠 Safety & guardrails

Real agents need walls:

| Guardrail | How |
|---|---|
| Max steps | LangGraph `recursion_limit=10` (default 25) |
| Allow-list of tools per user | Conditional `tools=[…]` per session |
| Approve dangerous tools | LangGraph `interrupt_before=["send_email"]` |
| Strip secrets from logs | Custom logging filter |
| Tool failure handling | Each tool returns `{ok, error}` shapes |

### Human-in-the-loop in 3 lines

```python
agent = create_react_agent(llm, tools=[...], interrupt_before_action=True)
state = agent.invoke({"messages": [...]})
# show the pending action to the human; then resume
```

---

## 🏋️ Exercises

### Exercise 1 — Add a tool
Add a `currency_convert(amount, from_ccy, to_ccy)` tool that uses a hard-coded rate table. Ask the agent: *"Convert $100 to INR."*

### Exercise 2 — Bounded steps
Set `recursion_limit=5`. Ask a question that needs 7 tool calls. Show that the agent stops and gives a partial answer.

### Exercise 3 — Stream the trace
Print each step of the agent as it happens (Action / Observation / Final).

### Exercise 4 — System prompt persona
Make the agent act as a *grumpy Parisian taxi driver*. Run the same query as before — feel the difference.

### Exercise 5 — Tool error
Modify `get_weather` to **randomly fail 50% of the time**. Use a simple retry pattern in the tool. Watch how the agent reacts.

---

## ✅ Solutions

### Solution 1
```python
@tool
def currency_convert(amount: float, from_ccy: str, to_ccy: str) -> str:
    """Convert a money amount between currencies using a static rate table."""
    rates = {"USD": 1.0, "EUR": 1.08, "INR": 0.012, "JPY": 0.0064, "GBP": 1.27}
    fr, to = from_ccy.upper(), to_ccy.upper()
    if fr not in rates or to not in rates:
        return f"Unknown currency: {fr} or {to}"
    usd = amount * rates[fr]
    out = usd / rates[to]
    return f"{amount} {fr} ≈ {out:.2f} {to}"
```

### Solution 2
```python
agent.invoke(
    {"messages": [("user", "Weather + translate + convert + …big multi-step query")]},
    config={"recursion_limit": 5},
)
```
The framework raises (or returns a partial state) when the limit is hit.

### Solution 3
```python
for ev in agent.stream({"messages": [("user", "Weather in Delhi and say hi in Hindi")]}):
    for k, v in ev.items():
        last = v["messages"][-1]
        print(f"--- {k}: {type(last).__name__} ---")
        print((last.content or "")[:200])
```

### Solution 4
```python
prompt = ("You are Pierre, a grumpy Parisian taxi driver. "
          "Use tools but complain a lot. Keep replies short and witty.")
agent = create_react_agent(llm, tools=[...], prompt=prompt)
```

### Solution 5
```python
import random
@tool
def get_weather(city: str) -> str:
    """Weather lookup with built-in retry."""
    for attempt in range(3):
        if random.random() > 0.5:
            return f"{city}: 24°C, clear"          # success
    return "Weather service unavailable, sorry."
```
You'll see the agent gracefully say *"I couldn't get the weather, but here's the translation…"* — the hallmark of robust agents.

---

## 🎯 What you should now be able to do

- [x] Build an agent with tools in ~80 lines
- [x] Stream the agent's reasoning trace
- [x] Bound it with step limits and safety
- [x] Reason about the ReAct loop

➡️ Next: **[Lesson 3 — Build a Reflection Agent from scratch](03_Build_a_Reflection_Agent.md)**
