# Module 2 · Lesson 1 — Introduction to Python

## 🍭 Imagine this…

A **recipe card** tells your kitchen exactly what to do:
1. Mix flour and water.
2. If oven is hot, bake 10 minutes.
3. Otherwise wait.

Python is just a recipe card the **computer** reads. Every line is one little instruction.

---

## 🧠 The 10 building blocks you really need

If you understand these 10 ideas, you can read 95% of the Python code in this course.

| # | Block | One-line summary | Example |
|---|---|---|---|
| 1 | **Variables** | Boxes that hold values | `name = "Raji"` |
| 2 | **Data types** | What's inside the box | `str`, `int`, `float`, `bool` |
| 3 | **Lists** | Ordered shelf of items | `colors = ["red", "blue"]` |
| 4 | **Dicts** | Labeled drawers | `user = {"name": "Raji", "age": 30}` |
| 5 | **If / else** | Take one path or another | `if x > 5: …` |
| 6 | **For loop** | Do something for each item | `for c in colors: …` |
| 7 | **Functions** | A re-usable mini-program | `def add(a, b): return a + b` |
| 8 | **Imports** | Borrow other people's code | `from openai import OpenAI` |
| 9 | **Files** | Read & write to disk | `open("x.txt").read()` |
| 10 | **Exceptions** | Catch errors politely | `try: … except: …` |

---

## 🌍 Real-world scenario — A tiny "movie picker"

You want a program that:
1. Asks the user for their mood (`happy`, `sad`, `excited`).
2. Picks a movie from a list that matches.
3. Saves the picked movie to a file `picks.txt`.

This needs: variables, dicts, lists, if/else, input, files. Perfect for practice.

---

## 💻 The code — explained line by line

```python
# movie_picker.py
import random                              # 1. import = borrow Python's randomness toolkit

# 2. A "dict" — keys (mood) → values (list of movies)
catalog = {
    "happy":   ["The Lego Movie", "Paddington 2", "Up"],
    "sad":     ["Inside Out", "About Time", "Coco"],
    "excited": ["Mission Impossible", "Top Gun: Maverick", "The Avengers"],
}

# 3. Talk to the user. input() returns a STRING.
mood = input("How are you feeling? (happy/sad/excited) ").strip().lower()

# 4. Decision tree
if mood in catalog:                        # is the user's mood a key in our dict?
    pick = random.choice(catalog[mood])    # pick a random movie from that list
    print(f"🎬 Tonight watch: {pick}")     # f-string = formatted string
else:
    print("Sorry, I don't know that mood yet.")
    pick = None

# 5. Save to a file ONLY if we made a pick
if pick:
    with open("picks.txt", "a", encoding="utf-8") as f:   # "a" = append mode
        f.write(f"{mood}: {pick}\n")                      # \n = new line
    print("Saved to picks.txt ✅")
```

### Toddler-level explanation
- `import random` → "Hey Python, I'll need dice today."
- `catalog = {...}` → "Here is a notebook with 3 labelled pages."
- `input(...)` → "Wait until the human types something and presses Enter."
- `.strip().lower()` → "Trim spaces and make lowercase so 'Happy ' still works."
- `if mood in catalog:` → "Is 'happy' a page in my notebook?"
- `random.choice(...)` → "Spin a wheel and pick one."
- `with open(...) as f:` → "Open a file, do stuff, close it automatically."
- `f"{mood}: {pick}\n"` → "Make a sentence with the box contents."

---

## 🧠 Concept refresh — Functions

A **function** is a reusable mini-program. Use them to keep code clean.

```python
def greet(name: str, polite: bool = True) -> str:
    """Return a greeting. Type hints (str, bool) help your editor."""
    if polite:
        return f"Good morning, {name}!"
    return f"Yo {name}"

print(greet("Raji"))                    # → "Good morning, Raji!"
print(greet("Raji", polite=False))      # → "Yo Raji"
```

### Anatomy
- `def`     — start a function definition
- `greet`   — the name
- `(...)`   — the inputs (called *parameters*)
- `: str`   — the type hint (optional but recommended)
- `return`  — hand back a value
- `"""…"""` — docstring (your future self will thank you)

---

## 🧠 Concept refresh — Loops & comprehensions

```python
prices = [10, 25, 7, 50]

# Boring way
discounted = []
for p in prices:
    discounted.append(p * 0.9)

# Pythonic way (list comprehension)
discounted = [p * 0.9 for p in prices]
```

A **comprehension** is just "do X for each item, optionally if Y".

```python
expensive = [p for p in prices if p > 20]    # [25, 50]
```

---

## 🧠 Concept refresh — Errors with `try/except`

```python
try:
    age = int(input("Your age? "))
except ValueError:
    print("Please type a number!")
```

Without `try`, a typo crashes your whole program. With it, you handle the mistake gracefully.

---

## 🏋️ Exercises

### Exercise 1 — Variables warmup
Create variables for your name, age, and favourite language. Print them in one sentence using an f-string.

### Exercise 2 — Calculator function
Write `calculate(a, b, op)` that supports `+ - * /` and returns the result. Raise a `ValueError` on unknown op.

### Exercise 3 — Word frequencies
Given a sentence, return a dict mapping each word to how many times it appears.
Hint: use `collections.Counter` or a `for` loop.

### Exercise 4 — FizzBuzz
Print 1–30. For multiples of 3 print `Fizz`, of 5 print `Buzz`, of both print `FizzBuzz`.

### Exercise 5 — Mood diary
Extend `movie_picker.py` to also log the **date** of each pick (use the `datetime` module).

### Exercise 6 — Read your file
Write a script that opens `picks.txt`, counts how many picks per mood, and prints them sorted by most-picked.

---

## ✅ Solutions

### Solution 1
```python
name = "Raji"
age  = 30
lang = "Python"
print(f"My name is {name}, I'm {age}, and I love {lang}.")
```

### Solution 2
```python
def calculate(a: float, b: float, op: str) -> float:
    ops = {"+": a + b, "-": a - b, "*": a * b, "/": a / b if b else float("inf")}
    if op not in ops:
        raise ValueError(f"Unknown op: {op}")
    return ops[op]

print(calculate(10, 5, "*"))    # 50
```

### Solution 3
```python
from collections import Counter

sentence = "the cat sat on the mat the mat was warm"
counts = Counter(sentence.lower().split())
print(counts)
# Counter({'the': 3, 'mat': 2, 'cat': 1, 'sat': 1, 'on': 1, 'was': 1, 'warm': 1})
```

### Solution 4
```python
for i in range(1, 31):
    if i % 15 == 0:
        print("FizzBuzz")
    elif i % 3 == 0:
        print("Fizz")
    elif i % 5 == 0:
        print("Buzz")
    else:
        print(i)
```

### Solution 5
```python
from datetime import datetime
# replace the file-write block in movie_picker.py with:
with open("picks.txt", "a", encoding="utf-8") as f:
    f.write(f"{datetime.now().isoformat(timespec='seconds')} | {mood}: {pick}\n")
```

### Solution 6
```python
from collections import Counter

mood_counts = Counter()
with open("picks.txt", encoding="utf-8") as f:
    for line in f:
        # line example: "2026-05-28T08:32:11 | happy: Up"
        parts = line.strip().split("|")
        if len(parts) == 2:
            mood = parts[1].split(":")[0].strip()
            mood_counts[mood] += 1

for mood, n in mood_counts.most_common():
    print(f"{mood:10} {n}")
```

---

## 🎯 What you should now be able to do

- [x] Write basic Python with variables, lists, dicts, ifs, loops, functions
- [x] Handle user input and errors safely
- [x] Read & write text files

➡️ Next: **[Lesson 2 — Working with Files and Databases](02_Files_and_Databases.md)**
