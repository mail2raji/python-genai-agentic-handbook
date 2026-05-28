# Lesson 5 — Lists

!!! info "Runnable source file"
    **Path:** `Phase1_Python_Fundamentals/05_lists.py`  
    **Phase:** Phase 1 — Python Fundamentals  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/python-genai-agentic-handbook)) and run it locally.

```python
"""
Lesson 5: Lists
================

📖 CONCEPT:
A list is an ordered collection of items. Lists are EVERYWHERE in AI:
- list of messages in a chat
- list of documents to embed
- list of tools an agent can use

💡 REAL-WORLD ANALOGY:
A list is like a numbered shopping list — order matters, you can add or remove items.

🧪 EXAMPLE — managing a chat conversation history:
"""

# Create a list
messages = [
    "Hello, how can I help?",
    "I forgot my password.",
    "I can help reset it. What's your email?",
]

# Access by index (starts at 0!)
print("First message:", messages[0])
print("Last message:", messages[-1])   # -1 = last item

# Length
print("Number of messages:", len(messages))

# Add an item to the end
messages.append("user@contoso.com")
print(messages)

# Insert at a specific position
messages.insert(0, "[SYSTEM] Session started")
print(messages)

# Remove an item
messages.remove("[SYSTEM] Session started")

# Slicing (get a sub-list)
print("First 2 messages:", messages[:2])
print("Last 2 messages:", messages[-2:])

# Loop through a list
print("\n--- All messages ---")
for msg in messages:
    print("→", msg)

# Check membership
if "I forgot my password." in messages:
    print("\nPassword reset flow detected!")

# List of dicts — THE most common LLM message format
chat_history = [
    {"role": "system",    "content": "You are a helpful IT assistant."},
    {"role": "user",      "content": "My laptop is slow."},
    {"role": "assistant", "content": "Have you tried restarting it?"},
]
print("\n--- Chat history ---")
for m in chat_history:
    print(f"{m['role']}: {m['content']}")


# ============================================================
# ✏️ EXERCISE:
# 1. Create a list of 5 AI tools an agent could use:
#    ["search_web", "send_email", "read_file", "run_sql", "create_ticket"]
# 2. Add "summarize_doc" to the list.
# 3. Remove "run_sql".
# 4. Print the final list and its length.
# ============================================================


# ✅ SOLUTION:
# tools = ["search_web", "send_email", "read_file", "run_sql", "create_ticket"]
# tools.append("summarize_doc")
# tools.remove("run_sql")
# print(tools, len(tools))

```
