# Lesson 5 — Streaming

!!! info "Runnable source file"
    **Path:** `Phase4_GenAI_Fundamentals/05_streaming.py`  
    **Phase:** Phase 4 — GenAI Fundamentals  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/python-genai-agentic-handbook)) and run it locally.

```python
"""
Lesson 5: Streaming Responses
===============================

📖 CONCEPT:
Instead of waiting for the full reply, stream tokens as they arrive.
Every modern AI app (ChatGPT, Copilot) uses streaming for fast UX.

💡 ANALOGY:
Watching someone type live vs waiting for them to email you the finished essay.
"""

from llm_client import chat_stream

print("Streaming response:\n")
for chunk in chat_stream([
    {"role": "system", "content": "You are a Python tutor."},
    {"role": "user",   "content": "Explain the difference between == and is in Python in 4 lines."},
]):
    print(chunk, end="", flush=True)

print("\n\n✅ Done.")


# ============================================================
# ✏️ EXERCISE:
# Stream the model writing a short bedtime story (about a curious AI agent).
# Add a typing-indicator like "🤖 thinking..." before streaming starts.
# ============================================================

```
