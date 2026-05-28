# Lesson 7 — Conditionals

!!! info "Runnable source file"
    **Path:** `Chapter01_Python_Fundamentals/07_conditionals.py`  
    **Phase:** Phase 1 — Python Fundamentals  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/genai-agentic-ai-handbook)) and run it locally.

```python
"""
Lesson 7: Conditionals (if / elif / else)
==========================================

📖 CONCEPT:
Make decisions in code. Used in agents to decide which tool to call,
or in safety filters to block bad content.

💡 REAL-WORLD ANALOGY:
A traffic light: IF red → stop, ELIF yellow → slow, ELSE → go.

🧪 EXAMPLE — content safety filter:
"""

user_message = "Tell me about Azure security best practices"

# Simple if/else
if "password" in user_message.lower():
    print("⚠️ Blocked: cannot discuss passwords")
else:
    print("✅ Safe to process")

# if / elif / else — routing an LLM request
intent = "billing"

if intent == "support":
    print("→ Route to IT support agent")
elif intent == "billing":
    print("→ Route to billing agent")
elif intent == "sales":
    print("→ Route to sales agent")
else:
    print("→ Route to general assistant")

# Comparison operators
tokens = 5000
MAX_TOKENS = 4096

if tokens > MAX_TOKENS:
    print(f"❌ Too many tokens: {tokens} > {MAX_TOKENS}")
elif tokens == MAX_TOKENS:
    print("⚠️ At the limit")
else:
    print(f"✅ OK: {tokens}/{MAX_TOKENS} tokens")

# Logical operators: and, or, not
user = {"is_premium": True, "age": 25}

if user["is_premium"] and user["age"] >= 18:
    print("→ Access GPT-4 model")
elif user["is_premium"] or user["age"] >= 21:
    print("→ Access GPT-3.5 model")

# Truthiness — empty values are "falsy"
api_key = ""
if not api_key:
    print("❌ API key missing!")


# ============================================================
# ✏️ EXERCISE:
# Write a function-like check:
#   - If a user query is empty → print "Please enter a question"
#   - If the query contains "delete" or "drop" → print "Dangerous action blocked"
#   - If the query length > 500 → print "Query too long"
#   - Otherwise → print "Processing..."
# Test with different queries.
# ============================================================


# ✅ SOLUTION:
# query = "drop table users"
# if not query:
#     print("Please enter a question")
# elif "delete" in query.lower() or "drop" in query.lower():
#     print("Dangerous action blocked")
# elif len(query) > 500:
#     print("Query too long")
# else:
#     print("Processing...")

```
