# Module 3 · Lesson 3 — Managing LLM Input / Output with LangChain

## 🍭 Imagine this…

You run a tiny mailroom:
- **In tray** = the *inputs* (user questions, files, history).
- **Out tray** = the *outputs* (clean answers, JSON, validated data).

If either tray is messy, the whole business breaks. This lesson is about **keeping both trays neat** using LangChain.

---

## 🧠 The real concept

### Input plumbing

| Tool | What it solves |
|---|---|
| `ChatPromptTemplate` | Reusable prompt with slots |
| `MessagesPlaceholder` | Inject prior chat history |
| `ChatMessageHistory` | Store conversation memory |
| `PromptTemplate.from_messages([...])` | Mix system / user / assistant turns |
| `format_prompt`, `partial_variables` | Pre-fill some slots |

### Output plumbing

| Parser | Output type |
|---|---|
| `StrOutputParser` | Plain string |
| `JsonOutputParser` | Python dict |
| `PydanticOutputParser` | Validated dataclass |
| `CommaSeparatedListOutputParser` | `list[str]` |
| `EnumOutputParser` | One of N labels |
| `OutputFixingParser` | Auto-retries when the LLM breaks the schema |

---

## 🌍 Real-world scenario — A multi-turn travel agent

You want a chat assistant that:
1. Remembers prior messages.
2. Returns answers in a strict shape: `{itinerary: [...], total_cost: float, currency: str}`.
3. Self-heals when GPT slightly breaks the JSON.

Without LangChain you'd hand-roll memory, manual parsers, and try/except retries. With it, ~30 lines.

---

## 💻 Inputs — Chat history with `MessagesPlaceholder`

```python
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.chat_history import InMemoryChatMessageHistory
from langchain_core.runnables.history import RunnableWithMessageHistory
from dotenv import load_dotenv

load_dotenv()
llm = ChatOpenAI(model="gpt-4o-mini", temperature=0.3)

prompt = ChatPromptTemplate.from_messages([
    ("system", "You are a friendly travel agent."),
    MessagesPlaceholder("history"),       # ← past messages dropped in here
    ("human",  "{question}"),
])
chain = prompt | llm

# 1️⃣ Store one history per user
stores: dict[str, InMemoryChatMessageHistory] = {}
def get_history(session_id: str):
    if session_id not in stores:
        stores[session_id] = InMemoryChatMessageHistory()
    return stores[session_id]

# 2️⃣ Wrap the chain to auto-load/append history
chat = RunnableWithMessageHistory(
    chain,
    get_history,
    input_messages_key="question",
    history_messages_key="history",
)

session = {"configurable": {"session_id": "raji-1"}}

print(chat.invoke({"question": "I want to go to Japan in October."}, session).content)
print(chat.invoke({"question": "What's the best city for foodies?"}, session).content)
print(chat.invoke({"question": "And how about a 5-day plan?"},        session).content)
```

### Toddler-level explanation
- `MessagesPlaceholder("history")` is the **empty space** in your prompt where past chats slot in.
- `InMemoryChatMessageHistory` is a list that **remembers** them.
- `RunnableWithMessageHistory` is a **butler** that automatically reads the list before each call and adds the new turn afterward.

---

## 💻 Outputs — Pydantic schema with auto-fix

```python
from typing import Literal
from pydantic import BaseModel, Field
from langchain_core.output_parsers import PydanticOutputParser
from langchain.output_parsers.fix import OutputFixingParser
from langchain_core.prompts import ChatPromptTemplate
from langchain_openai import ChatOpenAI
from dotenv import load_dotenv

load_dotenv()
llm = ChatOpenAI(model="gpt-4o-mini", temperature=0)

# 1️⃣ The strict schema
class DayPlan(BaseModel):
    day:   int
    city:  str
    activities: list[str] = Field(max_length=5)

class Itinerary(BaseModel):
    itinerary:  list[DayPlan]
    total_cost: float
    currency:   Literal["INR", "USD", "EUR", "JPY"]

# 2️⃣ The parser
parser = PydanticOutputParser(pydantic_object=Itinerary)

# 3️⃣ The prompt — include the format instructions automatically
prompt = ChatPromptTemplate.from_messages([
    ("system",
     "You are a travel planner. {format_instructions}"),
    ("human",
     "Plan a {days}-day trip to {country} for budget {budget} {currency}."),
]).partial(format_instructions=parser.get_format_instructions())

# 4️⃣ A self-healing parser — if model returns broken JSON, retry once
fixing = OutputFixingParser.from_llm(parser=parser, llm=llm)

chain = prompt | llm | fixing

result: Itinerary = chain.invoke({
    "days":     "3",
    "country":  "Japan",
    "budget":   "100000",
    "currency": "INR",
})

for day in result.itinerary:
    print(f"Day {day.day} ({day.city}): {', '.join(day.activities)}")
print(f"Total: {result.total_cost} {result.currency}")
```

### Why `OutputFixingParser`?
About **2–5%** of LLM responses contain tiny JSON glitches (extra comma, smart-quote). The fixer **catches the error and asks the LLM to repair its own output** instead of crashing.

---

## 💻 The comma-list parser (super handy for short lists)

```python
from langchain_core.output_parsers import CommaSeparatedListOutputParser

parser = CommaSeparatedListOutputParser()
prompt = ChatPromptTemplate.from_template(
    "List 5 vegetables. {format_instructions}\n\nQuery: {q}"
).partial(format_instructions=parser.get_format_instructions())

chain = prompt | llm | parser
print(chain.invoke({"q": "What's healthy?"}))
# → ['Spinach', 'Broccoli', 'Carrot', 'Tomato', 'Kale']
```

---

## 🧠 The "input/output" production checklist

| Checkpoint | Tool |
|---|---|
| Per-user memory | `RunnableWithMessageHistory` |
| Persistent memory (across server restarts) | swap `InMemoryChatMessageHistory` for Redis/Postgres |
| Strict shape | `PydanticOutputParser` |
| Self-heal | `OutputFixingParser` |
| Streaming JSON | `JsonOutputParser` (yields partial dicts as they arrive) |
| PII redaction | A `RunnableLambda` filter before the LLM |

---

## 🏋️ Exercises

### Exercise 1 — Build a per-user joke bot
Use `RunnableWithMessageHistory` so two users (`alice`, `bob`) get **independent** joke streams.

### Exercise 2 — Strict Pydantic
Define a `MovieReview(title, year, rating_out_of_10, one_line_summary)` schema and have the chain extract these from a paragraph.

### Exercise 3 — OutputFixingParser
Force the model to output deliberately weird JSON by asking it to "use single quotes". Show that the fixer rescues you.

### Exercise 4 — Streaming JSON
Use `JsonOutputParser` on a chain that returns a `{steps: [...]}` shape. While streaming, print each step as it appears.

### Exercise 5 — PII redactor
Add a `RunnableLambda` that masks anything matching an email regex with `<email>` BEFORE the chain hits the LLM.

---

## ✅ Solutions

### Solution 1
```python
joke_prompt = ChatPromptTemplate.from_messages([
    ("system", "You are a stand-up comedian."),
    MessagesPlaceholder("history"),
    ("human", "{request}"),
])
joke_chain = joke_prompt | llm

bot = RunnableWithMessageHistory(joke_chain, get_history,
        input_messages_key="request", history_messages_key="history")

for user in ["alice", "bob"]:
    cfg = {"configurable": {"session_id": user}}
    print(user, ":", bot.invoke({"request": "Tell me a coffee joke."}, cfg).content)
    print(user, ":", bot.invoke({"request": "Now a sequel."},           cfg).content)
```

### Solution 2
```python
from pydantic import BaseModel
class MovieReview(BaseModel):
    title: str
    year: int
    rating_out_of_10: float
    one_line_summary: str

parser = PydanticOutputParser(pydantic_object=MovieReview)
prompt = ChatPromptTemplate.from_messages([
    ("system", "Extract structured movie review data. {format_instructions}"),
    ("human",  "{text}"),
]).partial(format_instructions=parser.get_format_instructions())

text = "Just saw Dune Part Two (2024). 9/10 - epic visuals, slow second act."
print((prompt | llm | parser).invoke({"text": text}))
```

### Solution 3
```python
broken_prompt = ChatPromptTemplate.from_template(
    "Return a JSON object with keys 'name' and 'age'. USE SINGLE QUOTES. About person: {p}"
)
parser = PydanticOutputParser(pydantic_object=type("P", (BaseModel,),
        {"__annotations__": {"name": str, "age": int}}))
fixer = OutputFixingParser.from_llm(parser=parser, llm=llm)
chain = broken_prompt | llm | fixer
print(chain.invoke({"p": "Raji, 30"}))    # still works
```

### Solution 4
```python
from langchain_core.output_parsers import JsonOutputParser
prompt = ChatPromptTemplate.from_template(
    "Return JSON: {{\"steps\": [\"...\", \"...\"]}}.\nTask: {task}"
)
chain = prompt | llm | JsonOutputParser()
for partial in chain.stream({"task": "How to make coffee"}):
    print(partial)            # each yield is a (possibly partial) dict
```

### Solution 5
```python
import re
from langchain_core.runnables import RunnableLambda

EMAIL_RE = re.compile(r"[\w.+-]+@[\w-]+\.[\w.-]+")
def redact(x: dict):
    x["question"] = EMAIL_RE.sub("<email>", x["question"])
    return x

safe_chain = RunnableLambda(redact) | chain
print(safe_chain.invoke({"question": "Send the report to raji@example.com please"}))
```

---

## 🎯 What you should now be able to do

- [x] Use `MessagesPlaceholder` + memory for stateful chats
- [x] Force outputs into Pydantic, JSON, or list shapes
- [x] Self-heal broken outputs with `OutputFixingParser`
- [x] Redact PII before it hits an LLM

➡️ Next: **[Lesson 4 — Prompt Engineering with LangChain & ChatGPT](04_Prompt_Engineering_with_LangChain.md)**
