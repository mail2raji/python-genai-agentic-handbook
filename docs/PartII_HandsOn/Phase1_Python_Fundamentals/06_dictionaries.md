# Lesson 6 — Dictionaries

!!! info "Runnable source file"
    **Path:** `Phase1_Python_Fundamentals/06_dictionaries.py`  
    **Phase:** Phase 1 — Python Fundamentals  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/python-genai-agentic-handbook)) and run it locally.

```python
"""
Lesson 6: Dictionaries
=======================

📖 CONCEPT:
A dictionary stores key → value pairs. It's the #1 data structure
for representing structured data: JSON, API responses, LLM messages.

💡 REAL-WORLD ANALOGY:
A dictionary is like a real dictionary — you look up a word (key)
to find its meaning (value).

🧪 EXAMPLE — representing an LLM API response:
"""

# Create a dict
user = {
    "id": 1042,
    "name": "Priya",
    "email": "priya@contoso.com",
    "is_admin": False,
}

# Access values by key
print(user["name"])
print(user["email"])

# Safe access (won't crash if key missing)
print(user.get("phone", "Not provided"))

# Add or update keys
user["phone"] = "+1-555-0100"
user["is_admin"] = True
print(user)

# Delete a key
del user["is_admin"]

# Loop through a dict
print("\n--- User fields ---")
for key, value in user.items():
    print(f"{key}: {value}")

# Nested dicts (real LLM API response shape)
llm_response = {
    "model": "gpt-4o-mini",
    "usage": {
        "input_tokens": 150,
        "output_tokens": 80,
        "total_tokens": 230,
    },
    "choices": [
        {"index": 0, "message": {"role": "assistant", "content": "Hi there!"}},
    ],
}

# Drill into nested structures
print("\nAssistant reply:", llm_response["choices"][0]["message"]["content"])
print("Tokens used:", llm_response["usage"]["total_tokens"])


# ============================================================
# ✏️ EXERCISE:
# Create a dictionary representing an AI agent's "tool definition":
#   - name: "send_email"
#   - description: "Sends an email to a recipient"
#   - parameters: a nested dict with "to" (str), "subject" (str), "body" (str)
# Then print the tool name and description.
# ============================================================


# ✅ SOLUTION:
# tool = {
#     "name": "send_email",
#     "description": "Sends an email to a recipient",
#     "parameters": {"to": "str", "subject": "str", "body": "str"},
# }
# print(tool["name"], "-", tool["description"])

```
