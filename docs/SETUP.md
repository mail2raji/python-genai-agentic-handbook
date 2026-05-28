# 🛠️ Setup — Get Ready in 10 Minutes

> Goal: by the end of this page you will have run your first LLM call from Python.

---

## Step 1 — Install Python 3.10+

### Windows
1. Go to <https://www.python.org/downloads/> and click **Download Python 3.12.x**.
2. Run the installer. **CHECK the box "Add Python to PATH"** before clicking Install.
3. Open PowerShell and verify:
   ```powershell
   python --version
   ```
   You should see `Python 3.12.x` (or 3.10+).

### macOS / Linux
Python usually exists. Just check:
```bash
python3 --version
```

---

## Step 2 — Create a project folder & virtual environment

```powershell
# Pick a folder you like
cd C:\learn
mkdir genai-learning
cd genai-learning

# Create an isolated Python "sandbox" so your packages don't fight each other
python -m venv .venv

# Activate the sandbox
.\.venv\Scripts\Activate.ps1     # Windows PowerShell
# source .venv/bin/activate      # macOS / Linux
```

Your prompt now shows `(.venv)` at the front. Good. ✅

---

## Step 3 — Install the packages

Copy the `requirements.txt` from this curriculum folder into your project, then:

```powershell
pip install -r requirements.txt
```

This takes 2–5 minutes.

---

## Step 4 — Get an LLM API key

You have **three options**. Pick ONE:

### Option A — OpenAI (easiest, paid)
1. Go to <https://platform.openai.com/api-keys>.
2. Add $5 credit, create a new key.
3. Save it.

### Option B — Azure OpenAI (corporate)
1. In Azure Portal, deploy a model (e.g., `gpt-4o-mini`).
2. Note the **endpoint**, **API key**, and **deployment name**.

### Option C — Ollama (100% free, runs on your laptop)
1. Install Ollama: <https://ollama.com/download>.
2. Pull a model: `ollama pull llama3.1:8b`.
3. No key needed — runs locally on port 11434.

---

## Step 5 — Store the key safely (never in code!)

Create a file called `.env` in your project folder:

```env
# .env
OPENAI_API_KEY=sk-proj-xxxxxxxxxxxxxxxxx

# OR for Azure OpenAI:
AZURE_OPENAI_API_KEY=your-key
AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com/
AZURE_OPENAI_DEPLOYMENT=gpt-4o-mini
AZURE_OPENAI_API_VERSION=2024-08-01-preview
```

> 🔒 **Add `.env` to `.gitignore`** so you never push your key to GitHub.

---

## Step 6 — Your first LLM call (proof of life)

Create `hello_llm.py`:

```python
# hello_llm.py — your very first AI program
from openai import OpenAI            # the official OpenAI client library
from dotenv import load_dotenv       # reads .env file into environment variables

load_dotenv()                        # load OPENAI_API_KEY from .env into memory

client = OpenAI()                    # auto-picks up OPENAI_API_KEY from env

response = client.chat.completions.create(
    model="gpt-4o-mini",             # cheap + smart enough for learning
    messages=[
        {"role": "system", "content": "You are a friendly tutor."},
        {"role": "user",   "content": "Explain photosynthesis in 2 lines."},
    ],
)

print(response.choices[0].message.content)
```

Run it:
```powershell
python hello_llm.py
```

You should see a 2-line explanation of photosynthesis. **You just used GPT-4o-mini.** 🎉

---

## 🆘 Troubleshooting

| Error | Fix |
|---|---|
| `ModuleNotFoundError: openai` | Forgot to activate `.venv` or didn't `pip install`. |
| `AuthenticationError` | Your key is wrong or has no credit. |
| `RateLimitError` | Wait 30s and retry, or add billing. |
| `python: command not found` | On Windows try `py` instead of `python`. |

---

✅ Ready? Open **[Module 1 → Lesson 1](Module1_GenAI_Foundations/01_Introduction_to_GenAI.md)** and let's start learning!
