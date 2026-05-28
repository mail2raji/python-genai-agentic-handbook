# Phase 6 — GitHub Copilot CLI

> **Goal:** use `gh copilot suggest` and `gh copilot explain` to make the terminal a productivity multiplier for GenAI / Agentic AI work.

Companion to Chapter 6 in [BOOK.md](../index.md).

## Install

```powershell
gh extension install github/gh-copilot
gh copilot config        # set default target = shell|git|gh
```

## Top-30 cookbook prompts

A non-exhaustive list of useful `gh copilot suggest` prompts for AI/ML work — see Chapter 6 §6.7 in [BOOK.md](../index.md) for the full list with expected commands.

1. *"create a Python venv, install langchain, chroma, openai"*
2. *"download all PDFs from this url list into ./data"*
3. *"split text files into 800-token chunks with 100 overlap"*
4. *"embed chunks with text-embedding-3-small and write to a parquet file"*
5. *"start qdrant via docker on port 6333"*
6. *"upsert vectors from parquet into a qdrant collection 'docs'"*
7. *"query qdrant for top-5 results"*
8. *"create a FastAPI app with /query and /healthz"*
9. *"build a multi-arch docker image and push to ghcr.io"*
10. *"deploy this container to azure container apps"*
11. *"run the eval.py across 3 models in parallel"*
12. *"summarize today's git log into release notes"*
13. *"find files larger than 100MB and add them to .gitattributes for LFS"*
14. *"redact email addresses from this csv"*
15. *"build a JSONL of (prompt, answer) from this CSV"*
16. *"start an ollama llama3 model and chat with it"*
17. *"compare two parquet files schema-wise"*
18. *"download a HuggingFace dataset 'squad' to ./data/squad"*
19. *"convert a JSONL to a parquet file with pandas"*
20. *"run pytest with coverage and open the html report"*

## 4 alias drills

| Goal | One-liner |
|---|---|
| Create eval shortcut | `gh copilot alias --shell pwsh -- "eval" "uv run python eval.py"` |
| RAG query | `gh copilot alias --shell pwsh -- "ragq" "curl http://localhost:8000/query?q="` |
| Open repo in browser | `gh copilot alias --shell pwsh -- "rweb" "gh repo view --web"` |
| List runs of a workflow | `gh copilot alias --shell pwsh -- "runs" "gh run list -w ci.yml"` |

## Quiz answers

See [exercises.md](exercises.md).

## Next

[Phase 7 — Agentic AI with Copilot / MCP](../Chapter20_Agentic_AI_Copilot/index.md).
