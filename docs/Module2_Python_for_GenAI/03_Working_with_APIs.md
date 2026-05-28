# Module 2 · Lesson 3 — Working with APIs

## 🍭 Imagine this…

A **restaurant** has two parts:
- The **kitchen** (does work).
- The **waiter** (takes your order, brings the food).

You never go into the kitchen. You speak to the waiter.

An **API** (Application Programming Interface) is the **waiter**. You send a polite request like *"please bring me the weather for Bangalore"* and it returns the data. The kitchen (the real server code) stays hidden.

---

## 🧠 The real concept

### The 4 HTTP "verbs"

| Verb | Means | Example |
|---|---|---|
| **GET** | Give me data | Fetch user profile |
| **POST** | Create something | New ticket |
| **PUT / PATCH** | Update something | Change email |
| **DELETE** | Remove something | Cancel an order |

### A REST API request has 5 parts

1. **URL** — `https://api.weather.com/v1/forecast`
2. **Verb** — `GET`
3. **Headers** — metadata, e.g. `Authorization: Bearer <token>`
4. **Query params or body** — the actual request data
5. **Response** — usually **JSON** + a status code

### Status codes everyone should memorize

| Code | Meaning |
|---|---|
| 200 | ✅ OK |
| 201 | ✅ Created |
| 400 | ❌ You sent bad data |
| 401 | ❌ You're not logged in |
| 403 | ❌ You're logged in but not allowed |
| 404 | ❌ Doesn't exist |
| 429 | ❌ Rate-limited — too many requests |
| 500 | ❌ Server is broken |

---

## 🌍 Real-world scenario — Mash-up: GitHub + LLM

You want a script that:
1. Fetches your **public GitHub repos** via the GitHub REST API.
2. Asks an LLM to write a **one-line description** for each repo.
3. Saves the result as a Markdown table to `repos.md`.

This is a real "data pipeline + AI" job.

---

## 💻 The code — talking to ANY REST API

```python
# requests is the de-facto Python HTTP library
import requests

# 1️⃣ Simple GET (public API, no auth)
resp = requests.get("https://api.github.com/users/mail2raji/repos",
                    params={"per_page": 5, "sort": "updated"},   # query string
                    timeout=10)

resp.raise_for_status()         # raise an exception if status was 4xx/5xx
repos = resp.json()             # parse JSON body into Python list/dict

for r in repos:
    print(r["name"], "-", r.get("description") or "(no description)")
```

### What each line does
- `requests.get(url, params=..., timeout=...)` — sends a GET. `params` becomes `?per_page=5&sort=updated`.
- `timeout=10` — *always* set this so a hung server doesn't freeze your script.
- `raise_for_status()` — turns "404 Not Found" into a Python exception you can catch.
- `resp.json()` — converts the JSON string into a Python dict/list.

### POST with a JSON body + auth header

```python
import os, requests

resp = requests.post(
    "https://api.example.com/v1/tickets",
    headers={
        "Authorization": f"Bearer {os.environ['EXAMPLE_TOKEN']}",
        "Content-Type":  "application/json",
    },
    json={"title": "VPN broken", "priority": "high"},   # 'json=' auto-encodes
    timeout=10,
)
print(resp.status_code, resp.json())
```

> 🔒 **Never hard-code tokens.** Always read from `os.environ` or a `.env` file.

---

## 💻 The mash-up script — GitHub + LLM → Markdown

```python
# repo_describer.py
import os, requests
from openai import OpenAI
from dotenv import load_dotenv

load_dotenv()
client = OpenAI()

USERNAME = "mail2raji"      # change to yours

# 1️⃣ Fetch repos
def fetch_repos(user: str, n: int = 10) -> list[dict]:
    resp = requests.get(
        f"https://api.github.com/users/{user}/repos",
        params={"per_page": n, "sort": "updated"},
        headers={"Accept": "application/vnd.github+json"},
        timeout=15,
    )
    resp.raise_for_status()
    return resp.json()

# 2️⃣ Ask the LLM for a 1-line summary
def llm_describe(name: str, language: str, existing_desc: str) -> str:
    prompt = (
        f"Repo name: {name}\n"
        f"Primary language: {language or 'unknown'}\n"
        f"Existing description: {existing_desc or '(none)'}\n\n"
        "Write ONE concise sentence (<= 20 words) describing what this repo likely does."
    )
    resp = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}],
        temperature=0.2,
    )
    return resp.choices[0].message.content.strip()

# 3️⃣ Build a Markdown table
def to_markdown(rows: list[tuple]) -> str:
    out = ["| Repo | Language | AI Description |", "|---|---|---|"]
    for name, lang, desc in rows:
        out.append(f"| {name} | {lang} | {desc} |")
    return "\n".join(out)

# 4️⃣ Glue it together
def main():
    repos = fetch_repos(USERNAME)
    rows = []
    for r in repos:
        desc = llm_describe(r["name"], r.get("language"), r.get("description"))
        rows.append((r["name"], r.get("language") or "-", desc))
        print(f"✓ {r['name']}")

    md = to_markdown(rows)
    with open("repos.md", "w", encoding="utf-8") as f:
        f.write("# My Repos\n\n" + md)
    print("\nSaved → repos.md")

if __name__ == "__main__":
    main()
```

### Step-by-step in toddler-speak
1. **Ask GitHub** for the latest 10 repos (the "waiter brings the menu").
2. **For each repo, ask the LLM** to write a clever one-liner.
3. **Format the result** as a neat table.
4. **Save** it to a Markdown file you can paste anywhere.

---

## 🧠 Robustness checklist for production APIs

| Risk | Fix |
|---|---|
| Network down | `try/except requests.RequestException` |
| 429 rate limit | `time.sleep` + retry, exponential backoff |
| Huge JSON | `resp.iter_content()` streaming |
| Token in URL | Never. Use **Authorization header** |
| HTTPS only | URLs must start with `https://`, never `http://` |

### Retry with backoff (a tiny utility)

```python
import time, random, requests

def http_get_with_retry(url, max_tries=4, **kw):
    for attempt in range(max_tries):
        try:
            resp = requests.get(url, timeout=10, **kw)
            if resp.status_code < 500 and resp.status_code != 429:
                resp.raise_for_status()
                return resp
        except requests.RequestException as e:
            if attempt == max_tries - 1:
                raise
        sleep = (2 ** attempt) + random.random()
        print(f"retry in {sleep:.1f}s…")
        time.sleep(sleep)
```

---

## 🏋️ Exercises

### Exercise 1 — Random joke API
Call `https://official-joke-api.appspot.com/random_joke` and print the setup + punchline.

### Exercise 2 — Weather lookup
Use `https://wttr.in/<city>?format=j1` (no auth) to print today's temperature for a city you choose.

### Exercise 3 — POST a ticket (mock)
Use `https://httpbin.org/post` (echoes whatever you send) to POST a JSON body with `title` and `priority`. Print the echoed body.

### Exercise 4 — LLM + API combo
Use the joke API to fetch a joke and ask GPT-4o-mini to **rate it 1–10** and explain why. Save to `rated_jokes.txt`.

### Exercise 5 — Add retries
Wrap a flaky-ish endpoint (`https://httpbin.org/status/500`) with the retry helper above. Show that it retries 4 times.

### Exercise 6 — Pagination
The GitHub API paginates with `?page=1&per_page=100`. Fetch ALL repos for a user (not just 100). Hint: loop while you keep getting non-empty pages.

---

## ✅ Solutions

### Solution 1
```python
import requests
data = requests.get("https://official-joke-api.appspot.com/random_joke", timeout=10).json()
print(data["setup"], "→", data["punchline"])
```

### Solution 2
```python
import requests
city = "Bangalore"
data = requests.get(f"https://wttr.in/{city}?format=j1", timeout=10).json()
cur = data["current_condition"][0]
print(f"{city}: {cur['temp_C']}°C, {cur['weatherDesc'][0]['value']}")
```

### Solution 3
```python
import requests
body = {"title": "VPN broken", "priority": "high"}
resp = requests.post("https://httpbin.org/post", json=body, timeout=10)
print(resp.json()["json"])         # echoes back our body
```

### Solution 4
```python
import requests
from openai import OpenAI
from dotenv import load_dotenv
load_dotenv()
client = OpenAI()

joke = requests.get("https://official-joke-api.appspot.com/random_joke", timeout=10).json()
joke_text = f"{joke['setup']} — {joke['punchline']}"

prompt = f"Rate this joke from 1-10 and explain why in 2 lines.\n\nJoke: {joke_text}"
review = client.chat.completions.create(
    model="gpt-4o-mini",
    messages=[{"role": "user", "content": prompt}],
).choices[0].message.content

with open("rated_jokes.txt", "a", encoding="utf-8") as f:
    f.write(f"{joke_text}\n→ {review}\n\n")
print(review)
```

### Solution 5
```python
http_get_with_retry("https://httpbin.org/status/500", max_tries=4)
# Watch it sleep 1s, 2s, 4s before raising on the final attempt.
```

### Solution 6
```python
import requests

def all_repos(user: str):
    page, out = 1, []
    while True:
        r = requests.get(
            f"https://api.github.com/users/{user}/repos",
            params={"per_page": 100, "page": page},
            timeout=15,
        )
        r.raise_for_status()
        batch = r.json()
        if not batch:
            return out
        out.extend(batch)
        page += 1

print(len(all_repos("mail2raji")))
```

---

## 🎯 What you should now be able to do

- [x] Call any REST API with GET / POST / PUT / DELETE
- [x] Handle status codes, timeouts, and retries
- [x] Combine an API with an LLM into a useful pipeline
- [x] Paginate through large result sets

➡️ Next: **[Lesson 4 — Working with LLMs](04_Working_with_LLMs.md)**
