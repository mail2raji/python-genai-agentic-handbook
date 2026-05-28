# Module 3 · Lesson 2 — LCEL Essentials

## 🍭 Imagine this…

A **toy train track** is just pieces snapped together: ⚪—🟦—⚪—🟩.
The train (your data) zooms through each piece in order.

**LCEL** (LangChain Expression Language) is the **snap mechanism** for AI components.
Every component has an "in" plug and an "out" plug. Snap them with `|`. Done.

---

## 🧠 The real concept

LCEL = a tiny mini-language that lets you express AI pipelines as **algebra** instead of imperative loops.

### The 7 LCEL primitives you'll meet

| Primitive | What it does | Code |
|---|---|---|
| `\|` | Snap two Runnables | `prompt \| llm` |
| `RunnableLambda` | Wrap any Python function | `RunnableLambda(lambda x: x.upper())` |
| `RunnableParallel` | Run branches concurrently | `{"a": chainA, "b": chainB}` |
| `RunnablePassthrough` | Pass input through unchanged | Used in fan-outs |
| `.invoke()` | Run once | `chain.invoke(x)` |
| `.batch()` | Run a list in parallel | `chain.batch([x1, x2])` |
| `.stream()` | Yield tokens as they arrive | `for c in chain.stream(x): …` |

### Mental model

```
input  →  [prompt]  →  [LLM]  →  [parser]  →  output
            (Runnable) (Runnable) (Runnable)
            \________________ chain ________________/
```

Every brick takes input, returns output. The chain is the composition.

---

## 🌍 Real-world scenario — Resume scorer

You give the chain a `{resume, job_description}`. In one shot it must produce:
1. A **match score** (0–100).
2. A **strengths** list.
3. **Gaps** list.
4. A **personalised email** inviting or rejecting the candidate.

That's 4 things. Naive code = 4 LLM calls. With LCEL `RunnableParallel` you can fan out and merge.

---

## 💻 The code — fan-out / fan-in with LCEL

```python
# resume_scorer.py
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser, JsonOutputParser
from langchain_core.runnables import RunnableParallel, RunnablePassthrough
from dotenv import load_dotenv

load_dotenv()
llm = ChatOpenAI(model="gpt-4o-mini", temperature=0)

# 1️⃣ Four small prompts
score_prompt = ChatPromptTemplate.from_template("""
Score how well this resume matches the job (0-100, integer only).
Resume: {resume}
Job: {job}
Output: just the integer.""")

strengths_prompt = ChatPromptTemplate.from_template("""
List 3 strengths of this candidate relevant to the job, as JSON array of strings.
Resume: {resume}
Job: {job}""")

gaps_prompt = ChatPromptTemplate.from_template("""
List up to 3 missing skills, as JSON array of strings.
Resume: {resume}
Job: {job}""")

email_prompt = ChatPromptTemplate.from_template("""
Write a kind 4-sentence email to the candidate.
If score >= 70 invite to interview; otherwise polite rejection.
Score: {score}
Resume: {resume}
Job: {job}""")

# 2️⃣ Small chains
score_chain = score_prompt | llm | StrOutputParser()
strengths_chain = strengths_prompt | llm | JsonOutputParser()
gaps_chain = gaps_prompt | llm | JsonOutputParser()

# 3️⃣ Fan-out first — compute score in parallel with strengths/gaps
fanout = RunnableParallel(
    score=score_chain,
    strengths=strengths_chain,
    gaps=gaps_chain,
    resume=RunnablePassthrough() | (lambda x: x["resume"]),   # carry inputs forward
    job=RunnablePassthrough() | (lambda x: x["job"]),
)

# 4️⃣ Now use score + inputs to write the email
def add_email(d: dict) -> dict:
    email = (email_prompt | llm | StrOutputParser()).invoke({
        "score": d["score"],
        "resume": d["resume"],
        "job": d["job"],
    })
    return {**d, "email": email}

# 5️⃣ Compose everything
pipeline = fanout | add_email

# 6️⃣ Use it
resume = "Python, AWS, 5 years backend. Built data pipelines, SQL, Kafka."
job    = "Senior backend engineer. Python + Postgres + GraphQL. Remote."

result = pipeline.invoke({"resume": resume, "job": job})
print("Score    :", result["score"])
print("Strengths:", result["strengths"])
print("Gaps     :", result["gaps"])
print("Email    :", result["email"])
```

### What's happening visually
```
            ┌── score_chain ─────┐
input ─────►│── strengths_chain ─├── merge ──► add_email ──► output
            └── gaps_chain ──────┘
            (all 3 run in parallel)
```

Three LLM calls happen **at the same time** → 3× faster than serial.

---

## 💻 RunnableLambda — drop in any function

```python
from langchain_core.runnables import RunnableLambda

upper = RunnableLambda(lambda s: s.upper())
chain = upper | (lambda s: s + " !!!")
print(chain.invoke("hello"))    # → "HELLO !!!"
```

A `RunnableLambda` lets you mix **plain Python** code with LangChain bricks. Use it for cleanup, formatting, filtering, etc.

---

## 💻 Conditional branching with `RunnableBranch`

```python
from langchain_core.runnables import RunnableBranch

# Pick a different chain depending on the input
support_chain = (
    ChatPromptTemplate.from_template("Help with IT: {q}") | llm | StrOutputParser()
)
billing_chain = (
    ChatPromptTemplate.from_template("Help with billing: {q}") | llm | StrOutputParser()
)
default_chain = (
    ChatPromptTemplate.from_template("Answer: {q}") | llm | StrOutputParser()
)

router = RunnableBranch(
    (lambda x: "vpn" in x["q"].lower() or "laptop" in x["q"].lower(), support_chain),
    (lambda x: "invoice" in x["q"].lower() or "refund" in x["q"].lower(), billing_chain),
    default_chain,        # fallback
)

print(router.invoke({"q": "My laptop won't connect to VPN"}))
print(router.invoke({"q": "Where's my refund?"}))
```

That's **routing in 8 lines** — the same thing you'd build with 50 lines of if/else.

---

## 💻 Async + parallelism

```python
import asyncio

async def main():
    results = await chain.abatch([{"resume": r, "job": j} for r, j in pairs])
    print(results)

asyncio.run(main())
```

Every `.invoke` has an `a-prefixed` cousin: `.ainvoke`, `.abatch`, `.astream`. Use these in FastAPI or any async server.

---

## 🏋️ Exercises

### Exercise 1 — Add a translation branch
Modify the resume scorer so it **also** returns an `email_es` field (Spanish version of the email) in parallel.

### Exercise 2 — Router with 3 destinations
Build a router for a customer-service bot with three topics: `shipping`, `returns`, `account`. Use `RunnableBranch`.

### Exercise 3 — Lambda cleanup step
Add a `RunnableLambda` that lowercases and strips whitespace **before** the prompt sees the user's question.

### Exercise 4 — Batch benchmark
Translate 10 sentences once via `.invoke()` in a loop and once via `.batch()`. Time both with `time.perf_counter()`. Report the speedup.

### Exercise 5 — Streaming summariser
Build a chain that streams a summary of a long article token by token. Display a live word counter that updates as tokens arrive.

---

## ✅ Solutions

### Solution 1
```python
email_es_chain = (
    ChatPromptTemplate.from_template(
        "Translate this email to Spanish. Output only the translation.\n\n{email}"
    )
    | llm
    | StrOutputParser()
)

def add_email_es(d):
    return {**d, "email_es": email_es_chain.invoke({"email": d["email"]})}

pipeline_v2 = fanout | add_email | add_email_es
```

### Solution 2
```python
shipping = ChatPromptTemplate.from_template("Help with shipping: {q}") | llm | StrOutputParser()
returns  = ChatPromptTemplate.from_template("Help with returns: {q}")  | llm | StrOutputParser()
account  = ChatPromptTemplate.from_template("Help with account: {q}")  | llm | StrOutputParser()

router = RunnableBranch(
    (lambda x: any(k in x["q"].lower() for k in ["ship", "track", "delivery"]), shipping),
    (lambda x: any(k in x["q"].lower() for k in ["return", "refund"]), returns),
    (lambda x: any(k in x["q"].lower() for k in ["login", "password", "account"]), account),
    default_chain,
)
```

### Solution 3
```python
cleanup = RunnableLambda(lambda x: {"q": x["q"].strip().lower()})
chain = cleanup | router
```

### Solution 4
```python
import time
sentences = [f"sample sentence number {i}" for i in range(10)]
translate = ChatPromptTemplate.from_template("Translate to French: {s}") | llm | StrOutputParser()

t0 = time.perf_counter()
serial = [translate.invoke({"s": s}) for s in sentences]
t_serial = time.perf_counter() - t0

t0 = time.perf_counter()
batched = translate.batch([{"s": s} for s in sentences])
t_batch = time.perf_counter() - t0

print(f"serial: {t_serial:.2f}s   batch: {t_batch:.2f}s   speedup: {t_serial/t_batch:.1f}×")
```

### Solution 5
```python
article = open("article.txt", encoding="utf-8").read()
chain = ChatPromptTemplate.from_template("Summarise:\n\n{text}") | llm | StrOutputParser()

words = 0
for tok in chain.stream({"text": article}):
    print(tok, end="", flush=True)
    words += len(tok.split())
print(f"\n\nWords so far: {words}")
```

---

## 🎯 What you should now be able to do

- [x] Compose any AI pipeline with `|`
- [x] Use `RunnableParallel`, `RunnableLambda`, `RunnableBranch`
- [x] Run things in batch, stream, async

➡️ Next: **[Lesson 3 — Managing LLM Input / Output](03_Managing_LLM_IO.md)**
