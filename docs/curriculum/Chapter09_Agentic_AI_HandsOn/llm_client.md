# Shared LLM Client

!!! info "Runnable source file"
    **Path:** `Chapter09_Agentic_AI_HandsOn/llm_client.py`  
    **Phase:** Phase 5 — Agentic AI  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/genai-agentic-ai-handbook)) and run it locally.

```python
"""
Shared LLM client for Phase 5.
Re-exports the same client from Phase 4 so all lessons stay in sync.
"""
import os
import sys

# Add Phase 4 to the import path
HERE = os.path.dirname(os.path.abspath(__file__))
PHASE4 = os.path.abspath(os.path.join(HERE, "..", "Phase4_GenAI_Fundamentals"))
if PHASE4 not in sys.path:
    sys.path.insert(0, PHASE4)

from llm_client import chat, chat_stream, embed, embed_many, MODE  # noqa: F401

```
