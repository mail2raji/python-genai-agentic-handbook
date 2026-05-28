# Lesson 4 — Numbers And Math

!!! info "Runnable source file"
    **Path:** `Phase1_Python_Fundamentals/04_numbers_and_math.py`  
    **Phase:** Phase 1 — Python Fundamentals  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/python-genai-agentic-handbook)) and run it locally.

```python
"""
Lesson 4: Numbers & Math
=========================

📖 CONCEPT:
Python handles math naturally. You'll use it for token counts,
cost calculations, similarity scores, etc.

💡 REAL-WORLD ANALOGY:
Like a calculator built into the language.

🧪 EXAMPLE — calculating LLM API costs:
"""

# Basic operators
print(10 + 3)    # addition       → 13
print(10 - 3)    # subtraction    → 7
print(10 * 3)    # multiplication → 30
print(10 / 3)    # division       → 3.333...
print(10 // 3)   # integer div    → 3
print(10 % 3)    # remainder      → 1
print(2 ** 10)   # power          → 1024

# Real example: OpenAI cost estimation
input_tokens = 1500
output_tokens = 800
input_price_per_1k = 0.00015       # $ per 1000 tokens
output_price_per_1k = 0.00060

cost = (input_tokens / 1000) * input_price_per_1k + \
       (output_tokens / 1000) * output_price_per_1k

print(f"\nTotal tokens: {input_tokens + output_tokens}")
print(f"Estimated cost: ${cost:.6f}")   # :.6f = 6 decimal places

# Rounding
print(round(3.14159, 2))   # 3.14

# Type conversion
age_text = "25"
age_number = int(age_text)
print(age_number + 5)      # 30


# ============================================================
# ✏️ EXERCISE:
# A model charges $0.002 per 1K input tokens and $0.008 per 1K output.
# A user sent 12,000 input tokens and got 4,500 output tokens.
# Calculate the total cost and print it formatted to 4 decimal places.
# ============================================================


# ✅ SOLUTION:
# in_tok, out_tok = 12000, 4500
# cost = (in_tok/1000)*0.002 + (out_tok/1000)*0.008
# print(f"Cost: ${cost:.4f}")

```
