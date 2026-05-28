# Phase 10 — Advanced Capstone

> **Goal:** ship five production-grade projects and defend 25 architecture decisions. Engineering muscle, not exam trivia.

Companion to Chapter 10 in [BOOK.md](../index.md).

## The five capstones

| # | Name | What you build |
|---|---|---|
| 1 | **doc-rag** | Multi-tenant RAG service on Azure Container Apps with full CI/CD, evals, GHAS, OIDC. |
| 2 | **AutoTriage** | Issue-opened agent that labels, assigns, milestones via Copilot + GitHub MCP. |
| 3 | **PR-Critic** | Safe PR review bot combining CodeQL + LLM critique posted as a single comment. |
| 4 | **Multi-model evaluator** | Nightly matrix eval across providers; auto-dashboard on Pages; regression alerts. |
| 5 | **GenAI-Skills-Marketplace** | Distributable bundle of prompt files, skill files, chat modes, MCP servers. |

## The 25 architecture exercises

Read them in [BOOK.md §10](../index.md). Sketch a one-page answer for each.

Recommended order:
- Start with **Q1, Q5, Q12, Q21, Q24** — direct extensions of capstone 1.
- Then **Q2, Q7, Q14, Q20** — security/admin focus.
- Save **Q15, Q18, Q19, Q25** — most senior, treat as final exam.

## How to defend a capstone

Use this 5-minute structure in interviews and exam-style scenario questions:

1. **Problem & constraints** (30 s) — what success looks like.
2. **High-level architecture** (60 s) — boxes and arrows.
3. **Critical path data flow** (60 s) — happy path.
4. **Failure & cost** (60 s) — what breaks, what it costs, blast radius.
5. **Security posture** (60 s) — secrets, identity, audit.
6. **Trade-offs you rejected** (30 s) — why not X.

## After Phase 10

You are *engineer-ready*. The exams from here are paperwork.

Return to [README](../index.md).
