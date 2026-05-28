# Capstone 3 — Incident Reporter

!!! info "Runnable source file"
    **Path:** `Chapter11_Capstones_ITops/capstone3_incident_reporter.py`  
    **Phase:** Phase 6 — Capstone Projects  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/genai-agentic-ai-handbook)) and run it locally.

```python
"""
🎓 CAPSTONE 3 — Multi-Agent Incident Reporter
==============================================

A 4-agent pipeline that turns a raw server log into a polished
incident report. Demonstrates: tool use + memory + multi-agent + structured output.

Pipeline:
    Log Analyst     → extract errors, group by type, find timeline
    Root-Cause Finder → propose hypotheses with confidence scores
    Report Writer   → produce a Markdown incident report
    Reviewer        → polish & verify, output final .md

▶️ Run:
    python capstone3_incident_reporter.py
"""

from __future__ import annotations
import os, sys, json, re
from datetime import datetime
from collections import Counter

HERE = os.path.dirname(os.path.abspath(__file__))
PHASE4 = os.path.abspath(os.path.join(HERE, "..", "Phase4_GenAI_Fundamentals"))
if PHASE4 not in sys.path:
    sys.path.insert(0, PHASE4)
from llm_client import chat                                  # noqa: E402

SAMPLE_LOG = """2026-05-27 09:01:12 INFO  Service started
2026-05-27 09:03:01 ERROR Database connection timeout to db-prod-1
2026-05-27 09:03:45 ERROR Failed to send email to ravi@contoso.com
2026-05-27 09:05:22 ERROR Database connection timeout to db-prod-1
2026-05-27 09:06:01 WARN  Memory usage at 85%
2026-05-27 09:07:14 ERROR Authentication failed for user unknown@x.com
2026-05-27 09:09:11 ERROR Database connection timeout to db-prod-1
2026-05-27 09:10:00 ERROR HTTP 503 on /api/orders
2026-05-27 09:10:30 ERROR HTTP 503 on /api/orders
2026-05-27 09:12:00 INFO  Failover to db-prod-2 triggered
2026-05-27 09:14:00 INFO  Service stabilized
"""


# ---------- Tool: deterministic stats from the log ----------
def log_stats(raw: str) -> dict:
    levels = Counter()
    errors = Counter()
    first, last = None, None
    for line in raw.splitlines():
        parts = line.split(maxsplit=3)
        if len(parts) < 4:
            continue
        date, time, level, msg = parts
        levels[level] += 1
        if level == "ERROR":
            errors[msg] += 1
        ts = f"{date} {time}"
        first = first or ts
        last = ts
    return {
        "levels": dict(levels),
        "top_errors": errors.most_common(5),
        "first_event": first,
        "last_event":  last,
    }


# ---------- Agents ----------
def log_analyst(raw: str, stats: dict) -> str:
    return chat([
        {"role": "system", "content":
         "You are LOG ANALYST. Given log content + pre-computed STATS, write a 3-bullet timeline of what happened. Be specific with times."},
        {"role": "user", "content": f"STATS: {json.dumps(stats)}\n\nLOG:\n{raw}"},
    ], temperature=0.2)


def root_cause(timeline: str, stats: dict) -> str:
    return chat([
        {"role": "system", "content":
         "You are ROOT-CAUSE FINDER. Output JSON: "
         '{"hypotheses":[{"cause":"<short>","confidence":"low|medium|high","evidence":"<facts>"}]}'},
        {"role": "user", "content": f"TIMELINE:\n{timeline}\n\nSTATS: {json.dumps(stats)}"},
    ], temperature=0, response_format={"type": "json_object"})


def report_writer(timeline: str, causes_json: str, stats: dict) -> str:
    return chat([
        {"role": "system", "content":
         "You are REPORT WRITER. Produce a Markdown incident report with sections: "
         "Summary, Timeline, Impact, Root-Cause Hypotheses, Recommended Actions. "
         "Keep it under 350 words."},
        {"role": "user", "content":
         f"TIMELINE:\n{timeline}\n\nCAUSES: {causes_json}\n\nSTATS: {json.dumps(stats)}"},
    ], temperature=0.3, max_tokens=900)


def reviewer(draft_md: str) -> str:
    return chat([
        {"role": "system", "content":
         "You are REVIEWER. Improve the report for executive clarity. "
         "Keep ALL section headings. Return ONLY the polished Markdown — no commentary."},
        {"role": "user", "content": draft_md},
    ], temperature=0.2, max_tokens=900)


def main():
    raw = SAMPLE_LOG
    stats = log_stats(raw)
    print("📊 Stats:", json.dumps(stats, indent=2))

    print("\n--- LOG ANALYST ---")
    timeline = log_analyst(raw, stats); print(timeline)

    print("\n--- ROOT CAUSE ---")
    causes = root_cause(timeline, stats); print(causes)

    print("\n--- REPORT WRITER (draft) ---")
    draft = report_writer(timeline, causes, stats); print(draft)

    print("\n--- REVIEWER (final) ---")
    final = reviewer(draft); print(final)

    out_path = os.path.join(HERE, f"incident_report_{datetime.now():%Y%m%d_%H%M%S}.md")
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(final)
    print(f"\n✅ Report saved: {out_path}")


if __name__ == "__main__":
    main()

```
