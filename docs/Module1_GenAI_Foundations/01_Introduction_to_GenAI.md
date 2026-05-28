# Module 1 · Lesson 1 — Introduction to Generative AI

## 🍭 Imagine this…

Pretend you have a **parrot** that has read **every book in the world**.
Ask it *"Tell me a story about a dragon"* — it will invent a brand-new story it has never been told, but stitched together from patterns it learned.

That parrot is a **Generative AI**. It *generates* (makes up) new things — text, images, music, code — based on patterns from huge piles of data it studied.

---

## 🧠 The real concept

**Generative AI** = AI that **creates** new content.

The most common kind today is the **Large Language Model (LLM)** — a giant calculator that, given some text, predicts the **next word** (technically a *token*). It does this so well that it feels like it's *thinking*.

### Key terms — memorize these 8

| Term | What it means | Real-world picture |
|---|---|---|
| **LLM** | Large Language Model | GPT-4o, Claude 3.5, Gemini, Llama 3 |
| **Token** | A word or piece of a word | "unbelievable" = `un` + `believ` + `able` = 3 tokens |
| **Prompt** | What you type to the LLM | "Write me a haiku about coffee" |
| **Completion** | What the LLM types back | "Hot bean in my cup…" |
| **Context window** | How much text it can read at once | GPT-4o = ~128,000 tokens (~300 pages) |
| **Temperature** | How "creative" the answer is (0–2) | 0 = boring & exact, 1 = creative, 2 = wild |
| **System prompt** | The "role" you give the model | "You are a polite IT helpdesk agent." |
| **Hallucination** | When the model confidently makes stuff up | "Einstein was born in 1492" 😬 |

### Two big families of GenAI

```
Generative AI
├── Text         → LLMs (GPT, Claude, Llama)
├── Images       → Diffusion models (DALL·E, Midjourney, Stable Diffusion)
├── Audio        → TTS / music (ElevenLabs, Suno)
├── Video        → Sora, Veo
└── Code         → GitHub Copilot, CodeLlama
```

For this whole curriculum we focus on **text LLMs**.

---

## 🌍 Real-world scenario — IT Helpdesk Triage

> **Problem:** Your company gets 500 emails a day saying things like "VPN broken!", "Outlook stuck", "Need access to FolderX". A human triager spends 4 hours/day sorting them into categories and writing first-reply drafts.
>
> **GenAI solution:** Send each email to an LLM with a prompt: *"Classify this ticket into {VPN, Email, Access, Other} and draft a 3-line reply."* Done in 2 seconds per ticket.

You'll build a tiny version of this in Module 2.

---

## 💻 The code — your first LLM call, explained line by line

```python
# 1️⃣  Bring in the tools we need
from openai import OpenAI          # The library that lets Python talk to OpenAI
from dotenv import load_dotenv     # Reads secret keys from a .env file

# 2️⃣  Load secrets (API key) from .env into memory so OpenAI() can find them
load_dotenv()

# 3️⃣  Make a "client" — think of it as a phone line to OpenAI's servers
client = OpenAI()

# 4️⃣  Build the conversation as a list of messages
messages = [
    # System message = the personality/rules. The user never sees this.
    {"role": "system", "content": "You are a friendly tutor who explains things simply."},

    # User message = what YOU are asking
    {"role": "user",   "content": "What is Generative AI? Answer in 2 sentences."},
]

# 5️⃣  Call the model. Three things to notice:
response = client.chat.completions.create(
    model="gpt-4o-mini",          # which brain to use (cheap + smart)
    messages=messages,            # the conversation so far
    temperature=0.3,              # low temp = focused, not creative
)

# 6️⃣  Read the reply. The reply is buried inside response.choices[0].message
answer = response.choices[0].message.content
print(answer)
```

### What just happened, in toddler-speak 🧒

1. We **opened the library** (`import …`).
2. We **unlocked the API key** (`load_dotenv`).
3. We **picked up the phone** (`OpenAI()`).
4. We **wrote a script of the chat** (the `messages` list).
5. We **made the call** (`chat.completions.create`).
6. We **listened to the reply** (`response.choices[0].message.content`).

---

## 🔍 Tiny experiment — feel temperature

Change `temperature` from `0.0` → `0.5` → `1.5` and ask:
> "Give me a name for a coffee shop."

- `0.0` → "The Coffee House" (boring, repeats)
- `0.5` → "Brew Haven"
- `1.5` → "Quantum Bean Quasar" (wild)

That's the **creativity dial**.

---

## 🏋️ Exercises

### Exercise 1 — Hello, Tutor
Write a Python script that asks the LLM:
> "Explain HTTP in 3 lines for a 10-year-old."

### Exercise 2 — Role play
Use the **system prompt** to make the model behave like:
- A pirate captain
- A Shakespearean poet
- A grumpy DBA

Ask each one: *"What is a database?"*

### Exercise 3 — Temperature lab
Send the same prompt *"Suggest a startup idea about pets"* with `temperature=0.0`, `0.7`, and `1.5`. Print all three answers. What do you notice?

### Exercise 4 — Token counter
Install `tiktoken` (`pip install tiktoken`). Count how many tokens are in the sentence:
> "Generative AI is changing how we build software in 2026."

### Exercise 5 — Cost estimator
GPT-4o-mini costs ~ $0.15 per 1 million input tokens. How much would 10,000 calls of ~200 tokens each cost?

---

## ✅ Solutions

### Solution 1
```python
from openai import OpenAI
from dotenv import load_dotenv
load_dotenv()

client = OpenAI()
resp = client.chat.completions.create(
    model="gpt-4o-mini",
    messages=[
        {"role": "system", "content": "You explain tech to kids."},
        {"role": "user",   "content": "Explain HTTP in 3 lines for a 10-year-old."},
    ],
)
print(resp.choices[0].message.content)
```

### Solution 2
```python
personalities = {
    "Pirate":      "You are Captain Blackbeard. Speak like a pirate. Use 'Arrr!'.",
    "Shakespeare": "You are William Shakespeare. Answer in iambic verse.",
    "Grumpy DBA":  "You are a grumpy 30-year DBA. Be sarcastic but technically correct.",
}

for name, system in personalities.items():
    resp = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {"role": "system", "content": system},
            {"role": "user",   "content": "What is a database?"},
        ],
    )
    print(f"\n=== {name} ===\n{resp.choices[0].message.content}")
```

### Solution 3
```python
for t in [0.0, 0.7, 1.5]:
    resp = client.chat.completions.create(
        model="gpt-4o-mini",
        temperature=t,
        messages=[{"role": "user", "content": "Suggest a startup idea about pets."}],
    )
    print(f"\n--- temperature={t} ---\n{resp.choices[0].message.content}")
```
**Observation:** Higher temperature ⇒ more diverse, weirder ideas; lower ⇒ safer and repetitive.

### Solution 4
```python
import tiktoken
enc = tiktoken.encoding_for_model("gpt-4o-mini")
text = "Generative AI is changing how we build software in 2026."
tokens = enc.encode(text)
print(f"Tokens: {len(tokens)}")   # ~ 12
print(tokens)
```

### Solution 5
- Tokens per call ≈ 200
- Total tokens = 10,000 × 200 = 2,000,000
- Cost = 2,000,000 / 1,000,000 × $0.15 = **$0.30**
- 👉 Very cheap. This is why GenAI is exploding.

---

## 🎯 What you should now be able to do

- [x] Explain what an LLM is to a friend
- [x] Make a call to GPT-4o-mini from Python
- [x] Use a system prompt to change the model's behaviour
- [x] Estimate the cost of running an LLM app

➡️ Next: **[Lesson 2 — Essentials of Prompt Engineering](02_Prompt_Engineering.md)**
