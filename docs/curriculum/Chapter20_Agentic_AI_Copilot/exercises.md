# Phase 7 — Quiz answers (Chapter 7)

| Q | Answer |
|---|---|
| 1 | MCP | Model Context Protocol — standard for tool/resource access by LLMs |
| 2 | tools, resources, prompts, sampling | the four primitives an MCP server can expose |
| 3 | `.vscode/mcp.json` | per-workspace MCP config |
| 4 | skills vs prompts | skills auto-invoke by description; prompts user-invoke by name |
| 5 | five agentic patterns | plan-and-execute, tool-use loop, evaluator-optimizer, multi-agent, reflection |
| 6 | approval modes | `request`, `auto-approve safe`, `auto-approve all` (per-tool) |
| 7 | content exclusions | block paths from any Copilot processing |
| 8 | OWASP LLM Top 10 | the canonical risks (prompt injection, insecure tool use, data poisoning, etc.) |
| 9 | sampling | server asks the host to call its LLM (lets server "ask" the model) |
| 10 | dry-run | post intent without doing the action (critical for agentic safety) |

## Security checklist

- Never give an agent write tokens unless required.
- Always cap tool calls per session.
- Always log every tool invocation.
- Test prompt-injection robustness with adversarial inputs.
