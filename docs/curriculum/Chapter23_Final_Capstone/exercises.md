# Phase 10 — Architecture-question playbook

Each of the 25 questions deserves a one-page answer with:

1. **Diagram** (mermaid or ascii).
2. **Decisions** (3–5 bullet points).
3. **Trade-offs** (what you rejected and why).
4. **Risks** (top 3 and mitigations).

Below are *seed* answers for the first five — finish the rest yourself as the final mastery test.

---

## Q1 — CI eval that runs only on `prompts/**` changes

**Decision:** use `on: pull_request` with `paths: [ "prompts/**" ]`. Long-running eval workflow is **never** triggered on README typos. Use a tiny `quickcheck.yml` (lint + unit tests) for everything else.

```yaml
on:
  pull_request:
    paths: ['prompts/**']
```

**Trade-offs:** miss eval if someone re-arranges directory layout; mitigate with a path-filter on `tests/eval/**` too.

---

## Q2 — Leaked `OPENAI_API_KEY` rotate-and-rewrite

1. Rotate the key at OpenAI **immediately** — invalidate old token.
2. Add to secret scanning custom pattern; turn on push protection.
3. `git filter-repo --replace-text rules.txt` (with the key as one rule).
4. Force-push with `--force-with-lease` after team coordination.
5. Audit log: filter for any external use of the key (Postman logs, CI logs, App Insights traces).
6. Post-incident: document, run a tabletop, mandate `direnv` + pre-commit gitleaks for the team.

---

## Q3 — GPU runners for A100 training

- **Self-hosted** behind a private VNet for cost + GPU pinning.
- Use ephemeral runners spun via ARC (Actions Runner Controller) on AKS.
- Isolate jobs with `runs-on: [self-hosted, gpu, a100]`.
- Disable for fork PRs to avoid abuse.

---

## Q4 — Copilot review respecting content exclusions

- Add `data/customers/**` to org-level content exclusions.
- Copilot will refuse to suggest in those files.
- Infra (`infra/**`) is still reviewable.
- Add `CODEOWNERS` entries so `data/**` PRs require security team approval.

---

## Q5 — Codespace template for langchain + qdrant

- Custom prebuild image: `ghcr.io/mail2raji/devcontainer-genai:latest` containing Python 3.12, uv, qdrant client, langchain.
- `.devcontainer/devcontainer.json` with `postCreateCommand: uv sync` and forwarded ports 6333, 8000.
- Codespace secrets: `OPENAI_API_KEY` (org-level), `QDRANT_URL` (per-user).
- Prebuilds nightly to keep startup under 30 s.

---

## ...and 20 more

Continue Q6–Q25 in your own notebook. Treat each as a 15-minute design exercise; review with Copilot agent mode and have it critique.
