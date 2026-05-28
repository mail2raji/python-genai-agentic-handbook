# Phase 4 — GitHub Actions

> **Goal:** ship CI/CD that builds, tests, evaluates a RAG service, and deploys to Azure with OIDC — no long-lived secrets.

Companion to Chapter 4 in [BOOK.md](../index.md).

## What you build

`doc-rag` repo with three workflows:

1. `ci.yml` — pytest on Python 3.11 + 3.12, matrix, caching.
2. `eval-nightly.yml` — schedule `0 2 * * *`; runs the eval script; uploads JUnit artifact; posts a summary.
3. `deploy.yml` — OIDC to Azure → `azure/login@v2` → `az containerapp up`.

## 8 hands-on exercises

1. Add `permissions: { contents: read }` and explain why default is unsafe.
2. Add a `concurrency` group keyed on `${{ github.ref }}` so re-pushes cancel old runs.
3. Cache `pip` with `actions/setup-python` + `cache: 'pip'`.
4. Build a matrix `{python: ['3.11','3.12'], os: ['ubuntu-latest','windows-latest']}` with `fail-fast: false`.
5. Use `${{ secrets.X }}` and `${{ vars.Y }}` correctly — and explain the difference.
6. Add an environment `production` with manual approval.
7. Configure OIDC: federated credential for `repo:OWNER/REPO:environment:production`.
8. Write a reusable workflow `wf-eval.yml` consumed by `eval-nightly.yml` via `uses: ./.github/workflows/wf-eval.yml`.

## Quiz answers

See [exercises.md](exercises.md).

## Next

[Phase 5 — Copilot for GenAI](../Chapter18_Copilot_GenAI/index.md).
