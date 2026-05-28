# Phase 9 — Git Fundamentals

> **Goal:** be unbreakable at solo Git workflows — init, commit, branch, merge, undo — using the "three trees" model.

!!! tip "The Lab Pack is where the real learning happens"
    Jump straight to **[🧪 Phase 9 Lab Pack](exercises.md)** — 12 scenario-driven labs + a 60-minute capstone, every command explained line-by-line.

---

## Mental model — the three trees

```text
working dir   <--  git checkout/restore  --  staging  <-- git reset --  HEAD (last commit)
working dir   --  git add  -->  staging   --  git commit  -->  HEAD
```

Memorize these three states. Every Git command moves a file between them.

## 🧭 What you'll master (12 labs)

| # | Skill | One-liner |
|---|---|---|
| 1 | Bootstrap | `git init` a `rag-notes` repo with sane defaults |
| 2 | Selective staging | Split one messy edit into two clean commits with `git add -p` |
| 3 | Rename without losing history | `git mv` + `git log --follow` |
| 4 | Feature branches | `git switch -c`, fast-forward vs `--no-ff` |
| 5 | Real merge conflicts | Force one, then resolve like a pro |
| 6 | Stash | Park work for a hotfix, then resume |
| 7 | Amend vs Revert | Local fix vs published-history fix |
| 8 | `git reflog` rescue | Recover a "lost" commit after `reset --hard` |
| 9 | Python+AI `.gitignore` | Ignore `__pycache__`, `.env`, vector DBs, models |
| 10 | Semantic tags | `git tag -a v0.1.0` with SemVer rules |
| 11 | Cherry-pick | Backport one hotfix across branches |
| 12 | Interactive rebase | Squash 5 WIP commits into 1 reviewable commit |
| 🏁 | **Capstone** | A simulated week-in-the-life: bootstrap → feature → interruption → conflict → release |

## Next

➡️ Start the **[🧪 Lab Pack](exercises.md)**.

Then continue to **[Phase 10 — GitHub Basics](../Chapter15_GitHub_Basics/index.md)**.

