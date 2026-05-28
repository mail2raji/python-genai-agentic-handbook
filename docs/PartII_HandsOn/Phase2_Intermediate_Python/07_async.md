# Lesson 7 — Async

!!! info "Runnable source file"
    **Path:** `Phase2_Intermediate_Python/07_async.py`  
    **Phase:** Phase 2 — Intermediate Python  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/python-genai-agentic-handbook)) and run it locally.

```python
"""
Lesson 7: Async & Await
========================

📖 CONCEPT:
Async lets you start a task (like an API call) and do other work
while waiting. Critical for agents that call multiple LLMs/tools in parallel.

💡 ANALOGY:
A chef cooking 3 dishes at once vs cooking each one to completion before starting the next.
That's async vs synchronous code.
"""

import asyncio
import time


# --- Synchronous (blocking) version ---
def fetch_sync(name, delay):
    print(f"Start {name}")
    time.sleep(delay)               # pretend this is an API call
    print(f"Done {name}")
    return f"result-{name}"

def run_sync():
    start = time.perf_counter()
    fetch_sync("A", 1)
    fetch_sync("B", 1)
    fetch_sync("C", 1)
    print(f"SYNC total: {time.perf_counter() - start:.2f}s")  # ~3s


# --- Async (non-blocking) version ---
async def fetch_async(name, delay):
    print(f"Start {name}")
    await asyncio.sleep(delay)       # await = "pause here, let others run"
    print(f"Done {name}")
    return f"result-{name}"

async def run_async():
    start = time.perf_counter()
    # gather() runs them concurrently
    results = await asyncio.gather(
        fetch_async("A", 1),
        fetch_async("B", 1),
        fetch_async("C", 1),
    )
    print("Results:", results)
    print(f"ASYNC total: {time.perf_counter() - start:.2f}s")  # ~1s


if __name__ == "__main__":
    print("--- Synchronous ---")
    run_sync()
    print("\n--- Asynchronous ---")
    asyncio.run(run_async())


# ============================================================
# 🧠 WHEN YOU'LL USE THIS:
# - Calling multiple LLMs in parallel
# - Fetching many documents at once for RAG
# - Multi-agent systems where agents work concurrently
# ============================================================

```
