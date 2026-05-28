# Mini-Project — Doc Qa

!!! info "Runnable source file"
    **Path:** `Chapter05_GenAI_Fundamentals/mini_project_doc_qa.py`  
    **Phase:** Phase 4 — GenAI Fundamentals  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/genai-agentic-ai-handbook)) and run it locally.

```python
"""
🏆 PHASE 4 MINI-PROJECT — Chat with YOUR Workspace Docs
==========================================================

A RAG-powered Q&A bot over the actual .ps1 / .md / .txt files in
your `c:\\Scripts\\Send-escalationEmail\\` workspace.

This is the same architecture as enterprise tools like
"Azure OpenAI on your data" — but in ~120 lines of code.

▶️ Run:
    python mini_project_doc_qa.py
Then type questions like:
    > What scripts handle SPN expiry?
    > How does the escalation email work?
"""

from __future__ import annotations
import os
import glob
import pickle
import numpy as np
from dataclasses import dataclass, field
from llm_client import chat, embed, embed_many

# Path to YOUR real workspace (edit if needed)
WORKSPACE = r"c:\Scripts\Send-escalationEmail"
CACHE     = os.path.join(os.path.dirname(__file__), "rag_index.pkl")
EXTS      = (".ps1", ".md", ".txt")
MAX_FILES = 25                              # keep first run small
CHUNK_WORDS = 200
OVERLAP     = 30


def cosine(a, b):
    a, b = np.array(a), np.array(b)
    return float(np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b)))


@dataclass
class Chunk:
    text: str
    source: str
    vector: list[float] = field(default_factory=list)


def chunk_text(text: str, size: int = CHUNK_WORDS, overlap: int = OVERLAP) -> list[str]:
    words = text.split()
    chunks, start = [], 0
    while start < len(words):
        end = min(start + size, len(words))
        chunks.append(" ".join(words[start:end]))
        if end == len(words):
            break
        start += size - overlap
    return chunks


def collect_files() -> list[str]:
    paths = []
    for ext in EXTS:
        paths.extend(glob.glob(os.path.join(WORKSPACE, f"*{ext}")))
    paths.sort()
    return paths[:MAX_FILES]


def load_or_build_index() -> list[Chunk]:
    if os.path.exists(CACHE):
        print(f"📦 Loading cached index from {CACHE}")
        with open(CACHE, "rb") as f:
            return pickle.load(f)

    print("📚 Building index from workspace files...")
    files = collect_files()
    chunks: list[Chunk] = []
    for path in files:
        try:
            with open(path, "r", encoding="utf-8", errors="ignore") as f:
                text = f.read()
        except Exception as e:
            print(f"  skip {path}: {e}")
            continue
        for piece in chunk_text(text):
            chunks.append(Chunk(text=piece, source=os.path.basename(path)))

    print(f"   Embedding {len(chunks)} chunks from {len(files)} files...")
    # Batch in groups of 50 to avoid huge requests
    BATCH = 50
    for i in range(0, len(chunks), BATCH):
        batch = chunks[i:i + BATCH]
        vecs = embed_many([c.text for c in batch])
        for c, v in zip(batch, vecs):
            c.vector = v
        print(f"   {min(i + BATCH, len(chunks))}/{len(chunks)} embedded")

    with open(CACHE, "wb") as f:
        pickle.dump(chunks, f)
    print(f"💾 Cached to {CACHE}")
    return chunks


def retrieve(query: str, index: list[Chunk], top_k: int = 5) -> list[Chunk]:
    qv = embed(query)
    return sorted(index, key=lambda c: cosine(qv, c.vector), reverse=True)[:top_k]


SYSTEM_PROMPT = """You are an expert assistant who answers questions about the user's
PowerShell automation workspace.

Rules:
- Use ONLY the provided CONTEXT. Don't invent file names, parameters, or features.
- If the answer is not in the CONTEXT, say "I don't see that in the provided files."
- Always end with a "Sources:" line listing the filenames you used.
"""


def answer(query: str, index: list[Chunk]) -> str:
    top = retrieve(query, index)
    context_block = "\n\n---\n\n".join(
        f"[FILE: {c.source}]\n{c.text}" for c in top
    )
    messages = [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user",   "content": f"CONTEXT:\n{context_block}\n\nQUESTION: {query}"},
    ]
    return chat(messages, temperature=0.2, max_tokens=700)


def main():
    index = load_or_build_index()
    print(f"\n🤖 Ready. {len(index)} chunks indexed. Type 'quit' to exit.\n")
    while True:
        try:
            q = input("> ").strip()
        except (EOFError, KeyboardInterrupt):
            break
        if not q or q.lower() in {"quit", "exit"}:
            break
        print(answer(q, index))
        print()


if __name__ == "__main__":
    main()


# ============================================================
# 🎓 EXTENSIONS:
#   1. Add file-type filters (only .ps1 vs only docs).
#   2. Show retrieval scores next to each source.
#   3. Persist conversation history across turns.
#   4. Add a 'refresh' command to re-index.
# ============================================================

```
