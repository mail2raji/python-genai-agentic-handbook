# Lesson 9 — Functions

!!! info "Runnable source file"
    **Path:** `Chapter01_Python_Fundamentals/09_functions.py`  
    **Phase:** Phase 1 — Python Fundamentals  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/genai-agentic-ai-handbook)) and run it locally.

```python
"""
Lesson 9: Functions
====================

📖 CONCEPT:
A function is a reusable block of code with a name.
In Agentic AI, every "tool" the agent uses is just a Python function!

💡 REAL-WORLD ANALOGY:
A microwave button: you press "popcorn" (the function name),
and it runs the same sequence every time.

🧪 EXAMPLE — defining "tools" for an AI agent:
"""

# Basic function
def greet(name):
    """Return a greeting string."""        # docstring (LLMs read this!)
    return f"Hello, {name}!"

print(greet("Priya"))


# Function with multiple parameters and a default value
def build_prompt(question, role="helpful assistant", language="English"):
    """Build a prompt for an LLM."""
    return f"You are a {role}. Respond in {language}.\n\nQuestion: {question}"

print(build_prompt("What is RAG?"))
print()
print(build_prompt("What is RAG?", role="senior AI engineer", language="French"))


# Function that returns multiple values
def analyze_text(text):
    word_count = len(text.split())
    char_count = len(text)
    return word_count, char_count

words, chars = analyze_text("Hello GenAI world")
print(f"\nWords: {words}, Chars: {chars}")


# Real agent tool example
def calculate_cost(input_tokens: int, output_tokens: int) -> float:
    """
    Calculate API cost in USD.
    This kind of function with type hints + docstring is EXACTLY
    what an LLM agent uses to decide whether to call it.
    """
    in_rate = 0.00015 / 1000    # per token
    out_rate = 0.00060 / 1000
    return input_tokens * in_rate + output_tokens * out_rate

print(f"\nCost: ${calculate_cost(1500, 800):.6f}")


# Tools registry — how agents discover available functions
def search_web(query: str) -> str:
    """Search the web and return the top result."""
    return f"[MOCK] Top result for '{query}'"

def send_email(to: str, subject: str, body: str) -> str:
    """Send an email and return a confirmation."""
    return f"[MOCK] Email sent to {to} with subject '{subject}'"

# Store functions in a dict — the foundation of an agent's tool registry
TOOLS = {
    "search_web": search_web,
    "send_email": send_email,
    "calculate_cost": calculate_cost,
}

# Call a tool by name (this is exactly what an LLM agent does!)
tool_name = "search_web"
result = TOOLS[tool_name]("What is LangChain?")
print(f"\nTool '{tool_name}' returned: {result}")


# ============================================================
# ✏️ EXERCISE:
# Build a function `summarize_ticket(ticket_id, priority, description)` that:
#   - priority defaults to "medium"
#   - returns a one-line summary string
#   - if priority == "critical", prefix with "🚨"
# Test it with different inputs.
# ============================================================


# ✅ SOLUTION:
# def summarize_ticket(ticket_id, description, priority="medium"):
#     prefix = "🚨 " if priority == "critical" else ""
#     return f"{prefix}[{ticket_id}] ({priority}) {description}"
#
# print(summarize_ticket("INC-1", "Server down", "critical"))
# print(summarize_ticket("INC-2", "Slow VPN"))

```
