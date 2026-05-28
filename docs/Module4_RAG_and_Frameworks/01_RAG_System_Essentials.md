# Module 4 · Lesson 1 — RAG System Essentials

## 🍭 Imagine this…

You're taking an open-book exam. You don't memorize the whole textbook — but the moment you see a question you **flip to the right page** and answer using it.

**RAG (Retrieval-Augmented Generation)** is exactly that: the LLM gets a question, *retrieves* the right "page" from your documents, and *generates* an answer grounded in it.

---

## 🧠 The real concept

### The RAG pipeline — 5 stages

```
1. LOAD       → read PDFs / web pages / CSVs / Confluence
2. SPLIT      → chop into ~500-token chunks (overlap a little)
3. EMBED      → convert each chunk into a vector
4. STORE      → save vectors + chunk text into a vector DB
5. RETRIEVE   → at query time, embed the question, find top-K
6. GENERATE   → stuff top-K chunks into the prompt, let LLM answer
```

### Why each step matters

| Stage | Why | Common mistake |
|---|---|---|
| Load  | Get clean text | Forget PDF tables → garbage |
| Split | LLMs have a context limit; small chunks search better | Splits too big = noisy retrieval; too small = lose context |
| Embed | Search by meaning, not keywords | Wrong model → poor recall |
| Store | Fast nearest-neighbour search | Forgetting to persist between runs |
| Retrieve | Top-K most relevant chunks | Too few = miss info; too many = drown the LLM |
| Generate | Force the model to **cite** or say "I don't know" | Letting it hallucinate |

### Vector DB shortlist

| Tool | When to pick |
|---|---|
| **ChromaDB** | Local dev, simple file-based |
| **FAISS** | In-memory, ultra-fast, no server |
| **Pinecone / Weaviate / Qdrant** | Production, managed |
| **Azure AI Search** | Enterprise/Azure stack |
| **Postgres + pgvector** | You already have Postgres |

---

## 🌍 Real-world scenario — "Ask my company handbook"

A 200-page employee handbook PDF. New hires constantly ask:
- "What's the WFH policy?"
- "How many sick days do I get?"
- "Who approves expenses over ₹50k?"

We'll build a chatbot that answers these grounded in the handbook, with **citations**.

---

## 💻 The code — a complete RAG pipeline (end to end)

```python
# rag_handbook.py
from pathlib import Path
from dotenv import load_dotenv

from langchain_community.document_loaders import PyPDFLoader, DirectoryLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_openai import OpenAIEmbeddings, ChatOpenAI
from langchain_chroma import Chroma
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
from langchain_core.runnables import RunnablePassthrough

load_dotenv()

# ──────────────────────────────────────────────────────────
# 1️⃣ LOAD documents
# ──────────────────────────────────────────────────────────
loader = DirectoryLoader(
    "docs",                      # folder with PDFs / .md / .txt
    glob="**/*.pdf",
    loader_cls=PyPDFLoader,
    show_progress=True,
)
docs = loader.load()
print(f"Loaded {len(docs)} pages")

# ──────────────────────────────────────────────────────────
# 2️⃣ SPLIT — 500 tokens with 80 overlap
# ──────────────────────────────────────────────────────────
splitter = RecursiveCharacterTextSplitter(
    chunk_size=500,
    chunk_overlap=80,
    separators=["\n\n", "\n", ". ", " "],
)
chunks = splitter.split_documents(docs)
print(f"Made {len(chunks)} chunks")

# ──────────────────────────────────────────────────────────
# 3️⃣ EMBED + 4️⃣ STORE in Chroma (persists to disk)
# ──────────────────────────────────────────────────────────
embeddings = OpenAIEmbeddings(model="text-embedding-3-small")

vectordb = Chroma.from_documents(
    chunks,
    embedding=embeddings,
    persist_directory=".chroma",
    collection_name="handbook",
)

# ──────────────────────────────────────────────────────────
# 5️⃣ RETRIEVER
# ──────────────────────────────────────────────────────────
retriever = vectordb.as_retriever(search_kwargs={"k": 4})

# ──────────────────────────────────────────────────────────
# 6️⃣ GENERATE — grounded prompt
# ──────────────────────────────────────────────────────────
RAG_PROMPT = ChatPromptTemplate.from_template("""
You are an HR assistant. Answer using ONLY the context below.
If the answer is not in the context, say "I don't know based on the handbook."

For every fact you use, cite the source page in brackets like [page 12].

Context:
{context}

Question: {question}

Answer:""")

llm = ChatOpenAI(model="gpt-4o-mini", temperature=0)

def format_context(docs):
    """Glue retrieved chunks with their page numbers for citations."""
    return "\n\n".join(
        f"[page {d.metadata.get('page', '?')}] {d.page_content}"
        for d in docs
    )

# ──────────────────────────────────────────────────────────
# The full chain in LCEL
# ──────────────────────────────────────────────────────────
rag_chain = (
    {
        "context":  retriever | format_context,
        "question": RunnablePassthrough(),
    }
    | RAG_PROMPT
    | llm
    | StrOutputParser()
)

# ──────────────────────────────────────────────────────────
# Try it
# ──────────────────────────────────────────────────────────
for q in [
    "What's the work-from-home policy?",
    "How many sick leave days do I get per year?",
    "Who is the CEO of OpenAI?",       # not in handbook → should say IDK
]:
    print(f"\nQ: {q}\nA: {rag_chain.invoke(q)}")
```

### Toddler-level walkthrough
1. **Loader** opens every PDF in the `docs` folder.
2. **Splitter** chops them into bite-sized chunks (500 chars with a small overlap so sentences don't get cut).
3. **Embeddings** turn each chunk into a list of 1,536 numbers (a "vector").
4. **Chroma** stores those vectors on disk so next run we don't re-pay for embeddings.
5. **Retriever** at query time: embed the question, find the **4 closest** chunks.
6. **Prompt** stuffs the question + chunks into a strict template.
7. **LLM** writes the answer **with [page X] citations** — and politely refuses if the answer isn't in the chunks.

---

## 🧠 Chunking — the most underrated step

Bad chunking = bad RAG. **Tune three knobs**:

| Knob | Typical | Effect |
|---|---|---|
| chunk_size | 300–800 tokens | Too big = noisy retrieval. Too small = missing context. |
| chunk_overlap | ~10–20% of chunk_size | Prevents cutting a sentence in half. |
| separators | `["\n\n", "\n", ". ", " "]` | Try to break on paragraph → sentence → word. |

For Markdown / code, use `MarkdownHeaderTextSplitter` / `Language.PYTHON` splitter.

---

## 🧠 Evaluation — how do you know it works?

Build a tiny "golden set" — 20 questions whose correct answers you know.

```python
golden = [
    {"q": "How many sick leave days?", "must_contain": "12"},
    {"q": "What is WFH policy?",       "must_contain": "hybrid"},
    # ...
]

hits = 0
for g in golden:
    ans = rag_chain.invoke(g["q"]).lower()
    if g["must_contain"].lower() in ans:
        hits += 1
print(f"Accuracy: {hits/len(golden):.0%}")
```

In real production, use **Ragas** or **DeepEval** for fancier metrics: *context_precision*, *faithfulness*, *answer_relevance*.

---

## 🧠 Common RAG failures & fixes

| Symptom | Likely cause | Fix |
|---|---|---|
| "I don't know" too often | Bad chunking or wrong embed model | Try larger chunks, semantic chunking |
| Hallucinations creep in | LLM ignoring "context only" rule | Stricter prompt; lower temperature; include `cite_required: true` |
| Wrong chunk retrieved | Vector similarity ≠ semantic similarity (rare words) | Add **hybrid search** (vector + BM25); add a re-ranker |
| Slow | Large vector DB or too many embed calls | Persist DB; batch embeddings |

### Add a re-ranker in 5 lines (cohere or local)

```python
from langchain.retrievers import ContextualCompressionRetriever
from langchain_community.cross_encoders import HuggingFaceCrossEncoder
from langchain.retrievers.document_compressors import CrossEncoderReranker

model = HuggingFaceCrossEncoder(model_name="BAAI/bge-reranker-base")
reranker = CrossEncoderReranker(model=model, top_n=3)
compressed = ContextualCompressionRetriever(
    base_retriever=retriever, base_compressor=reranker
)
```

Re-rankers regularly add **+10-20% accuracy** for ~50 ms latency.

---

## 🏋️ Exercises

### Exercise 1 — Build RAG over your own docs
Drop 1–3 PDFs (resume, policy doc, book sample) into `docs/`. Re-run the script. Ask 5 questions.

### Exercise 2 — Citations check
Make the prompt **require** citations and then add a Python step that fails if the answer has no `[page N]` in it.

### Exercise 3 — Hybrid search
Add BM25 alongside vector retrieval using `EnsembleRetriever`. Compare answers.

### Exercise 4 — Eval harness
Write a `evaluate(golden_set)` function that returns precision, plus prints questions where the answer is wrong.

### Exercise 5 — Source filter
Imagine you have HR docs AND finance docs in the same DB. Add a filter so HR questions only retrieve HR chunks (use metadata + `filter=` in `as_retriever`).

---

## ✅ Solutions

### Solution 1
Walkthrough: put PDFs in `docs/`, run the script. The persist directory `.chroma` will be re-used on subsequent runs (skip the embed cost).

### Solution 2
```python
import re
def must_have_citation(answer: str) -> str:
    if not re.search(r"\[page \d+\]", answer):
        raise ValueError("Answer has no citation! Refusing.")
    return answer

guarded_chain = rag_chain | must_have_citation
```

### Solution 3
```python
from langchain.retrievers import EnsembleRetriever
from langchain_community.retrievers import BM25Retriever

bm25 = BM25Retriever.from_documents(chunks)
bm25.k = 4
ensemble = EnsembleRetriever(retrievers=[retriever, bm25], weights=[0.6, 0.4])
# Replace retriever with `ensemble` in the chain dict.
```

### Solution 4
```python
def evaluate(golden):
    wrong = []
    for g in golden:
        a = rag_chain.invoke(g["q"]).lower()
        if g["must_contain"].lower() not in a:
            wrong.append((g["q"], a))
    print(f"Precision: {1 - len(wrong)/len(golden):.0%}")
    for q, a in wrong:
        print(f"\n❌ {q}\n   {a[:120]}…")
```

### Solution 5
```python
# When you ADD documents, tag them with metadata:
# Chroma.from_documents([Document(page_content=..., metadata={"source": "hr"}), ...])
hr_retriever = vectordb.as_retriever(
    search_kwargs={"k": 4, "filter": {"source": "hr"}},
)
```

---

## 🎯 What you should now be able to do

- [x] Build a RAG pipeline from PDFs in ~50 lines
- [x] Force citations and "I don't know" behaviour
- [x] Improve recall with hybrid search + re-rankers
- [x] Measure RAG quality with a golden set

➡️ Next: **[Lesson 2 — LangChain vs LangGraph vs CrewAI](02_LangChain_LangGraph_CrewAI.md)**
