# Lesson 2 — First Llm Call

!!! info "Runnable source file"
    **Path:** `Phase4_GenAI_Fundamentals/02_first_llm_call.py`  
    **Phase:** Phase 4 — GenAI Fundamentals  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/python-genai-agentic-handbook)) and run it locally.

```python
"""
Lesson 2: Your First LLM Call
==============================

📖 CONCEPT:
Send a list of messages to the model, receive an assistant reply.
This is the foundation of EVERYTHING in GenAI.

💡 ANALOGY:
Like texting a very knowledgeable assistant. You give it context (system),
then chat back and forth (user/assistant turns).

📦 INSTALL:  pip install openai python-dotenv
"""

from llm_client import chat


# --- The 3 standard roles ---
messages = [
    {"role": "system",  "content": "You are a friendly IT support assistant. Keep replies to 2 sentences."},
    {"role": "user",    "content": "My VPN keeps disconnecting every few minutes. Any quick tips?"},
]

reply = chat(messages, temperature=0.5)
print("Assistant:", reply)


# --- Multi-turn conversation ---
print("\n--- Multi-turn ---")
history = [
    {"role": "system", "content": "You are a senior Python tutor for beginners."},
]
turns = [
    "What's the difference between a list and a tuple?",
    "Give me a one-line code example for each.",
]
for user_text in turns:
    history.append({"role": "user", "content": user_text})
    reply = chat(history, temperature=0.3)
    history.append({"role": "assistant", "content": reply})
    print(f"\nYOU:       {user_text}")
    print(f"ASSISTANT: {reply}")


# --- Try different temperatures ---
print("\n--- Temperature comparison ---")
prompt = [{"role": "user", "content": "Write a one-sentence tagline for an AI startup."}]
for temp in [0.0, 0.7, 1.3]:
    print(f"\ntemp={temp}: {chat(prompt, temperature=temp)}")


# ============================================================
# ✏️ EXERCISE:
# 1. Build a `tutor(question)` function that always uses the same system prompt.
# 2. Call it with 3 different beginner Python questions.
# 3. Notice how the system prompt affects the style of answers.
# ============================================================

```
