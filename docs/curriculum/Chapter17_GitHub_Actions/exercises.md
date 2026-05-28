# Phase 4 — Quiz answers (Chapter 4)

| Q | Answer |
|---|---|
| 1 | `.github/workflows/*.yml` | location of workflow files |
| 2 | `on:` | triggers |
| 3 | `runs-on:` | runner OS / label |
| 4 | `jobs:` | parallel by default; `needs:` adds dependencies |
| 5 | `steps:` | sequential within a job |
| 6 | secrets vs vars | secrets are encrypted, vars are plaintext, both per-repo/env/org |
| 7 | matrix | run the same job over a grid; `fail-fast: false` continues siblings |
| 8 | reusable workflow | called via `uses: org/repo/.github/workflows/x.yml@ref` |
| 9 | composite action | step bundle in `action.yml` (`runs.using: composite`) |
| 10 | OIDC | request short-lived federated token; replaces stored cloud creds |

## Key gotchas

- **`permissions:`** — default is too broad; set least privilege.
- **`pull_request_target`** — runs with base secrets; never check out PR code with it.
- **`set-output` is deprecated** — write to `$GITHUB_OUTPUT` instead.
- **Don't echo secrets** — Actions masks them, but `printenv` can leak.
