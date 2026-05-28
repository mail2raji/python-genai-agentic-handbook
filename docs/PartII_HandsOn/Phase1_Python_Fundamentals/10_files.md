# Lesson 10 — Files

!!! info "Runnable source file"
    **Path:** `Phase1_Python_Fundamentals/10_files.py`  
    **Phase:** Phase 1 — Python Fundamentals  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/python-genai-agentic-handbook)) and run it locally.

```python
"""
Lesson 10: Reading & Writing Files
====================================

📖 CONCEPT:
Files store data on disk. You'll use them to load documents for RAG,
save chat histories, log agent decisions, and more.

💡 REAL-WORLD ANALOGY:
A file is a notebook — open it, read pages, write new pages, close it.

🧪 EXAMPLE — building a simple knowledge base:
"""

import os

# Make sure we're in this lesson's folder
HERE = os.path.dirname(os.path.abspath(__file__))
sample_path = os.path.join(HERE, "sample_kb.txt")

# --- WRITING a file ---
# "w" = write (overwrites). "a" = append. "r" = read.
with open(sample_path, "w", encoding="utf-8") as f:
    f.write("Azure Key Vault stores secrets, keys, and certificates.\n")
    f.write("Entra ID is Microsoft's cloud identity service.\n")
    f.write("Microsoft Sentinel is a cloud-native SIEM.\n")

print(f"✅ Wrote knowledge base to {sample_path}")

# --- READING a file (whole content) ---
with open(sample_path, "r", encoding="utf-8") as f:
    content = f.read()
print("\n--- Full content ---")
print(content)

# --- READING line by line (memory-efficient for big files) ---
print("--- Line by line ---")
with open(sample_path, "r", encoding="utf-8") as f:
    for i, line in enumerate(f, start=1):
        print(f"Line {i}: {line.strip()}")

# --- APPENDING ---
with open(sample_path, "a", encoding="utf-8") as f:
    f.write("Azure OpenAI hosts GPT models in your tenant.\n")

# --- Working with JSON (most common AI data format) ---
import json

config = {
    "model": "gpt-4o-mini",
    "temperature": 0.7,
    "tools": ["search_web", "send_email"],
}

config_path = os.path.join(HERE, "agent_config.json")

# Save
with open(config_path, "w", encoding="utf-8") as f:
    json.dump(config, f, indent=2)
print(f"\n✅ Saved JSON config to {config_path}")

# Load
with open(config_path, "r", encoding="utf-8") as f:
    loaded = json.load(f)
print("Loaded model:", loaded["model"])
print("Tools available:", loaded["tools"])


# ============================================================
# ✏️ EXERCISE:
# 1. Create a file called "chat_log.txt"
# 2. Write 3 chat messages (each on its own line, prefixed with role)
# 3. Read the file back and count how many lines start with "user:"
# ============================================================


# ✅ SOLUTION:
# log_path = os.path.join(HERE, "chat_log.txt")
# with open(log_path, "w", encoding="utf-8") as f:
#     f.write("user: hi\n")
#     f.write("assistant: hello\n")
#     f.write("user: bye\n")
#
# count = 0
# with open(log_path) as f:
#     for line in f:
#         if line.startswith("user:"):
#             count += 1
# print("User messages:", count)

```
