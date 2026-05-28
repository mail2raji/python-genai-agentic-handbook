# Capstone 2 — Powershell Doc Buddy

!!! info "Runnable source file"
    **Path:** `Chapter11_Capstones_ITops/capstone2_powershell_doc_buddy.py`  
    **Phase:** Phase 6 — Capstone Projects  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/genai-agentic-ai-handbook)) and run it locally.

```python
"""
🎓 CAPSTONE 2 — PowerShell Doc Buddy
=====================================

A focused RAG agent that answers questions about YOUR workspace's
PowerShell scripts and docs, with cited sources.

This is a thin wrapper around the Phase 4 RAG mini-project,
tuned with a system prompt that emphasizes:
  - Citing source filenames
  - Quoting exact parameter names
  - Saying "I don't know" when the info isn't in the indexed files

▶️ Run:
    python capstone2_powershell_doc_buddy.py
"""

import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
PHASE4 = os.path.abspath(os.path.join(HERE, "..", "Phase4_GenAI_Fundamentals"))
if PHASE4 not in sys.path:
    sys.path.insert(0, PHASE4)

# Re-use everything from Phase 4 mini-project
from mini_project_doc_qa import load_or_build_index, retrieve   # noqa: E402
from llm_client import chat                                      # noqa: E402

SYSTEM_PROMPT = """You are PowerShell Doc Buddy — an expert on the user's local
PowerShell automation repo.

Hard rules:
1. Use ONLY the provided CONTEXT.
2. Quote exact parameter names, file names, and cmdlets — don't paraphrase identifiers.
3. If the answer isn't fully supported by the CONTEXT, say:
   "I don't see that in the files I have access to."
4. Always end with a 'Sources:' line listing the FILE names used.
5. If the user asks "how do I run X", show an actual sample invocation.
"""


def ask(query: str, index, top_k: int = 6) -> str:
    chunks = retrieve(query, index, top_k=top_k)
    ctx = "\n\n---\n\n".join(f"[FILE: {c.source}]\n{c.text}" for c in chunks)
    return chat(
        [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user",   "content": f"CONTEXT:\n{ctx}\n\nQUESTION: {query}"},
        ],
        temperature=0.1, max_tokens=800,
    )


def main():
    index = load_or_build_index()
    print(f"\n🤖 PowerShell Doc Buddy ready. {len(index)} chunks indexed.")
    print("Type a question, or 'quit' to exit.\n")
    while True:
        try:
            q = input("> ").strip()
        except (EOFError, KeyboardInterrupt):
            break
        if not q or q.lower() in {"quit", "exit"}:
            break
        print("\n" + ask(q, index) + "\n")


if __name__ == "__main__":
    main()

```
