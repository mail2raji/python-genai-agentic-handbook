# Phase 6 — Quiz answers (Chapter 6)

| Q | Answer |
|---|---|
| 1 | `gh extension install github/gh-copilot` | install the CLI |
| 2 | `suggest`, `explain` | the two main verbs |
| 3 | `--target shell\|git\|gh` | target mode of suggestion |
| 4 | `gh copilot alias` | persist a suggested command as a shell alias |
| 5 | `gh copilot config` | set default target, hostname, etc. |

## Trick

Use `--shell pwsh` on Windows so the produced commands respect PowerShell syntax (`$env:`, `Get-ChildItem`, etc.) instead of Bash.
