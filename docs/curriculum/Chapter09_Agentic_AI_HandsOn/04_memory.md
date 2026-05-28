# Lesson 4 — Memory

!!! info "Runnable source file"
    **Path:** `Chapter09_Agentic_AI_HandsOn/04_memory.py`  
    **Phase:** Phase 5 — Agentic AI  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/genai-agentic-ai-handbook)) and run it locally.

```python
"""
Lesson 4: Memory — Short-term & Long-term
==========================================

📖 CONCEPT:
LLMs are stateless. To make an agent "remember", YOU must give it memory.

- Short-term memory: the message history of the current conversation.
- Long-term memory: stored externally (vector DB, file, SQL) and recalled when relevant.

💡 ANALOGY:
Short-term = sticky notes on your desk for today.
Long-term = a filing cabinet of everything you've ever learned.
"""

from __future__ import annotations
import json
import os
import numpy as np
from dataclasses import dataclass, field
from llm_client import chat, embed


def cosine(a, b):
    a, b = np.array(a), np.array(b)
    return float(np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b)))


# ---------------- SHORT-TERM MEMORY ----------------
@dataclass
class ShortTermMemory:
    max_turns: int = 6                        # last N user+assistant turns
    history: list[dict] = field(default_factory=list)

    def add(self, role: str, content: str):
        self.history.append({"role": role, "content": content})
        # Keep system + last 2*max_turns messages
        sys_msgs = [m for m in self.history if m["role"] == "system"]
        other = [m for m in self.history if m["role"] != "system"][-2 * self.max_turns:]
        self.history = sys_msgs + other


# ---------------- LONG-TERM MEMORY (vector store on disk) ----------------
@dataclass
class LongTermMemory:
    path: str
    facts: list[dict] = field(default_factory=list)

    def load(self):
        if os.path.exists(self.path):
            with open(self.path, "r", encoding="utf-8") as f:
                self.facts = json.load(f)

    def save(self):
        with open(self.path, "w", encoding="utf-8") as f:
            json.dump(self.facts, f, indent=2)

    def remember(self, text: str):
        self.facts.append({"text": text, "vec": embed(text)})
        self.save()

    def recall(self, query: str, top_k: int = 3) -> list[str]:
        if not self.facts:
            return []
        qv = embed(query)
        ranked = sorted(self.facts, key=lambda f: cosine(qv, f["vec"]), reverse=True)
        return [f["text"] for f in ranked[:top_k]]


# ---------------- AN AGENT WITH BOTH MEMORIES ----------------
class MemoryAgent:
    def __init__(self, ltm_path: str):
        self.short = ShortTermMemory()
        self.long  = LongTermMemory(ltm_path)
        self.long.load()
        self.short.add("system",
            "You are a helpful assistant with memory. "
            "Use the RECALLED FACTS to personalize answers. "
            "If the user states a preference or fact about themselves, "
            "begin your reply with '[REMEMBER] <fact>' on its own line so the system can store it."
        )

    def chat(self, user_msg: str) -> str:
        # Recall relevant long-term memories
        recalled = self.long.recall(user_msg)
        context = ""
        if recalled:
            context = "RECALLED FACTS:\n" + "\n".join(f"- {r}" for r in recalled) + "\n\n"

        self.short.add("user", context + user_msg)
        reply = chat(self.short.history, temperature=0.4)
        self.short.add("assistant", reply)

        # Detect and store new memories
        for line in reply.splitlines():
            if line.startswith("[REMEMBER]"):
                fact = line.replace("[REMEMBER]", "").strip()
                if fact:
                    self.long.remember(fact)
                    print(f"   💾 stored: {fact}")
        return reply


if __name__ == "__main__":
    HERE = os.path.dirname(os.path.abspath(__file__))
    agent = MemoryAgent(os.path.join(HERE, "long_term_memory.json"))

    turns = [
        "Hi! My name is Priya and I prefer concise answers.",
        "I work at Contoso as a security engineer.",
        "What should I focus on this week?",        # depends on remembered context
    ]
    for t in turns:
        print(f"\nUSER: {t}")
        print(f"BOT : {agent.chat(t)}")


# ============================================================
# ✏️ EXERCISE:
# Run the script twice. The second time, just ask "Who am I?" — the agent
# should recall what was stored in `long_term_memory.json` from run 1.
# ============================================================

```
