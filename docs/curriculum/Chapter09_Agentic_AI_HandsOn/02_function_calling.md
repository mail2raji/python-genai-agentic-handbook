# Lesson 2 — Function Calling

!!! info "Runnable source file"
    **Path:** `Chapter09_Agentic_AI_HandsOn/02_function_calling.py`  
    **Phase:** Phase 5 — Agentic AI  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/genai-agentic-ai-handbook)) and run it locally.

```python
"""
Lesson 2: Function Calling — The Agent's Hands
================================================

📖 CONCEPT:
"Function calling" (aka tool-use) is the LLM's way of asking your code to do something.
You expose Python functions to the model with a schema; when needed, the model
replies with a structured request: "call `get_weather` with city='London'".
Your code runs the function and feeds the result back.

This is THE building block of every agent.

💡 ANALOGY:
You're a manager. The LLM is an assistant who can't browse the web or check
the database directly — so they ask you (the runtime) to do it on their behalf.
"""

from __future__ import annotations
import json
import os
from llm_client import MODE

# ---------------- Define real Python tools ----------------
def get_weather(city: str) -> dict:
    """Mock weather lookup. Replace with a real API in production."""
    fake = {
        "London":  {"temp_c": 14, "condition": "rainy"},
        "Mumbai":  {"temp_c": 32, "condition": "humid"},
        "Tokyo":   {"temp_c": 21, "condition": "clear"},
        "Redmond": {"temp_c": 11, "condition": "cloudy"},
    }
    return fake.get(city.title(), {"error": f"Unknown city: {city}"})


def calculate(expression: str) -> str:
    """Safely evaluate a simple math expression."""
    allowed = set("0123456789+-*/(). ")
    if not set(expression) <= allowed:
        return "ERROR: only digits and + - * / ( ) allowed"
    try:
        return str(eval(expression, {"__builtins__": {}}, {}))
    except Exception as e:
        return f"ERROR: {e}"


# ---------------- Tool schemas (what the LLM sees) ----------------
TOOL_SCHEMAS = [
    {
        "type": "function",
        "function": {
            "name": "get_weather",
            "description": "Get the current weather for a city.",
            "parameters": {
                "type": "object",
                "properties": {
                    "city": {"type": "string", "description": "City name, e.g. 'London'."},
                },
                "required": ["city"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "calculate",
            "description": "Evaluate a simple math expression.",
            "parameters": {
                "type": "object",
                "properties": {
                    "expression": {"type": "string", "description": "Math expression like '2+3*4'."},
                },
                "required": ["expression"],
            },
        },
    },
]

# Map name → real Python function
DISPATCH = {
    "get_weather": get_weather,
    "calculate":   calculate,
}


# ---------------- The agent loop ----------------
# Function calling requires the real OpenAI/Azure client (not our mock).
# We'll use the underlying client directly for this lesson.

if MODE == "mock":
    print("⚠️  Function calling needs a real LLM. Set OPENAI_API_KEY or AZURE_OPENAI_* in .env.")
    print("    Showing a SIMULATED trace instead.\n")

    SIM = [
        {"thought": "User asked about weather in London.",
         "tool": "get_weather", "args": {"city": "London"}},
        {"thought": "Got weather. Now compute the asked math.",
         "tool": "calculate",   "args": {"expression": "14 * 9/5 + 32"}},
    ]
    print("USER: What's the weather in London, and convert that to Fahrenheit?\n")
    for step in SIM:
        print(f"💭 {step['thought']}")
        result = DISPATCH[step["tool"]](**step["args"])
        print(f"🔧 calling {step['tool']}({step['args']}) → {result}\n")
    print("ASSISTANT: It's 14°C and rainy in London, which is about 57.2°F.")

else:
    # Real function-calling loop with OpenAI/Azure
    from openai import OpenAI, AzureOpenAI
    if MODE == "openai":
        client = OpenAI()
        model = os.getenv("OPENAI_MODEL", "gpt-4o-mini")
    else:
        client = AzureOpenAI(
            api_key=os.getenv("AZURE_OPENAI_API_KEY"),
            api_version=os.getenv("AZURE_OPENAI_API_VERSION", "2024-10-21"),
            azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"),
        )
        model = os.getenv("AZURE_OPENAI_DEPLOYMENT", "gpt-4o-mini")

    messages = [
        {"role": "system", "content":
         "You are a helpful assistant. Use tools when needed. "
         "Always provide a final, plain-English answer to the user."},
        {"role": "user", "content":
         "What's the weather in London right now, and convert that temperature to Fahrenheit?"},
    ]

    for step in range(5):                      # safety: max 5 turns
        resp = client.chat.completions.create(
            model=model,
            messages=messages,
            tools=TOOL_SCHEMAS,
            tool_choice="auto",
        )
        msg = resp.choices[0].message
        messages.append(msg)

        if not msg.tool_calls:                 # done thinking — final answer
            print("\n🤖 FINAL ANSWER:", msg.content)
            break

        for call in msg.tool_calls:
            name = call.function.name
            args = json.loads(call.function.arguments or "{}")
            print(f"🔧 LLM wants to call {name}({args})")
            result = DISPATCH[name](**args)
            print(f"   → {result}")
            messages.append({
                "role": "tool",
                "tool_call_id": call.id,
                "name": name,
                "content": json.dumps(result),
            })


# ============================================================
# ✏️ EXERCISE:
# Add a 3rd tool: `send_email(to, subject, body)` that just prints
# what would be sent. Modify the user goal to require sending an email.
# ============================================================

```
