# Phase 7 — Agentic AI with Copilot + MCP

> **Goal:** turn Copilot into an *agent* — chain plan → tool → observe → next step — via the Model Context Protocol (MCP), prompt files, skills, and chat modes.

Companion to Chapter 7 in [BOOK.md](../index.md).

## What is MCP?

> An open protocol for an LLM to discover and call *tools* (functions), read *resources* (files/data), and use *sampling* (inner LLM calls). One server can be consumed by Copilot, Claude, ChatGPT, or your own agent.

## 5 agentic patterns

1. **Plan-and-execute** — agent plans, then runs each step (best for sequential).
2. **Tool-use loop** — call a tool, observe, decide next (general-purpose).
3. **Evaluator-optimizer** — one model writes, another scores, looped.
4. **Multi-agent orchestrator** — a router agent dispatches to specialists.
5. **Reflection** — agent critiques its own output before returning.

## Build your first MCP server

`mcp-servers/genai-eval/` — a Python MCP server exposing `eval_rag(question, expected_keywords)` as a tool.

`.vscode/mcp.json`:

```json
{
  "servers": {
    "genai-eval": {
      "command": "python",
      "args": ["mcp-servers/genai-eval/server.py"]
    },
    "github": {
      "command": "docker",
      "args": ["run","-i","--rm","-e","GITHUB_PERSONAL_ACCESS_TOKEN","ghcr.io/github/github-mcp-server"]
    }
  }
}
```

## 6 exercises

1. Configure 3 MCP servers: `github`, `filesystem`, `genai-eval`.
2. Build a tool `summarize_pr(pr_number)` that uses GitHub MCP + an LLM.
3. Build a skill `incident-rca` and verify Copilot auto-invokes it on "RCA" prompts.
4. Build a chat mode `architect.chatmode.md` restricted to read-only tools.
5. Compose an evaluator-optimizer prompt file (`/optimize`) that loops up to 3 times.
6. Add a dry-run mode flag your agent honors.

## Quiz answers

See [exercises.md](exercises.md).

## Next

[Phase 8 — GHAS + Admin](../Chapter21_GHAS_Admin_Security/index.md).
