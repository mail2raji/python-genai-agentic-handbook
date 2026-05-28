# Lesson 2 — Variables And Types

!!! info "Runnable source file"
    **Path:** `Chapter01_Python_Fundamentals/02_variables_and_types.py`  
    **Phase:** Phase 1 — Python Fundamentals  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/genai-agentic-ai-handbook)) and run it locally.

```python
"""
Lesson 2: Variables & Data Types
=================================

📖 CONCEPT:
A variable is a labeled box where you store a value.
Python has built-in "types": text (str), whole numbers (int),
decimals (float), True/False (bool).

💡 REAL-WORLD ANALOGY:
A variable is like a sticky note: "user_name → Alex".
You can change what's on the note any time.

🧪 EXAMPLE — modeling an LLM API request:
"""

# String — text wrapped in quotes
model_name = "gpt-4o-mini"

# Integer — whole number
max_tokens = 500

# Float — decimal number
temperature = 0.7

# Boolean — True or False
streaming = True

# Check the type of any variable
print("model_name:", model_name, "→ type:", type(model_name))
print("max_tokens:", max_tokens, "→ type:", type(max_tokens))
print("temperature:", temperature, "→ type:", type(temperature))
print("streaming:", streaming, "→ type:", type(streaming))

# Variables can be reassigned
temperature = 0.2  # lower = more deterministic responses
print("\nUpdated temperature to:", temperature)


# ============================================================
# ✏️ EXERCISE:
# Create variables to represent a "user" of an AI chatbot:
#   - user_id (integer)
#   - username (string)
#   - is_premium (bool)
#   - account_balance (float)
# Then print each one with its type.
# ============================================================


# ✅ SOLUTION:
# user_id = 1042
# username = "ravi"
# is_premium = True
# account_balance = 19.99
# print(user_id, username, is_premium, account_balance)

```
