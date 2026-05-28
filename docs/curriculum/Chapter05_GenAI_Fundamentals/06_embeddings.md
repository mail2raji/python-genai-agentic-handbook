# Lesson 6 — Embeddings

!!! info "Runnable source file"
    **Path:** `Chapter05_GenAI_Fundamentals/06_embeddings.py`  
    **Phase:** Phase 4 — GenAI Fundamentals  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/genai-agentic-ai-handbook)) and run it locally.

```python
"""
Lesson 6: Embeddings — Turning Text into Vectors
===================================================

📖 CONCEPT:
An embedding turns text into a vector (list of numbers) that captures meaning.
Two pieces of text with similar meaning have similar vectors (high cosine similarity).
This is THE foundation of search, RAG, recommendation, and clustering.

💡 ANALOGY:
A GPS coordinate for a piece of meaning. "I lost my password" and
"I can't sign in" end up near each other on the map.
"""

import numpy as np
from llm_client import embed, embed_many


def cosine(a, b):
    a, b = np.array(a), np.array(b)
    return float(np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b)))


# --- Show that similar meanings cluster together ---
texts = [
    "How do I reset my password?",
    "I forgot my login credentials.",
    "What's the company holiday schedule?",
    "When is the office closed for vacations?",
    "The printer is jammed again.",
]

print("Embedding 5 sentences...")
vectors = embed_many(texts)
print(f"Each vector has {len(vectors[0])} dimensions.\n")

# Compare every pair
print("Pairwise similarity matrix:")
print(" " * 4, end="")
for j in range(len(texts)):
    print(f"  S{j}", end="")
print()
for i in range(len(texts)):
    print(f"S{i}: ", end="")
    for j in range(len(texts)):
        print(f"{cosine(vectors[i], vectors[j]):5.2f} ", end="")
    print()

print("\nSentences:")
for i, t in enumerate(texts):
    print(f"S{i}: {t}")


# --- Use embeddings for semantic search ---
print("\n--- Semantic search demo ---")
knowledge_base = [
    "Microsoft Sentinel is a cloud-native SIEM that helps detect threats.",
    "Azure Key Vault stores API keys, secrets, and certificates securely.",
    "Entra ID manages user identities, conditional access, and SSO.",
    "Cosmos DB is a globally distributed NoSQL database.",
    "Defender for Cloud provides cloud security posture management.",
]

kb_vectors = embed_many(knowledge_base)

queries = [
    "Where do I store passwords for my apps?",
    "How do I detect attacks across my environment?",
    "What tool gives me a global database?",
]

for q in queries:
    qv = embed(q)
    scored = sorted(
        zip(knowledge_base, kb_vectors),
        key=lambda kv: cosine(qv, kv[1]),
        reverse=True,
    )
    best_doc, best_vec = scored[0]
    print(f"\nQ: {q}")
    print(f"   → {cosine(qv, best_vec):.3f}  {best_doc}")


# ============================================================
# 🧠 KEY FACTS:
#   - OpenAI's `text-embedding-3-small` → 1536 dimensions
#   - Cost: very cheap (~$0.02 per 1M tokens)
#   - Always cache embeddings — never re-compute for the same text!
# ============================================================

```
