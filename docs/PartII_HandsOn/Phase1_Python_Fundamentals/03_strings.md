# Lesson 3 — Strings

!!! info "Runnable source file"
    **Path:** `Phase1_Python_Fundamentals/03_strings.py`  
    **Phase:** Phase 1 — Python Fundamentals  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/python-genai-agentic-handbook)) and run it locally.

```python
"""
Lesson 3: Strings & f-strings
==============================

📖 CONCEPT:
Strings are text. You can join them, slice them, and embed values using f-strings.
f-strings are the #1 tool you'll use when building prompts for LLMs!

💡 REAL-WORLD ANALOGY:
An f-string is like Mad Libs — you have a template with blanks,
and you fill in the blanks with variable values.

🧪 EXAMPLE — building a prompt for an LLM:
"""

user_name = "Priya"
ticket_id = "INC-78421"
issue = "VPN disconnects every 5 minutes"

# OLD WAY (avoid this):
prompt_old = "Hello " + user_name + ", your ticket " + ticket_id + " is being reviewed."
print(prompt_old)

# MODERN WAY — f-string (note the f before the quote):
prompt = f"Hello {user_name}, your ticket {ticket_id} is being reviewed."
print(prompt)

# Multi-line prompt template (used HEAVILY in GenAI)
llm_prompt = f"""
You are an IT support assistant.
Customer: {user_name}
Ticket: {ticket_id}
Issue: {issue}

Suggest 3 troubleshooting steps in numbered format.
"""
print(llm_prompt)

# String methods
text = "  Hello World  "
print(text.strip())          # remove whitespace
print(text.lower())          # lowercase
print(text.upper())          # UPPERCASE
print(text.replace("World", "AI"))
print(len(text))             # length

# Slicing (very common in data cleaning)
email = "ravi@contoso.com"
print(email[:4])             # first 4 chars → "ravi"
print(email.split("@"))      # split into list → ['ravi', 'contoso.com']


# ============================================================
# ✏️ EXERCISE:
# Build an f-string prompt for an LLM that:
#   - Greets a user by name
#   - Mentions their company
#   - Asks the LLM to write a 2-line product description
# ============================================================


# ✅ SOLUTION:
# name = "Sara"
# company = "Contoso"
# product = "AI-powered firewall"
# prompt = f"Hi {name} from {company}, write a 2-line marketing pitch for our {product}."
# print(prompt)

```
