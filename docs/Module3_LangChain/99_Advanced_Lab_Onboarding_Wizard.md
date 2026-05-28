# Module 3 · Advanced Lab — Multi-Language Onboarding Wizard with LCEL

> **Time:** 90 minutes · **Difficulty:** ⭐⭐⭐ (capstone for Module 3)
>
> You'll compose **5+ LCEL Runnables** into a single declarative chain that intelligently onboards a new employee — pulling from their resume, deciding which checklists apply, translating into their language, and remembering the conversation across turns.

---

## 🌍 The real-world scenario

You work for **AuroraBank** (operations in 12 countries). HR has a problem:

- Every new joiner needs to read 30 pages of policies.
- Different roles (Engineer, Trader, Compliance Officer) need different checklists.
- New joiners speak 8 languages.
- HR wants to *chat* with new joiners, not send PDFs.

You build an **onboarding wizard chatbot** that:

1. Takes the new joiner's **resume PDF** + their preferred **language**.
2. Extracts their role, country, and seniority into a typed struct (Pydantic).
3. Routes them down the right onboarding branch (Eng vs Trader vs Compliance).
4. Generates a personalised 5-day plan in their language.
5. Remembers prior turns so follow-up questions stay in context.
6. Always cites the policy line number when answering.

All in **~80 lines of LangChain LCEL** — no glue code.

---

## 🧠 Why this lab is special

LCEL is at its best when you start treating chains like **Lego blocks**:

| Lego block | What it does |
|---|---|
| `prompt \| llm \| parser` | classic chain |
| `RunnableParallel({a:..., b:...})` | fan-out — run independent steps in parallel |
| `RunnableBranch((cond, A), (cond, B), default)` | router |
| `RunnableLambda(fn)` | drop in any plain Python function |
| `RunnableWithMessageHistory(chain, get_session)` | adds chat memory transparently |
| `.with_fallbacks([slow_chain])` | resilience |

In this lab you wire **all of them** together.

---

## 📂 Files

```
m3_lab/
├── policies.md              ← 5 short numbered policies
├── checklists/
│   ├── engineering.md
│   ├── trading.md
│   └── compliance.md
├── wizard.py                ← the LCEL chain
└── chat.py                  ← simple CLI loop
```

---

## 1️⃣ The policies (with line numbers — for citations)

`policies.md`:

```markdown
P-01 All employees must enable phishing-resistant MFA on day 1.
P-02 Trading-floor staff must complete Market Abuse training in week 1.
P-03 Engineering staff must finish the secure-coding test by day 14.
P-04 Compliance officers must read AML SOP v8 before client contact.
P-05 All new joiners book a meet-and-greet with their manager within 48h.
```

`checklists/engineering.md`:
```markdown
E-1 Pair with senior dev on day 1.
E-2 Install secure dev toolkit (see wiki).
E-3 Complete OWASP top-10 lab by day 7.
E-4 Submit first PR by day 10.
E-5 Demo at sprint review on day 14.
```

`checklists/trading.md`:
```markdown
T-1 Shadow desk for 3 days.
T-2 Complete Market Abuse module (P-02).
T-3 Make first paper trade by day 5.
T-4 Risk training day 7.
T-5 Sign code-of-conduct attestation day 10.
```

`checklists/compliance.md`:
```markdown
C-1 Read AML SOP v8 (P-04).
C-2 Shadow senior compliance officer 5 days.
C-3 Pass internal AML quiz day 8.
C-4 Sign confidentiality agreement.
C-5 Set up SAR-monitoring tool.
```

---

## 2️⃣ The Pydantic schema for resume extraction

```python
# wizard.py
from __future__ import annotations
import pathlib, os, uuid
from typing import Literal
from pydantic import BaseModel, Field
from pypdf import PdfReader
from dotenv import load_dotenv

from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.runnables import RunnableParallel, RunnableBranch, RunnableLambda
from langchain_core.runnables.history import RunnableWithMessageHistory
from langchain_community.chat_message_histories import ChatMessageHistory

load_dotenv()
llm = ChatOpenAI(model="gpt-4o-mini", temperature=0.2)

class Profile(BaseModel):
    full_name: str
    country:   str
    role:      Literal["engineering", "trading", "compliance", "other"]
    seniority: Literal["junior", "mid", "senior"]
    language:  Literal["en", "es", "fr", "de", "it", "pt", "ja", "hi"] = "en"
```

---

## 3️⃣ Step 1 — extract a `Profile` from raw resume text

```python
EXTRACT_PROMPT = ChatPromptTemplate.from_messages([
    ("system",
     "You convert resume text into a strict Profile JSON. "
     "If unclear, choose your best guess. Field 'role' must be one of: "
     "engineering, trading, compliance, other."),
    ("user", "Resume:\n{resume}\nLanguage preference (ISO 639-1): {lang}"),
])

extract_profile = EXTRACT_PROMPT | llm.with_structured_output(Profile)
```

### Toddler-level
- `with_structured_output(Profile)` makes the LLM emit **JSON that matches Pydantic exactly**. If it can't, LangChain re-asks.

---

## 4️⃣ Step 2 — load the right checklist (RunnableBranch)

```python
def _load(role: str) -> str:
    path = pathlib.Path(f"checklists/{role}.md")
    return path.read_text(encoding="utf-8") if path.exists() else ""

load_checklist = RunnableLambda(lambda p: {"checklist": _load(p.role), "profile": p})
```

We could write a branch with `RunnableBranch`, but a 1-line `RunnableLambda` is cleaner here. **Use the simplest tool that works.**

---

## 5️⃣ Step 3 — fan out: build a day-by-day plan AND a welcome video script in parallel

```python
PLAN_PROMPT = ChatPromptTemplate.from_messages([
    ("system",
     "You are AuroraBank's onboarding coach. Build a day-by-day plan (D1..D14) "
     "for this new joiner. Cite the policy/checklist code in [brackets] whenever "
     "a step is required by a policy. Write in language: {lang}."),
    ("user", "Profile: {profile}\nApplicable checklist:\n{checklist}\nPolicies:\n{policies}"),
])
plan_chain = PLAN_PROMPT | llm

VIDEO_PROMPT = ChatPromptTemplate.from_messages([
    ("system", "Write a 60-second welcome video script in {lang} for the new joiner. "
               "Keep it warm, mention their name, role, country."),
    ("user",   "{profile}"),
])
video_chain = VIDEO_PROMPT | llm

# Run both at the same time
fanout = RunnableParallel({"plan": plan_chain, "video": video_chain})
```

LCEL spins both calls **concurrently** — overall latency = max(plan, video), not sum. Free speed-up.

---

## 6️⃣ Step 4 — wire everything: resume → profile → checklist → fan-out

```python
POLICIES = pathlib.Path("policies.md").read_text(encoding="utf-8")

def _augment(p: Profile) -> dict:
    return {
        "profile":   p.model_dump(),
        "checklist": _load(p.role),
        "policies":  POLICIES,
        "lang":      p.language,
    }

augment = RunnableLambda(_augment)

build_plan = extract_profile | augment | fanout
```

A single pipe runs 3 LLM calls (extract → plan → video), and the middle one is plain Python. **No `if` statements, no try/except boilerplate.**

---

## 7️⃣ Step 5 — Q&A with memory

After the plan is generated, the new joiner can chat:

> *"Why do I need to finish OWASP top-10 by day 7?"*
> *"What if I'm sick on day 5?"*

```python
QA_PROMPT = ChatPromptTemplate.from_messages([
    ("system",
     "You are AuroraBank's onboarding assistant. Always cite policy "
     "codes [P-01, E-3, ...] when answering. Respond in {lang}.\n"
     "Profile: {profile}\nPolicies:\n{policies}\nChecklist:\n{checklist}"),
    MessagesPlaceholder("history"),
    ("user", "{question}"),
])

qa_chain = QA_PROMPT | llm

# session-scoped memory
_store: dict[str, ChatMessageHistory] = {}
def _history(session_id: str) -> ChatMessageHistory:
    return _store.setdefault(session_id, ChatMessageHistory())

qa_with_memory = RunnableWithMessageHistory(
    qa_chain,
    _history,
    input_messages_key="question",
    history_messages_key="history",
)
```

### Toddler-level
- We give the chain a **brain box** (the dict). Each user gets their own box keyed by `session_id`.
- LangChain auto-appends `user` + `ai` messages every turn.

---

## 8️⃣ The CLI runner

`chat.py`:

```python
import pathlib, uuid
from pypdf import PdfReader
from wizard import build_plan, qa_with_memory, _augment, extract_profile

def main():
    resume = "\n".join(p.extract_text() or ""
                       for p in PdfReader("samples/jane.pdf").pages)
    lang = "en"

    result = build_plan.invoke({"resume": resume, "lang": lang})
    print("\n=== PLAN ===\n", result["plan"].content)
    print("\n=== VIDEO SCRIPT ===\n", result["video"].content)

    # Now chat
    profile = extract_profile.invoke({"resume": resume, "lang": lang})
    ctx = _augment(profile)
    session_id = str(uuid.uuid4())
    cfg = {"configurable": {"session_id": session_id}}
    print("\n(type 'quit' to exit)\n")
    while True:
        q = input("you> ").strip()
        if q.lower() in {"quit", "exit"}: break
        out = qa_with_memory.invoke({**ctx, "question": q}, config=cfg)
        print("ai>", out.content, "\n")

if __name__ == "__main__":
    main()
```

---

## ✅ Sample run

```
=== PLAN ===
Day 1: Welcome session, enable MFA [P-01]. Pair with senior dev [E-1].
Day 2: Install secure toolkit [E-2]. Manager 1:1 [P-05].
...
Day 14: Demo at sprint review [E-5].

=== VIDEO SCRIPT ===
Hi Jane! Welcome to AuroraBank Madrid...

you> Why do I need MFA on day 1?
ai>  Policy [P-01] requires phishing-resistant MFA on day 1 for all employees...
you> ¿Y si estoy enfermo el día 5?
ai>  No te preocupes Jane. Si estás enferma, [E-3]...
```

---

## 🏋️ Exercises

### Exercise 1 — Add a 4th branch: "marketing"
Add `checklists/marketing.md` and extend the `role` Literal. Confirm the `RunnableLambda` picks the right file.

### Exercise 2 — Few-shot the resume extractor
Provide 2 example resume/Profile pairs to the system prompt to improve accuracy on edge cases (e.g., a resume that says "Quant Strategy Analyst" should be classified as `trading`).

### Exercise 3 — Add a fallback chain
Wrap `build_plan` with `.with_fallbacks([build_plan_simple])` where the simple version uses a cheaper model and a shorter plan. Force-fail the main chain (e.g., set `model="bad-model"`) to verify.

### Exercise 4 — Translate outputs on-demand
Add a small chain `translate = ChatPromptTemplate.from_template("Translate to {target}: {text}") | llm`. Add a CLI command `/translate fr` that re-renders the plan in another language.

### Exercise 5 — Token budget guard
Before calling `qa_with_memory`, count tokens in `history` (use `tiktoken`). If > 2000 tokens, summarise history with one cheap call and replace it.

### Exercise 6 — Streaming + cancellation
Replace `.invoke` with `.stream` so output prints word-by-word. Add Ctrl-C handling that cancels the current call but keeps the session.

---

## ✅ Solutions

### Solution 1 — Marketing branch
```python
class Profile(BaseModel):
    ...
    role: Literal["engineering","trading","compliance","marketing","other"]
# add checklists/marketing.md, the loader picks it up automatically.
```

### Solution 2 — Few-shot extractor
```python
EXAMPLES = [
    {"resume": "Quant Strategy Analyst, JPMorgan...",
     "profile": Profile(full_name="X", country="UK",
                        role="trading", seniority="mid").model_dump_json()},
    {"resume": "Senior Site Reliability Engineer at Google...",
     "profile": Profile(full_name="Y", country="US",
                        role="engineering", seniority="senior").model_dump_json()},
]
example_block = "\n\n".join(
    f"Resume:\n{e['resume']}\nProfile: {e['profile']}" for e in EXAMPLES
)
EXTRACT_PROMPT = ChatPromptTemplate.from_messages([
    ("system", f"You convert resumes into Profile JSON.\nExamples:\n{example_block}"),
    ("user", "Resume:\n{resume}"),
])
```

### Solution 3 — Fallback
```python
simple_plan = ChatPromptTemplate.from_template(
    "Give a 5-bullet onboarding plan for {profile}."
) | ChatOpenAI(model="gpt-4o-mini", temperature=0)
build_plan = (extract_profile | augment | fanout).with_fallbacks([
    extract_profile | RunnableLambda(lambda p: {"profile": p.model_dump()}) | simple_plan
])
```

### Solution 4 — Translate
```python
translate_chain = ChatPromptTemplate.from_template(
    "Translate to {target}: {text}") | llm
# CLI handler:
if q.startswith("/translate "):
    target = q.split()[1]
    txt = translate_chain.invoke({"target": target, "text": result["plan"].content})
    print(txt.content)
```

### Solution 5 — Token budget
```python
import tiktoken
enc = tiktoken.encoding_for_model("gpt-4o-mini")

def maybe_compact(session_id):
    hist = _store.get(session_id)
    if not hist: return
    total = sum(len(enc.encode(m.content)) for m in hist.messages)
    if total > 2000:
        summary = llm.invoke(
            f"Summarise this conversation in <300 tokens: {hist.messages}").content
        hist.clear()
        hist.add_user_message(f"[Earlier conversation summary]: {summary}")
```

### Solution 6 — Streaming
```python
try:
    for chunk in qa_with_memory.stream({**ctx, "question": q}, config=cfg):
        print(chunk.content, end="", flush=True)
    print()
except KeyboardInterrupt:
    print("\n[cancelled]")
```

---

## 🎯 What you should now be able to do

- [x] Compose 5+ Runnables with `|`, `RunnableParallel`, `RunnableLambda`, `with_fallbacks`
- [x] Use `with_structured_output(Pydantic)` for strict extraction
- [x] Run independent chain branches in parallel for free latency wins
- [x] Add per-session memory via `RunnableWithMessageHistory`
- [x] Few-shot prompt edge cases
- [x] Stream + cancel + token-budget guard a production chat chain

---

## 🌐 Where this leads in real life

- **HR onboarding bots** (HiBob, Lattice).
- **Bank KYC interviews** — same flow, different prompts.
- **Healthcare patient intake** — schema-first + branches by symptom area.

➡️ Continue to **[Module 4 — RAG & Frameworks](../Module4_RAG_and_Frameworks/01_RAG_System_Essentials.md)**.
