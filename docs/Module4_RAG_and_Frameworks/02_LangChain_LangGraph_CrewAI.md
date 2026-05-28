# Module 4 · Lesson 2 — LangChain vs LangGraph vs CrewAI

## 🍭 Imagine this…

You're cooking.

- **LangChain** = your **pots and pans** — versatile tools you snap together to make any dish.
- **LangGraph** = a **flow chart** of the recipe — "if the soup is salty, add water; if too thin, simmer". Loops and conditions on a graph.
- **CrewAI** = a **team of chefs** with assigned roles (head chef, sous chef, sommelier) that **collaborate** on a meal.

All three live in the same kitchen and can call each other.

---

## 🧠 The real concept

| Framework | One-line | Best when… | Mental model |
|---|---|---|---|
| **LangChain** | Linear LCEL pipelines + built-in components | Single-shot tasks: RAG, summarise, classify | `prompt \| llm \| parser` |
| **LangGraph** | Stateful **graph** (DAG/cycles) of nodes | Agents that loop, branch, retry, hand off | Nodes + edges + a shared `State` dict |
| **CrewAI** | Multiple **role-based agents** that collaborate | Researcher → Writer → Editor style flows | Agents + Tasks + Crew |

### When to use which?

```
Need a one-shot AI step?                                    → LangChain
Need loops, decision trees, human-in-the-loop, retries?     → LangGraph
Need multiple "people" with roles to collaborate?           → CrewAI
```

You can — and often will — combine them. LangGraph nodes can be LangChain chains. CrewAI tasks can call LangChain tools.

---

## 🌍 Real-world scenario — "Research → Write → Edit" blog generator

Given a topic, we want:
1. A **researcher** agent that gathers facts.
2. A **writer** agent that drafts the article.
3. An **editor** agent that polishes & fact-checks.

We'll build the **same** workflow three ways so you feel the difference.

---

## 💻 Version A — Pure LangChain (sequential)

```python
# Simple, no agents, just chains.
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
from dotenv import load_dotenv

load_dotenv()
llm = ChatOpenAI(model="gpt-4o-mini", temperature=0.4)

research = ChatPromptTemplate.from_template(
    "Give 5 key facts (bulleted) about: {topic}. Be accurate."
) | llm | StrOutputParser()

write = ChatPromptTemplate.from_template(
    "Write a 350-word blog post using these facts:\n{facts}\n\nTopic: {topic}"
) | llm | StrOutputParser()

edit = ChatPromptTemplate.from_template(
    "Edit this blog for clarity and a friendly tone. Keep it ~350 words:\n\n{draft}"
) | llm | StrOutputParser()

def blog(topic: str) -> str:
    facts = research.invoke({"topic": topic})
    draft = write.invoke({"facts": facts, "topic": topic})
    return edit.invoke({"draft": draft})

print(blog("the science of why coffee tastes bitter"))
```

✅ Simple.
❌ Static. No retries if the researcher returns nonsense. No human-in-the-loop. No branching.

---

## 💻 Version B — LangGraph (stateful, loopable)

```python
# pip install langgraph
from typing import TypedDict, Annotated
from operator import add
from langgraph.graph import StateGraph, START, END
from langchain_openai import ChatOpenAI
from dotenv import load_dotenv

load_dotenv()
llm = ChatOpenAI(model="gpt-4o-mini", temperature=0.4)

# 1️⃣ Shared state — every node reads/updates this
class BlogState(TypedDict):
    topic: str
    facts: str
    draft: str
    feedback: str
    revisions: Annotated[int, add]      # `add` reducer accumulates

# 2️⃣ Node functions — plain Python
def researcher(state: BlogState):
    facts = llm.invoke(f"Give 5 key facts about {state['topic']}").content
    return {"facts": facts}

def writer(state: BlogState):
    prompt = f"Write a 350-word blog about {state['topic']}.\nFacts:\n{state['facts']}"
    if state.get("feedback"):
        prompt += f"\nIncorporate this editor feedback: {state['feedback']}"
    return {"draft": llm.invoke(prompt).content}

def editor(state: BlogState):
    review = llm.invoke(
        f"Review this draft. Reply 'OK' if good, or give ONE concrete fix:\n\n{state['draft']}"
    ).content
    return {"feedback": review, "revisions": 1}

# 3️⃣ Decision: stop when editor says OK or after 3 revisions
def should_revise(state: BlogState):
    if state["revisions"] >= 3 or state["feedback"].strip().upper().startswith("OK"):
        return END
    return "writer"

# 4️⃣ Build the graph
graph = StateGraph(BlogState)
graph.add_node("researcher", researcher)
graph.add_node("writer",     writer)
graph.add_node("editor",     editor)

graph.add_edge(START, "researcher")
graph.add_edge("researcher", "writer")
graph.add_edge("writer", "editor")
graph.add_conditional_edges("editor", should_revise)

app = graph.compile()

result = app.invoke({"topic": "the science of why coffee tastes bitter",
                     "revisions": 0})
print(result["draft"])
print("\nRevisions made:", result["revisions"])
```

### What's new vs Version A
- **Loops!** The editor can send the draft back to the writer up to 3 times.
- **State** carries information (facts, draft, feedback) across nodes.
- **Conditional edges** = branching logic in a clean way.
- LangGraph also supports **persistence**, **human-in-the-loop**, **time-travel debugging**.

---

## 💻 Version C — CrewAI (role-based agents)

```python
# pip install crewai
from crewai import Agent, Task, Crew, Process
from langchain_openai import ChatOpenAI
from dotenv import load_dotenv

load_dotenv()
llm = ChatOpenAI(model="gpt-4o-mini", temperature=0.4)

# 1️⃣ Agents with roles, goals, backstories
researcher = Agent(
    role="Senior Researcher",
    goal="Find 5 accurate, specific facts on the topic.",
    backstory="20-year veteran science journalist.",
    llm=llm,
    verbose=True,
)

writer = Agent(
    role="Tech Blogger",
    goal="Write engaging, 350-word blog posts for curious general readers.",
    backstory="Wrote 200 popular tech blog posts last year.",
    llm=llm,
    verbose=True,
)

editor = Agent(
    role="Managing Editor",
    goal="Polish drafts for clarity, accuracy and friendly tone.",
    backstory="Ex Wired magazine editor with a no-fluff rule.",
    llm=llm,
    verbose=True,
)

# 2️⃣ Tasks — each is assigned to one agent
research_task = Task(
    description="Research the topic: {topic}. Output 5 bullet facts.",
    expected_output="5 bullet points.",
    agent=researcher,
)
write_task = Task(
    description="Write a 350-word blog post about {topic} using the facts.",
    expected_output="A 350-word blog post.",
    agent=writer,
    context=[research_task],                # depends on researcher
)
edit_task = Task(
    description="Edit the blog for clarity, tone and accuracy.",
    expected_output="Final polished blog.",
    agent=editor,
    context=[write_task],
)

# 3️⃣ Crew runs the tasks sequentially (or `Process.hierarchical` w/ manager)
crew = Crew(
    agents=[researcher, writer, editor],
    tasks=[research_task, write_task, edit_task],
    process=Process.sequential,
    verbose=True,
)

result = crew.kickoff(inputs={"topic": "the science of why coffee tastes bitter"})
print(result.raw)
```

### What's new vs Version B
- **Personas.** Each agent has a `role`, `goal`, `backstory` — this shapes its writing voice automatically.
- **Task dependencies** make the data flow declarative.
- **Process.hierarchical** lets you add a "manager" agent that delegates dynamically.
- CrewAI is brilliant when you want the *vibes* of a team of specialists.

---

## 🧠 Cheat sheet

| Need | Use |
|---|---|
| One LLM call with a prompt template | LangChain |
| RAG pipeline | LangChain |
| A 3-step linear chain | LangChain |
| Loop with retries / branching / human approval | LangGraph |
| Persistent multi-turn agents | LangGraph (checkpointers) |
| Multiple specialists collaborating (roles & goals) | CrewAI |
| Hierarchical manager-and-workers | CrewAI (`hierarchical`) or LangGraph (manual) |

---

## 🧠 They are NOT mutually exclusive

You can — and many production teams do — combine:

```
LangGraph node ──► uses LangChain chain ──► which uses a CrewAI sub-team
```

Example:
- LangGraph orchestrates a **support workflow** (intake → triage → resolve → notify).
- The "resolve" node calls a **CrewAI crew** of (Investigator, Solver, Communicator).
- Each agent has tools and a RAG chain built in **LangChain**.

---

## 🏋️ Exercises

### Exercise 1 — Sequential LangChain
Build a 3-step LangChain pipeline that takes a product name and outputs `tagline → marketing email → social-media post`.

### Exercise 2 — LangGraph with retry
Make a LangGraph workflow that translates English → French and **re-runs** if the translation contains any English word from a stop-list.

### Exercise 3 — CrewAI for travel planning
Three agents: **Destination Researcher**, **Itinerary Planner**, **Budget Reviewer**. Run them sequentially to plan a 5-day Japan trip under $2000.

### Exercise 4 — Pick the right tool
For each scenario, name the best framework and justify:
1. Summarise a 100-page PDF.
2. A code-review bot that loops until the linter passes.
3. A "newsroom" with reporter, fact-checker, copy-editor agents.
4. A simple "translate then summarise" pipeline.
5. A workflow with a human approval step in the middle.

### Exercise 5 — Hybrid challenge
Build a LangGraph where one node calls a CrewAI crew. (You can stub them lightly to keep it short.)

---

## ✅ Solutions

### Solution 1
```python
tagline = ChatPromptTemplate.from_template("Create a 6-word tagline for {product}.") | llm | StrOutputParser()
email   = ChatPromptTemplate.from_template("Write a 5-sentence marketing email for {product}. Hook: {tag}") | llm | StrOutputParser()
post    = ChatPromptTemplate.from_template("Write a 280-char tweet for {product}. Hook: {tag}") | llm | StrOutputParser()

def market(product):
    tag = tagline.invoke({"product": product})
    return {"tag": tag, "email": email.invoke({"product": product, "tag": tag}),
            "post": post.invoke({"product": product, "tag": tag})}
```

### Solution 2
```python
STOP = {"the", "and", "of", "is"}
def translate(state):
    return {"fr": llm.invoke(f"Translate to French: {state['en']}").content,
            "attempts": 1}
def check(state):
    leak = any(w in state["fr"].lower().split() for w in STOP)
    return "translate" if leak and state["attempts"] < 3 else END
```

### Solution 3
```python
researcher = Agent(role="Destination Researcher", goal="Pick top regions for foodies", ...)
planner    = Agent(role="Itinerary Planner",      goal="Day-by-day 5-day plan",        ...)
budget     = Agent(role="Budget Reviewer",         goal="Stay under $2000",             ...)
tasks = [
    Task("Pick 3 regions of Japan for a foodie trip in Oct.", agent=researcher,
         expected_output="3 regions + reasons"),
    Task("Build day-by-day plan from the chosen regions.",     agent=planner,
         context=[...]),
    Task("Add costs and trim to <$2000.",                      agent=budget,
         context=[...]),
]
Crew(agents=[researcher, planner, budget], tasks=tasks).kickoff()
```

### Solution 4
1. **LangChain** — 1-shot summarisation.
2. **LangGraph** — needs a loop with retries.
3. **CrewAI** — multiple specialists with roles.
4. **LangChain** — 2 linear steps.
5. **LangGraph** — built-in human-in-the-loop nodes.

### Solution 5
```python
from langgraph.graph import StateGraph, START, END
from crewai import Agent, Task, Crew

def writing_node(state):
    # stub crew
    drafter = Agent(role="Drafter", goal="Draft a 100-word post", backstory="...", llm=llm)
    crew = Crew(agents=[drafter],
                tasks=[Task("Write about {topic}.", agent=drafter,
                            expected_output="100 words")])
    result = crew.kickoff(inputs={"topic": state["topic"]})
    return {"draft": result.raw}

g = StateGraph(dict)
g.add_node("write", writing_node)
g.add_edge(START, "write"); g.add_edge("write", END)
print(g.compile().invoke({"topic": "octopuses"})["draft"])
```

---

## 🎯 What you should now be able to do

- [x] Explain when to use LangChain vs LangGraph vs CrewAI
- [x] Build the same workflow in each
- [x] Add loops & retries with LangGraph
- [x] Spin up a role-based crew with CrewAI

🎉 **Module 4 complete!**
➡️ Next module: **[Module 5 — Agentic Design Patterns](../Module5_Agentic_AI/01_Agentic_Design_Patterns.md)**
