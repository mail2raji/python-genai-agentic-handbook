# Lesson 7 — Rag System

!!! info "Runnable source file"
    **Path:** `Chapter05_GenAI_Fundamentals/07_rag_system.py`  
    **Phase:** Phase 4 — GenAI Fundamentals  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/genai-agentic-ai-handbook)) and run it locally.

```python
"""
Lesson 7: Building a RAG System from Scratch
==============================================

📖 CONCEPT:
RAG = Retrieval-Augmented Generation. The pipeline:

   1. INGEST  → split documents into chunks
   2. EMBED   → vector for each chunk, store in a vector DB
   3. RETRIEVE → embed user question, find top-k similar chunks
   4. GENERATE → ask LLM with the chunks as context

This is how ChatGPT "knows your docs", Copilot "knows your repo",
and every enterprise AI bot works.

We build it FROM SCRATCH in ~80 lines. Production systems use libraries like
LangChain, LlamaIndex, Azure AI Search, etc.

💡 ANALOGY:
A student given an open-book exam. They look up the answer, then write it
in their own words.
"""

from __future__ import annotations
import numpy as np
from dataclasses import dataclass, field
from llm_client import chat, embed, embed_many


def cosine(a, b):
    a, b = np.array(a), np.array(b)
    return float(np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b)))


@dataclass
class Chunk:
    text: str
    source: str
    vector: list[float] = field(default_factory=list)


# --- Step 1: Sample knowledge base ---
DOCUMENTS = {
    "vpn_guide.md": (
        "Our company VPN is Cisco AnyConnect. "
        "To connect: open AnyConnect → enter vpn.contoso.com → use your Entra ID credentials. "
        "If you see error 'login failed', reset your password at https://passwords.contoso.com."
    ),
    "password_policy.md": (
        "Passwords must be 14+ characters with upper, lower, number, and symbol. "
        "Passwords expire every 90 days. "
        "Use the self-service portal at https://passwords.contoso.com to change yours."
    ),
    "office_hours.md": (
        "Headquarters is open 8am to 6pm, Monday to Friday. "
        "Closed on US federal holidays. "
        "After-hours building access requires a security badge."
    ),
    "ai_policy.md": (
        "Employees may use approved AI tools (Microsoft Copilot, Azure OpenAI). "
        "Do NOT paste customer data, secrets, or source code into public LLMs like ChatGPT free tier. "
        "All AI usage must comply with the Data Handling Standard SEC-104."
    ),
}


# --- Step 2: Chunking ---
def chunk_text(text: str, size: int = 100, overlap: int = 20) -> list[str]:
    """Naive word-based chunking. Production uses recursive char/token splitters."""
    words = text.split()
    chunks = []
    start = 0
    while start < len(words):
        end = min(start + size, len(words))
        chunks.append(" ".join(words[start:end]))
        if end == len(words):
            break
        start += size - overlap
    return chunks


# --- Step 3: Build the index ---
def build_index() -> list[Chunk]:
    all_chunks: list[Chunk] = []
    for source, text in DOCUMENTS.items():
        for piece in chunk_text(text):
            all_chunks.append(Chunk(text=piece, source=source))
    vectors = embed_many([c.text for c in all_chunks])
    for c, v in zip(all_chunks, vectors):
        c.vector = v
    return all_chunks


# --- Step 4: Retrieve ---
def retrieve(query: str, index: list[Chunk], top_k: int = 3) -> list[Chunk]:
    qv = embed(query)
    ranked = sorted(index, key=lambda c: cosine(qv, c.vector), reverse=True)
    return ranked[:top_k]


# --- Step 5: Generate ---
SYSTEM = """You are a helpful internal IT assistant.
Answer the user's question using ONLY the provided context.
If the context does not contain the answer, say: "I don't know based on the available documents."
Always cite the source filename in square brackets at the end.
"""

def answer(query: str, index: list[Chunk]) -> str:
    top = retrieve(query, index)
    context = "\n\n".join(f"[{c.source}] {c.text}" for c in top)
    messages = [
        {"role": "system", "content": SYSTEM},
        {"role": "user",   "content": f"CONTEXT:\n{context}\n\nQUESTION: {query}"},
    ]
    return chat(messages, temperature=0.2)


# --- Step 6: Try it out ---
if __name__ == "__main__":
    print("📚 Building index...")
    index = build_index()
    print(f"Indexed {len(index)} chunks.\n")

    questions = [
        "How do I connect to the VPN?",
        "What are the password rules?",
        "Can I paste source code into ChatGPT?",
        "When is the office closed?",
        "What's the moon made of?",                  # not in docs → should say "don't know"
    ]
    for q in questions:
        print(f"\nQ: {q}")
        print(f"A: {answer(q, index)}")


# ============================================================
# 🎓 NEXT STEPS:
#   - Replace the in-memory list with a real vector DB (Chroma, Qdrant, Azure AI Search).
#   - Add metadata filtering (e.g., only "ai_policy" docs).
#   - Add re-ranking (e.g., cross-encoder).
#   - We do all this in Phase 6's capstone.
# ============================================================

```
