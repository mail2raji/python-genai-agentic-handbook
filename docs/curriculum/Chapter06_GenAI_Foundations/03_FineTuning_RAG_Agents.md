# Module 1 · Lesson 3 — Fine-tuning, RAG, and Agents

## 🍭 Imagine this…

You hire a brilliant new employee — but they don't know your company yet.

You have **three options**:

1. **Hand them a thick employee handbook every morning** to read before they speak. → **Prompt engineering**
2. **Let them look things up in your company wiki while they work.** → **RAG**
3. **Send them to a 6-month training course on your company.** → **Fine-tuning**
4. **Give them keys to the building, the ERP system, and email — and let them act.** → **Agents**

These are the **four ways to make an LLM useful in *your* world**.

---

## 🧠 The real concept

### 1. Prompt engineering (revisited)
The model sees only what you put in the prompt. Limit: prompts are small (a few thousand tokens).

### 2. Fine-tuning
You take an existing model and **retrain** some of its weights on **your** data (1,000+ labelled examples). The model now "knows" your style.

| ✅ Good for | ❌ Bad for |
|---|---|
| Domain-specific *tone* / *format* (e.g. legal language) | Adding new facts that change daily |
| Reducing prompt length & cost | Small datasets |
| Specialized classifiers | Quick prototypes |

### 3. RAG (Retrieval-Augmented Generation)
Before answering, the model **retrieves** relevant chunks from your knowledge base (PDFs, wiki, DB) and stuffs them into the prompt.

```
Question  ─►  Vector DB (search)  ─►  Top 5 chunks
                                          │
                                          ▼
                                LLM (Question + chunks)
                                          │
                                          ▼
                                    Final answer
```

**Why RAG wins for facts**: you can update the knowledge base in seconds; fine-tuning takes hours and money.

### 4. Agents
An **agent** is an LLM that can **decide** to use **tools** (functions, APIs, databases) in a loop until the goal is met.

```
Goal → [LLM thinks → picks a tool → runs it → reads result] → repeat → Final answer
```

Example: "Book me a flight under $400 to Tokyo on Friday." → the agent calls a flights API, compares results, picks one, calls a booking API.

---

## 🌍 Real-world scenario — "Ask my company" assistant

> A bank wants employees to ask: *"What's our password policy for vendor accounts?"* and get the correct answer from internal policy PDFs — **not** a hallucinated one.

| Approach | Outcome |
|---|---|
| Prompt only | Model invents a plausible (wrong) policy. 😱 |
| Fine-tuning | Possible but expensive; needs re-training every policy update. |
| **RAG** | ✅ Cheap, current, cite-able. **This is the right answer.** |
| Agent with tools | Even better if it can also *create* a ticket to update a policy. |

**Industry rule of thumb (2026):**
> Start with **prompt engineering**. Add **RAG** when you need facts. Add **agents** when you need actions. Only **fine-tune** when the first three can't reach your accuracy/tone target.

---

## 💻 The code — a tiny RAG taste (you'll build the full thing in Module 4)

```python
# mini_rag_demo.py — a tiny "fake" RAG to show the IDEA
from openai import OpenAI
from dotenv import load_dotenv

load_dotenv()
client = OpenAI()

# 1️⃣  Pretend this is our company knowledge base
knowledge_base = [
    "Vendor passwords must be 16+ characters and rotated every 60 days.",
    "All vendor accounts require MFA via the Acme Authenticator app.",
    "Vendor access requests must be approved by a Director or above.",
    "Production database backups happen at 02:00 UTC daily.",
    "The on-call rotation is managed in PagerDuty under team 'Platform-Ops'.",
]

# 2️⃣  "Retrieval" — pick chunks whose words overlap with the question (super naive!)
def retrieve(question: str, k: int = 2) -> list[str]:
    q_words = set(question.lower().split())
    scored = [
        (len(q_words & set(doc.lower().split())), doc)
        for doc in knowledge_base
    ]
    scored.sort(reverse=True)                       # best matches first
    return [doc for _, doc in scored[:k]]


# 3️⃣  "Generation" — give the model ONLY those chunks and forbid making things up
def rag_answer(question: str) -> str:
    chunks = retrieve(question)
    context = "\n".join(f"- {c}" for c in chunks)

    prompt = f"""Answer the question using ONLY the context below.
If the answer is not in the context, say "I don't know."

Context:
{context}

Question: {question}
"""
    resp = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}],
        temperature=0,
    )
    return resp.choices[0].message.content


# 4️⃣  Try it
print(rag_answer("What's our vendor password policy?"))
print()
print(rag_answer("Who is the CEO?"))   # not in the KB → "I don't know."
```

### Line-by-line in toddler-speak
1. We **make a list of "facts"** (`knowledge_base`).
2. `retrieve()` picks the **2 facts** that share the most words with the question.
3. `rag_answer()` builds a prompt: *"Use ONLY these facts. If unknown, say so."*
4. The LLM answers **grounded** on real data — no hallucinations.

In a real RAG (Module 4) we replace the naive word-overlap step with **vector embeddings + a vector DB**. The shape stays exactly the same.

---

## 💻 A tiny agent taste (you'll build the full thing in Module 5)

```python
# mini_agent_demo.py — a 1-tool "agent"
from openai import OpenAI
from dotenv import load_dotenv
import json, datetime

load_dotenv()
client = OpenAI()

# 1️⃣  Define one "tool" the model can call
def get_current_time(timezone: str = "UTC") -> str:
    """Return the current time. (In real life, use pytz.)"""
    return datetime.datetime.utcnow().isoformat() + "Z"

# 2️⃣  Describe the tool to the model in OpenAI's "function calling" format
tools = [{
    "type": "function",
    "function": {
        "name": "get_current_time",
        "description": "Get the current UTC time.",
        "parameters": {
            "type": "object",
            "properties": {
                "timezone": {"type": "string", "description": "IANA tz, default UTC"}
            },
            "required": []
        }
    }
}]

# 3️⃣  Ask the model — it will DECIDE to call the tool
messages = [{"role": "user", "content": "What time is it right now?"}]

first = client.chat.completions.create(
    model="gpt-4o-mini", messages=messages, tools=tools,
)
choice = first.choices[0].message

# 4️⃣  Did it ask for a tool?
if choice.tool_calls:
    call = choice.tool_calls[0]
    args = json.loads(call.function.arguments)
    result = get_current_time(**args)                       # ← we run the function

    messages.append(choice)                                 # the model's "I want to use a tool" turn
    messages.append({                                       # our tool's reply
        "role": "tool",
        "tool_call_id": call.id,
        "content": result,
    })

    # 5️⃣  Call the model AGAIN with the tool result so it can answer the user
    final = client.chat.completions.create(model="gpt-4o-mini", messages=messages)
    print(final.choices[0].message.content)
else:
    print(choice.content)
```

### What just happened
1. We gave the model a tool: `get_current_time`.
2. The model decided **"to answer this, I need that tool"** → returned a tool call.
3. We **executed the function** ourselves and gave the result back.
4. The model used the result to write the user-facing answer.

**This loop is the foundation of every agent.**

---

## 🧭 Decision flowchart — which technique to use?

```
Need to make AI helpful for YOUR use case?
│
├── Does the answer change daily?            ──Yes──► RAG
│
├── Need a specific tone/format consistently? ──Yes──► Fine-tune (or prompt + few-shot first)
│
├── Need to TAKE ACTIONS (DB writes, API calls)?  ──Yes──► Agents
│
└── Mostly Q&A, content gen?                 ──Yes──► Prompt engineering
```

---

## 🏋️ Exercises

### Exercise 1 — RAG vs Fine-tuning
For each scenario, choose **RAG** or **Fine-tuning** and justify in one line:
1. A legal firm needs the LLM to write contracts in their unique house style.
2. A hospital wants the LLM to answer based on the most recent clinical guidelines (updated weekly).
3. A startup wants the chatbot to refer to the user always as "amigo".
4. A bank wants instant answers from a 2,000-page risk policy PDF.

### Exercise 2 — Extend the mini RAG
Add 5 more "facts" to `knowledge_base` about a fake company *MoonBank*. Ask 3 questions including one that **isn't** in the KB. Confirm it says "I don't know."

### Exercise 3 — New tool for the mini agent
Add a `calculator(a, b, op)` tool. Ask the model: *"What is 184 × 27?"* — it should call `calculator`.

### Exercise 4 — Hallucination hunt
Ask GPT-4o-mini *without* RAG: *"Who is the CEO of MoonBank in 2026?"*
Then with your RAG (where the KB says nothing about a CEO).
Compare the answers.

### Exercise 5 — Mini design doc
Write a 1-page plan for **"AI assistant for the HR team"**:
- Which of the 4 techniques would you use, in which order?
- What are the risks (PII, bias, hallucination)?
- How would you measure success?

---

## ✅ Solutions

### Solution 1
1. **Fine-tuning** — house style = stable tone & format.
2. **RAG** — guidelines change weekly; updates must be instant.
3. **Prompt engineering** (system prompt). Fine-tuning is overkill.
4. **RAG** — facts from a long doc, cite-able.

### Solution 2
```python
knowledge_base += [
    "MoonBank was founded in 2018 in Singapore.",
    "MoonBank's HQ is at 88 Marina Bay Drive.",
    "MoonBank offers Premium and Standard accounts.",
    "Premium accounts get free international wire transfers.",
    "The MoonBank helpline is +65-800-MOON.",
]
for q in [
    "When was MoonBank founded?",
    "Do Premium accounts get free wires?",
    "Who is the CEO?",                 # not in KB
]:
    print(q, "→", rag_answer(q))
```

### Solution 3
```python
def calculator(a: float, b: float, op: str) -> str:
    return str({"add": a+b, "sub": a-b, "mul": a*b, "div": a/b}[op])

tools.append({
    "type": "function",
    "function": {
        "name": "calculator",
        "description": "Do arithmetic on two numbers.",
        "parameters": {
            "type": "object",
            "properties": {
                "a":  {"type": "number"},
                "b":  {"type": "number"},
                "op": {"type": "string", "enum": ["add", "sub", "mul", "div"]},
            },
            "required": ["a", "b", "op"],
        }
    }
})
```
Then run a tool loop (same shape as the time example). For `184 × 27` the model will pick `calculator(a=184, b=27, op="mul")` and return `4968`.

### Solution 4
- Without RAG: the model will likely **make up** a CEO name → **hallucination**.
- With RAG (no mention in KB): the model says **"I don't know."** → safe and trustworthy.
- This is the whole reason enterprises adopt RAG.

### Solution 5 — Example HR assistant plan
1. **Prompt engineering** for system role: "You are an HR assistant for ACME Corp. Be empathetic."
2. **RAG** over HR policy docs, leave handbook, benefits PDFs.
3. **Agent tools**: `lookup_leave_balance(emp_id)`, `submit_leave_request(...)`.
4. Avoid **fine-tuning** unless tone tests fail.

**Risks & mitigations**
- *PII leakage* → strip employee names before logging; per-user filters on RAG.
- *Bias* in policy interpretation → human-in-the-loop for decisions affecting comp/promotion.
- *Hallucination* → always cite the source chunk; fall back to "I don't know."

**Success metrics**
- Ticket deflection rate (% of HR tickets handled by AI without human)
- Employee CSAT score for AI answers
- Hallucination rate (sampled human eval)
- Cost per interaction

---

## 🎯 What you should now be able to do

- [x] Explain when to use prompts, RAG, fine-tuning, or agents
- [x] Read code for a tiny RAG and a tiny tool-calling agent
- [x] Write a 1-page design doc for an AI use case

🎉 **Module 1 complete!**
➡️ Next module: **[Module 2 — Python for GenAI](../Chapter04_Python_for_GenAI/01_Intro_to_Python.md)**
