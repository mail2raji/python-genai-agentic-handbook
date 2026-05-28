# Phase 3 — Quiz answers (Chapter 3)

| Q | Answer |
|---|---|
| 1 | rebase | linear history; never on shared branches |
| 2 | merge | preserves topology; safe default |
| 3 | cherry-pick | copies *one* commit onto current HEAD |
| 4 | stash | shelve uncommitted work without losing it |
| 5 | reflog | local log of every HEAD move (kept ~90 days by default) |
| 6 | bisect | binary search a regression across commits |
| 7 | filter-repo | rewrite history (e.g. purge secrets); replaces filter-branch |
| 8 | submodule | pin to a commit of another repo |
| 9 | worktree | a second checkout of the same repo |
| 10 | LFS | offload large binaries to a separate store via pointers |

## Recover patterns

```text
"I lost my commit"           -> git reflog -> git reset --hard <reflog-sha>
"I broke history on push"   -> git push --force-with-lease (only if you own the branch)
"Conflict mid-rebase"       -> fix; git add; git rebase --continue
"Botched rebase"            -> git rebase --abort
"Botched merge"             -> git merge --abort
```
