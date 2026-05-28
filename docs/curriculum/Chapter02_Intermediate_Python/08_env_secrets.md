# Lesson 8 — Env Secrets

!!! info "Runnable source file"
    **Path:** `Chapter02_Intermediate_Python/08_env_secrets.py`  
    **Phase:** Phase 2 — Intermediate Python  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/genai-agentic-ai-handbook)) and run it locally.

```python
"""
Lesson 8: Environment Variables & Secrets
==========================================

📖 CONCEPT:
NEVER hard-code API keys in your code. Store them in a `.env` file
and load them at runtime. This is rule #1 of AI/cloud security.

💡 ANALOGY:
You don't tape your house key to the front door — you keep it in your pocket.
`.env` is the "pocket".

📦 INSTALL:  pip install python-dotenv
"""

import os

# --- Step 1: Create a sample .env file for this lesson ---
HERE = os.path.dirname(os.path.abspath(__file__))
env_path = os.path.join(HERE, ".env")

if not os.path.exists(env_path):
    with open(env_path, "w", encoding="utf-8") as f:
        f.write("OPENAI_API_KEY=sk-FAKE-DEMO-KEY-DO-NOT-USE\n")
        f.write("MODEL_NAME=gpt-4o-mini\n")
        f.write("MAX_TOKENS=2000\n")
    print(f"Created sample {env_path}")

# --- Step 2: Add .env to .gitignore so it's never committed ---
gitignore_path = os.path.join(HERE, ".gitignore")
if not os.path.exists(gitignore_path):
    with open(gitignore_path, "w", encoding="utf-8") as f:
        f.write(".env\n.venv/\n__pycache__/\n")

# --- Step 3: Load environment variables ---
try:
    from dotenv import load_dotenv
    load_dotenv(env_path)
except ImportError:
    print("⚠️  Install python-dotenv:  pip install python-dotenv")

api_key = os.getenv("OPENAI_API_KEY")
model   = os.getenv("MODEL_NAME", "default-model")    # 2nd arg = default
max_tok = int(os.getenv("MAX_TOKENS", "1000"))

# NEVER print the full key! Mask it.
if api_key:
    masked = api_key[:6] + "..." + api_key[-4:]
    print(f"Loaded API key: {masked}")
print(f"Model: {model}")
print(f"Max tokens: {max_tok}")


# --- Step 4: Defensive helper ---
def require_env(var_name: str) -> str:
    """Get an env var or raise a clear error."""
    value = os.getenv(var_name)
    if not value:
        raise RuntimeError(
            f"Missing required environment variable: {var_name}\n"
            f"Add it to your .env file."
        )
    return value


# ============================================================
# 🔐 SECURITY CHECKLIST (memorize this):
#   ✅ Store secrets in .env, not in code
#   ✅ Add .env to .gitignore
#   ✅ Never print or log full keys
#   ✅ Use a different .env per environment (dev / prod)
#   ✅ In production, use Azure Key Vault / AWS Secrets Manager
# ============================================================

```
