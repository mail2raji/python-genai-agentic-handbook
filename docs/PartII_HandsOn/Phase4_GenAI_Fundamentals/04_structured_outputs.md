# Lesson 4 — Structured Outputs

!!! info "Runnable source file"
    **Path:** `Phase4_GenAI_Fundamentals/04_structured_outputs.py`  
    **Phase:** Phase 4 — GenAI Fundamentals  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/python-genai-agentic-handbook)) and run it locally.

```python
"""
Lesson 4: Structured Outputs (JSON Mode)
==========================================

📖 CONCEPT:
For agents, you need predictable output your code can parse.
Modern LLMs support "JSON mode" — guaranteed to return valid JSON.

💡 ANALOGY:
Instead of an essay, ask for a form filled in. Easier to process programmatically.
"""

import json
from llm_client import chat


# --- Method 1: Ask + JSON mode flag ---
SYSTEM = """You extract structured info from IT support tickets.
Respond ONLY with valid JSON in this exact schema:
{
  "category": "NETWORK|ACCOUNT|HARDWARE|SOFTWARE|OTHER",
  "priority": "low|medium|high|critical",
  "affected_user": "<email or null>",
  "key_phrases": ["<keyword>", ...]
}
"""

tickets = [
    "Priya from finance can't access the SAP server. Production is halted.",
    "ravi@contoso.com forgot his password — please reset.",
    "My headset mic isn't working in Teams. No rush.",
]

for t in tickets:
    raw = chat(
        [
            {"role": "system", "content": SYSTEM},
            {"role": "user",   "content": t},
        ],
        temperature=0,
        response_format={"type": "json_object"},   # OpenAI/Azure OpenAI JSON mode
    )

    print(f"\nTicket: {t}")
    try:
        parsed = json.loads(raw)
        print("Parsed:", json.dumps(parsed, indent=2))
    except json.JSONDecodeError:
        print("⚠️  LLM did not return valid JSON. Raw:", raw)


# --- Method 2: With Pydantic validation (production-grade) ---
# Pydantic ensures the JSON matches your schema. If it doesn't, you can re-prompt.
try:
    from pydantic import BaseModel, Field, ValidationError

    class TicketAnalysis(BaseModel):
        category: str = Field(..., pattern="^(NETWORK|ACCOUNT|HARDWARE|SOFTWARE|OTHER)$")
        priority: str = Field(..., pattern="^(low|medium|high|critical)$")
        affected_user: str | None
        key_phrases: list[str]

    raw = chat(
        [
            {"role": "system", "content": SYSTEM},
            {"role": "user",   "content": tickets[0]},
        ],
        temperature=0,
        response_format={"type": "json_object"},
    )
    try:
        analysis = TicketAnalysis.model_validate_json(raw)
        print("\n✅ Validated:", analysis)
    except ValidationError as e:
        print("⚠️ Validation failed:", e)

except ImportError:
    print("\n(Install pydantic to try strict validation:  pip install pydantic)")


# ============================================================
# ✏️ EXERCISE:
# Build an extractor that turns a free-text product review into:
# {"rating": 1-5, "sentiment": "positive|neutral|negative", "topics": [...]}
# Run it on 3 reviews and print the parsed dicts.
# ============================================================

```
