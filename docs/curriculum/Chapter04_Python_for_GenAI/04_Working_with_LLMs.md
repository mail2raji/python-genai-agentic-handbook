# Module 2 · Lesson 4 — Working with LLMs in Python

## 🍭 Imagine this…

You met the parrot in Module 1. Now you'll **teach it tricks**:
1. **Stream** its voice live (don't wait for the whole reply).
2. **Force structure** so it always answers in neat JSON.
3. **Plug in tools** so it can call functions.
4. **Use embeddings** so you can search by meaning, not exact words.
5. **Save money** with caching.

By the end you'll have a **reusable LLM helper module** you'll use in every later lesson.

---

## 🧠 The 6 things every LLM engineer does

| # | Skill | What it solves |
|---|---|---|
| 1 | **Provider abstraction** | Don't lock yourself to one vendor |
| 2 | **Streaming** | Feels instant for chat UIs |
| 3 | **Structured outputs (JSON / Pydantic)** | Reliable downstream parsing |
| 4 | **Function / tool calling** | Lets LLM run code |
| 5 | **Embeddings** | Semantic search, RAG, clustering |
| 6 | **Error handling, retries, cost tracking** | Production readiness |

---

## 🌍 Real-world scenario — "Smart inbox" service

Your team is drowning in support email. You'll build a tiny library that:
- Streams an AI summary to the agent as it arrives (feels instant).
- Returns a strict JSON of `{intent, urgency, draft_reply}`.
- Optionally calls a `lookup_order(order_id)` tool.
- Tracks how many tokens (and $) each call used.

You'll reuse this helper across Modules 3 / 4 / 5.

---

## 💻 1. A clean, provider-agnostic helper

```python
# llm_client.py — keep this in every project
import os
from typing import Iterable
from dotenv import load_dotenv
from openai import OpenAI, AzureOpenAI

load_dotenv()


def get_client():
    """Return an OpenAI-compatible client (works for OpenAI or Azure OpenAI)."""
    if os.getenv("AZURE_OPENAI_API_KEY"):
        return AzureOpenAI(
            api_key=os.environ["AZURE_OPENAI_API_KEY"],
            azure_endpoint=os.environ["AZURE_OPENAI_ENDPOINT"],
            api_version=os.getenv("AZURE_OPENAI_API_VERSION", "2024-08-01-preview"),
        )
    return OpenAI()                       # falls back to OPENAI_API_KEY


def model_name() -> str:
    """Same code works for both — deployment name on Azure, model on OpenAI."""
    return os.getenv("AZURE_OPENAI_DEPLOYMENT") or os.getenv("OPENAI_MODEL", "gpt-4o-mini")
```

### Why bother with the abstraction?
You can swap OpenAI ↔ Azure OpenAI without touching the rest of your code by just changing the `.env` file. Big enterprises require Azure.

---

## 💻 2. Streaming responses

```python
from llm_client import get_client, model_name

client = get_client()

def stream_chat(prompt: str) -> str:
    """Print tokens as they arrive AND return the full text."""
    stream = client.chat.completions.create(
        model=model_name(),
        messages=[{"role": "user", "content": prompt}],
        stream=True,                              # ← the magic flag
    )

    full = []
    for chunk in stream:
        delta = chunk.choices[0].delta.content or ""
        print(delta, end="", flush=True)          # show live
        full.append(delta)
    print()
    return "".join(full)

stream_chat("Tell me a 4-sentence bedtime story about a brave robot.")
```

### Why streaming?
A 200-word answer takes ~4 seconds total — but the **first token** arrives in <500 ms. Streaming makes your chat UI feel **8× faster** to the user.

---

## 💻 3. Structured output with Pydantic

```python
# pydantic gives runtime-validated typed dataclasses
from pydantic import BaseModel, Field
from typing import Literal
import json
from llm_client import get_client, model_name

client = get_client()

class TicketAnalysis(BaseModel):
    intent:      Literal["refund", "shipping", "tech_support", "billing", "other"]
    urgency:     int = Field(ge=1, le=5)
    sentiment:   Literal["negative", "neutral", "positive"]
    draft_reply: str

def analyze_ticket(text: str) -> TicketAnalysis:
    # Newer OpenAI SDK supports response_format=parse with Pydantic directly:
    completion = client.beta.chat.completions.parse(
        model=model_name(),
        messages=[
            {"role": "system", "content": "You analyze customer-support tickets."},
            {"role": "user",   "content": text},
        ],
        response_format=TicketAnalysis,         # ← the magic line
    )
    return completion.choices[0].message.parsed


result = analyze_ticket("My package is 4 days late and I need it for a wedding!")
print(result.intent, result.urgency, result.sentiment)
print(result.draft_reply)
```

### Why is this huge?
Before this feature you'd write a 20-line regex parser and pray. Now you get a **typed object** — `result.urgency` is guaranteed to be an int between 1 and 5. Downstream code becomes safe.

---

## 💻 4. Function (tool) calling

```python
import json
from llm_client import get_client, model_name

client = get_client()

# 1️⃣ Your real function
def lookup_order(order_id: str) -> dict:
    fake_db = {"O123": {"status": "in_transit", "eta_days": 2}}
    return fake_db.get(order_id, {"error": "not found"})

# 2️⃣ Describe it to the model
TOOLS = [{
    "type": "function",
    "function": {
        "name": "lookup_order",
        "description": "Look up the live status of an order.",
        "parameters": {
            "type": "object",
            "properties": {"order_id": {"type": "string"}},
            "required": ["order_id"],
        },
    },
}]

def chat_with_tools(user_msg: str) -> str:
    msgs = [{"role": "user", "content": user_msg}]
    while True:
        resp = client.chat.completions.create(
            model=model_name(), messages=msgs, tools=TOOLS,
        )
        reply = resp.choices[0].message
        msgs.append(reply)

        if not reply.tool_calls:                      # model done thinking
            return reply.content

        # 3️⃣ Run every tool the model requested
        for call in reply.tool_calls:
            args = json.loads(call.function.arguments)
            if call.function.name == "lookup_order":
                result = lookup_order(**args)
            else:
                result = {"error": f"unknown tool {call.function.name}"}

            msgs.append({
                "role": "tool",
                "tool_call_id": call.id,
                "content": json.dumps(result),
            })


print(chat_with_tools("Where is my order O123?"))
```

### What just happened (the tool loop) 🔄
1. We send the user message + the tool list.
2. The model thinks "I need `lookup_order`" → returns a `tool_call`.
3. We **run** the function, append the result, and call the model again.
4. Now the model has the data → writes the human-facing reply.
5. The `while True` repeats only if the model decides to call **more** tools.

This loop is **literally how every agent works.** You'll see it again in Module 5.

---

## 💻 5. Embeddings (semantic search, the seed of RAG)

```python
import numpy as np
from llm_client import get_client

client = get_client()

def embed(texts: list[str]) -> np.ndarray:
    """Turn each text into a 1536-dim vector."""
    resp = client.embeddings.create(
        model="text-embedding-3-small",        # cheap & good
        input=texts,
    )
    return np.array([d.embedding for d in resp.data])

def cosine(a, b):
    return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))


docs = [
    "How to reset my password",
    "Refund policy for damaged items",
    "International shipping times",
    "My cat keeps sleeping on the keyboard",   # noise!
]
query = "I forgot my login password"

vecs = embed(docs + [query])
doc_vecs, q_vec = vecs[:-1], vecs[-1]

for doc, dv in zip(docs, doc_vecs):
    print(f"{cosine(q_vec, dv):.3f}  ↔  {doc}")
```

### Why this matters
The first doc (about passwords) gets the **highest similarity score** — even though the words "forgot" and "login" don't appear in it. **Embeddings find meaning, not keywords.** This is the entire foundation of RAG.

---

## 💻 6. Cost tracking + retry helper

```python
import time, random
from openai import RateLimitError, APIError

def chat_safe(client, **kwargs):
    """Retry on rate limits / transient errors and return usage stats."""
    for attempt in range(5):
        try:
            resp = client.chat.completions.create(**kwargs)
            u = resp.usage
            cost = (u.prompt_tokens * 0.15 + u.completion_tokens * 0.60) / 1_000_000
            return resp, cost
        except (RateLimitError, APIError) as e:
            wait = (2 ** attempt) + random.random()
            print(f"[{type(e).__name__}] retry in {wait:.1f}s")
            time.sleep(wait)
    raise RuntimeError("LLM call failed after 5 attempts")
```

> Prices change. For GPT-4o-mini as of 2026-Q1: ~$0.15/M input, ~$0.60/M output.

---

## 🏋️ Exercises

### Exercise 1 — Hello, streaming
Make a streaming version that asks for a 200-word essay on "why Python is fun" and prints tokens live.

### Exercise 2 — Strict JSON product extractor
Use Pydantic to extract `Product(name, price_inr, weight_g, vegetarian)` from this text:
> *"Maggie 70g pack — ₹14 each, vegetarian."*

### Exercise 3 — Two tools
Add a second tool `cancel_order(order_id)`. Ask the model: *"Cancel order O999, then tell me the status of O123."* Verify both tools fire.

### Exercise 4 — Search engine
Index 10 sentences with embeddings. Ask the user for a query, return the top 3 most similar sentences.

### Exercise 5 — Token budget guard
Write `assert_under(prompt, max_tokens)` that uses `tiktoken` to refuse a prompt over the limit.

### Exercise 6 — A/B model compare
Send the same prompt to `gpt-4o-mini` and `gpt-4o`. Print both replies and token costs side by side.

---

## ✅ Solutions

### Solution 1
```python
stream_chat("Write a 200-word essay on why Python is fun. Use simple words.")
```

### Solution 2
```python
from pydantic import BaseModel, Field
class Product(BaseModel):
    name: str
    price_inr: float
    weight_g: int
    vegetarian: bool

resp = client.beta.chat.completions.parse(
    model=model_name(),
    messages=[{"role": "user",
               "content": "Extract product info: 'Maggie 70g pack — ₹14 each, vegetarian.'"}],
    response_format=Product,
)
print(resp.choices[0].message.parsed)
# Product(name='Maggie', price_inr=14.0, weight_g=70, vegetarian=True)
```

### Solution 3
```python
def cancel_order(order_id: str) -> dict:
    return {"order_id": order_id, "status": "cancelled"}

TOOLS.append({
    "type": "function",
    "function": {
        "name": "cancel_order",
        "description": "Cancel an order by ID.",
        "parameters": {
            "type": "object",
            "properties": {"order_id": {"type": "string"}},
            "required": ["order_id"],
        },
    },
})
# Then add an elif in the dispatcher:
# elif call.function.name == "cancel_order": result = cancel_order(**args)
```

### Solution 4
```python
sentences = [
    "Python is a versatile programming language.",
    "Bananas are great for potassium.",
    "Machine learning needs lots of data.",
    "Cats love sleeping in cardboard boxes.",
    "Quantum computers use qubits.",
    "Pizza is everyone's favourite food.",
    "FastAPI is a modern Python web framework.",
    "Embeddings power semantic search.",
    "The Eiffel Tower is in Paris.",
    "GPT models are large language models."
]
vecs = embed(sentences)

query = input("Search: ")
qv = embed([query])[0]
scored = sorted(((cosine(qv, v), s) for v, s in zip(vecs, sentences)), reverse=True)
for score, s in scored[:3]:
    print(f"{score:.3f}  {s}")
```

### Solution 5
```python
import tiktoken
def assert_under(prompt: str, max_tokens: int, model="gpt-4o-mini"):
    enc = tiktoken.encoding_for_model(model)
    n = len(enc.encode(prompt))
    if n > max_tokens:
        raise ValueError(f"Prompt is {n} tokens (> {max_tokens})")
    return n
```

### Solution 6
```python
prompt = "Explain blockchain in 3 sentences."
for m in ["gpt-4o-mini", "gpt-4o"]:
    resp, cost = chat_safe(client, model=m, messages=[{"role":"user","content":prompt}])
    print(f"\n=== {m} (${cost:.5f}) ===\n{resp.choices[0].message.content}")
```

---

## 🎯 What you should now be able to do

- [x] Build a provider-agnostic LLM helper
- [x] Stream responses live
- [x] Force structured JSON / Pydantic outputs
- [x] Add tools to an LLM (the agent loop!)
- [x] Use embeddings for semantic search
- [x] Track cost and retry safely

🎉 **Module 2 complete!**
➡️ Next module: **[Module 3 — Introduction to LangChain](../Chapter07_LangChain_Core/01_Introduction_to_LangChain.md)**
