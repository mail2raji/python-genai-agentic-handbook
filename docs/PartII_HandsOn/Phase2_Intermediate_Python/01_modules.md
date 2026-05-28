# Lesson 1 — Modules

!!! info "Runnable source file"
    **Path:** `Phase2_Intermediate_Python/01_modules.py`  
    **Phase:** Phase 2 — Intermediate Python  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/python-genai-agentic-handbook)) and run it locally.

```python
"""
Lesson 1: Modules & Imports
============================

📖 CONCEPT:
A module is a .py file you can import into another file.
A package is a folder of modules.

This lets you split code into reusable pieces — exactly how
real AI projects are organized (e.g., `agents/`, `tools/`, `prompts/`).

💡 REAL-WORLD ANALOGY:
Like LEGO bricks: instead of one giant brick, you build with many small reusable pieces.
"""

# --- Built-in modules ---
import math
import random
import datetime as dt              # 'as' = alias

print("Pi:", math.pi)
print("Random number:", random.randint(1, 100))
print("Now:", dt.datetime.now())

# Import specific things
from math import sqrt, pow
print("sqrt(16) =", sqrt(16))

# --- Importing your OWN module ---
# We'll create a tiny helper module inline
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
helper_path = os.path.join(HERE, "my_helpers.py")
with open(helper_path, "w", encoding="utf-8") as f:
    f.write('def shout(text):\n    return text.upper() + "!"\n')
    f.write('PI_APPROX = 3.14\n')

# Make sure Python can find it
if HERE not in sys.path:
    sys.path.insert(0, HERE)

import my_helpers
print(my_helpers.shout("hello ai"))
print(my_helpers.PI_APPROX)


# ============================================================
# ✏️ EXERCISE:
# 1. Create a file `prompts.py` with a function `system_prompt(role)` that
#    returns f"You are a {role}."
# 2. Import it here and call it with role="data analyst".
# ============================================================

```
