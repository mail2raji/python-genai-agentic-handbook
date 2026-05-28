# Lesson 3 — Error Handling

!!! info "Runnable source file"
    **Path:** `Chapter02_Intermediate_Python/03_error_handling.py`  
    **Phase:** Phase 2 — Intermediate Python  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/genai-agentic-ai-handbook)) and run it locally.

```python
"""
Lesson 3: Error Handling (try / except)
========================================

📖 CONCEPT:
APIs fail. Files are missing. LLMs return invalid JSON. Robust agents
MUST handle errors gracefully — otherwise one failed tool call crashes everything.

💡 REAL-WORLD ANALOGY:
A safety net under a tightrope walker. They might fall — the net catches them.
"""

# --- Basic try/except ---
try:
    result = 10 / 0
except ZeroDivisionError as e:
    print("❌ Math error:", e)

# --- Multiple exception types ---
def parse_int(text):
    try:
        return int(text)
    except ValueError:
        print(f"⚠️  '{text}' is not a number, returning 0")
        return 0
    except TypeError:
        print("⚠️  Wrong type, returning 0")
        return 0

print(parse_int("42"))
print(parse_int("abc"))
print(parse_int(None))

# --- try / except / else / finally ---
import json

def safe_load_json(raw_text):
    """Real GenAI scenario: LLMs sometimes return broken JSON."""
    try:
        data = json.loads(raw_text)
    except json.JSONDecodeError as e:
        print(f"❌ LLM returned invalid JSON: {e}")
        return None
    else:
        print("✅ JSON parsed successfully")
        return data
    finally:
        print("   (cleanup always runs)\n")

safe_load_json('{"name": "Priya", "age": 30}')   # valid
safe_load_json('{"name": Priya}')                 # invalid

# --- Raising your own errors ---
def call_llm(prompt, api_key):
    if not api_key:
        raise ValueError("API key is required!")
    if len(prompt) > 10000:
        raise ValueError(f"Prompt too long: {len(prompt)} chars")
    return f"[MOCK LLM RESPONSE for: {prompt[:30]}...]"

try:
    call_llm("Hello", api_key="")
except ValueError as e:
    print("Caught:", e)

# --- Retry pattern (super common in AI code) ---
import time, random

def retry_api_call(max_attempts=3):
    for attempt in range(1, max_attempts + 1):
        try:
            if random.random() < 0.7:           # 70% chance of failure
                raise ConnectionError("Network blip")
            print(f"✅ Attempt {attempt} succeeded")
            return "data"
        except ConnectionError as e:
            print(f"⚠️  Attempt {attempt} failed: {e}")
            if attempt == max_attempts:
                print("❌ All retries exhausted")
                raise
            time.sleep(0.1 * attempt)            # exponential-ish backoff

try:
    retry_api_call()
except ConnectionError:
    pass


# ============================================================
# ✏️ EXERCISE:
# Write a function `read_user_file(path)` that:
#   - Tries to open and read the file
#   - Returns the content if successful
#   - Catches FileNotFoundError → returns "FILE NOT FOUND"
#   - Catches PermissionError → returns "ACCESS DENIED"
#   - Has a finally block that prints "Done"
# ============================================================

```
