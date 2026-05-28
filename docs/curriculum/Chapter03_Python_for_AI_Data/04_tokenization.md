# Lesson 4 — Tokenization

!!! info "Runnable source file"
    **Path:** `Chapter03_Python_for_AI_Data/04_tokenization.py`  
    **Phase:** Phase 3 — Python for AI & Data  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/genai-agentic-ai-handbook)) and run it locally.

```python
"""
Lesson 4: Tokenization Preview
================================

📖 CONCEPT:
LLMs don't read characters — they read "tokens". A token is roughly a
word fragment. "Hello, world!" might be 3 tokens. "antidisestablishmentarianism"
might be 8.

Why care?
- You're billed PER TOKEN.
- Models have a TOKEN LIMIT (context window).
- Long prompts cost more & are slower.

💡 ANALOGY:
Like Scrabble tiles — words are broken into reusable pieces.

📦 INSTALL:  pip install tiktoken
"""

# --- Fallback if tiktoken isn't installed ---
try:
    import tiktoken
    enc = tiktoken.encoding_for_model("gpt-4o-mini")
    HAS_TIKTOKEN = True
except Exception as e:
    print(f"(tiktoken not available: {e}) — using char/4 estimate")
    HAS_TIKTOKEN = False


def count_tokens(text: str) -> int:
    if HAS_TIKTOKEN:
        return len(enc.encode(text))
    return max(1, len(text) // 4)        # rough approximation


def show_tokens(text: str) -> None:
    if HAS_TIKTOKEN:
        ids = enc.encode(text)
        pieces = [enc.decode([i]) for i in ids]
        print("  Pieces:", pieces)
        print("  IDs:   ", ids)
    else:
        print("  (install tiktoken to see real tokens)")


samples = [
    "Hello, world!",
    "Antidisestablishmentarianism",
    "The quick brown fox jumps over the lazy dog.",
    "GPT-4o is a multimodal model from OpenAI.",
    "日本語のテキスト",                          # Japanese
]

for s in samples:
    n = count_tokens(s)
    print(f"\nText: {s!r}")
    print(f"  Length in chars: {len(s)} | Tokens: {n}")
    show_tokens(s)


# --- Cost example ---
prompt = "Summarize the following email in 2 sentences. " * 50
n_tokens = count_tokens(prompt)
cost = n_tokens * 0.00015 / 1000
print(f"\nLong prompt → {n_tokens} tokens → ~${cost:.6f}")


# ============================================================
# 🧠 RULES OF THUMB:
#  - 1 token ≈ 4 chars of English text ≈ 0.75 of a word
#  - 1000 tokens ≈ 750 words ≈ ~1.5 pages
#  - GPT-4o context window: 128,000 tokens
#  - Always count tokens before sending — keep budgets in code.
# ============================================================

```
