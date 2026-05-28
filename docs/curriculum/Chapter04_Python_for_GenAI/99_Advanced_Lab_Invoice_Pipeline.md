# Module 2 · Advanced Lab — "Invoice-to-Insights" CLI

> **Time:** 90–120 minutes · **Difficulty:** ⭐⭐⭐ (capstone for Module 2)
>
> You'll build a small **command-line app** that ingests a folder of messy invoices (PDF + CSV), normalises them into a SQLite database, asks an LLM to enrich each row with categorisation + tax notes, and emits a CFO-ready Markdown report.

This lab cements **everything** in Module 2: Python basics, files, SQL, APIs, LLM calls, error handling.

---

## 🌍 The real-world scenario

You're the only engineer at **PixelLatte**, a 12-person coffee-tech startup. The CFO ships you a folder every month:

```
2026-05/
├── invoices_pdf/
│   ├── aws-2026-05.pdf
│   ├── gcp-2026-05.pdf
│   └── snowflake-2026-05.pdf
├── credit_card_export.csv
└── bank_transfers.csv
```

She wants a single Markdown file with:

1. Total spend grouped by **category** (cloud, SaaS, payroll, marketing, etc.).
2. Top 5 vendors by spend.
3. Anything that looks **anomalous** (sudden 3× increase, new vendor, etc.).
4. A short narrative "what changed vs last month".

You'll automate this. Next month it's one command.

---

## 🧠 Why this lab is special

It's the first time you bring together **5 separate skills** from Module 2:

| Skill | Where in this lab |
|---|---|
| File I/O (PDF, CSV) | Stage 1 — ingest |
| `pandas` for tabular data | Stage 2 — normalise |
| `sqlite3` parameterised queries | Stage 3 — persist |
| HTTP API (currency converter) | Stage 4 — FX conversion |
| LLM with structured output | Stage 5 — enrich + narrate |

This is how **production data pipelines** are structured. Every step is **idempotent** — you can rerun without duplicating data.

---

## 📂 What you'll build

```
m2_lab/
├── data/
│   └── 2026-05/             ← input folder (PDFs + CSVs)
├── pipeline.py              ← orchestrator
├── ingest.py                ← Stage 1
├── normalise.py             ← Stage 2
├── db.py                    ← Stage 3 (schema + helpers)
├── fx.py                    ← Stage 4 (currency)
├── enrich.py                ← Stage 5 (LLM)
├── report.py                ← Stage 6 (Markdown out)
├── ledger.db                ← created at runtime
└── report-2026-05.md        ← created at runtime
```

---

## 1️⃣ Stage 1 — Ingest (extract text + rows)

`ingest.py`:

```python
"""Stage 1 — pull raw rows out of every file."""
from __future__ import annotations
import pathlib, hashlib, csv, datetime as dt
from typing import Iterator
from pypdf import PdfReader

RawRow = dict   # {source_file, line_no, content_hash, raw_text}

def _hash(text: str) -> str:
    return hashlib.sha1(text.encode()).hexdigest()[:12]

def ingest_pdfs(folder: pathlib.Path) -> Iterator[RawRow]:
    for pdf in folder.glob("*.pdf"):
        text = "\n".join(p.extract_text() or "" for p in PdfReader(pdf).pages)
        yield {"source_file": pdf.name, "line_no": 0,
               "content_hash": _hash(text), "raw_text": text}

def ingest_csvs(folder: pathlib.Path) -> Iterator[RawRow]:
    for csv_path in folder.glob("*.csv"):
        with csv_path.open(newline="", encoding="utf-8") as f:
            for i, row in enumerate(csv.DictReader(f), start=2):  # row 1 = header
                line = ",".join(f"{k}={v}" for k, v in row.items())
                yield {"source_file": csv_path.name, "line_no": i,
                       "content_hash": _hash(line), "raw_text": line}

def ingest_all(month_folder: pathlib.Path) -> list[RawRow]:
    return list(ingest_pdfs(month_folder / "invoices_pdf")) + list(ingest_csvs(month_folder))
```

### Toddler-level
- Each row gets a **`content_hash`** — a fingerprint. If you rerun the pipeline, we already know we've seen this row before. **Idempotency**.

---

## 2️⃣ Stage 2 — Normalise to a tidy table

`normalise.py`:

```python
"""Stage 2 — convert messy rows to a clean schema."""
import re, datetime as dt
from decimal import Decimal

CLEAN = {
    "date": "yyyy-mm-dd",
    "vendor": "str",
    "description": "str",
    "amount": "Decimal",
    "currency": "ISO 4217",
    "source_file": "str",
    "content_hash": "str",
}

_AMOUNT_RE = re.compile(r"(?P<curr>USD|EUR|GBP|INR|\$|€|£)?\s*(?P<amt>[\d,]+\.\d{2})")
_DATE_RE   = re.compile(r"(\d{4}-\d{2}-\d{2})")
_VENDOR_RE = re.compile(r"(?:From|Vendor|Pay to|Merchant)[: ]+([A-Za-z0-9 .&\-]+)")

CURRENCY_MAP = {"$": "USD", "€": "EUR", "£": "GBP"}

def normalise_pdf(row) -> dict | None:
    text = row["raw_text"]
    amt_m = _AMOUNT_RE.search(text)
    date_m = _DATE_RE.search(text)
    vendor_m = _VENDOR_RE.search(text)
    if not (amt_m and date_m and vendor_m):
        return None
    curr = amt_m.group("curr") or "USD"
    curr = CURRENCY_MAP.get(curr, curr)
    return {
        "date": date_m.group(1),
        "vendor": vendor_m.group(1).strip(),
        "description": "PDF invoice",
        "amount": Decimal(amt_m.group("amt").replace(",", "")),
        "currency": curr,
        "source_file": row["source_file"],
        "content_hash": row["content_hash"],
    }

def normalise_csv(row) -> dict | None:
    parts = dict(p.split("=", 1) for p in row["raw_text"].split(",") if "=" in p)
    try:
        return {
            "date":   parts["date"],
            "vendor": parts.get("vendor") or parts.get("merchant", "UNKNOWN"),
            "description": parts.get("description", ""),
            "amount": Decimal(parts["amount"]),
            "currency": parts.get("currency", "USD"),
            "source_file": row["source_file"],
            "content_hash": row["content_hash"],
        }
    except (KeyError, ValueError):
        return None
```

### Why both regex AND CSV parsing
- PDFs are unstructured → regex.
- CSVs are structured → DictReader.
- Both end up as the **same dict shape**. Downstream code doesn't care where it came from.

---

## 3️⃣ Stage 3 — Persist (SQLite + UPSERT)

`db.py`:

```python
import sqlite3
from contextlib import contextmanager

SCHEMA = """
CREATE TABLE IF NOT EXISTS transactions (
    content_hash TEXT PRIMARY KEY,
    date         TEXT NOT NULL,
    vendor       TEXT NOT NULL,
    description  TEXT,
    amount       NUMERIC NOT NULL,
    currency     TEXT NOT NULL DEFAULT 'USD',
    amount_usd   NUMERIC,
    category     TEXT,
    tax_note     TEXT,
    source_file  TEXT NOT NULL,
    inserted_at  TEXT DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_tx_date     ON transactions(date);
CREATE INDEX IF NOT EXISTS idx_tx_vendor   ON transactions(vendor);
CREATE INDEX IF NOT EXISTS idx_tx_category ON transactions(category);
"""

@contextmanager
def conn(path="ledger.db"):
    c = sqlite3.connect(path)
    c.executescript(SCHEMA)
    try:
        yield c
        c.commit()
    finally:
        c.close()

def upsert(c, rows):
    c.executemany("""
        INSERT INTO transactions (content_hash, date, vendor, description,
                                  amount, currency, source_file)
        VALUES (:content_hash, :date, :vendor, :description,
                :amount, :currency, :source_file)
        ON CONFLICT(content_hash) DO NOTHING
    """, rows)
```

### What's happening
- `content_hash` is the primary key. Re-running the pipeline → `ON CONFLICT DO NOTHING` → **no duplicates**.
- We use **named parameter binding** (`:date`) — never f-strings — to block SQL injection (OWASP A03).

---

## 4️⃣ Stage 4 — Currency normalisation

`fx.py`:

```python
import requests, datetime as dt, sqlite3, time
from functools import lru_cache

# free, no-auth FX API
URL = "https://open.er-api.com/v6/latest/USD"

@lru_cache(maxsize=1)
def _rates_cached_at(_minute_bucket: int):
    r = requests.get(URL, timeout=10)
    r.raise_for_status()
    return r.json()["rates"]      # {"EUR": 0.92, "INR": 83.0, ...}

def rates():
    # bust cache every 60 minutes
    return _rates_cached_at(int(time.time() // 3600))

def to_usd(amount, currency: str) -> float:
    if currency == "USD": return float(amount)
    return float(amount) / rates()[currency]

def backfill_usd(c: sqlite3.Connection):
    cur = c.execute("SELECT content_hash, amount, currency FROM transactions WHERE amount_usd IS NULL")
    updates = [(to_usd(a, cu), h) for h, a, cu in cur.fetchall()]
    c.executemany("UPDATE transactions SET amount_usd=? WHERE content_hash=?", updates)
```

### Production touches
- `lru_cache` per hour → at most 1 HTTP call/hour.
- Backfills only **NULL** rows → cheap to re-run.

---

## 5️⃣ Stage 5 — LLM enrichment (category + tax note)

`enrich.py`:

```python
import json, os, sqlite3
from openai import OpenAI
from pydantic import BaseModel, Field
from typing import Literal

client = OpenAI()
MODEL = "gpt-4o-mini"
BATCH = 20

CATEGORIES = ("cloud_infra", "saas", "payroll", "marketing",
              "office", "travel", "professional_services", "other")

class Enrichment(BaseModel):
    content_hash: str
    category: Literal[CATEGORIES] = Field(description="Best-fit category")
    tax_note: str = Field(max_length=140,
                          description="One line on tax/expense treatment")

SYSTEM = """You categorise PixelLatte expenses for tax & reporting.

Output a JSON ARRAY where each item matches:
- content_hash (echo input)
- category: one of [cloud_infra, saas, payroll, marketing, office,
                    travel, professional_services, other]
- tax_note: ≤140 chars, e.g. "VAT-recoverable; UK reverse charge applies"

Be conservative — when unclear, use 'other'."""

def enrich_pending(c: sqlite3.Connection):
    rows = c.execute("""
        SELECT content_hash, vendor, description, amount_usd
        FROM transactions
        WHERE category IS NULL
        LIMIT ?""", (BATCH,)).fetchall()

    if not rows: return 0
    payload = [{"content_hash": h, "vendor": v, "description": d, "amount_usd": a}
               for (h, v, d, a) in rows]

    resp = client.chat.completions.create(
        model=MODEL,
        response_format={"type": "json_object"},
        messages=[
            {"role": "system", "content": SYSTEM},
            {"role": "user",   "content": json.dumps({"items": payload})},
        ],
    )
    items = json.loads(resp.choices[0].message.content)["items"]
    parsed = [Enrichment.model_validate(i) for i in items]

    c.executemany("""
        UPDATE transactions
        SET category=:category, tax_note=:tax_note
        WHERE content_hash=:content_hash
    """, [e.model_dump() for e in parsed])
    return len(parsed)
```

### Why batch
- 1 call → 20 rows enriched. **~20× cheaper** than per-row.
- The schema forces a stable shape across all 20 items.

---

## 6️⃣ Stage 6 — The CFO report

`report.py`:

```python
import pandas as pd, sqlite3, pathlib, datetime as dt
from openai import OpenAI

def export_report(month: str, db="ledger.db", out_dir="."):
    with sqlite3.connect(db) as c:
        df = pd.read_sql("""SELECT date, vendor, category, amount_usd, currency, tax_note
                            FROM transactions WHERE substr(date,1,7)=?""", c, params=[month])

    if df.empty: raise RuntimeError(f"No data for {month}")

    total = df["amount_usd"].sum()
    by_cat = (df.groupby("category")["amount_usd"].sum()
                .sort_values(ascending=False).round(2))
    top_vendors = (df.groupby("vendor")["amount_usd"].sum()
                     .sort_values(ascending=False).head(5).round(2))

    md  = f"# PixelLatte — Expense Report {month}\n\n"
    md += f"**Total:** ${total:,.2f}\n\n"
    md += "## Spend by category\n\n" + by_cat.to_markdown() + "\n\n"
    md += "## Top 5 vendors\n\n" + top_vendors.to_markdown() + "\n\n"

    # Narrative via LLM
    summary = OpenAI().chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {"role": "system", "content":
             "You are a CFO assistant. Given a category breakdown, write 4 bullet points: "
             "(1) biggest line item, (2) anything anomalous, (3) suggestion, (4) one-sentence outlook."},
            {"role": "user", "content": by_cat.to_string()},
        ],
    ).choices[0].message.content
    md += "## Narrative\n\n" + summary + "\n"

    path = pathlib.Path(out_dir) / f"report-{month}.md"
    path.write_text(md, encoding="utf-8")
    return path
```

---

## 7️⃣ The orchestrator

`pipeline.py`:

```python
"""End-to-end. Run with:  python pipeline.py 2026-05  data/"""
import sys, pathlib
import ingest, normalise, db, fx, enrich, report

def run(month: str, root="data"):
    month_folder = pathlib.Path(root) / month
    raws = ingest.ingest_all(month_folder)
    pdf_rows = [normalise.normalise_pdf(r) for r in raws if r["source_file"].endswith(".pdf")]
    csv_rows = [normalise.normalise_csv(r) for r in raws if r["source_file"].endswith(".csv")]
    rows = [{**r, "amount": str(r["amount"])} for r in pdf_rows + csv_rows if r]
    print(f"[ingest]   {len(rows)} clean rows")

    with db.conn() as c:
        db.upsert(c, rows)
        fx.backfill_usd(c)
        while enrich.enrich_pending(c):
            print("[enrich]   batch done")
    path = report.export_report(month)
    print(f"[report]   {path}")

if __name__ == "__main__":
    run(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else "data")
```

Run:

```powershell
python pipeline.py 2026-05 data
```

---

## ✅ What you'll see

```
[ingest]   23 clean rows
[enrich]   batch done
[report]   report-2026-05.md
```

Open `report-2026-05.md` — totals, breakdown, top vendors, narrative.

---

## 🏋️ Exercises

### Exercise 1 — Anomaly detector
Add a new section "Anomalies" comparing this month to last month for each category. Flag any category that grew >2× or where a brand-new vendor appeared.

### Exercise 2 — Receipts upload via Gmail
Add a step that pulls all `from:noreply@*` emails with PDF attachments for the month from Gmail's API and drops them into `data/<month>/invoices_pdf/`.

### Exercise 3 — Forecast next month
Add a 3rd LLM call that, given the last 3 months of totals, predicts next month's spend with a confidence interval. Add to the report.

### Exercise 4 — Multi-currency CFO
Add CLI flag `--display-currency EUR`. Convert and re-render the whole report in EUR using the same `fx.py`.

### Exercise 5 — Slack delivery
Post the top 3 bullet points to a Slack channel via incoming-webhook URL (env var `SLACK_WEBHOOK`). Don't post if `--dry-run`.

### Exercise 6 — pytest suite
Write `test_pipeline.py` with at least:
- one test that idempotency works (running twice → same row count)
- one test that a PDF without a date is skipped (not crashes)
- one test that `to_usd(100, "EUR")` round-trips within 1¢

---

## ✅ Solutions (key points)

### Solution 1 — Anomaly detector
```python
prev = pd.read_sql("...substr(date,1,7)=?", c, params=[prev_month])
curr = pd.read_sql("...substr(date,1,7)=?", c, params=[month])
pivot = pd.merge(prev.groupby("category")["amount_usd"].sum().rename("prev"),
                 curr.groupby("category")["amount_usd"].sum().rename("curr"),
                 left_index=True, right_index=True, how="outer").fillna(0)
pivot["ratio"] = pivot["curr"] / pivot["prev"].replace(0, 1)
anomalies = pivot[pivot["ratio"] > 2.0]
```

### Solution 2 — Gmail pull (sketch)
Use `google-api-python-client`. The key part:
```python
from googleapiclient.discovery import build
svc = build("gmail", "v1", credentials=creds)
msgs = svc.users().messages().list(userId="me",
        q=f"from:noreply has:attachment after:{month}/01 before:{month}/31").execute()
```

### Solution 3 — Forecast
```python
prompt = ("You're a finance forecaster. Given monthly totals, "
          "estimate next month's spend and a 90% interval. "
          "Output JSON: {expected: number, low: number, high: number, note: str}")
```

### Solution 4 — Display currency
Pass `display_currency` into `export_report`; convert with `to_usd` inverted:
```python
def from_usd(amount, currency):
    return amount * fx.rates()[currency]
df["amount_disp"] = df["amount_usd"].map(lambda x: from_usd(x, args.display_currency))
```

### Solution 5 — Slack
```python
import requests, os
def post_to_slack(text):
    requests.post(os.environ["SLACK_WEBHOOK"], json={"text": text}, timeout=10).raise_for_status()
```

### Solution 6 — pytest
```python
def test_idempotent(tmp_path):
    pipeline.run("2026-05", root="tests/fixtures")
    pipeline.run("2026-05", root="tests/fixtures")
    with db.conn() as c:
        n = c.execute("SELECT COUNT(*) FROM transactions").fetchone()[0]
    assert n == EXPECTED_ROW_COUNT
```

---

## 🎯 What you should now be able to do

- [x] Build a multi-stage Python data pipeline
- [x] Handle PDFs and CSVs in the same flow
- [x] Persist with SQLite + UPSERT + content-hash idempotency
- [x] Cache external API calls cleanly
- [x] Batch LLM enrichment for cost & speed
- [x] Generate a Markdown report with both numbers and LLM narrative

---

## 🌐 Where this leads in real life

- **Stripe Sigma / Plaid Dashboards** — same skeleton.
- **Procurement automation** (Tipalti, Airbase) — exactly this flow plus approval routing.
- **Hospital billing** — PDF EOBs → normalise → categorise → reconcile.

➡️ Continue to **[Module 3 — LangChain Core](../Chapter07_LangChain_Core/01_Introduction_to_LangChain.md)**.
