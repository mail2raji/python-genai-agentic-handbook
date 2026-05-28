# Module 2 · Lesson 2 — Working with Files and Databases

## 🍭 Imagine this…

Your memory has two storage rooms:
- **A notepad** on your desk — easy to write on, but messy after 100 notes. → **Files**
- **A filing cabinet** with labelled drawers — slower to open but you find things instantly. → **Databases**

Both store data. You choose based on **size** and **how you'll search it**.

---

## 🧠 The real concept

### Files you'll meet every day

| Format | What it looks like | Best for |
|---|---|---|
| **TXT** | plain text | Quick logs, notes |
| **CSV** | rows of comma-separated values | Spreadsheets, tabular data |
| **JSON** | nested key/value | API responses, configs |
| **PDF** | binary, formatted documents | Reports, policies (read-only for us) |
| **Markdown / DOCX** | rich text | Documents to RAG-ify |

### Databases you'll meet

| Type | Example | When |
|---|---|---|
| **SQLite** | `chinook.db` | Tiny apps, files-on-disk DB |
| **PostgreSQL** | Postgres / Supabase | Web apps, production |
| **Vector DB** | ChromaDB, Pinecone | Embeddings for RAG (Module 4) |

The mental model is identical: a **table** is like a CSV with rules, and **SQL** is a query language to ask questions.

---

## 🌍 Real-world scenario — Build a "support log" pipeline

You have **support_tickets.csv** dropped daily. You want to:
1. Read each row.
2. Skip rows missing a `customer_id`.
3. Convert to JSON for an API.
4. Insert into a **SQLite** DB so we can `SELECT` later.

This is the daily life of every data engineer.

---

## 💻 The code — reading & writing files (5 formats)

### 1) Plain text

```python
# Write
with open("hello.txt", "w", encoding="utf-8") as f:
    f.write("Hello from Python!\n")
    f.write("A second line.\n")

# Read all at once
text = open("hello.txt", encoding="utf-8").read()
print(text)

# Read line-by-line (best for big files)
for line in open("hello.txt", encoding="utf-8"):
    print(line.rstrip())   # rstrip() removes the trailing \n
```

**Note:** Always use `encoding="utf-8"` — otherwise Windows defaults bite you with non-English characters.

### 2) CSV

```python
import csv

# Write
rows = [
    {"id": 1, "name": "Alice", "score": 92},
    {"id": 2, "name": "Bob",   "score": 78},
]
with open("scores.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=["id", "name", "score"])
    writer.writeheader()
    writer.writerows(rows)

# Read
with open("scores.csv", encoding="utf-8") as f:
    reader = csv.DictReader(f)
    for row in reader:
        # everything in CSV is a string, so cast
        print(row["name"], int(row["score"]))
```

### 3) JSON

```python
import json

config = {
    "model": "gpt-4o-mini",
    "temperature": 0.2,
    "tools": ["calculator", "search"],
}

# Write (with pretty indent)
with open("config.json", "w", encoding="utf-8") as f:
    json.dump(config, f, indent=2)

# Read
with open("config.json", encoding="utf-8") as f:
    loaded = json.load(f)
print(loaded["model"])
```

### 4) PDF (read-only)

```python
# pip install pypdf
from pypdf import PdfReader

reader = PdfReader("policy.pdf")
all_text = ""
for page in reader.pages:
    all_text += page.extract_text() + "\n"
print(all_text[:500])
```

This is **how RAG starts** — you'll feed `all_text` to an embedder later.

### 5) Pandas (the data engineer's swiss army)

```python
# pip install pandas
import pandas as pd

df = pd.read_csv("scores.csv")
print(df.head())
print(df.describe())                     # quick stats
high = df[df["score"] > 80]              # filter
df.to_excel("scores.xlsx", index=False)  # export to Excel
```

---

## 💻 The code — SQLite (a real database in a single file)

```python
import sqlite3

# 1️⃣ Connect (creates file if missing)
conn = sqlite3.connect("tickets.db")
cur = conn.cursor()

# 2️⃣ Create a table
cur.execute("""
CREATE TABLE IF NOT EXISTS tickets (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    customer_id TEXT NOT NULL,
    category    TEXT NOT NULL,
    urgency     INTEGER CHECK(urgency BETWEEN 1 AND 5),
    body        TEXT NOT NULL,
    created_at  TEXT DEFAULT CURRENT_TIMESTAMP
)
""")

# 3️⃣ Insert rows safely (parameterised → blocks SQL injection)
cur.execute(
    "INSERT INTO tickets (customer_id, category, urgency, body) VALUES (?, ?, ?, ?)",
    ("CUST001", "shipping", 4, "Where is my order?"),
)
conn.commit()

# 4️⃣ Query
cur.execute("SELECT id, category, urgency FROM tickets WHERE urgency >= 4")
for row in cur.fetchall():
    print(row)

conn.close()
```

### Why parameterised queries (the `?`)?
**Never** do `f"INSERT INTO x VALUES ('{user_input}')"`. A malicious user types
`'); DROP TABLE tickets; --` and your DB is gone. Parameters escape input safely. This is OWASP A03 — **the #1 cause of breaches**.

---

## 💻 Putting it all together — the daily pipeline

```python
# pipeline.py — runs once per day
import csv, json, sqlite3
from pathlib import Path

INPUT = Path("support_tickets.csv")
JSON_OUT = Path("payload.json")
DB = Path("tickets.db")

# 1️⃣ Read CSV → list of clean dicts
clean = []
with INPUT.open(encoding="utf-8") as f:
    for row in csv.DictReader(f):
        if not row.get("customer_id"):
            continue                                     # skip junk
        clean.append({
            "customer_id": row["customer_id"].strip(),
            "category":    row.get("category", "other").lower(),
            "urgency":     int(row.get("urgency", 3)),
            "body":        row.get("body", "").strip(),
        })

# 2️⃣ Write JSON
JSON_OUT.write_text(json.dumps(clean, indent=2), encoding="utf-8")
print(f"Wrote {len(clean)} tickets to {JSON_OUT}")

# 3️⃣ Insert into SQLite
conn = sqlite3.connect(DB)
conn.execute("""CREATE TABLE IF NOT EXISTS tickets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    customer_id TEXT, category TEXT, urgency INTEGER, body TEXT)""")
conn.executemany(
    "INSERT INTO tickets (customer_id, category, urgency, body) VALUES (?, ?, ?, ?)",
    [(t["customer_id"], t["category"], t["urgency"], t["body"]) for t in clean],
)
conn.commit()

# 4️⃣ Verify
n = conn.execute("SELECT COUNT(*) FROM tickets").fetchone()[0]
print(f"DB now has {n} tickets total.")
conn.close()
```

### Why this matters for GenAI
Almost every GenAI app starts the same way: **read documents → clean → store → retrieve**. RAG is literally this pipeline + embeddings.

---

## 🏋️ Exercises

### Exercise 1 — JSON config loader
Write `load_config(path)` that reads a JSON file and returns the dict. If file is missing, raise `FileNotFoundError` with a helpful message.

### Exercise 2 — CSV → SQLite importer
Take any CSV and a table name, and import all rows into a new SQLite table whose columns match the CSV headers.

### Exercise 3 — PDF text extractor
Read a PDF (find any free one online or use a policy PDF you have). Save the full text to `output.txt`. Print the number of pages and approximate word count.

### Exercise 4 — Daily log rotator
Write a script that reads `app.log` line by line and writes each day's lines into separate files (`app-2026-05-27.log`, etc). Assume each line starts with an ISO timestamp.

### Exercise 5 — Pandas analytics
Using the `support_tickets.csv` (create a fake one with 100 rows), compute:
- top 3 categories
- average urgency per category
- number of tickets per day

---

## ✅ Solutions

### Solution 1
```python
import json
from pathlib import Path

def load_config(path: str) -> dict:
    p = Path(path)
    if not p.exists():
        raise FileNotFoundError(f"Config not found: {p.resolve()}")
    return json.loads(p.read_text(encoding="utf-8"))
```

### Solution 2
```python
import csv, sqlite3, sys, re

def import_csv_to_sqlite(csv_path: str, db_path: str, table: str):
    # sanitize table name (only letters/digits/underscore) — SQL injection guard
    if not re.fullmatch(r"\w+", table):
        raise ValueError("Invalid table name")

    with open(csv_path, encoding="utf-8") as f:
        reader = csv.DictReader(f)
        headers = reader.fieldnames
        rows = list(reader)

    conn = sqlite3.connect(db_path)
    cols_ddl = ", ".join(f'"{h}" TEXT' for h in headers)
    conn.execute(f'CREATE TABLE IF NOT EXISTS "{table}" ({cols_ddl})')

    placeholders = ", ".join(["?"] * len(headers))
    conn.executemany(
        f'INSERT INTO "{table}" VALUES ({placeholders})',
        [tuple(r[h] for h in headers) for r in rows],
    )
    conn.commit()
    conn.close()
    print(f"Inserted {len(rows)} rows.")
```

### Solution 3
```python
from pypdf import PdfReader

reader = PdfReader("policy.pdf")
text = "\n".join(p.extract_text() or "" for p in reader.pages)

with open("output.txt", "w", encoding="utf-8") as f:
    f.write(text)

print(f"Pages: {len(reader.pages)}")
print(f"Words: ~{len(text.split())}")
```

### Solution 4
```python
from collections import defaultdict
from pathlib import Path

by_day = defaultdict(list)
with open("app.log", encoding="utf-8") as f:
    for line in f:
        day = line[:10]                      # "YYYY-MM-DD"
        if len(day) == 10 and day[4] == "-":
            by_day[day].append(line)

for day, lines in by_day.items():
    Path(f"app-{day}.log").write_text("".join(lines), encoding="utf-8")
print(f"Created {len(by_day)} files.")
```

### Solution 5
```python
import pandas as pd

df = pd.read_csv("support_tickets.csv", parse_dates=["created_at"])

print("Top categories:")
print(df["category"].value_counts().head(3))

print("\nAvg urgency by category:")
print(df.groupby("category")["urgency"].mean().sort_values(ascending=False))

print("\nTickets per day:")
print(df.groupby(df["created_at"].dt.date).size())
```

---

## 🎯 What you should now be able to do

- [x] Read & write text, CSV, JSON and PDF files
- [x] Use SQLite to store and query data
- [x] Always use parameterised queries (no SQL injection)
- [x] Slice/dice data with pandas

➡️ Next: **[Lesson 3 — Working with APIs](03_Working_with_APIs.md)**
