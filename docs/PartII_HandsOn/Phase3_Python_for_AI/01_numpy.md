# Lesson 1 — Numpy

!!! info "Runnable source file"
    **Path:** `Phase3_Python_for_AI/01_numpy.py`  
    **Phase:** Phase 3 — Python for AI & Data  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/python-genai-agentic-handbook)) and run it locally.

```python
"""
Lesson 1: NumPy Basics
=======================

📖 CONCEPT:
NumPy gives Python fast arrays + math. Every AI model deals with arrays
(called "tensors" in deep learning). An "embedding" of text is just an array of 1536 numbers.

💡 ANALOGY:
A Python list is a paper checklist. A NumPy array is a spreadsheet — fast bulk math.

📦 INSTALL:  pip install numpy
"""

import numpy as np

# --- Create arrays ---
a = np.array([1, 2, 3, 4])
print("Array:", a, "| shape:", a.shape, "| dtype:", a.dtype)

# 2D array (matrix)
m = np.array([[1, 2, 3], [4, 5, 6]])
print("\nMatrix:\n", m, "| shape:", m.shape)

# Special arrays
print("\nZeros:", np.zeros(5))
print("Ones:",  np.ones((2, 3)))
print("Range:", np.arange(0, 10, 2))      # 0,2,4,6,8
print("Random:", np.random.rand(4))       # uniform 0–1
print("Random normal:", np.random.randn(4))


# --- Element-wise math (no loops needed!) ---
x = np.array([1, 2, 3, 4])
y = np.array([10, 20, 30, 40])

print("\nx + y =", x + y)
print("x * y =", x * y)
print("x * 2 =", x * 2)


# --- Vector operations used in AI ---
v1 = np.array([1.0, 2.0, 3.0])
v2 = np.array([4.0, 5.0, 6.0])

# Dot product (foundation of attention, similarity, etc.)
print("\nDot product:", np.dot(v1, v2))

# Magnitude (length of vector)
print("Magnitude of v1:", np.linalg.norm(v1))

# Normalize (unit vector — used in embeddings)
v1_unit = v1 / np.linalg.norm(v1)
print("Unit vector:", v1_unit)


# --- Simulating an embedding ---
np.random.seed(42)
fake_embedding = np.random.randn(1536)        # OpenAI text-embedding-3-small size
print("\nFake embedding shape:", fake_embedding.shape)
print("First 5 dims:", fake_embedding[:5])


# --- Indexing & slicing ---
arr = np.array([10, 20, 30, 40, 50])
print("\narr[0] =", arr[0])
print("arr[-1] =", arr[-1])
print("arr[1:4] =", arr[1:4])
print("arr > 25:", arr[arr > 25])             # boolean mask — POWERFUL


# ============================================================
# ✏️ EXERCISE:
# 1. Create a 1D array of 10 random numbers.
# 2. Print only those greater than 0.5.
# 3. Compute the mean, max, and standard deviation.
# ============================================================

```
