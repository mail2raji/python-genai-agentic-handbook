# Module 1 · Advanced Lab — Build a Customer-Service Triage Assistant

> **Time:** 60–90 minutes · **Difficulty:** ⭐⭐⭐ (capstone for Module 1)
>
> You will combine **prompt engineering, structured output, RAG-lite, and basic agentic decisions** into one working business tool. This is the kind of script you'd actually ship to production for a small support team.

---

## 🌍 The real-world scenario

You work for **NimbusCloud**, a B2B SaaS company. Support is drowning in tickets. Most of them fall into 4 buckets:

| Category | Example | What support has to do |
|---|---|---|
| **Billing** | "Why was I charged twice?" | Pull invoice, refund if duplicate |
| **Technical** | "API returning 503 since 14:00 UTC" | Check status page, escalate to SRE |
| **Account** | "Can't log in" | Reset MFA / unlock |
| **Feature request** | "Please add SAML support" | Log in product backlog |

The CEO wants a **first-line AI** that:

1. Classifies the ticket into one of the 4 buckets.
2. Detects urgency (P1/P2/P3) from tone + keywords.
3. Cites which line(s) of the **support handbook** justify the suggested action (so reps can verify).
4. Drafts a polite first reply in the customer's language.
5. Outputs **valid JSON** so the helpdesk's existing automation can ingest it.

This lab is the *minimum* prototype that proves it works.

---

## 🧠 Why this lab is special

Up to now we built tiny demos. This lab introduces three production-grade habits:

| Habit | Why |
|---|---|
| **Schema-first thinking** | If the JSON is wrong, downstream automation breaks. We define the schema before the prompt. |
| **Grounded answers** | We force the model to cite the handbook to reduce hallucinations and give reps something to verify. |
| **Self-check pass** | A second LLM call re-reads the JSON and flags anything that looks wrong before we send it. |

---

## 📂 Files you'll create

```
m1_lab/
├── handbook.md         ← 30-line internal SOPs
├── tickets.jsonl       ← 5 sample tickets (1 per line)
├── triage.py           ← the assistant
└── output.jsonl        ← results — one JSON object per ticket
```

---

## 1️⃣ The handbook (the model's "ground truth")

Save as `m1_lab/handbook.md`:

```markdown
# NimbusCloud — Support SOPs (v3.2)

## Billing
- B-01 Duplicate charges within 30 days → refund in full, no manager approval.
- B-02 Customer claims wrong plan → verify in Stripe before changes.
- B-03 Failed invoice retry → recommend ACH instead of card.

## Technical
- T-01 API 5xx errors for >5 minutes → escalate to SRE on-call.
- T-02 Single 5xx → ask customer for request ID, do NOT escalate.
- T-03 Webhook delivery failure → check signing secret first.

## Account
- A-01 Locked after 5 failed logins → manual unlock after identity check.
- A-02 MFA reset → require government ID via secure upload form.
- A-03 SSO not redirecting → verify ACS URL with customer admin.

## Feature requests
- F-01 Log in Productboard with tag `customer-voice`.
- F-02 Always respond with timeline expectations (no firm dates).

## Tone
- TO-01 Empathy first sentence, action second.
- TO-02 Match the customer's language (English/Spanish/French/German).
```

---

## 2️⃣ Sample tickets

Save as `m1_lab/tickets.jsonl` (one per line — no commas between):

```json
{"id":"TKT-1001","customer":"acme@example.com","language":"en","subject":"Double charge this month","body":"Hi, I see TWO charges for $99 on May 14 and May 16. We only have one team."}
{"id":"TKT-1002","customer":"globex@example.com","language":"en","subject":"API down","body":"Our prod app has been getting 503 from your /v1/events endpoint for the past 20 minutes. This is breaking checkout. Status page says all green. Help!"}
{"id":"TKT-1003","customer":"hooli@example.com","language":"es","subject":"No puedo entrar","body":"Hola, no puedo iniciar sesión, dice que mi cuenta está bloqueada. ¿Pueden ayudar?"}
{"id":"TKT-1004","customer":"piedpiper@example.com","language":"en","subject":"SAML support?","body":"We'd really like SAML SSO with Okta. Any plans?"}
{"id":"TKT-1005","customer":"vandelay@example.com","language":"en","subject":"Tried once, got 503","body":"I hit your API once and got a 503. Should I worry?"}
```

---

## 3️⃣ The schema (Pydantic)

Open `m1_lab/triage.py` and start with this:

```python
# triage.py
from __future__ import annotations
import json, os, pathlib, time
from typing import Literal
from pydantic import BaseModel, Field, ValidationError
from openai import OpenAI
from dotenv import load_dotenv

load_dotenv()
client = OpenAI()
MODEL = "gpt-4o-mini"
HANDBOOK = pathlib.Path("handbook.md").read_text(encoding="utf-8")

class Triage(BaseModel):
    ticket_id: str
    category: Literal["billing", "technical", "account", "feature_request"]
    urgency:  Literal["P1", "P2", "P3"]
    handbook_refs: list[str] = Field(min_length=1, max_length=4,
        description="Codes from the handbook like 'B-01', 'T-02'")
    summary:  str = Field(max_length=200)
    suggested_action: str = Field(max_length=300)
    draft_reply: str = Field(max_length=800)
    confidence: float = Field(ge=0.0, le=1.0)
```

### Toddler-level explanation
- **`Literal[...]`** = the LLM must pick **one** of these exact strings. No "billing question?" allowed.
- **`min_length=1`** on `handbook_refs` = we **demand** at least one citation. No citation → not valid → we'll regenerate.
- **`confidence: float`** = the model tells us how sure it is. We use this to flag for human review.

---

## 4️⃣ The triage prompt

```python
SYSTEM_PROMPT = """You are NimbusCloud's tier-1 support triage assistant.

You will receive ONE ticket. Output a JSON object that matches this schema EXACTLY:
- ticket_id (echo from input)
- category: one of [billing, technical, account, feature_request]
- urgency: P1 (revenue/availability impact in <1h), P2 (broken non-urgent), P3 (nice-to-have)
- handbook_refs: list of codes (like "B-01") from the handbook that justify your action
- summary: <=200 chars, factual
- suggested_action: what an agent should DO (1-2 sentences)
- draft_reply: polite reply IN THE CUSTOMER'S LANGUAGE (use the `language` field)
- confidence: 0.0-1.0 — your honest self-assessment

Rules:
* If you cannot find a handbook code that fits, set confidence <= 0.6.
* NEVER promise refunds or timelines outside the handbook.
* Empathy first sentence, action second (rule TO-01).
* Output JSON only — no markdown fences, no commentary.

Handbook follows:
""" + HANDBOOK
```

### Why we paste the handbook into every call
This is **RAG-lite**: no vector DB needed because the corpus is tiny (1 KB). We'll graduate to real RAG in Module 4. For now, every call sees the same source of truth.

---

## 5️⃣ The triage function (with retry on bad JSON)

```python
def triage_one(ticket: dict, max_attempts: int = 3) -> Triage:
    last_error = None
    for attempt in range(1, max_attempts + 1):
        resp = client.chat.completions.create(
            model=MODEL,
            response_format={"type": "json_object"},
            temperature=0.2,
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user",   "content": json.dumps(ticket)},
            ],
        )
        raw = resp.choices[0].message.content
        try:
            return Triage.model_validate_json(raw)
        except ValidationError as e:
            last_error = e
            # ask the model to fix its own output
            ticket = {**ticket, "_previous_error": str(e)[:400],
                      "_previous_output": raw[:800]}
    raise RuntimeError(f"Gave up after {max_attempts} attempts: {last_error}")
```

### What's happening
1. We force `response_format=json_object` (model **must** output valid JSON).
2. Pydantic validates against the schema. If invalid, we **feed the error back** into the prompt and try again. This is called *self-correction* and is a key production trick.

---

## 6️⃣ The self-check pass

After we get a valid `Triage`, we run a second cheap call asking *another* prompt: "Does this make sense?"

```python
CHECK_PROMPT = """You are a senior support manager auditing a triage result.
Return JSON: {"ok": bool, "issues": [str, ...]}.
Flag anything that:
- Contradicts the handbook
- Has wrong urgency (e.g. single 5xx as P1 — that's T-02, P3)
- Reply tone is not empathetic-first
- Reply is not in the customer's language"""

def self_check(ticket: dict, result: Triage) -> dict:
    resp = client.chat.completions.create(
        model=MODEL,
        response_format={"type": "json_object"},
        temperature=0.0,
        messages=[
            {"role": "system", "content": CHECK_PROMPT + "\n\nHandbook:\n" + HANDBOOK},
            {"role": "user", "content": json.dumps({
                "ticket": ticket,
                "triage": result.model_dump(),
            })},
        ],
    )
    return json.loads(resp.choices[0].message.content)
```

If `ok` is false, we either downgrade `confidence` or send to human review.

---

## 7️⃣ The main loop

```python
if __name__ == "__main__":
    out = pathlib.Path("output.jsonl").open("w", encoding="utf-8")
    for line in pathlib.Path("tickets.jsonl").read_text(encoding="utf-8").splitlines():
        if not line.strip(): continue
        ticket = json.loads(line)
        t0 = time.perf_counter()
        result = triage_one(ticket)
        audit  = self_check(ticket, result)
        if not audit["ok"]:
            result.confidence = min(result.confidence, 0.5)
        record = {
            **result.model_dump(),
            "audit": audit,
            "latency_ms": round((time.perf_counter() - t0) * 1000),
        }
        out.write(json.dumps(record) + "\n")
        print(f"{ticket['id']} → {result.category}/{result.urgency} "
              f"(conf={result.confidence:.2f}, ok={audit['ok']})")
    out.close()
```

---

## ✅ Expected output (your numbers may vary slightly)

```
TKT-1001 → billing/P2          (conf=0.92, ok=True)   refs ['B-01']
TKT-1002 → technical/P1        (conf=0.88, ok=True)   refs ['T-01']
TKT-1003 → account/P2          (conf=0.85, ok=True)   refs ['A-01'] — reply in Spanish
TKT-1004 → feature_request/P3  (conf=0.90, ok=True)   refs ['F-01','F-02']
TKT-1005 → technical/P3        (conf=0.82, ok=True)   refs ['T-02']  ← NOT P1!
```

Notice TKT-1005: a single 5xx is **NOT** P1 per rule T-02. If your model classifies it as P1, the self-check catches it and lowers confidence. That's the whole point of the audit pass.

---

## 🏋️ Exercises (graduated)

### Exercise 1 — Cost dashboard
Add a counter that tracks `prompt_tokens`, `completion_tokens`, and total `$cost` across the 5 tickets. Print a summary at the end. Use GPT-4o-mini pricing: $0.15 / 1M in, $0.60 / 1M out.

### Exercise 2 — Language coverage test
Add a 6th ticket in French and a 7th in German. Verify the `draft_reply` is in the correct language. (Use a 1-line check: ask another LLM call "what language is this?" and assert it matches `ticket["language"]`.)

### Exercise 3 — Add a `customer_tier`
Extend the ticket schema with `tier` in `["free", "pro", "enterprise"]`. Add a rule to the handbook: enterprise tickets are **always at least P2**. Verify the triage respects this.

### Exercise 4 — Build a human-review queue
Tickets with `confidence < 0.7` OR `audit.ok == False` go to a `review.jsonl` file. Everything else goes to `auto.jsonl`. Print the split.

### Exercise 5 — Stress test
Generate 50 synthetic tickets with a tiny script (mix the 5 examples randomly with paraphrases via the LLM). Run the pipeline. Report:
- accuracy of the category (compared to your ground truth)
- average latency
- % that needed human review

---

## ✅ Solutions (key points)

### Solution 1 — Cost dashboard
```python
totals = {"in": 0, "out": 0}

def _add_usage(resp):
    u = resp.usage
    totals["in"]  += u.prompt_tokens
    totals["out"] += u.completion_tokens

# call _add_usage(resp) inside triage_one and self_check
# at end:
cost = totals["in"]*0.15/1e6 + totals["out"]*0.60/1e6
print(f"Tokens in={totals['in']}, out={totals['out']}, $={cost:.4f}")
```

### Solution 2 — Language coverage test
```python
def detect_lang(text: str) -> str:
    resp = client.chat.completions.create(
        model=MODEL, temperature=0,
        messages=[{"role":"system","content":"Reply with only the ISO-639-1 code."},
                  {"role":"user","content":text[:400]}])
    return resp.choices[0].message.content.strip().lower()

assert detect_lang(result.draft_reply) == ticket["language"], "Wrong language!"
```

### Solution 3 — `customer_tier`
Append to the handbook:
```markdown
## Tiers
- TI-01 Enterprise tickets are minimum P2.
- TI-02 Free-tier feature requests do not get a timeline promise.
```
Add `tier: Literal["free","pro","enterprise"]` to the Pydantic schema; the audit prompt enforces TI-01.

### Solution 4 — Review queue
```python
review = pathlib.Path("review.jsonl").open("w", encoding="utf-8")
auto   = pathlib.Path("auto.jsonl").open("w", encoding="utf-8")
for record in records:
    target = review if record["confidence"] < 0.7 or not record["audit"]["ok"] else auto
    target.write(json.dumps(record) + "\n")
```

### Solution 5 — Stress test
```python
def gen_ticket(seed: dict) -> dict:
    resp = client.chat.completions.create(model=MODEL, temperature=0.8,
        messages=[{"role":"system","content":"Paraphrase this support ticket. Keep the same intent. Output JSON with subject,body."},
                  {"role":"user","content":json.dumps(seed)}])
    body = json.loads(resp.choices[0].message.content)
    return {**seed, **body, "id": f"SYN-{int(time.time()*1000)%100000}"}

# Build ground truth by tagging your 5 seeds with the expected category, generate 10 paraphrases each.
# Compare predicted category to seed.category. Print accuracy.
```

---

## 🎯 What you should now be able to do

- [x] Design a Pydantic schema first, then write the prompt
- [x] Force valid JSON with `response_format=json_object`
- [x] Self-correct on validation errors
- [x] Run an audit pass to catch hallucinations
- [x] Build a confidence-based human-in-the-loop queue
- [x] Measure tokens, cost, latency, and accuracy

---

## 🌐 Where this leads in real life

- **Zendesk / Freshdesk** plugins do exactly this — see Zendesk's "AI Triage".
- **Banks** use the same pattern for AML alert triage (regulated, audit pass mandatory).
- **Healthcare** uses it for nurse-line triage (HIPAA + cite-the-protocol).

➡️ Continue to **[Module 2 — Python for GenAI](../Chapter04_Python_for_GenAI/01_Intro_to_Python.md)**.
