# Phase 3 — Intermediate Git

> **Goal:** rebase, cherry-pick, stash, reflog, bisect, filter-repo, pre-commit, submodules, worktrees, LFS — like a senior.

Companion to Chapter 3 in [BOOK.md](../index.md).

## When to use what (decision table)

| Situation | Command |
|---|---|
| Replay my commits onto latest `main` | `git rebase main` |
| Pull a single fix from another branch | `git cherry-pick <sha>` |
| Park dirty work for an emergency hotfix | `git stash push -m "wip"` |
| Find which commit broke a test | `git bisect` |
| Recover from a "lost" reset | `git reflog` |
| Purge a leaked secret from all history | `git filter-repo --replace-text rules.txt` |
| Block bad commits before they happen | `pre-commit` framework |
| Embed a third-party repo without copying | submodules |
| Have two branches checked out at once | `git worktree` |
| Track 200 MB model weights | Git LFS |

## 10 drills

1. Interactive rebase: squash 3 commits, reword the result.
2. Cherry-pick a commit from `release` onto `main` and resolve a conflict.
3. Bisect a failing test (sketch with `git bisect run pytest`).
4. Recover a reset-hard'd commit via reflog.
5. Use `filter-repo` to remove a `secrets.env` file from history.
6. Set up `pre-commit` with `ruff`, `black`, and `gitleaks`.
7. Add a submodule, update it, remove it cleanly.
8. Create a second worktree for a long-running hotfix.
9. Track `.gguf` files with Git LFS.
10. Configure `git rerere` and prove it remembers a resolution.

## Quiz answers

See [exercises.md](exercises.md).

## Next

[Phase 4 — GitHub Actions](../Chapter17_GitHub_Actions/index.md).
