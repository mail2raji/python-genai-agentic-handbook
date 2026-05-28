# Phase 0 — Setup

> **Goal:** install Git, GitHub CLI, VS Code, GitHub Copilot, Copilot CLI, and mdBook on Windows / macOS / Linux, then verify each piece end-to-end.

This folder is the **companion** to Chapter 0 in [BOOK.md](../index.md). Read it for orientation; do the drills here.

## What you will install

| Tool | Why |
|---|---|
| Git | Version control engine |
| GitHub CLI (`gh`) | Talk to GitHub from the terminal |
| VS Code | Editor + Copilot host |
| GitHub Copilot extension | AI pair programmer |
| GitHub Copilot CLI (`gh copilot`) | AI for the shell |
| mdBook | Render this handbook into a website |
| Python 3.11+ | For all GenAI capstones |

## 4 drills before moving on

1. `git --version`, `gh --version`, `code --version`, `python --version` — **all four** print versions.
2. `gh auth status` shows you authenticated as your account.
3. `gh copilot explain "git rebase --autosquash"` returns a useful explanation.
4. Open VS Code, sign in to Copilot, ask: *"write a Python function that reverses a string."* The completion appears.

## Exercise answers

See [exercises.md](exercises.md) for the worked answers to Chapter 0's drills.

## Next

Move to [Phase 1 — Git Fundamentals](../Chapter14_Git_Fundamentals/index.md).
