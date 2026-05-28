# Lesson 5 — Type Hints

!!! info "Runnable source file"
    **Path:** `Phase2_Intermediate_Python/05_type_hints.py`  
    **Phase:** Phase 2 — Intermediate Python  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/python-genai-agentic-handbook)) and run it locally.

```python
"""
Lesson 5: Type Hints
=====================

📖 CONCEPT:
Type hints tell readers (and your IDE, and LLM agents!) what types
functions expect and return. They don't enforce anything at runtime,
but they catch bugs early and improve autocompletion.

💡 WHY THIS MATTERS FOR AI:
LLMs read function signatures + docstrings to decide which tool to call.
Good types = the LLM picks the right tool with the right args.

💡 ANALOGY:
Like food labels — they don't change the food, but they tell you what's inside.
"""

from typing import Optional, Union

# --- Basic type hints ---
def greet(name: str) -> str:
    return f"Hello, {name}"

# --- Multiple param types + return ---
def add(a: int, b: int) -> int:
    return a + b

# --- Collections ---
def average(numbers: list[float]) -> float:
    return sum(numbers) / len(numbers)

print(average([1.0, 2.0, 3.0]))

# --- Optional (can be None) ---
def find_user(user_id: int) -> Optional[dict]:
    if user_id == 1:
        return {"name": "Priya"}
    return None

# --- Union (Python 3.10+ shorter syntax: int | str) ---
def stringify(value: int | str) -> str:
    return str(value)

# --- Dict shape with TypedDict ---
from typing import TypedDict

class LLMResponse(TypedDict):
    model: str
    content: str
    tokens: int

def parse_response() -> LLMResponse:
    return {"model": "gpt-4o", "content": "hi", "tokens": 42}

# --- Real agent tool signature ---
def search_documents(
    query: str,
    top_k: int = 5,
    min_score: float = 0.7,
) -> list[dict]:
    """
    Search the document store and return the top-k most relevant docs.

    Args:
        query: User's search query.
        top_k: Number of results to return.
        min_score: Minimum similarity score (0-1).

    Returns:
        List of {"title": str, "score": float, "snippet": str} dicts.
    """
    return [
        {"title": "Doc1", "score": 0.92, "snippet": "..."},
        {"title": "Doc2", "score": 0.85, "snippet": "..."},
    ]


# --- Dataclasses: classes with auto-generated __init__ ---
from dataclasses import dataclass

@dataclass
class AgentConfig:
    model: str
    temperature: float = 0.7
    max_tokens: int = 1000
    tools: list[str] = None

config = AgentConfig(model="gpt-4o-mini", tools=["search", "email"])
print(config)


# ============================================================
# ✏️ EXERCISE:
# Add type hints to this function:
#   def make_prompt(role, question, examples=None):
#       ...
# (role: str, question: str, examples: optional list of dicts, returns str)
# ============================================================

```
