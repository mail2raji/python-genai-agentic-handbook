# Lesson 8 — Loops

!!! info "Runnable source file"
    **Path:** `Chapter01_Python_Fundamentals/08_loops.py`  
    **Phase:** Phase 1 — Python Fundamentals  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/genai-agentic-ai-handbook)) and run it locally.

```python
"""
Lesson 8: Loops (for / while)
==============================

📖 CONCEPT:
Loops repeat code. Used to process every document in a corpus,
every message in a chat, every result from a search, etc.

💡 REAL-WORLD ANALOGY:
A washing machine cycle — repeat "wash → rinse → spin" for every batch of clothes.

🧪 EXAMPLE — processing a batch of documents for embedding:
"""

# FOR loop over a list
documents = [
    "Azure Key Vault stores secrets securely.",
    "Entra ID handles identity management.",
    "Sentinel is Microsoft's SIEM tool.",
]

print("--- Processing documents ---")
for i, doc in enumerate(documents):    # enumerate gives index + value
    print(f"Doc {i+1}: {doc[:30]}... → embedding generated")

# FOR loop over a range of numbers
print("\n--- Retrying API call ---")
for attempt in range(1, 4):            # 1, 2, 3
    print(f"Attempt {attempt}...")

# FOR loop over a dict
metrics = {"latency_ms": 320, "tokens": 540, "cost_usd": 0.0021}
for key, value in metrics.items():
    print(f"{key}: {value}")

# WHILE loop — keep going until a condition is False
print("\n--- Agent thinking loop ---")
step = 1
max_steps = 5
done = False
while step <= max_steps and not done:
    print(f"Agent step {step}: thinking...")
    if step == 3:                      # pretend agent finished
        done = True
        print("✅ Agent reached final answer")
    step += 1

# BREAK — exit loop early
print("\n--- Searching for keyword ---")
for doc in documents:
    if "Sentinel" in doc:
        print(f"Found! → {doc}")
        break                          # stop searching

# CONTINUE — skip to next iteration
print("\n--- Filtering long docs ---")
for doc in documents:
    if len(doc) < 40:
        continue                       # skip short docs
    print(f"Long doc: {doc}")

# List comprehension — pythonic 1-line loop (you'll see this everywhere)
lengths = [len(d) for d in documents]
print("\nDoc lengths:", lengths)

upper_docs = [d.upper() for d in documents if "Azure" in d]
print("Filtered + transformed:", upper_docs)


# ============================================================
# ✏️ EXERCISE:
# Given this list of chat messages, write a loop that:
#   1. Counts how many came from the "user"
#   2. Prints only the assistant's messages
#   3. Stops if it sees the word "goodbye"
# ============================================================

# chat = [
#     {"role": "user", "content": "hi"},
#     {"role": "assistant", "content": "hello!"},
#     {"role": "user", "content": "what's the weather?"},
#     {"role": "assistant", "content": "sunny"},
#     {"role": "user", "content": "goodbye"},
#     {"role": "assistant", "content": "bye!"},   # should NOT be printed
# ]


# ✅ SOLUTION:
# user_count = 0
# for m in chat:
#     if m["content"] == "goodbye":
#         break
#     if m["role"] == "user":
#         user_count += 1
#     else:
#         print("Assistant:", m["content"])
# print("User messages:", user_count)

```
