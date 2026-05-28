# Module 3 · Lesson 1 — Introduction to LangChain

## 🍭 Imagine this…

You want to build a sandwich. You could:
- Bake the bread, grow the lettuce, milk the cow for cheese — **the raw way**.
- OR walk into a sandwich shop where everything is **prepped, labeled, and waiting** — pick, combine, eat.

**LangChain** is the sandwich shop. The OpenAI SDK gave us raw ingredients — LangChain gives us **Prompts**, **Models**, **Parsers**, **Memory**, **Retrievers**, **Agents**, and **Chains** that all snap together.

---

## 🧠 The real concept

**LangChain** is a Python framework that gives you reusable "Lego bricks" for LLM apps:

| Brick | What it does | Real-world example |
|---|---|---|
| `ChatModel` | Wraps any provider | OpenAI, Anthropic, Azure, Ollama |
| `PromptTemplate` | Reusable prompt with `{variables}` | "Hello {name}, classify {text}" |
| `OutputParser` | Turn text into Python objects | JSON, Pydantic, list |
| `Retriever` | Pulls relevant docs from a vector DB | RAG over PDFs |
| `Memory` | Stores conversation history | Chatbots |
| `Tool` | A function the LLM can call | Calculator, search, SQL |
| `Agent` | Loop: think → act → observe | "Plan my trip" |
| **`Runnable`** | The interface every brick implements | Lets you snap them together with `\|` |

The huge insight: **everything is a `Runnable`**, and you connect them with the **pipe operator `|`** — like Unix pipes.

```python
chain = prompt | model | parser
chain.invoke({"name": "Raji"})
```

That's it. That little `|` is **LCEL** (LangChain Expression Language), which is the entire topic of Lesson 2.

---

## 🌍 Real-world scenario — "Translate then summarise"

Build a pipeline: French text → English translation → 1-sentence summary.

Without LangChain you'd write 30 lines of OpenAI calls. With LangChain it's about 10.

---

## 💻 The code — your first LangChain pipeline

```python
# pip install langchain langchain-openai
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
from dotenv import load_dotenv

load_dotenv()

# 1️⃣ The model — same shape regardless of provider
llm = ChatOpenAI(model="gpt-4o-mini", temperature=0)

# 2️⃣ Two prompt templates
translate_prompt = ChatPromptTemplate.from_template(
    "Translate this French text to English. Output only the translation.\n\n{french_text}"
)
summarise_prompt = ChatPromptTemplate.from_template(
    "Summarise this in ONE sentence:\n\n{english_text}"
)

# 3️⃣ Tiny parser — turns ChatMessage into a plain string
parser = StrOutputParser()

# 4️⃣ Build two chains
translate_chain = translate_prompt | llm | parser
summarise_chain = summarise_prompt | llm | parser

# 5️⃣ Compose them — wire output of first to input of second
def run(french_text: str) -> dict:
    english = translate_chain.invoke({"french_text": french_text})
    summary = summarise_chain.invoke({"english_text": english})
    return {"translation": english, "summary": summary}


sample = ("La fusée européenne Ariane 6 a réussi son tout premier "
          "vol commercial après plusieurs reports techniques.")

result = run(sample)
print(result["translation"])
print(result["summary"])
```

### Toddler-level walkthrough
- `ChatOpenAI(model=...)` — pick the brain.
- `ChatPromptTemplate.from_template("…{var}…")` — a recipe with **slots**.
- `prompt | llm | parser` — assemble the sandwich. Read as: *"put the prompt **into** the model, then **into** the parser"*.
- `.invoke({...})` — fill the slots and run the chain.
- `StrOutputParser()` — strips the message wrapper so we get plain text.

---

## 🧠 Why LangChain instead of raw OpenAI?

| You want… | Without LangChain | With LangChain |
|---|---|---|
| Switch from OpenAI to Anthropic | Rewrite client + message shape | Change 1 import line |
| Cache identical calls | Custom dict + hash | `set_llm_cache(...)` 1 line |
| Track every step in a dashboard | Manual logging | LangSmith auto-traces |
| Combine 3 LLM calls + 2 functions | 80 lines of glue | `a | b | c` |
| Build a RAG pipeline | Manual vector DB code | `retriever | prompt | llm` |
| Build an agent | Build the loop yourself | `create_react_agent(...)` |

---

## 💻 Variations & idioms

### Use `.batch()` to run many inputs in parallel

```python
texts = ["bonjour", "comment ça va", "j'aime le chocolat"]
results = translate_chain.batch([{"french_text": t} for t in texts])
print(results)
```

### Stream tokens

```python
for chunk in translate_chain.stream({"french_text": "salut le monde"}):
    print(chunk, end="", flush=True)
```

### Switch providers in 1 line

```python
# from langchain_anthropic import ChatAnthropic
# llm = ChatAnthropic(model="claude-3-5-sonnet-latest")

# from langchain_community.chat_models import ChatOllama   # local & free
# llm = ChatOllama(model="llama3.1:8b")
```

Same chain, different brain. Magical.

---

## 🏋️ Exercises

### Exercise 1 — Email rewriter chain
Build a chain that takes a casual email draft and outputs a formal version. Then run `.batch()` on 5 drafts at once.

### Exercise 2 — Two-step joke critic
Step 1: ask the LLM to write a joke about a topic.
Step 2: feed that joke into a second chain that rates it 1–10 and explains why.

### Exercise 3 — Provider swap
Run the translate→summarise pipeline using **Ollama** (`llama3.1`) instead of OpenAI. Compare quality.

### Exercise 4 — Streaming chain
Build a chain that streams a 300-word story prompt-by-prompt to your terminal.

### Exercise 5 — Reusable prompt library
Create a Python file `prompts.py` with at least 4 reusable `ChatPromptTemplate` objects (summarise, translate, sentiment, JSON-extract). Import them into another file and use them.

---

## ✅ Solutions

### Solution 1
```python
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

llm = ChatOpenAI(model="gpt-4o-mini", temperature=0.2)
prompt = ChatPromptTemplate.from_template(
    "Rewrite this email in a formal, polite tone. Output only the email body.\n\n{draft}"
)
chain = prompt | llm | StrOutputParser()

drafts = [
    "hey boss, can't come tomorrow, kid sick",
    "yo team meeting moved to 3pm, deal with it",
    "u still need that report?",
    "lunch?? same place??",
    "fix the build pls thanks",
]
for d, formal in zip(drafts, chain.batch([{"draft": d} for d in drafts])):
    print(f"\n🐤 {d}\n👔 {formal}")
```

### Solution 2
```python
joke_prompt = ChatPromptTemplate.from_template(
    "Tell ONE short joke about {topic}. Just the joke, no commentary."
)
rate_prompt = ChatPromptTemplate.from_template(
    "Rate this joke from 1-10 and explain in 2 lines.\n\nJoke: {joke}"
)

joke_chain = joke_prompt | llm | StrOutputParser()
rate_chain = rate_prompt | llm | StrOutputParser()

joke = joke_chain.invoke({"topic": "programmers"})
print("Joke :", joke)
print("Rating:", rate_chain.invoke({"joke": joke}))
```

### Solution 3
```python
# After: ollama pull llama3.1:8b
from langchain_community.chat_models import ChatOllama
llm_local = ChatOllama(model="llama3.1:8b", temperature=0)
chain_local = translate_prompt | llm_local | StrOutputParser()
print(chain_local.invoke({"french_text": "Bonjour le monde"}))
```

### Solution 4
```python
story_chain = ChatPromptTemplate.from_template(
    "Write a 300-word fairy-tale about a {hero}."
) | llm | StrOutputParser()

for chunk in story_chain.stream({"hero": "talking pencil"}):
    print(chunk, end="", flush=True)
```

### Solution 5
```python
# prompts.py
from langchain_core.prompts import ChatPromptTemplate

SUMMARISE = ChatPromptTemplate.from_template(
    "Summarise in 2 sentences:\n\n{text}"
)
TRANSLATE = ChatPromptTemplate.from_template(
    "Translate from {source} to {target}. Output only the translation.\n\n{text}"
)
SENTIMENT = ChatPromptTemplate.from_template(
    "Classify sentiment as positive/neutral/negative. Output ONE word.\n\n{text}"
)
EXTRACT_JSON = ChatPromptTemplate.from_template(
    "Extract as JSON with keys {keys}. Return JSON only.\n\n{text}"
)
```

```python
# main.py
from prompts import SUMMARISE, SENTIMENT
chain = SUMMARISE | llm | StrOutputParser()
print(chain.invoke({"text": open("news.txt", encoding="utf-8").read()}))
```

---

## 🎯 What you should now be able to do

- [x] Install LangChain and run a `prompt | llm | parser` chain
- [x] Compose two chains together
- [x] Swap providers with one import change
- [x] Batch and stream inputs

➡️ Next: **[Lesson 2 — LCEL Essentials](02_LCEL_Essentials.md)**
