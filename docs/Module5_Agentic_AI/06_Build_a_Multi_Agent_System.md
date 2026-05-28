# Module 5 · Lesson 6 — Build a Multi-Agent System from scratch

## 🍭 Imagine this…

A **soccer team**:
- The **striker** scores goals.
- The **midfielder** passes.
- The **goalkeeper** defends.
- The **coach** decides strategy.

Each player is specialised. Nobody tries to do everything. They **pass the ball** based on the situation.

A **multi-agent system** is exactly this: a team of LLM-powered specialists that **hand off** work to each other.

---

## 🧠 The real concept

### Three classic topologies

| Topology | Picture | Use |
|---|---|---|
| **Supervisor / Router** | one boss → many workers | Triage + delegate |
| **Pipeline** | linear hand-off A → B → C | Newsroom: researcher → writer → editor |
| **Network / Group chat** | agents talk freely | Brainstorming, debate, "AutoGen" style |

### Anatomy of each agent

| Slot | Role | Example |
|---|---|---|
| `name` | identifier | `analyst` |
| `system_prompt` | persona + scope | "You are a SQL analyst. You write SELECT queries." |
| `tools` | what it can do | `run_sql`, `chart` |
| `handoff_to` | who it can call | `["writer", "supervisor"]` |

### Why multi-agent at all?
- **Specialisation** — narrower scope ⇒ better prompts ⇒ better outputs.
- **Parallelism** — many agents can work simultaneously.
- **Modularity** — swap one agent without breaking others.
- **Realism** — mirrors how human teams already work.

But beware: more agents = more **coordination overhead, latency, and cost**. Start with the smallest team that works.

---

## 🌍 Real-world scenario — "Data analyst team in a box"

You give a CSV and a business question. The team:
1. **Analyst** writes & runs a SQL query on the CSV.
2. **Charter** turns the result into an ASCII chart description.
3. **Writer** produces an executive summary.
4. **Supervisor** decides who goes next and when to stop.

We'll build this **two ways**: hand-rolled (full control), then in CrewAI (less code).

---

## 💻 Version A — Hand-rolled supervisor with LangGraph

```python
# multi_agent.py
from typing import TypedDict, Annotated, Literal
from operator import add
import duckdb, json
from langgraph.graph import StateGraph, START, END
from langchain_openai import ChatOpenAI
from langchain_core.messages import SystemMessage, HumanMessage
from dotenv import load_dotenv

load_dotenv()
llm = ChatOpenAI(model="gpt-4o-mini", temperature=0)

# ──────────────────────────────────────────────────────────
# State shared by all agents
# ──────────────────────────────────────────────────────────
class TeamState(TypedDict):
    question: str
    csv_path: str
    sql: str
    rows:  list
    chart: str
    summary: str
    log:   Annotated[list[str], add]
    next:  Literal["analyst", "charter", "writer", "supervisor", "end"]

# ──────────────────────────────────────────────────────────
# 1️⃣  ANALYST — writes SQL and runs it on the CSV via DuckDB
# ──────────────────────────────────────────────────────────
ANALYST_SYS = (
    "You are a SQL analyst. Given a question and the CSV columns, "
    "write ONE SELECT query that answers it. "
    "Use table name 'csv'. Reply with ONLY the SQL."
)

def analyst_node(state: TeamState):
    # Peek at CSV columns
    cols = duckdb.sql(f"SELECT * FROM read_csv_auto('{state['csv_path']}') LIMIT 0"
                      ).columns
    sql = llm.invoke([
        SystemMessage(content=ANALYST_SYS),
        HumanMessage(content=f"Question: {state['question']}\nColumns: {cols}"),
    ]).content.strip().rstrip(";")

    rows = duckdb.sql(
        f"WITH csv AS (SELECT * FROM read_csv_auto('{state['csv_path']}')) {sql}"
    ).fetchall()

    return {"sql": sql, "rows": rows,
            "log": [f"[analyst] SQL → {sql} | rows={len(rows)}"],
            "next": "charter"}

# ──────────────────────────────────────────────────────────
# 2️⃣  CHARTER — turn results into an ASCII bar chart
# ──────────────────────────────────────────────────────────
def charter_node(state: TeamState):
    chart_prompt = (
        "Given these rows (each is a tuple), produce a 6-line ASCII bar chart "
        "that visualises them clearly.\n\nRows:\n" + json.dumps(state["rows"][:20])
    )
    chart = llm.invoke(chart_prompt).content
    return {"chart": chart,
            "log": ["[charter] built chart"],
            "next": "writer"}

# ──────────────────────────────────────────────────────────
# 3️⃣  WRITER — exec summary
# ──────────────────────────────────────────────────────────
def writer_node(state: TeamState):
    summary = llm.invoke(
        "Write a 4-sentence executive summary.\n"
        f"Question: {state['question']}\n"
        f"Data sample: {state['rows'][:10]}\n"
    ).content
    return {"summary": summary,
            "log": ["[writer] wrote summary"],
            "next": "supervisor"}

# ──────────────────────────────────────────────────────────
# 4️⃣  SUPERVISOR — decides what to do next
# ──────────────────────────────────────────────────────────
SUPERVISOR_SYS = (
    "You are the team manager. "
    "Given the state, choose the NEXT agent to call from: "
    "[analyst, charter, writer, end]. "
    "Reply with ONE word."
)
def supervisor_node(state: TeamState):
    has_sql, has_chart, has_summary = bool(state.get("sql")), bool(state.get("chart")), bool(state.get("summary"))

    # Simple deterministic policy:
    if not has_sql:     nxt = "analyst"
    elif not has_chart: nxt = "charter"
    elif not has_summary: nxt = "writer"
    else: nxt = "end"

    return {"next": nxt, "log": [f"[supervisor] → {nxt}"]}

def router(state: TeamState):
    return state["next"]

# ──────────────────────────────────────────────────────────
# Build the graph
# ──────────────────────────────────────────────────────────
g = StateGraph(TeamState)
g.add_node("supervisor", supervisor_node)
g.add_node("analyst",    analyst_node)
g.add_node("charter",    charter_node)
g.add_node("writer",     writer_node)

g.add_edge(START, "supervisor")
g.add_conditional_edges("supervisor", router,
    {"analyst": "analyst", "charter": "charter",
     "writer": "writer",   "end": END})
g.add_edge("analyst",  "supervisor")
g.add_edge("charter",  "supervisor")
g.add_edge("writer",   "supervisor")

app = g.compile()

# ──────────────────────────────────────────────────────────
# Run it
# ──────────────────────────────────────────────────────────
out = app.invoke({
    "question": "Top 5 product categories by total revenue",
    "csv_path": "sales.csv",
    "log": [], "next": "supervisor",
})

print("\n=== LOG ===")
for line in out["log"]: print(line)
print("\n=== SQL ===\n", out["sql"])
print("\n=== CHART ===\n", out["chart"])
print("\n=== SUMMARY ===\n", out["summary"])
```

### What's special here
- **Supervisor** is the brain. Workers don't know about each other.
- **State** is the shared whiteboard. Each agent reads from it & writes to it.
- The router function is deterministic — replace it with an **LLM-driven router** when the workflow gets fuzzier.

---

## 💻 Version B — Same team in CrewAI (shorter)

```python
from crewai import Agent, Task, Crew, Process
from langchain_openai import ChatOpenAI
from dotenv import load_dotenv
load_dotenv()
llm = ChatOpenAI(model="gpt-4o-mini")

analyst = Agent(role="SQL Analyst",
                goal="Answer business questions with one SELECT query.",
                backstory="A senior SQL whiz.", llm=llm, verbose=True)
charter = Agent(role="Data Charter",
                goal="Produce a clear ASCII chart from result rows.",
                backstory="Loves ASCII art.", llm=llm, verbose=True)
writer  = Agent(role="Exec Summary Writer",
                goal="Produce a crisp 4-sentence executive summary.",
                backstory="Ex-McKinsey writer.", llm=llm, verbose=True)

t1 = Task("Write SQL for: {question}. Columns: {cols}.",
          agent=analyst, expected_output="A SELECT query.")
t2 = Task("Build an ASCII chart for the rows.",
          agent=charter, context=[t1], expected_output="ASCII chart.")
t3 = Task("Write a 4-sentence executive summary.",
          agent=writer, context=[t1, t2], expected_output="Summary.")

Crew(agents=[analyst, charter, writer], tasks=[t1, t2, t3],
     process=Process.sequential).kickoff(inputs={
        "question": "Top 5 product categories by total revenue",
        "cols":     "['category', 'product', 'revenue', 'date']",
     })
```

**Same outcome, 1/3 the code.** Trade-off: less control, less observability.

---

## 🧠 Patterns to know

| Pattern | One-liner |
|---|---|
| **Supervisor + workers** | LangGraph "agentic state machine". Best for production. |
| **Hierarchical (CrewAI)** | A manager LLM auto-delegates. |
| **Swarm / network** | Free-form chat among agents (AutoGen). Great for brainstorming, harder to control. |
| **Hand-off (OpenAI Swarm)** | Each agent has tools that say *"transfer to agent X"*. |
| **Critic-Actor** | One agent does, another grades. (Reflection scaled up.) |

### Pitfalls 🪤
- **Chatty agents** burning tokens. Add a "max-turns-per-agent" cap.
- **Loops** (A asks B, B asks A). Add a step counter; break.
- **Conflicting state writes**. Use **typed reducers** like `add` for lists.
- **Hallucinated handoffs** ("call agent Z" that doesn't exist). Validate against a whitelist.

---

## 🧠 Observability for multi-agent

You **will** be debugging traces. Set up either:
- **LangSmith** (works with LangChain/LangGraph out of the box).
- **Langfuse** (open-source).
- DIY: append every `(agent, prompt_hash, in_tokens, out_tokens, latency_ms)` to a JSONL file.

---

## 🏋️ Exercises

### Exercise 1 — Add a Fact Checker agent
After the writer, add a `fact_checker` that compares the summary to the SQL rows and flags any inconsistency. Loop back to writer if issues found.

### Exercise 2 — LLM-driven supervisor
Replace the deterministic `if not has_sql` policy with an LLM that picks the next worker based on the full state. Add a JSON parser for the choice.

### Exercise 3 — Parallel charter + writer
Make `charter` and `writer` run in parallel (LangGraph supports concurrent branches). Time the difference vs sequential.

### Exercise 4 — CrewAI hierarchical
In Version B, switch `process=Process.hierarchical` and let CrewAI's manager LLM decide which agent runs when. Compare quality.

### Exercise 5 — Mini AutoGen-style
Build a "debate" between a **bull** and a **bear** agent about a stock. The supervisor decides after 3 rounds.

---

## ✅ Solutions

### Solution 1
```python
def fact_checker(state):
    bad = llm.invoke(
        f"Are any of these statements unsupported by the rows?\n"
        f"Rows: {state['rows'][:10]}\nSummary: {state['summary']}\n"
        "Reply OK or list issues."
    ).content
    if bad.strip().upper().startswith("OK"):
        return {"next": "end", "log": ["[fact_checker] OK"]}
    return {"summary": "", "next": "writer", "log": [f"[fact_checker] issues: {bad}"]}
```

### Solution 2
```python
SUP_LLM = "Pick next agent. Reply JSON: {{\"next\": \"analyst|charter|writer|end\"}}"
def supervisor_node(state):
    decision = llm.invoke([
        SystemMessage(content=SUP_LLM),
        HumanMessage(content=json.dumps({
            "has_sql": bool(state.get("sql")),
            "has_chart": bool(state.get("chart")),
            "has_summary": bool(state.get("summary")),
        })),
    ]).content
    nxt = json.loads(decision)["next"]
    if nxt not in {"analyst", "charter", "writer", "end"}:
        nxt = "end"
    return {"next": nxt}
```

### Solution 3
```python
# LangGraph supports concurrent branches by having the same node fan out to two.
g.add_edge("analyst", "charter")
g.add_edge("analyst", "writer")        # both run after analyst
# join via a 'collector' node that proceeds when BOTH have produced output.
```

### Solution 4
```python
Crew(agents=[analyst, charter, writer], tasks=[t1, t2, t3],
     process=Process.hierarchical, manager_llm=llm,
     verbose=True).kickoff(inputs={...})
```

### Solution 5
```python
def bull(state):
    return {"messages": state["messages"] + [
        ("bull", llm.invoke(f"Argue BULL on {state['stock']}. Past:{state['messages']}").content)]}
def bear(state):
    return {"messages": state["messages"] + [
        ("bear", llm.invoke(f"Argue BEAR on {state['stock']}. Past:{state['messages']}").content)]}
def supervisor(state):
    if len(state["messages"]) >= 6:
        verdict = llm.invoke(f"Read the debate and pick BULL or BEAR.\n{state['messages']}").content
        return {"verdict": verdict, "next": "end"}
    return {"next": "bull" if len(state["messages"]) % 2 == 0 else "bear"}
```

---

## 🎯 What you should now be able to do

- [x] Build a hand-rolled multi-agent system with a supervisor + workers
- [x] Run the same team in CrewAI with 1/3 the code
- [x] Add a fact-checker / critic agent
- [x] Reason about hierarchical vs network topologies and their trade-offs

🎉 **You finished Module 5 — and the whole curriculum.** Congratulations!

➡️ Next steps: see **[the homepage](../index.md#where-to-go-next)** for portfolio project ideas, evaluation tooling, and production deployment.
