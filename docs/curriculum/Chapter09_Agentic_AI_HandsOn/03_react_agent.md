# Lesson 3 — React Agent

!!! info "Runnable source file"
    **Path:** `Chapter09_Agentic_AI_HandsOn/03_react_agent.py`  
    **Phase:** Phase 5 — Agentic AI  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/genai-agentic-ai-handbook)) and run it locally.

```python
"""
Lesson 3: The ReAct Loop — Reason + Act
=========================================

📖 CONCEPT:
ReAct = the agent ALTERNATES "Thought" → "Action" → "Observation" → "Thought" ...
until it produces "Final Answer".

This works even WITHOUT native function calling — pure prompting.
Understanding ReAct is essential before using frameworks (LangChain, LangGraph).

💡 ANALOGY:
A detective talking out loud: "I think it's the butler. Let me check his alibi.
[checks] → alibi is fake. Now let me question the maid..."
"""

from __future__ import annotations
import re
from llm_client import chat


# --- Tools (same shape as Lesson 2) ---
def search_kb(query: str) -> str:
    kb = {
        "vpn": "Use AnyConnect, host vpn.contoso.com, login with Entra ID.",
        "password": "Reset at https://passwords.contoso.com. Rules: 14 chars, mixed case + number + symbol.",
        "office": "HQ open 8am–6pm Mon–Fri. Closed federal holidays.",
    }
    for k, v in kb.items():
        if k in query.lower():
            return v
    return "No match found in knowledge base."

def calculator(expr: str) -> str:
    try:
        return str(eval(expr, {"__builtins__": {}}, {}))
    except Exception as e:
        return f"ERROR: {e}"


TOOLS = {
    "search_kb":  ("Search the IT knowledge base. Input: a search query.", search_kb),
    "calculator": ("Evaluate a math expression. Input: a math string.",   calculator),
}


SYSTEM = f"""You are a ReAct agent. You solve user requests by reasoning and using tools.

You have these tools:
{chr(10).join(f"- {name}: {desc}" for name, (desc, _) in TOOLS.items())}

Format STRICTLY like this, one step per response:

Thought: <your reasoning>
Action: <tool name>
Action Input: <input string>

When you have the final answer, output:
Thought: <reasoning>
Final Answer: <answer for the user>

Do NOT output anything else.
"""


STEP_RE = re.compile(
    r"Thought:\s*(?P<thought>.+?)(?:\n+Action:\s*(?P<action>\S+)\s*\n+Action Input:\s*(?P<input>.+?)|\n+Final Answer:\s*(?P<final>.+))",
    re.DOTALL,
)


def run_agent(user_goal: str, max_steps: int = 6) -> str:
    messages = [
        {"role": "system", "content": SYSTEM},
        {"role": "user",   "content": user_goal},
    ]

    for step in range(1, max_steps + 1):
        print(f"\n--- Step {step} ---")
        raw = chat(messages, temperature=0).strip()
        print(raw)
        messages.append({"role": "assistant", "content": raw})

        m = STEP_RE.search(raw)
        if not m:
            return f"⚠️ Agent broke format:\n{raw}"

        if m.group("final"):
            return m.group("final").strip()

        action = m.group("action").strip()
        action_input = m.group("input").strip()

        if action not in TOOLS:
            obs = f"ERROR: Unknown tool '{action}'. Available: {list(TOOLS)}"
        else:
            obs = TOOLS[action][1](action_input)
        print(f"Observation: {obs}")

        messages.append({
            "role": "user",
            "content": f"Observation: {obs}\nContinue."
        })

    return "⚠️ Agent ran out of steps."


if __name__ == "__main__":
    # NOTE: the mock client returns canned text, so ReAct only "works" with
    # a real LLM. With MOCK_MODE the loop will still demo the structure.
    print("\n🎯 GOAL: 'I forgot my password and need to know the rules.'")
    print("Final:", run_agent("I forgot my password and need to know the rules."))

    print("\n🎯 GOAL: 'What is 15% of 240?'")
    print("Final:", run_agent("What is 15% of 240?"))


# ============================================================
# 🧠 WHY THIS MATTERS:
# ReAct is the conceptual basis of LangChain agents, AutoGPT, BabyAGI, etc.
# Once you understand this, frameworks are just nicer wrappers.
# ============================================================

```
