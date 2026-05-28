# Phase 4 — GenAI Fundamentals

**Goal:** Understand and use Large Language Models, prompts, embeddings, and Retrieval-Augmented Generation (RAG).

## 📦 Install
```powershell
pip install openai tiktoken python-dotenv chromadb
```

## 🔑 Setup an API Key

Choose ONE of these:

### Option A — OpenAI (easiest to start)
1. Get a key: https://platform.openai.com/api-keys
2. Add to `.env`:
   ```
   OPENAI_API_KEY=sk-...
   ```

### Option B — Azure OpenAI (recommended for enterprise)
Add to `.env`:
```
AZURE_OPENAI_ENDPOINT=https://YOUR-RESOURCE.openai.azure.com/
AZURE_OPENAI_API_KEY=...
AZURE_OPENAI_DEPLOYMENT=gpt-4o-mini
AZURE_OPENAI_API_VERSION=2024-10-21
```

### Option C — No API (use mock/local)
Every lesson has a **MOCK_MODE** that runs without an API. Set:
```
MOCK_MODE=1
```

## 📚 Lessons

| # | Lesson | File |
|---|--------|------|
| 1 | What is an LLM? | `01_what_is_llm.md` |
| 2 | First LLM call (chat completion) | `02_first_llm_call.py` |
| 3 | Prompt engineering patterns | `03_prompt_engineering.py` |
| 4 | Structured outputs (JSON mode) | `04_structured_outputs.py` |
| 5 | Streaming responses | `05_streaming.py` |
| 6 | Embeddings | `06_embeddings.py` |
| 7 | Building a RAG system | `07_rag_system.py` |

## 🏆 Mini-project
**`mini_project_doc_qa.py`** — A "chat with your docs" app over your existing workspace files.

