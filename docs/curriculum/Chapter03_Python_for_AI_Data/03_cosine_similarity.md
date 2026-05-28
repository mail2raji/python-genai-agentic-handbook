# Lesson 3 — Cosine Similarity

!!! info "Runnable source file"
    **Path:** `Chapter03_Python_for_AI_Data/03_cosine_similarity.py`  
    **Phase:** Phase 3 — Python for AI & Data  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/genai-agentic-ai-handbook)) and run it locally.

```python
"""
Lesson 3: Cosine Similarity — The Math Behind RAG
====================================================

📖 CONCEPT:
In GenAI, every chunk of text is converted to a vector (embedding).
To find "the most relevant document for this question", we compute
the cosine similarity between the question vector and each document vector.

cosine_similarity(A, B) = (A · B) / (||A|| * ||B||)

Range: -1 (opposite) to 1 (identical). For embeddings, ~0.8+ usually means "very similar".

💡 ANALOGY:
Imagine two arrows in space. If they point in the same direction, similarity ≈ 1.
If perpendicular, similarity ≈ 0.

This is the core of EVERY vector database (Pinecone, Chroma, FAISS, Azure AI Search).
"""

import numpy as np


def cosine_similarity(a: np.ndarray, b: np.ndarray) -> float:
    """Cosine similarity between two vectors."""
    return float(np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b)))


# --- Toy example: 3-dimensional "embeddings" ---
question        = np.array([1.0, 1.0, 0.0])
doc_about_cats  = np.array([0.9, 1.1, 0.1])     # similar direction
doc_about_dogs  = np.array([1.0, 0.9, 0.2])     # similar
doc_about_taxes = np.array([0.0, 0.0, 1.0])     # different direction

print("Q ↔ Cats:",  round(cosine_similarity(question, doc_about_cats),  3))
print("Q ↔ Dogs:",  round(cosine_similarity(question, doc_about_dogs),  3))
print("Q ↔ Taxes:", round(cosine_similarity(question, doc_about_taxes), 3))


# --- Mini-RAG simulation ---
documents = {
    "Doc A — VPN troubleshooting":       np.array([0.9, 0.1, 0.0]),
    "Doc B — Password reset guide":      np.array([0.8, 0.2, 0.1]),
    "Doc C — Vacation policy":           np.array([0.0, 0.9, 0.1]),
    "Doc D — Office holiday calendar":   np.array([0.1, 0.8, 0.2]),
    "Doc E — Annual report 2025":        np.array([0.0, 0.1, 0.9]),
}

user_query_vec = np.array([0.85, 0.15, 0.05])    # IT-related question

# Rank documents by similarity
ranked = sorted(
    documents.items(),
    key=lambda kv: cosine_similarity(user_query_vec, kv[1]),
    reverse=True,
)

print("\n🔍 Top results:")
for name, vec in ranked[:3]:
    score = cosine_similarity(user_query_vec, vec)
    print(f"  {score:.3f}  →  {name}")


# --- Why normalization matters ---
short_vec = np.array([1.0, 0.0])
long_vec  = np.array([10.0, 0.0])
# Same direction → cosine = 1.0 (length doesn't matter)
print("\nSame direction, diff length:", cosine_similarity(short_vec, long_vec))


# ============================================================
# ✏️ EXERCISE:
# Given:
#   query = np.array([0.5, 0.5, 0.5])
#   docs = {
#       "Pizza recipes":  np.array([0.6, 0.4, 0.5]),
#       "Tax forms":      np.array([0.1, 0.0, 0.9]),
#       "Cooking tips":   np.array([0.7, 0.5, 0.4]),
#   }
# Rank the docs by similarity to the query.
# ============================================================

```
