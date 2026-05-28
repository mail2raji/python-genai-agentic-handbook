# Lesson 6 — Multi Agent

!!! info "Runnable source file"
    **Path:** `Chapter09_Agentic_AI_HandsOn/06_multi_agent.py`  
    **Phase:** Phase 5 — Agentic AI  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/genai-agentic-ai-handbook)) and run it locally.

```python
"""
Lesson 6: Multi-Agent Collaboration
=====================================

📖 CONCEPT:
Instead of one super-agent, use multiple specialists that pass work between them.
This often gives better results, parallelism, and clearer responsibilities.

Common roles:
  - Planner: breaks down goal into steps
  - Researcher: gathers info
  - Writer: drafts the answer
  - Critic: reviews and improves

💡 ANALOGY:
A newsroom: editor → reporter → copy editor → publisher.
Each is great at one job and hands off when done.
"""

from llm_client import chat


def planner(goal: str) -> str:
    """Break a goal into 3–5 ordered steps."""
    return chat([
        {"role": "system", "content":
         "You are PLANNER. Output a numbered list of 3–5 short steps to achieve the user's goal. No prose."},
        {"role": "user", "content": goal},
    ], temperature=0.2)


def researcher(step: str) -> str:
    """Find relevant info for one step."""
    return chat([
        {"role": "system", "content":
         "You are RESEARCHER. Given a single research step, output 3 bullet facts (made up but plausible) needed to complete it."},
        {"role": "user", "content": step},
    ], temperature=0.3)


def writer(goal: str, research_blob: str) -> str:
    """Produce the final answer for the user."""
    return chat([
        {"role": "system", "content":
         "You are WRITER. Use the research notes to answer the user's goal. "
         "Style: clear, concise, audience = non-technical executive."},
        {"role": "user", "content": f"GOAL: {goal}\n\nRESEARCH:\n{research_blob}"},
    ], temperature=0.4)


def critic(draft: str) -> str:
    """Critique the draft and output an improved version."""
    return chat([
        {"role": "system", "content":
         "You are CRITIC. Improve the draft for clarity and remove fluff. "
         "Return ONLY the improved version (no commentary)."},
        {"role": "user", "content": draft},
    ], temperature=0.3)


def run(goal: str) -> str:
    print(f"\n🎯 GOAL: {goal}")

    print("\n--- 1. PLANNER ---")
    plan = planner(goal)
    print(plan)

    print("\n--- 2. RESEARCHER (per step) ---")
    research = []
    for line in plan.splitlines():
        if line.strip() and line.strip()[0].isdigit():
            print(f"\nStep: {line}")
            facts = researcher(line)
            print(facts)
            research.append(f"### {line}\n{facts}")

    print("\n--- 3. WRITER ---")
    draft = writer(goal, "\n\n".join(research))
    print(draft)

    print("\n--- 4. CRITIC ---")
    final = critic(draft)
    print(final)
    return final


if __name__ == "__main__":
    run("Brief our executives on the risks of using public LLMs for company data.")


# ============================================================
# 🧠 KEY IDEAS:
#  - Each agent has its own system prompt (its personality + job).
#  - The OUTPUT of one becomes the INPUT of the next.
#  - You can run independent steps in parallel with asyncio.
#  - Frameworks (CrewAI, AutoGen, LangGraph) formalize this pattern.
# ============================================================

```
