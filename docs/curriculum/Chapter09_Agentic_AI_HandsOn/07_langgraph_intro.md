# Lesson 7 — Langgraph Intro

!!! info "Runnable source file"
    **Path:** `Chapter09_Agentic_AI_HandsOn/07_langgraph_intro.py`  
    **Phase:** Phase 5 — Agentic AI  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/genai-agentic-ai-handbook)) and run it locally.

```python
"""
Lesson 7: LangGraph Intro (Framework Glimpse)
================================================

📖 CONCEPT:
You've now built agents from scratch. Frameworks save boilerplate:
  - LangChain  → Lego blocks for LLM apps
  - LangGraph  → Build agents as STATE GRAPHS (nodes & edges)
  - CrewAI     → Role-based multi-agent crews
  - AutoGen    → Multi-agent conversations
  - Semantic Kernel → Microsoft's framework (great for .NET interop)

This lesson sketches what LangGraph looks like. It's OPTIONAL — read it,
install the lib later when you start a real project.

📦 INSTALL (when you're ready):
    pip install langgraph langchain langchain-openai

⚠️ This file is illustrative — it won't run without the libraries installed
   and a real LLM key configured.
"""

LANGGRAPH_EXAMPLE = r"""
from typing import Annotated, TypedDict
from langgraph.graph import StateGraph, END
from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage, AIMessage

llm = ChatOpenAI(model="gpt-4o-mini")

class State(TypedDict):
    messages: list
    needs_research: bool

def planner(state: State) -> State:
    last = state["messages"][-1].content
    state["needs_research"] = "research" in last.lower()
    state["messages"].append(AIMessage(content="Planned next step."))
    return state

def researcher(state: State) -> State:
    state["messages"].append(AIMessage(content="Researched relevant facts."))
    return state

def writer(state: State) -> State:
    reply = llm.invoke(state["messages"])
    state["messages"].append(reply)
    return state

def router(state: State) -> str:
    return "researcher" if state["needs_research"] else "writer"

graph = StateGraph(State)
graph.add_node("planner",    planner)
graph.add_node("researcher", researcher)
graph.add_node("writer",     writer)
graph.set_entry_point("planner")
graph.add_conditional_edges("planner", router,
                            {"researcher": "researcher", "writer": "writer"})
graph.add_edge("researcher", "writer")
graph.add_edge("writer", END)

app = graph.compile()
result = app.invoke({
    "messages": [HumanMessage(content="Please research and write me a summary about RAG.")],
    "needs_research": False,
})
print(result["messages"][-1].content)
"""

print(__doc__)
print("=" * 70)
print("SAMPLE LANGGRAPH CODE (illustrative):")
print("=" * 70)
print(LANGGRAPH_EXAMPLE)

# ============================================================
# 🧠 KEY TAKEAWAYS:
#   - LangGraph models agents as a DAG / state machine.
#   - Nodes = functions (LLM calls, tools, custom logic).
#   - Edges = transitions (conditional or fixed).
#   - State = a TypedDict that flows through the graph.
#
# You DO NOT need a framework to build great agents.
# Use one when:
#   - You need streaming, persistence, retries out of the box.
#   - You're building complex multi-agent workflows.
#   - You want LangSmith for tracing & evals.
# ============================================================

```
