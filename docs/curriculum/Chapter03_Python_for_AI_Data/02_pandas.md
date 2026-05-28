# Lesson 2 — Pandas

!!! info "Runnable source file"
    **Path:** `Chapter03_Python_for_AI_Data/02_pandas.py`  
    **Phase:** Phase 3 — Python for AI & Data  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/genai-agentic-ai-handbook)) and run it locally.

```python
"""
Lesson 2: Pandas — Loading & Cleaning Data
============================================

📖 CONCEPT:
Pandas is "Excel for Python". A DataFrame is a 2D table with named columns.
You'll use it to load CSVs, clean text, prepare data for embedding, etc.

💡 ANALOGY:
A DataFrame is a smart spreadsheet that you can slice, filter, and transform with code.

📦 INSTALL:  pip install pandas
"""

import pandas as pd
import os

# --- Create a DataFrame ---
data = {
    "ticket_id":   ["INC-1", "INC-2", "INC-3", "INC-4"],
    "priority":    ["high", "low", "critical", "medium"],
    "description": [
        "VPN disconnects",
        "Printer offline",
        "Production database down",
        "Slow email delivery",
    ],
    "assigned_to": ["team-net", "team-end", "team-db", "team-mail"],
}
df = pd.DataFrame(data)
print(df)


# --- Inspect ---
print("\nShape:", df.shape)            # (rows, cols)
print("\nColumns:", df.columns.tolist())
print("\nFirst 2 rows:\n", df.head(2))
print("\nDescribe (numeric only):\n", df.describe(include="all"))


# --- Selecting ---
print("\nOne column:\n", df["priority"])
print("\nTwo columns:\n", df[["ticket_id", "priority"]])
print("\nRow by index:\n", df.iloc[0])
print("\nRow by condition:\n", df[df["priority"] == "critical"])


# --- Adding columns ---
df["urgency_score"] = df["priority"].map({
    "critical": 4, "high": 3, "medium": 2, "low": 1,
})
print("\nWith urgency score:\n", df)


# --- Sorting ---
print("\nSorted by urgency:\n", df.sort_values("urgency_score", ascending=False))


# --- Grouping ---
print("\nCount per team:\n", df.groupby("assigned_to").size())


# --- Save & load CSV ---
HERE = os.path.dirname(os.path.abspath(__file__))
csv_path = os.path.join(HERE, "tickets.csv")
df.to_csv(csv_path, index=False)
print(f"\n✅ Saved to {csv_path}")

# Load it back
df2 = pd.read_csv(csv_path)
print("\nLoaded back:\n", df2)


# --- Missing data handling (essential for real datasets) ---
df_dirty = pd.DataFrame({
    "name":  ["Priya", "Ravi", None, "Sara"],
    "email": ["p@x.com", None, "x@x.com", "s@x.com"],
})
print("\nDirty data:\n", df_dirty)
print("\nMissing counts:\n", df_dirty.isna().sum())

df_clean = df_dirty.dropna()              # drop rows with any NaN
print("\nAfter dropna:\n", df_clean)

df_filled = df_dirty.fillna("UNKNOWN")    # or fill with default
print("\nAfter fillna:\n", df_filled)


# ============================================================
# ✏️ EXERCISE — uses your real workspace data:
# 1. Load `c:/Scripts/Send-escalationEmail/SPN_ExpiryReport.csv`
# 2. Print its shape and columns.
# 3. If it has an "expiry" or "daysLeft" column, find rows expiring within 30 days.
# ============================================================

```
