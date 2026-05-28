# Lesson 3 — Memory Production

!!! info "Runnable source file"
    **Path:** `Phase7_Production_Agents/03_memory_production.py`  
    **Phase:** Phase 7 — Production Agents  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/python-genai-agentic-handbook)) and run it locally.

```python
"""
Lesson 3: Production-Grade Memory
===================================

Demo memory (Phase 5 Lesson 4) was fine for learning.
Production memory must be:

  ✅ Persistent           (survive process restarts)
  ✅ Per-user / per-session (isolation, multi-tenant)
  ✅ Bounded              (token budget, TTL, eviction)
  ✅ Searchable           (semantic + keyword)
  ✅ Privacy-aware        (PII scrubbing, right-to-delete)
  ✅ Observable           (you can see what was injected and why)

We'll build the 3 tiers used in real systems:

  1) WORKING MEMORY — the current request's messages (capped by tokens)
  2) SHORT-TERM MEMORY — recent conversation history per user (Redis-backed)
  3) LONG-TERM MEMORY — semantic facts about the user (vector store)

Run modes:
  - Default: uses in-process fakes for Redis/vector store so it works anywhere.
  - With Redis running: set REDIS_URL=redis://localhost:6379/0

📦 INSTALL (optional, only if you want real Redis):
    pip install redis
"""

from __future__ import annotations
import os
import json
import time
import uuid
import numpy as np
from dataclasses import dataclass, field
from typing import Iterable
from llm_client import chat, embed


# ----------------------------------------------------------------
# Tier 0 — Token budgeting (used by every tier)
# ----------------------------------------------------------------
def estimate_tokens(text: str) -> int:
    """Cheap fallback estimator. Use tiktoken in production."""
    try:
        import tiktoken
        return len(tiktoken.get_encoding("cl100k_base").encode(text))
    except Exception:
        return max(1, len(text) // 4)


def trim_messages(messages: list[dict], max_tokens: int) -> list[dict]:
    """
    Keep the system message + the most recent messages that fit `max_tokens`.
    A classic and simple eviction strategy ('sliding window').
    """
    system = [m for m in messages if m["role"] == "system"]
    rest = [m for m in messages if m["role"] != "system"]

    kept_rev: list[dict] = []
    total = sum(estimate_tokens(m["content"]) for m in system)
    for m in reversed(rest):
        t = estimate_tokens(m["content"])
        if total + t > max_tokens:
            break
        kept_rev.append(m)
        total += t
    return system + list(reversed(kept_rev))


# ----------------------------------------------------------------
# Tier 1 — Short-term store (Redis-like)
# ----------------------------------------------------------------
class _MemoryDict:
    """A tiny in-process stand-in for Redis when REDIS_URL isn't set."""
    def __init__(self): self._d, self._exp = {}, {}
    def set(self, k, v, ex=None):
        self._d[k] = v
        if ex: self._exp[k] = time.time() + ex
    def get(self, k):
        if k in self._exp and time.time() > self._exp[k]:
            self._d.pop(k, None); self._exp.pop(k, None); return None
        return self._d.get(k)
    def delete(self, k): self._d.pop(k, None); self._exp.pop(k, None)


def _make_redis():
    url = os.getenv("REDIS_URL")
    if not url:
        return _MemoryDict()
    try:
        import redis
        return redis.from_url(url, decode_responses=True)
    except Exception as e:
        print(f"(no redis: {e}) — falling back to in-memory store")
        return _MemoryDict()


class ShortTermStore:
    """Per-session message history with TTL."""

    def __init__(self, ttl_seconds: int = 60 * 60):
        self.r = _make_redis()
        self.ttl = ttl_seconds

    def _key(self, session_id: str) -> str:
        return f"chat:{session_id}"

    def get(self, session_id: str) -> list[dict]:
        raw = self.r.get(self._key(session_id))
        return json.loads(raw) if raw else []

    def append(self, session_id: str, message: dict) -> None:
        history = self.get(session_id) + [message]
        # cap raw length so Redis doesn't grow unbounded
        if len(history) > 200:
            history = history[-200:]
        self.r.set(self._key(session_id), json.dumps(history), ex=self.ttl)


# ----------------------------------------------------------------
# Tier 2 — Long-term semantic store
# ----------------------------------------------------------------
def _cosine(a, b):
    a, b = np.array(a), np.array(b)
    return float(np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b) + 1e-9))


@dataclass
class Fact:
    id: str
    user_id: str
    text: str
    vec: list[float]
    created_at: float


class LongTermStore:
    """
    Vector store with per-user isolation.
    In production, swap for Azure AI Search / pgvector / Qdrant / Chroma.
    """

    def __init__(self, path: str):
        self.path = path
        self._facts: list[Fact] = []
        if os.path.exists(path):
            with open(path, "r", encoding="utf-8") as f:
                for d in json.load(f):
                    self._facts.append(Fact(**d))

    def _save(self):
        with open(self.path, "w", encoding="utf-8") as f:
            json.dump([f.__dict__ for f in self._facts], f, indent=2)

    def remember(self, user_id: str, text: str) -> str:
        # Deduplicate near-identical facts to keep the store clean
        vec = embed(text)
        for f in self._facts:
            if f.user_id == user_id and _cosine(vec, f.vec) > 0.95:
                return f.id              # already known
        fact = Fact(
            id=str(uuid.uuid4()),
            user_id=user_id,
            text=text,
            vec=vec,
            created_at=time.time(),
        )
        self._facts.append(fact)
        self._save()
        return fact.id

    def recall(self, user_id: str, query: str, top_k: int = 3,
               min_score: float = 0.55) -> list[Fact]:
        qv = embed(query)
        mine = [f for f in self._facts if f.user_id == user_id]
        scored = [(f, _cosine(qv, f.vec)) for f in mine]
        scored = [s for s in scored if s[1] >= min_score]
        scored.sort(key=lambda kv: kv[1], reverse=True)
        return [f for f, _ in scored[:top_k]]

    def forget(self, user_id: str) -> int:
        """GDPR-friendly: delete all facts for a user."""
        before = len(self._facts)
        self._facts = [f for f in self._facts if f.user_id != user_id]
        self._save()
        return before - len(self._facts)


# ----------------------------------------------------------------
# Tier 3 — PII redaction (cheap regex layer)
# ----------------------------------------------------------------
import re
_PII_PATTERNS = [
    (re.compile(r"\b[\w.+-]+@[\w-]+\.[\w.-]+\b"), "<EMAIL>"),
    (re.compile(r"\b\d{3}-\d{2}-\d{4}\b"),         "<SSN>"),
    (re.compile(r"\b(?:\d[ -]*?){13,16}\b"),       "<CARD>"),
]

def redact(text: str) -> str:
    for pat, repl in _PII_PATTERNS:
        text = pat.sub(repl, text)
    return text


# ----------------------------------------------------------------
# The MemoryManager — the only thing your agent should touch
# ----------------------------------------------------------------
SYSTEM = """You are a helpful assistant with memory.
You will be given RECALLED FACTS about the user. Use them silently.
If the user states a stable preference or fact about themselves,
end your reply with a line: '[REMEMBER] <fact>'."""


class MemoryManager:
    def __init__(self, ltm_path: str, working_token_budget: int = 2000):
        self.short = ShortTermStore()
        self.long  = LongTermStore(ltm_path)
        self.budget = working_token_budget

    def build_prompt(self, user_id: str, session_id: str, user_input: str) -> list[dict]:
        # 1) recall relevant long-term facts
        recalled = self.long.recall(user_id, user_input)
        recalled_block = ""
        if recalled:
            recalled_block = (
                "RECALLED FACTS:\n" + "\n".join(f"- {r.text}" for r in recalled) + "\n\n"
            )
        # 2) load short-term history
        history = self.short.get(session_id)
        # 3) build final message list and trim to budget
        msgs = (
            [{"role": "system", "content": SYSTEM}]
            + history
            + [{"role": "user", "content": recalled_block + redact(user_input)}]
        )
        return trim_messages(msgs, self.budget)

    def post(self, user_id: str, session_id: str, user_input: str, reply: str) -> None:
        # persist turn (with PII scrubbed)
        self.short.append(session_id, {"role": "user", "content": redact(user_input)})
        self.short.append(session_id, {"role": "assistant", "content": reply})
        # extract "[REMEMBER] ..." facts and store
        for line in reply.splitlines():
            line = line.strip()
            if line.startswith("[REMEMBER]"):
                fact = redact(line[len("[REMEMBER]"):].strip())
                if fact:
                    self.long.remember(user_id, fact)


# ----------------------------------------------------------------
# Demo
# ----------------------------------------------------------------
if __name__ == "__main__":
    HERE = os.path.dirname(os.path.abspath(__file__))
    mm = MemoryManager(os.path.join(HERE, "ltm_v2.json"))

    user_id, session_id = "u-42", "s-001"

    turns = [
        "Hi! I'm Priya from Contoso. Please be brief — my email is priya@contoso.com.",
        "I prefer Markdown over plain text.",
        "What should I focus on this week?",   # uses recalled facts
    ]
    for t in turns:
        prompt = mm.build_prompt(user_id, session_id, t)
        print(f"\nUSER: {t}")
        print(f"  (prompt tokens ≈ {sum(estimate_tokens(m['content']) for m in prompt)})")
        reply = chat(prompt, temperature=0.3)
        print(f"BOT : {reply}")
        mm.post(user_id, session_id, t, reply)


# ============================================================
# 🧠 PRODUCTION CHECKLIST
#   - [ ] Per-user isolation (never mix tenants)
#   - [ ] TTL on short-term history (default: 1 hour)
#   - [ ] Token budgeting before every LLM call
#   - [ ] PII redaction before storing
#   - [ ] Dedupe long-term facts (cosine > 0.95 = same)
#   - [ ] Right-to-delete API (`forget(user_id)`)
#   - [ ] Metric: avg recalled-facts per request
#   - [ ] Metric: working-memory token usage (p50/p95)
# ============================================================

```
