# Phase 5 — GitHub Copilot for GenAI

> **Goal:** master Copilot across all five surfaces — completions, inline chat, side chat, agent mode, and Copilot in PRs — with prompt files, skills, and custom instructions.

Companion to Chapter 5 in [BOOK.md](../index.md).

## Five surfaces

| Surface | Where | When |
|---|---|---|
| Completions | gray ghost text in editor | typing |
| Inline chat | `Ctrl+I` | edit *this code* |
| Side chat | `Ctrl+Alt+I` | ask, plan, explain |
| Agent mode | side chat → mode picker | "make the whole change" |
| PR review | `gh copilot pr-review` / web UI | review a diff |

## Customization stack

| Artifact | Auto-applies? | Filename |
|---|---|---|
| Custom instructions | always | `.github/copilot-instructions.md` |
| Path instructions | per-file via `applyTo:` | `.github/instructions/*.instructions.md` |
| Skill files | via description | `.github/skills/*/SKILL.md` |
| Prompt files | user-invoked `/name` | `.github/prompts/*.prompt.md` |
| Chat modes | user-picked dropdown | `.github/chatmodes/*.chatmode.md` |
| Repo agents file | always | `AGENTS.md` |

## 6 hands-on labs

1. Add a `copilot-instructions.md` setting your stack to FastAPI + pytest + ruff.
2. Add a path-scoped instruction file applying to `infra/**/*.bicep`.
3. Write an `eval-rag.prompt.md` invoked with `/eval-rag` that loads `tests/eval.jsonl` and scores 3 models.
4. Write a `security-review` skill that Copilot auto-invokes on prompts mentioning `secret` or `auth`.
5. Configure a content exclusion for `data/customers/**`.
6. Author one `architect.chatmode.md` with a system prompt and a restricted tool list.

## Quiz answers

See [exercises.md](exercises.md).

## Next

[Phase 6 — Copilot CLI](../Chapter19_Copilot_CLI/index.md).
