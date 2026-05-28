# Capstone 1 — Spn Renewal Concierge

!!! info "Runnable source file"
    **Path:** `Phase6_Capstone_Projects/capstone1_spn_renewal_concierge.py`  
    **Phase:** Phase 6 — Capstone Projects  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/python-genai-agentic-handbook)) and run it locally.

```python
"""
🎓 CAPSTONE 1 — SPN Renewal Concierge
======================================

End-to-end automation that:
  1. Loads `SPN_ExpiryReport.csv` (or generates a sample)
  2. Finds owners whose SPNs expire within 30 days
  3. Uses an LLM to draft a personalized renewal email per owner
  4. Saves drafts to disk (and optionally hands off to Send-EscalationEmail.ps1)

This is a Python-side "co-pilot" for your existing PowerShell workflow.
"""

from __future__ import annotations
import os, sys
import pandas as pd
from datetime import datetime, timedelta

HERE = os.path.dirname(os.path.abspath(__file__))
PHASE4 = os.path.abspath(os.path.join(HERE, "..", "Phase4_GenAI_Fundamentals"))
if PHASE4 not in sys.path:
    sys.path.insert(0, PHASE4)
from llm_client import chat                                            # noqa: E402

WORKSPACE  = r"c:\Scripts\Send-escalationEmail"
REAL_CSV   = os.path.join(WORKSPACE, "SPN_ExpiryReport.csv")
DRAFTS_DIR = os.path.join(HERE, "drafts")
os.makedirs(DRAFTS_DIR, exist_ok=True)

EMAIL_SYSTEM = """You write polite, concise renewal emails for IT app owners.
Rules:
- 4–6 sentences, friendly but professional.
- Mention the app name, exact expiry date, and link to renew (use https://renew.contoso.com).
- Include a clear call to action.
- Subject line on the first line, prefixed with 'Subject: '.
- Do NOT invent technical details beyond what's provided.
"""


def load_or_make_data() -> pd.DataFrame:
    if os.path.exists(REAL_CSV):
        try:
            df = pd.read_csv(REAL_CSV)
            print(f"📂 Loaded real data: {REAL_CSV} ({len(df)} rows)")
            return df
        except Exception as e:
            print(f"⚠️ Could not read {REAL_CSV}: {e}. Using sample.")

    print("📝 Using sample data (no real CSV found).")
    today = datetime(2026, 5, 27)
    return pd.DataFrame([
        {"AppName": "SalesPortalSPN", "Owner": "alice@contoso.com",  "Expires": (today + timedelta(days=5)).date()},
        {"AppName": "FinanceETL",     "Owner": "bob@contoso.com",    "Expires": (today + timedelta(days=12)).date()},
        {"AppName": "LegalArchive",   "Owner": "carol@contoso.com",  "Expires": (today + timedelta(days=28)).date()},
        {"AppName": "HRAnalytics",    "Owner": "dan@contoso.com",    "Expires": (today + timedelta(days=120)).date()},
    ])


def normalize(df: pd.DataFrame) -> pd.DataFrame:
    """Try to find usable columns regardless of exact naming in the real CSV."""
    cols = {c.lower(): c for c in df.columns}

    def pick(*candidates, default=None):
        for c in candidates:
            if c in cols:
                return cols[c]
        return default

    app_col    = pick("appname", "displayname", "name", "application")
    owner_col  = pick("owner", "ownermail", "owneremail", "contact")
    expiry_col = pick("expires", "expiry", "expirydate", "enddate")

    if not (app_col and owner_col and expiry_col):
        raise RuntimeError(f"Could not detect required columns. Found: {df.columns.tolist()}")

    out = df.rename(columns={app_col: "AppName", owner_col: "Owner", expiry_col: "Expires"}).copy()
    out["Expires"] = pd.to_datetime(out["Expires"], errors="coerce")
    return out.dropna(subset=["Expires"])


def find_expiring_soon(df: pd.DataFrame, days: int = 30) -> pd.DataFrame:
    today = pd.Timestamp(datetime.now().date())
    df["DaysLeft"] = (df["Expires"] - today).dt.days
    return df[(df["DaysLeft"] >= 0) & (df["DaysLeft"] <= days)].sort_values("DaysLeft")


def draft_email(app: str, owner: str, expires: str, days_left: int) -> str:
    user = (
        f"App: {app}\n"
        f"Owner email: {owner}\n"
        f"Expires on: {expires}\n"
        f"Days remaining: {days_left}\n"
    )
    return chat(
        [{"role": "system", "content": EMAIL_SYSTEM},
         {"role": "user",   "content": user}],
        temperature=0.4, max_tokens=400,
    )


def main():
    df = normalize(load_or_make_data())
    soon = find_expiring_soon(df)
    print(f"\n⚠️ {len(soon)} SPN(s) expiring within 30 days.\n")

    for _, row in soon.iterrows():
        email = draft_email(
            app=row["AppName"],
            owner=row["Owner"],
            expires=row["Expires"].date().isoformat(),
            days_left=int(row["DaysLeft"]),
        )
        out_path = os.path.join(DRAFTS_DIR, f"{row['AppName']}__{row['Owner'].replace('@','_at_')}.txt")
        with open(out_path, "w", encoding="utf-8") as f:
            f.write(email)
        print(f"✉️  Drafted → {out_path}")

    print(f"\n✅ All drafts saved in: {DRAFTS_DIR}")
    print("\nNext step: review the drafts, then hand off to your existing")
    print("Send-EscalationEmail.ps1 to actually send them.")


if __name__ == "__main__":
    main()

```
