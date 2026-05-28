# Shared LLM Client

!!! info "Runnable source file"
    **Path:** `Chapter05_GenAI_Fundamentals/llm_client.py`  
    **Phase:** Phase 4 — GenAI Fundamentals  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/genai-agentic-ai-handbook)) and run it locally.

```python
"""
Shared LLM client used by all Phase 4 & 5 lessons.

Supports 3 modes (auto-detected from environment variables):
  1. OpenAI            (OPENAI_API_KEY)
  2. Azure OpenAI      (AZURE_OPENAI_ENDPOINT, AZURE_OPENAI_API_KEY, AZURE_OPENAI_DEPLOYMENT)
  3. Mock              (no keys set, or MOCK_MODE=1)  — works fully offline

Usage:
    from llm_client import chat, embed
    reply = chat([{"role": "user", "content": "Hi!"}])
"""

from __future__ import annotations
import os
import json
import hashlib
from typing import Iterable

try:
    from dotenv import load_dotenv
    load_dotenv()
except Exception:
    pass


def _mode() -> str:
    if os.getenv("MOCK_MODE") == "1":
        return "mock"
    if os.getenv("AZURE_OPENAI_API_KEY") and os.getenv("AZURE_OPENAI_ENDPOINT"):
        return "azure"
    if os.getenv("OPENAI_API_KEY"):
        return "openai"
    return "mock"


MODE = _mode()
print(f"[llm_client] mode = {MODE}")


# ---------------------- MOCK implementations ---------------------- #
def _mock_chat(messages: list[dict], **kwargs) -> str:
    last_user = next(
        (m["content"] for m in reversed(messages) if m["role"] == "user"),
        "",
    )
    # tiny rule-based "intelligence" for predictable demos
    if "json" in str(kwargs).lower() or "json" in last_user.lower():
        return '{"summary": "mock summary", "topics": ["a", "b"]}'
    if "summari" in last_user.lower():
        return "[MOCK SUMMARY] This appears to be about: " + last_user[:60]
    if "translate" in last_user.lower():
        return "[MOCK TRANSLATION] " + last_user
    return f"[MOCK REPLY] You said: {last_user[:80]}"


def _mock_embed(text: str, dims: int = 64) -> list[float]:
    """Deterministic pseudo-embedding from a hash. Good enough to demo cosine similarity."""
    import math
    h = hashlib.sha256(text.encode("utf-8")).digest()
    vec = [((b / 255.0) * 2 - 1) for b in h[:dims]]
    # normalize to unit length
    norm = math.sqrt(sum(v * v for v in vec)) or 1.0
    return [v / norm for v in vec]


# ---------------------- Real client setup ---------------------- #
_client = None
_model_chat = None
_model_embed = None

if MODE == "openai":
    from openai import OpenAI
    _client = OpenAI()
    _model_chat  = os.getenv("OPENAI_MODEL", "gpt-4o-mini")
    _model_embed = os.getenv("OPENAI_EMBED_MODEL", "text-embedding-3-small")
elif MODE == "azure":
    from openai import AzureOpenAI
    _client = AzureOpenAI(
        api_key=os.getenv("AZURE_OPENAI_API_KEY"),
        api_version=os.getenv("AZURE_OPENAI_API_VERSION", "2024-10-21"),
        azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"),
    )
    _model_chat  = os.getenv("AZURE_OPENAI_DEPLOYMENT", "gpt-4o-mini")
    _model_embed = os.getenv("AZURE_OPENAI_EMBED_DEPLOYMENT", "text-embedding-3-small")


# ---------------------- Public API ---------------------- #
def chat(
    messages: list[dict],
    temperature: float = 0.7,
    max_tokens: int = 600,
    response_format: dict | None = None,
) -> str:
    """Run a chat completion and return the assistant's text."""
    if MODE == "mock":
        return _mock_chat(messages, response_format=response_format)
    kwargs = {
        "model": _model_chat,
        "messages": messages,
        "temperature": temperature,
        "max_tokens": max_tokens,
    }
    if response_format:
        kwargs["response_format"] = response_format
    resp = _client.chat.completions.create(**kwargs)
    return resp.choices[0].message.content or ""


def chat_stream(messages: list[dict], temperature: float = 0.7) -> Iterable[str]:
    """Yield chunks of the assistant's reply."""
    if MODE == "mock":
        full = _mock_chat(messages)
        for word in full.split(" "):
            yield word + " "
        return
    stream = _client.chat.completions.create(
        model=_model_chat,
        messages=messages,
        temperature=temperature,
        stream=True,
    )
    for chunk in stream:
        delta = chunk.choices[0].delta
        if delta and delta.content:
            yield delta.content


def embed(text: str) -> list[float]:
    """Return an embedding vector for the input text."""
    if MODE == "mock":
        return _mock_embed(text)
    resp = _client.embeddings.create(model=_model_embed, input=text)
    return resp.data[0].embedding


def embed_many(texts: list[str]) -> list[list[float]]:
    if MODE == "mock":
        return [_mock_embed(t) for t in texts]
    resp = _client.embeddings.create(model=_model_embed, input=texts)
    return [d.embedding for d in resp.data]


if __name__ == "__main__":
    print("Quick test:")
    print(chat([{"role": "user", "content": "Say hi in one short line."}]))
    print("Embed length:", len(embed("hello world")))

```
