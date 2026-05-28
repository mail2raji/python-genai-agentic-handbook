# Mini-Project — Log Analyzer

!!! info "Runnable source file"
    **Path:** `Chapter01_Python_Fundamentals/mini_project_log_analyzer.py`  
    **Phase:** Phase 1 — Python Fundamentals  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/genai-agentic-ai-handbook)) and run it locally.

```python
"""
🏆 PHASE 1 MINI-PROJECT — Log Analyzer
=======================================

Goal: Parse a server log file, count error types, and write a summary report.

This combines EVERYTHING from Phase 1:
- Variables, strings, lists, dicts
- Loops, conditionals
- Functions, file I/O

In Phase 4, we'll upgrade this same project to use an LLM to
*explain* the errors in plain English. That's GenAI in action!
"""

import os
from collections import Counter

HERE = os.path.dirname(os.path.abspath(__file__))
log_path     = os.path.join(HERE, "server.log")
report_path  = os.path.join(HERE, "log_report.txt")


# --- Step 1: Create a sample log file (so you can run this anywhere) ---
sample_log = """2026-05-27 09:01:12 INFO  User priya@contoso.com logged in
2026-05-27 09:02:33 WARN  Slow query detected (3.2s) on users table
2026-05-27 09:03:01 ERROR Database connection timeout
2026-05-27 09:03:45 ERROR Failed to send email to ravi@contoso.com
2026-05-27 09:04:10 INFO  Background job started
2026-05-27 09:05:22 ERROR Database connection timeout
2026-05-27 09:06:01 WARN  Memory usage at 85%
2026-05-27 09:07:14 ERROR Authentication failed for user unknown@x.com
2026-05-27 09:08:00 INFO  Cache cleared
2026-05-27 09:09:11 ERROR Database connection timeout
"""

with open(log_path, "w", encoding="utf-8") as f:
    f.write(sample_log)
print(f"📝 Sample log written: {log_path}")


# --- Step 2: Function to parse one line ---
def parse_line(line: str) -> dict:
    """Convert a raw log line into a structured dict."""
    parts = line.strip().split(maxsplit=3)
    if len(parts) < 4:
        return {}
    return {
        "date":    parts[0],
        "time":    parts[1],
        "level":   parts[2],
        "message": parts[3],
    }


# --- Step 3: Read & analyze ---
levels = []
error_messages = []

with open(log_path, "r", encoding="utf-8") as f:
    for line in f:
        entry = parse_line(line)
        if not entry:
            continue
        levels.append(entry["level"])
        if entry["level"] == "ERROR":
            error_messages.append(entry["message"])

# Counter is a super-useful dict subclass
level_counts = Counter(levels)
error_counts = Counter(error_messages)


# --- Step 4: Build a report ---
def build_report() -> str:
    lines = []
    lines.append("=" * 50)
    lines.append("           SERVER LOG SUMMARY REPORT")
    lines.append("=" * 50)
    lines.append(f"\nTotal log lines: {len(levels)}\n")
    lines.append("By severity:")
    for level, count in level_counts.most_common():
        lines.append(f"  {level:<6} {count}")
    lines.append("\nTop error messages:")
    for msg, count in error_counts.most_common(5):
        lines.append(f"  [{count}x] {msg}")
    lines.append("\n" + "=" * 50)
    return "\n".join(lines)


report = build_report()
print("\n" + report)

# --- Step 5: Save report ---
with open(report_path, "w", encoding="utf-8") as f:
    f.write(report)
print(f"\n✅ Report saved to {report_path}")


# ============================================================
# 🎓 CHALLENGE EXTENSIONS:
#   1. Add a function `filter_by_level(level)` that returns only those lines.
#   2. Count how many ERRORs occurred per hour.
#   3. Save the report as JSON instead of text.
# ============================================================

```
