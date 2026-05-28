# Lesson 6 — Apis Requests

!!! info "Runnable source file"
    **Path:** `Chapter02_Intermediate_Python/06_apis_requests.py`  
    **Phase:** Phase 2 — Intermediate Python  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/genai-agentic-ai-handbook)) and run it locally.

```python
"""
Lesson 6: Working with APIs (requests)
========================================

📖 CONCEPT:
APIs let your program talk to web services — OpenAI, Azure, weather services, etc.
The `requests` library is the standard tool for HTTP calls in Python.

💡 ANALOGY:
An API is a restaurant waiter — you (the client) hand them an order (request),
they bring back food (response).

📦 INSTALL:  pip install requests
"""

import requests

# --- A real, free, no-auth API for practice ---
URL = "https://api.coindesk.com/v1/bpi/currentprice.json"

# Some networks block the default URL; use jsonplaceholder as a fallback example
URL = "https://jsonplaceholder.typicode.com/posts/1"

try:
    response = requests.get(URL, timeout=10)
    response.raise_for_status()          # raises if 4xx/5xx
    data = response.json()               # parse JSON to a dict
    print("Status:", response.status_code)
    print("Title:", data.get("title"))
    print("Body:", data.get("body")[:60], "...")
except requests.exceptions.RequestException as e:
    print("❌ API call failed:", e)


# --- POST request (sending data) ---
new_post = {
    "title": "Learning GenAI",
    "body":  "Today I learned how to call APIs from Python.",
    "userId": 1,
}

resp = requests.post(
    "https://jsonplaceholder.typicode.com/posts",
    json=new_post,                        # auto-converts dict → JSON
    timeout=10,
)
print("\nCreated post id:", resp.json().get("id"))


# --- Headers (used for API keys later) ---
headers = {
    "Authorization": "Bearer FAKE_TOKEN_FOR_DEMO",
    "Content-Type":  "application/json",
}

# This is the SAME shape you'll use for OpenAI / Azure OpenAI:
#   headers = {"Authorization": f"Bearer {OPENAI_API_KEY}"}
#   requests.post("https://api.openai.com/v1/chat/completions",
#                 headers=headers, json={...})


# --- Wrap an API call into a clean function ---
def fetch_post(post_id: int) -> dict:
    """Fetch a post by ID. Returns {} on failure."""
    try:
        r = requests.get(
            f"https://jsonplaceholder.typicode.com/posts/{post_id}",
            timeout=10,
        )
        r.raise_for_status()
        return r.json()
    except requests.exceptions.RequestException as e:
        print(f"Error fetching post {post_id}: {e}")
        return {}


post = fetch_post(2)
print("\nFetched post 2 title:", post.get("title"))


# ============================================================
# ✏️ EXERCISE:
# Write a function `get_random_user()` that calls
# https://randomuser.me/api/ and returns the first result's
# "name.first" and "email" as a dict.
# (Tip: drill into response.json()["results"][0]["name"]["first"])
# ============================================================

```
