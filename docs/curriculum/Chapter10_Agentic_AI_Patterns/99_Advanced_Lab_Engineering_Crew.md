# Module 5 · Advanced Lab — "Friday Ship" Engineering Crew (Multi-Agent + RAG + Tools + Reflection)

> **Time:** 3–4 hours · **Difficulty:** ⭐⭐⭐⭐⭐ (capstone for the whole curriculum)
>
> This is the moment you bring **everything** together: planning, tool use, RAG, reflection, and a multi-agent crew. You'll build a virtual engineering team that takes a feature request in plain English and ships a working Python script — code, tests, docs, and a PR-style summary.

---

## 🌍 The real-world scenario

It's Friday 4 pm at **NovaDB**, a 3-person developer-tools startup. Your CEO drops this in Slack:

> *"We promised a customer a tiny tool that reads a CSV of GitHub repo URLs and outputs a Markdown table with stars, language, and last-commit date. Demo Monday 9 am. Can someone build it?"*

You're alone. So you launch your **AI engineering crew** — five specialised agents that:

| Agent | Job |
|---|---|
| **PM** | Refine the request into a tight spec |
| **Architect** | Sketch a plan; pick libraries from the internal best-practices doc (RAG) |
| **Coder** | Write the Python code (with tool use to run snippets) |
| **Tester** | Write & run pytest, report failures |
| **Reviewer** | Reflect on quality, demand fixes, sign off |

The crew runs autonomously until the **Reviewer** approves. You watch the trace and merge.

---

## 🧠 Why this lab is the capstone

This lab uses **every pattern** from Module 5 at the same time:

| Pattern | Where it shows up |
|---|---|
| **Planning** | PM + Architect produce a Pydantic plan |
| **Tool use** | Coder calls `write_file`, `run_python`, `pytest` |
| **Reflection** | Reviewer critiques → loops back to Coder |
| **Multi-agent + supervisor** | LangGraph routes between agents |
| **RAG** | Architect queries the best-practices doc |
| **Termination / safety** | Hard max-loops + sandboxed subprocess |

This is roughly the architecture **Devin-style coding agents** use in production.

---

## 📂 What you'll build

```
m5_lab/
├── best_practices.md       ← team's internal coding standards
├── workspace/              ← agents write code here
│   └── (created at runtime)
├── tools.py                ← sandboxed write_file, run_python, pytest
├── rag.py                  ← tiny RAG over best_practices.md
├── agents.py               ← 5 agents
├── graph.py                ← LangGraph supervisor wiring
└── ship.py                 ← CLI: ship.py "build me X"
```

---

## 1️⃣ Best-practices doc (RAG source)

`best_practices.md`:

```markdown
# NovaDB Python — Internal Best Practices

BP-01 Always use `pathlib.Path`, never raw strings for paths.
BP-02 Prefer `requests` with `timeout=10` and explicit `raise_for_status()`.
BP-03 All public functions must have type hints.
BP-04 Tests live in `test_*.py` and use `pytest`, not `unittest`.
BP-05 Read GitHub stars via `https://api.github.com/repos/{owner}/{repo}`.
BP-06 No bare except. Catch specific exceptions only.
BP-07 CSV writing must use `csv.DictWriter` and UTF-8.
BP-08 Output Markdown tables with header + alignment row.
BP-09 Add a `__main__` guard for scripts.
BP-10 Log via the `logging` module, not `print`.
```

---

## 2️⃣ The sandbox tools

`tools.py`:

```python
"""Tools the Coder agent can call. EVERYTHING is sandboxed in workspace/."""
from __future__ import annotations
import subprocess, pathlib, sys, json, signal, os
WORKSPACE = pathlib.Path("workspace").resolve()
WORKSPACE.mkdir(exist_ok=True)
PY = sys.executable

def _safe(path: str) -> pathlib.Path:
    p = (WORKSPACE / path).resolve()
    if not str(p).startswith(str(WORKSPACE)):
        raise ValueError(f"Path escapes sandbox: {path}")
    return p

def write_file(path: str, content: str) -> str:
    p = _safe(path); p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content, encoding="utf-8")
    return f"wrote {p.relative_to(WORKSPACE)} ({len(content)} chars)"

def read_file(path: str) -> str:
    return _safe(path).read_text(encoding="utf-8")

def list_files() -> str:
    return "\n".join(str(p.relative_to(WORKSPACE))
                     for p in WORKSPACE.rglob("*") if p.is_file())

def run_python(path: str, args: list[str] | None = None, timeout: int = 30) -> dict:
    args = args or []
    try:
        r = subprocess.run([PY, str(_safe(path)), *args],
                           cwd=WORKSPACE, capture_output=True,
                           text=True, timeout=timeout)
        return {"returncode": r.returncode, "stdout": r.stdout[-4000:], "stderr": r.stderr[-2000:]}
    except subprocess.TimeoutExpired:
        return {"returncode": -1, "stdout": "", "stderr": "TIMEOUT"}

def run_pytest(timeout: int = 60) -> dict:
    try:
        r = subprocess.run([PY, "-m", "pytest", "-q"],
                           cwd=WORKSPACE, capture_output=True, text=True, timeout=timeout)
        return {"returncode": r.returncode, "stdout": r.stdout[-4000:], "stderr": r.stderr[-2000:]}
    except subprocess.TimeoutExpired:
        return {"returncode": -1, "stdout": "", "stderr": "TIMEOUT"}

TOOLS = {
    "write_file": write_file,
    "read_file":  read_file,
    "list_files": list_files,
    "run_python": run_python,
    "run_pytest": run_pytest,
}

TOOL_DOCS = """
Available tools (call by returning JSON: {"tool": "<name>", "args": {...}}):
- write_file(path: str, content: str)
- read_file(path: str)
- list_files()
- run_python(path: str, args: list = [])
- run_pytest()
"""
```

### Safety
- `_safe` blocks `..` escapes.
- Subprocesses have `timeout`.
- No `shell=True`, no `eval`, no network egress (you could add this with a firewall rule).

---

## 3️⃣ Mini-RAG over the best-practices doc

`rag.py`:

```python
"""Tiny RAG — 10 lines, perfect for a small doc."""
import pathlib, re
LINES = [ln for ln in pathlib.Path("best_practices.md").read_text(encoding="utf-8").splitlines()
         if ln.strip().startswith("BP-")]

def search(query: str, top: int = 4) -> list[str]:
    q = set(re.findall(r"\w+", query.lower()))
    scored = [(sum(1 for w in re.findall(r"\w+", ln.lower()) if w in q), ln) for ln in LINES]
    return [ln for s, ln in sorted(scored, reverse=True)[:top] if s > 0] or LINES[:top]
```

> For a real codebase use Chroma + embeddings as in Module 4. Here, lexical search is enough.

---

## 4️⃣ The five agents

`agents.py`:

```python
from __future__ import annotations
import json
from typing import TypedDict, Annotated, Literal
from operator import add
from pydantic import BaseModel, Field
from langchain_openai import ChatOpenAI
from langchain_core.messages import SystemMessage, HumanMessage
from tools import TOOLS, TOOL_DOCS
import rag

llm = ChatOpenAI(model="gpt-4o-mini", temperature=0.2)
llm_strong = ChatOpenAI(model="gpt-4o", temperature=0)

# ── Shared state ──────────────────────────────────────────
class CrewState(TypedDict):
    request: str
    spec: str
    plan: str
    code_files: list[str]
    test_result: str
    review_verdict: Literal["approved", "revise", "fail"]
    review_notes: str
    iterations: int
    log: Annotated[list[str], add]
    next: str

# ── 1. PM ─────────────────────────────────────────────────
PM = SystemMessage(content=(
    "You are the Product Manager. Rewrite the user's vague request "
    "into a CRISP 5-bullet spec: inputs, outputs, edge cases, success criteria, non-goals. "
    "Return ONLY the spec text."))

def pm_node(state: CrewState):
    spec = llm.invoke([PM, HumanMessage(content=state["request"])]).content
    return {"spec": spec, "log": ["[pm] spec drafted"], "next": "architect"}

# ── 2. Architect (uses RAG) ───────────────────────────────
def architect_node(state: CrewState):
    bp = "\n".join(rag.search(state["spec"]))
    plan = llm.invoke([
        SystemMessage(content=(
            "You are the Architect. Produce a numbered build plan "
            "(steps + file names). Respect our best-practices:\n" + bp)),
        HumanMessage(content=f"Spec:\n{state['spec']}"),
    ]).content
    return {"plan": plan, "log": ["[architect] plan drafted with BPs"], "next": "coder"}

# ── 3. Coder (tool-using) ─────────────────────────────────
CODER_SYS = (
    "You are the Coder. Implement the plan by calling tools.\n"
    "Reply with EITHER (a) a JSON tool call: "
    '{"tool":"write_file","args":{...}} or '
    '(b) "DONE" once main.py and test_main.py exist and look right.\n'
    + TOOL_DOCS)

def coder_node(state: CrewState):
    files: list[str] = state.get("code_files", []) or []
    # short tool loop — give it up to N steps
    history: list = []
    for step in range(10):
        msgs = [SystemMessage(content=CODER_SYS),
                HumanMessage(content=(
                    f"Plan:\n{state['plan']}\n\n"
                    f"Best practices (must follow):\n{chr(10).join(rag.search(state['plan']))}\n\n"
                    f"Existing files: {TOOLS['list_files']()}\n"
                    f"Review notes (if revising): {state.get('review_notes','-')}\n"
                    f"History (last 4 actions): {history[-4:]}"))]
        out = llm_strong.invoke(msgs).content.strip()
        if out.upper().startswith("DONE"):
            break
        try:
            call = json.loads(out)
            tool = TOOLS[call["tool"]]
            result = tool(**call.get("args", {}))
            history.append({"tool": call["tool"], "result": str(result)[:300]})
            if call["tool"] == "write_file":
                files.append(call["args"]["path"])
        except Exception as e:
            history.append({"error": str(e), "raw": out[:300]})
    return {"code_files": sorted(set(files)),
            "log": [f"[coder] step{step} files={len(set(files))}"],
            "next": "tester"}

# ── 4. Tester ─────────────────────────────────────────────
def tester_node(state: CrewState):
    res = TOOLS["run_pytest"]()
    summary = f"returncode={res['returncode']}\nstdout:\n{res['stdout']}\nstderr:\n{res['stderr']}"
    return {"test_result": summary,
            "log": [f"[tester] returncode={res['returncode']}"],
            "next": "reviewer"}

# ── 5. Reviewer (Reflection) ──────────────────────────────
class Review(BaseModel):
    verdict: Literal["approved", "revise", "fail"]
    notes: str = Field(max_length=600)

REVIEW_SYS = (
    "You are the senior Reviewer. Read the spec, the file list, and the "
    "pytest output. Decide:\n"
    " - approved: all green AND code obeys best practices.\n"
    " - revise:   fixable issues — explain WHAT to change.\n"
    " - fail:     unsalvageable.\n"
    "Return strict JSON: {verdict, notes}.")

def reviewer_node(state: CrewState):
    review_llm = llm_strong.with_structured_output(Review)
    review = review_llm.invoke([
        SystemMessage(content=REVIEW_SYS),
        HumanMessage(content=(
            f"Spec:\n{state['spec']}\n\n"
            f"Files written: {state['code_files']}\n\n"
            f"Test result:\n{state['test_result']}\n\n"
            f"Best practices to satisfy:\n{chr(10).join(rag.search(state['spec']))}"))])
    nxt = "end" if review.verdict in ("approved", "fail") else "coder"
    return {"review_verdict": review.verdict,
            "review_notes":   review.notes,
            "iterations":     state.get("iterations", 0) + 1,
            "log": [f"[reviewer] verdict={review.verdict}"],
            "next": nxt}
```

### Toddler-level
- Every agent reads from `CrewState` and writes back.
- Coder is the only one with tools — others reason about results.
- Reviewer enforces the **Reflection** loop: bad → back to Coder.

---

## 5️⃣ The supervisor graph

`graph.py`:

```python
from langgraph.graph import StateGraph, START, END
from agents import (CrewState, pm_node, architect_node,
                    coder_node, tester_node, reviewer_node)

MAX_ITERS = 3

def router(state: CrewState):
    if state.get("iterations", 0) >= MAX_ITERS and state["next"] == "coder":
        return "end"     # safety stop
    return state["next"]

g = StateGraph(CrewState)
g.add_node("pm",        pm_node)
g.add_node("architect", architect_node)
g.add_node("coder",     coder_node)
g.add_node("tester",    tester_node)
g.add_node("reviewer",  reviewer_node)

g.add_edge(START, "pm")
g.add_edge("pm",       "architect")
g.add_edge("architect","coder")
g.add_edge("coder",    "tester")
g.add_conditional_edges("tester",   router, {"reviewer":"reviewer"})
g.add_conditional_edges("reviewer", router, {"coder":"coder", "end":END})

app = g.compile()
```

The conditional edge after the Reviewer is the **Reflection loop**.

---

## 6️⃣ CLI

`ship.py`:

```python
import sys, json
from graph import app

req = " ".join(sys.argv[1:]) or (
    "Build a CLI tool that reads a CSV of GitHub repo URLs (col `repo_url`) "
    "and writes a Markdown table with columns: name, language, stars, last_commit. "
    "Add tests.")
final = app.invoke({"request": req, "log": [], "iterations": 0, "code_files": []})

print("\n=== LOG ===")
for line in final["log"]: print(line)
print(f"\n=== VERDICT === {final['review_verdict']}  "
      f"(after {final['iterations']} iterations)\n")
print("Notes:", final["review_notes"])
print("Files:", final["code_files"])
print("\nWorkspace:", "workspace/")
```

```powershell
python ship.py
```

You'll see the agents trade messages, the Coder writing files, pytest running, and the Reviewer either approving or sending it back.

---

## ✅ What you'll see (typical trace)

```
[pm] spec drafted
[architect] plan drafted with BPs
[coder] step5 files=2
[tester] returncode=1
[reviewer] verdict=revise
[coder] step3 files=2
[tester] returncode=0
[reviewer] verdict=approved

=== VERDICT === approved  (after 2 iterations)
Files: ['main.py', 'test_main.py']
```

Open `workspace/main.py` — actual working code.

---

## 🏋️ Exercises

### Exercise 1 — Add a Security agent
Insert a 6th agent **before** the Reviewer that runs `bandit -r .` (or a regex scan for `eval`, `os.system`) and rejects if any high-severity finding. Loop back to Coder.

### Exercise 2 — Cost-aware termination
Track total tokens. If the crew burns more than 20k tokens, stop and emit `fail`.

### Exercise 3 — Hand-off to human
If `Review.verdict == "revise"` after 3 iterations, write a clean `HANDOFF.md` summarising what's blocking and exit. (Real-world graceful degradation.)

### Exercise 4 — Multi-task crew
Wrap `app.invoke` in a loop that consumes a `tasks.txt` file (one feature per line). Run them sequentially, store outputs under `workspace/<task_id>/`.

### Exercise 5 — Swap to CrewAI for the same crew
Re-implement the same 5 roles in CrewAI with `Process.sequential` then `Process.hierarchical`. Compare LangGraph control vs CrewAI brevity.

### Exercise 6 — Web GUI
Wrap `ship.py` in a 30-line FastAPI app with a single `/ship` endpoint that streams the log via Server-Sent Events. Render the result as a one-page status board.

---

## ✅ Solutions (key points)

### Solution 1 — Security agent
```python
import subprocess
def security_node(state):
    r = subprocess.run(["bandit","-r",".","-q"], cwd="workspace",
                       capture_output=True, text=True, timeout=30)
    bad = "Severity: High" in r.stdout
    return {"next": "coder" if bad else "reviewer",
            "review_notes": r.stdout if bad else "",
            "log": [f"[security] bad={bad}"]}
```
Insert: `g.add_edge("tester","security")` then `add_conditional_edges("security", ...)`.

### Solution 2 — Cost-aware termination
Track `usage` from each LLM call via OpenAI response metadata; sum into `state["tokens"]`. In `router`:
```python
if state.get("tokens", 0) > 20_000:
    return "end"
```

### Solution 3 — Hand-off
```python
if state["iterations"] >= MAX_ITERS and state["review_verdict"] == "revise":
    pathlib.Path("workspace/HANDOFF.md").write_text(
        f"## Blocked after {MAX_ITERS} iterations\n\n"
        f"Notes:\n{state['review_notes']}\n\n"
        f"Last tests:\n```\n{state['test_result']}\n```\n")
    return "end"
```

### Solution 4 — Multi-task
```python
for task in pathlib.Path("tasks.txt").read_text().splitlines():
    if not task.strip(): continue
    workspace = pathlib.Path(f"workspace/{abs(hash(task))%10000}")
    workspace.mkdir(parents=True, exist_ok=True)
    os.environ["WORKSPACE_DIR"] = str(workspace)
    app.invoke({"request": task, "log": [], "iterations": 0, "code_files": []})
```

### Solution 5 — CrewAI version
```python
from crewai import Agent, Task, Crew, Process
pm  = Agent(role="PM", goal="Refine specs", backstory="...", llm=llm_strong)
arch= Agent(role="Architect", ..., tools=[search_bp_tool])
coder = Agent(role="Coder", ..., tools=[write_file_tool, pytest_tool])
review= Agent(role="Reviewer", ...)
Crew(agents=[pm,arch,coder,review],
     tasks=[Task(...), ...],
     process=Process.hierarchical,
     manager_llm=llm_strong).kickoff()
```

### Solution 6 — FastAPI streaming
```python
from fastapi import FastAPI
from fastapi.responses import StreamingResponse
api = FastAPI()
@api.get("/ship")
def ship(req: str):
    def gen():
        for state in app.stream({"request": req, "log": [], "iterations": 0}):
            yield f"data: {json.dumps(state)}\n\n"
    return StreamingResponse(gen(), media_type="text/event-stream")
```

---

## 🎯 What you should now be able to do

- [x] Compose Planning + Tools + Reflection + Multi-Agent + RAG in one system
- [x] Sandbox an autonomous coding agent
- [x] Enforce best-practices via RAG into the planning step
- [x] Loop a Reflection cycle with hard safety stops
- [x] Hand off gracefully to humans when the agent is stuck

---

## 🌐 Where this leads in real life

- **Devin / SWE-agent / OpenHands** — same architecture, more polished tooling.
- **Cursor / Copilot Workspace** — IDE-integrated variants of the same loop.
- **Internal-tool factories** at every mid-sized SaaS company by 2027.

---

## 🎉 You finished the entire curriculum!

You went from "what's an LLM?" to **shipping** an autonomous engineering crew that uses every Module 1–5 idea at once.

### Portfolio ideas
1. **Personal finance crew** — RAG over your bank PDFs (Module 4 lab) + planning agent that drafts your monthly budget (Module 5 patterns).
2. **Resume-to-interview prep** — Module 3 wizard pattern + Module 5 reflection.
3. **Local-Ollama RAG** — same legal RAG (Module 4 lab) but offline with Llama 3.

### Next reading
- LangChain docs: <https://python.langchain.com/>
- LangGraph multi-agent guide: <https://langchain-ai.github.io/langgraph/tutorials/multi_agent/>
- Anthropic "Building effective agents": <https://www.anthropic.com/research/building-effective-agents>
- Ragas evaluation: <https://docs.ragas.io/>

➡️ Back to **[the homepage](../index.md)** to admire how far you've come. 🚀
