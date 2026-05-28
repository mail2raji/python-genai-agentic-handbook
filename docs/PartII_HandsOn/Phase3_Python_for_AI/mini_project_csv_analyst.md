# Mini-Project — Csv Analyst

!!! info "Runnable source file"
    **Path:** `Phase3_Python_for_AI/mini_project_csv_analyst.py`  
    **Phase:** Phase 3 — Python for AI & Data  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/python-genai-agentic-handbook)) and run it locally.

```python
"""
🏆 PHASE 3 MINI-PROJECT — CSV Expiry Analyst
==============================================

Loads a CSV (or generates a sample), finds rows expiring soon,
and produces both a summary AND a per-team breakdown.

This is the SAME shape as your real `SPN_ExpiryReport.csv` workflow,
but written in Python with Pandas.
"""

from __future__ import annotations
import os
import pandas as pd
from datetime import datetime, timedelta

HERE = os.path.dirname(os.path.abspath(__file__))
csv_path     = os.path.join(HERE, "spn_sample.csv")
report_path  = os.path.join(HERE, "expiry_report.txt")


# --- Step 1: Build a sample CSV (so anyone can run this) ---
today = datetime(2026, 5, 27)
sample_rows = [
    {"app_name": "App-Sales",     "owner": "alice@x.com",  "team": "Sales",   "expires": today + timedelta(days=5)},
    {"app_name": "App-Finance",   "owner": "bob@x.com",    "team": "Finance", "expires": today + timedelta(days=90)},
    {"app_name": "App-Marketing", "owner": "carol@x.com",  "team": "Sales",   "expires": today + timedelta(days=20)},
    {"app_name": "App-HR",        "owner": "dan@x.com",    "team": "HR",      "expires": today + timedelta(days=-3)},
    {"app_name": "App-IT",        "owner": "eve@x.com",    "team": "IT",      "expires": today + timedelta(days=200)},
    {"app_name": "App-Legal",     "owner": "frank@x.com",  "team": "Legal",   "expires": today + timedelta(days=15)},
]
pd.DataFrame(sample_rows).to_csv(csv_path, index=False)
print(f"📝 Sample CSV created: {csv_path}")


# --- Step 2: Load & inspect ---
df = pd.read_csv(csv_path, parse_dates=["expires"])
print(f"\nLoaded {len(df)} rows. Columns: {df.columns.tolist()}")


# --- Step 3: Compute days-to-expiry ---
df["days_to_expiry"] = (df["expires"] - today).dt.days


def bucket(days: int) -> str:
    if days < 0:    return "🔴 EXPIRED"
    if days <= 30:  return "🟠 30 days"
    if days <= 90:  return "🟡 90 days"
    return "🟢 OK"

df["status"] = df["days_to_expiry"].apply(bucket)


# --- Step 4: Filter "expiring soon" ---
soon = df[df["days_to_expiry"] <= 30].sort_values("days_to_expiry")
print("\n⚠️  Expiring within 30 days:")
print(soon[["app_name", "owner", "team", "days_to_expiry", "status"]].to_string(index=False))


# --- Step 5: Per-team summary ---
per_team = (
    df.groupby("team")
      .agg(total=("app_name", "count"),
           expiring_soon=("days_to_expiry", lambda s: int((s <= 30).sum())))
      .sort_values("expiring_soon", ascending=False)
)
print("\n📊 Per-team summary:")
print(per_team)


# --- Step 6: Write report file ---
lines = []
lines.append("=" * 60)
lines.append("         SPN EXPIRY REPORT")
lines.append(f"         Generated: {today.date()}")
lines.append("=" * 60)
lines.append(f"\nTotal apps: {len(df)}")
lines.append(f"Expiring within 30 days: {len(soon)}\n")
lines.append("Expiring soon (per app):")
for _, row in soon.iterrows():
    lines.append(f"  • {row['app_name']:<14}  owner={row['owner']:<18}  "
                 f"team={row['team']:<8}  in {row['days_to_expiry']} days")
lines.append("\nPer-team summary:")
lines.append(per_team.to_string())
lines.append("\n" + "=" * 60)

report = "\n".join(lines)
with open(report_path, "w", encoding="utf-8") as f:
    f.write(report)
print(f"\n✅ Report saved to {report_path}")


# ============================================================
# 🎓 EXTENSIONS:
#   1. Load your REAL c:/Scripts/Send-escalationEmail/SPN_ExpiryReport.csv
#      (adjust the column names accordingly).
#   2. Email the soon-to-expire owners (using your existing PS workflow ideas).
#   3. In Phase 4, ask an LLM to draft personalized renewal emails.
# ============================================================

```
