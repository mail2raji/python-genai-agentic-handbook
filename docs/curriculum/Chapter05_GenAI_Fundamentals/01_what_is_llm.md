# Lesson 1: What is an LLM?

## 🧠 The 60-second version

A **Large Language Model (LLM)** is a neural network trained on huge amounts of text. It learns to predict the next "token" (word fragment). By predicting one token at a time, it can:
- Answer questions
- Write code
- Summarize documents
- Translate
- Follow instructions

Examples: **GPT-4o** (OpenAI), **Claude** (Anthropic), **Gemini** (Google), **Llama** (Meta), **Phi** (Microsoft).

---

## 🎯 Core concepts you MUST know

| Concept | Meaning | Why it matters |
|---|---|---|
| **Token** | A word fragment (3–4 chars). | Billed per token. Context limits are in tokens. |
| **Context window** | Max tokens the model can "see" at once. | GPT-4o = 128K tokens (~300 pages). |
| **Prompt** | Your text input to the model. | The art of prompt engineering. |
| **Completion** | The model's text output. | What you pay for. |
| **Temperature** | Randomness 0–2. | 0 = deterministic, 1 = creative. |
| **System prompt** | Instructions setting the model's behavior. | "You are a helpful IT support agent." |
| **Embeddings** | Vector representation of text (e.g., 1536 numbers). | Used for search & RAG. |
| **Fine-tuning** | Re-training on your own data. | For specialized tasks. |
| **RAG** | Retrieval-Augmented Generation. | Inject relevant docs into prompt. |

---

## 💬 The Chat Completion Format

All modern LLMs use a list of **messages**:

```python
messages = [
    {"role": "system", "content": "You are a helpful IT assistant."},
    {"role": "user",   "content": "My laptop won't connect to VPN."},
    {"role": "assistant", "content": "Have you tried restarting the VPN client?"},
    {"role": "user",   "content": "Yes, didn't help."},
]
```

The model sees the WHOLE history and produces the next assistant message.

---

## 🚦 Capabilities vs Limitations

✅ **Great at**
- Pattern matching, summarization, translation
- Writing code from spec
- Following structured instructions

❌ **Bad at (alone)**
- Real-time facts (training data has a cutoff)
- Math beyond simple arithmetic
- Long-term memory
- Knowing your private data → **this is why we need RAG and Agents**

---

## 🏗️ The journey ahead

```
Phase 4:  LLM call → prompts → embeddings → RAG
Phase 5:  Add tools → make decisions → multi-agent
Phase 6:  Real projects
```

Continue to **`02_first_llm_call.py`**.

