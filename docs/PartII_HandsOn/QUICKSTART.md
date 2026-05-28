# 🚀 Quick Start — Day 1 in 10 minutes

Follow these steps once, then you can run any lesson.

## Step 1 — Open a PowerShell terminal in this folder
```powershell
cd c:\Scripts\Send-escalationEmail\PythonGenAI_Learning
```

## Step 2 — Create & activate a virtual environment
```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```
Your prompt should now show `(.venv)`.

> If activation is blocked, run once (current user, safe):
> `Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned`

## Step 3 — Install required packages
```powershell
pip install --upgrade pip
pip install -r requirements.txt
```

## Step 4 — Configure API access (or use MOCK mode)
```powershell
Copy-Item .env.example .env
notepad .env
```
- Easiest: leave `MOCK_MODE=1` — every lesson runs offline.
- Or fill in your OpenAI / Azure OpenAI keys.

## Step 5 — Run your first lesson
```powershell
python Phase1_Python_Fundamentals\01_hello_world.py
```

## Step 6 — Follow the roadmap
Open [README.md](index.md) and start at **Phase 1**.
Each phase has a `00_START_HERE.md`.

---

## 📅 Suggested study plan

| Week | Phase | Daily commitment |
|---|---|---|
| 1 | Phase 1 — Fundamentals | 45 min |
| 2 | Phase 2 — Intermediate | 45 min |
| 3 | Phase 3 — Data & AI math | 30 min |
| 4–5 | Phase 4 — GenAI | 60 min |
| 6–7 | Phase 5 — Agents | 60 min |
| 8 | Phase 6 — Capstone | 90 min |

> Consistency > intensity. 30 min daily beats 5 hours on Saturday.

## 🧪 Verify everything works
```powershell
python Phase4_GenAI_Fundamentals\llm_client.py
```
You should see `[llm_client] mode = mock` (or openai/azure) and a short reply.

Happy learning! 🐍✨

