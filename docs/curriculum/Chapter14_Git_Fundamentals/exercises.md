# Phase 9 — Git Fundamentals · 🧪 Lab Pack

> **Mission:** Make Git muscle-memory. By the end of this lab pack you will have rescued a "lost" commit,
> resolved a real conflict, cherry-picked a hotfix, and shipped a clean PR — all from the terminal.

!!! abstract "How this lab pack works"
    Each lab follows the same beat:

    1. **🌍 Scenario** — the real-world situation that triggers the workflow
    2. **🎯 Why this matters** — what skill you build and where you'll need it
    3. **🧰 Setup** — exactly what you need
    4. **▶️ Steps** — every command, line-by-line, *with annotations*
    5. **✅ Expected output** — what success looks like
    6. **🧠 Use case in the wild** — real teams that use this exact flow
    7. **⚠️ Gotchas** — what bites beginners

    All labs run **offline** — no GitHub account required for Phase 9 (we use the local `.git` folder).

---

## 🧭 Lab roadmap

| # | Lab | Difficulty | Time | What you'll do |
|---|-----|:---:|:---:|---|
| 1 | [Bootstrap a `rag-notes` repo](#lab-1-bootstrap-the-rag-notes-repo) | ⭐ | 10 min | `git init`, first commit, `.gitignore` |
| 2 | [Selective staging with `git add -p`](#lab-2-selective-staging-with-git-add-p) | ⭐⭐ | 15 min | Split one messy edit into two clean commits |
| 3 | [Rename files **without losing history**](#lab-3-rename-files-without-losing-history) | ⭐⭐ | 10 min | `git mv` + `--follow` |
| 4 | [Feature branch + clean merge](#lab-4-feature-branch-clean-merge) | ⭐⭐ | 15 min | `git switch -c`, fast-forward vs `--no-ff` |
| 5 | [Resolve a real merge conflict](#lab-5-resolve-a-real-merge-conflict) | ⭐⭐⭐ | 20 min | Edit both branches, resolve, finish merge |
| 6 | [Stash during an interruption](#lab-6-stash-during-an-interruption) | ⭐⭐ | 10 min | Park work for a hotfix, then resume |
| 7 | [`commit --amend` vs `revert`](#lab-7-amend-vs-revert-when-to-use-each) | ⭐⭐ | 15 min | Fix a typo locally vs undo a shipped bug |
| 8 | [Rescue with `git reflog`](#lab-8-rescue-with-git-reflog) | ⭐⭐⭐ | 15 min | Recover after a `reset --hard` disaster |
| 9 | [The perfect Python+AI `.gitignore`](#lab-9-the-perfect-pythonai-gitignore) | ⭐ | 10 min | Ignore `__pycache__`, `.env`, vector DBs, models |
| 10 | [Tag a semantic release](#lab-10-tag-a-semantic-release-v010) | ⭐⭐ | 10 min | `git tag -a v0.1.0` with release notes |
| 11 | [Cherry-pick a hotfix](#lab-11-cherry-pick-a-hotfix-across-branches) | ⭐⭐⭐ | 15 min | Apply one commit from branch A onto branch B |
| 12 | [Clean history with interactive rebase](#lab-12-clean-history-with-interactive-rebase) | ⭐⭐⭐⭐ | 25 min | Squash 5 WIP commits into 1 reviewable commit |
| 🏁 | [**Capstone — a week in the life of a Git user**](#capstone-a-week-in-the-life-of-a-git-user) | ⭐⭐⭐⭐ | 60 min | All 12 skills in one realistic flow |

---

## 🪜 Mental model — the **three trees**

Before any lab, anchor this picture in your head. **Every Git command just moves a file between these three places.**

```text
   ┌─────────────────┐    git add     ┌─────────────────┐   git commit    ┌─────────────────┐
   │   working dir   │  ─────────────▶│     staging     │ ──────────────▶ │  HEAD (history) │
   │  (your editor)  │                │  (next commit)  │                 │ (committed code)│
   └─────────────────┘  ◀─────────────└─────────────────┘ ◀──────────────└─────────────────┘
                       git restore                       git reset
```

| Command | Direction | What it does |
|---|---|---|
| `git add file` | Working → Staging | Marks the change to be in the next commit |
| `git commit` | Staging → HEAD | Records a snapshot |
| `git restore --staged file` | Staging → Working | Un-stages (keeps edits) |
| `git restore file` | HEAD → Working | Throws away edits ⚠️ |
| `git reset --hard <sha>` | HEAD jumps, others wiped | Time-travel (destructive) |

!!! tip "Memorise this picture"
    99% of Git confusion comes from not knowing **which tree a file is in**. When in doubt, run `git status` — it will literally tell you ("Changes staged for commit", "Changes not staged", "Untracked").

---

## Lab 1 — Bootstrap the `rag-notes` repo

!!! example "🌍 Scenario"
    You're starting a personal **RAG knowledge base** — a folder where you'll dump
    notes, code snippets and embeddings for a future "ask my notes" agent.
    Before writing a single line of Python you want it under version control.

**🎯 Why this matters:** *Every* project should start with `git init` before line 1. It is
free, and it is the only way to undo mistakes.

### ▶️ Steps

```bash
mkdir rag-notes && cd rag-notes          # (1) create the project folder

git init -b main                         # (2) initialise repo with `main` as the default branch
                                         #     -b main avoids the legacy "master" name

git config user.name  "Your Name"        # (3) tell Git who you are — only needs to be done once
git config user.email "you@example.com"  #     (use --global to set for every repo)

echo "# rag-notes" > README.md           # (4) create a tiny README
echo "*.env"        >  .gitignore        # (5) start a .gitignore (we'll expand it in Lab 9)
echo "__pycache__/" >> .gitignore

git status                               # (6) confirm Git sees 2 untracked files

git add README.md .gitignore             # (7) move both files into staging
git commit -m "chore: initial commit"    # (8) snapshot — your repo now has 1 commit

git log --oneline                        # (9) verify
```

### ✅ Expected output (last command)

```text
abc1234 (HEAD -> main) chore: initial commit
```

### 🧠 Use case in the wild

- **Solo dev on a weekend prototype:** `git init` lets you experiment fearlessly — every wrong turn is reversible.
- **Onboarding a new microservice:** even private team repos start with these exact 9 commands.
- **Conventional commits:** the `chore:` prefix is a [Conventional Commits](https://www.conventionalcommits.org/) marker — tools like `release-please` read these to auto-generate changelogs.

### ⚠️ Gotchas

- Forgetting `git config user.email` ⇒ your commit author shows up as `(none)` on GitHub.
- Running `git init` *inside* an already-init'd folder is harmless but creates surprise nested repos if you're inside a sub-folder by accident. Run `git rev-parse --show-toplevel` to confirm where the repo root is.

---

## Lab 2 — Selective staging with `git add -p`

!!! example "🌍 Scenario"
    You opened `chat.py` to fix a **bug** — but along the way you also reformatted some imports and updated a comment.
    Your reviewer hates noisy PRs. You want **two clean commits**:
    one labelled `fix: …` and one labelled `style: …`.

**🎯 Why this matters:** Clean history makes `git blame`, `git bisect`, and code review 10× faster.

### ▶️ Steps

```bash
# starting state: chat.py has 2 unrelated change-types in one file
git status                          # shows: modified: chat.py

git add -p chat.py                  # (1) interactive patch mode
                                    #     Git walks every "hunk" and asks:
                                    #       y = stage this hunk
                                    #       n = skip
                                    #       s = split into smaller hunks
                                    #       q = quit
                                    #     Stage only the bug-fix hunks → press y / n appropriately.

git status                          # (2) you'll see chat.py in BOTH staged + unstaged
                                    #     because half the file is in staging, half still in working dir.

git commit -m "fix: handle empty user message"  # (3) commit just the fix

git add chat.py                     # (4) stage the rest (the cosmetic edits)
git commit -m "style: regroup imports"          # (5) second clean commit

git log --oneline -2                # (6) verify two distinct commits
```

### 🧠 Use case in the wild

- **PR hygiene on a team repo:** one PR = one concern. Reviewers can read 50 lines, not 500.
- **Backporting:** later you may want to cherry-pick *just* the fix to a release branch — Lab 11 shows how. That's only possible if it's a standalone commit.

### ⚠️ Gotchas

- `git add -p` doesn't work on **untracked** files. Run `git add -N newfile.py` first to "intend to add" so patch mode sees it.
- If you make a mistake mid-patch, press `q` (quit) — staging up to that point is preserved, you can re-run.

---

## Lab 3 — Rename files **without losing history**

!!! example "🌍 Scenario"
    Your `notes.md` is growing huge. You want to move it to `docs/chapter1.md` —
    but you also want `git log` to **follow** that file through the rename so future you
    can still see who wrote a line 6 months ago.

### ▶️ Steps

```bash
mkdir -p docs                                  # (1) create the destination folder
git mv notes.md docs/chapter1.md               # (2) Git does the rename AND stages it in one step
git commit -m "refactor: move notes -> docs/chapter1.md"

git log --follow docs/chapter1.md              # (3) --follow walks back across the rename
                                               #     and shows commits from BEFORE the move too
```

### 🧠 Use case in the wild

- **Repo restructuring:** monorepos rename packages every quarter. `git mv` + `--follow` preserves blame.
- **Refactoring large modules:** moving `utils.py` → `core/utils/strings.py` and keeping author history makes code review easier.

### ⚠️ Gotchas

- If you do `mv notes.md docs/chapter1.md` (plain shell `mv`) Git sees a **delete + create** — history is broken unless similarity detection kicks in (`-M` flag). Always prefer `git mv`.

---

## Lab 4 — Feature branch + clean merge

!!! example "🌍 Scenario"
    You're about to add an **embedding helper** (`embed.py`) to `rag-notes`.
    You don't want half-broken code on `main`, so you isolate it on a branch
    and merge only when green.

### ▶️ Steps

=== "Fast-forward merge (default)"

    ```bash
    git switch -c feat/embedding                # (1) create + switch to new branch
    # ... write embed.py ...
    git add embed.py
    git commit -m "feat: add OpenAI embedding helper"

    git switch main                             # (2) back to main
    git merge feat/embedding                    # (3) main pointer jumps forward — no merge commit
                                                #     This is called a "fast-forward" merge
    git log --oneline --graph
    ```

=== "Force a merge commit (preserves the branch)"

    ```bash
    git switch -c feat/embedding
    # ... commits ...
    git switch main
    git merge --no-ff feat/embedding \
      -m "Merge feat/embedding into main"       # --no-ff = always create a merge commit
                                                # Useful when you want to SEE the branch in git log --graph
    git log --oneline --graph
    ```

### 🧠 Use case in the wild

- **Solo dev:** fast-forward keeps history linear and easy to read.
- **Team repo:** most teams use `--no-ff` (or squash-merge from a PR — see Phase 10) so the branch boundary is visible in history.

### ⚠️ Gotchas

- `git checkout -b feat/x` works too, but the **modern** verb is `git switch -c feat/x` (Git 2.23+). It separates "switch branches" from "restore files" — fewer accidents.

---

## Lab 5 — Resolve a real merge conflict

!!! example "🌍 Scenario"
    Two of you (yes, **you** playing both sides) edited the **same line** of `README.md` on two different branches.
    Git can't decide which version wins. Time to resolve a conflict the right way.

### ▶️ Setup

```bash
echo "Welcome to rag-notes (v0)" > README.md
git add README.md && git commit -m "chore: initial readme"

git switch -c feat/branding
# Edit README.md in your editor → change "v0" to "v0 - your AI second brain"
git commit -am "docs: branding tagline"

git switch main
# Edit README.md in your editor → change "v0" to "v0 - built for IT ops"
git commit -am "docs: ops tagline"

# now try to merge - boom, conflict on line 1
git merge feat/branding
```

### ▶️ Resolve

```bash
git status                            # shows: both modified: README.md
cat README.md                         # you'll see conflict markers:
                                      # <<<<<<< HEAD
                                      # Welcome to rag-notes (v0 - built for IT ops)
                                      # =======
                                      # Welcome to rag-notes (v0 - your AI second brain)
                                      # >>>>>>> feat/branding

# (1) Open README.md in your editor, DELETE the <<<<, ====, >>>> markers,
#     and write the line you actually want - e.g. a combined version:
#     "Welcome to rag-notes (v0 - your AI second brain for IT ops)"

git add README.md                     # (2) tell Git "I resolved it"
git status                            # status now says: All conflicts fixed but you are still merging.

git commit                            # (3) finish the merge (uses the auto-generated merge message)
                                      #     Or:  git commit -m "Merge: combined branding + ops taglines"

git log --oneline --graph -5
```

### 🧠 Use case in the wild

- **Two devs editing the same config file:** happens 5×/day in any team. You'll need this reflex.
- **Long-running release branches:** the longer a branch lives, the worse the conflict. Lesson: merge `main` into your branch *often* with `git merge main` or `git rebase main`.

### ⚠️ Gotchas

- Don't `git checkout --ours` or `--theirs` blindly — read both sides first; sometimes the right answer is *both*.
- If you panic, `git merge --abort` rewinds to before the merge. No harm done.

---

## Lab 6 — Stash during an interruption

!!! example "🌍 Scenario"
    You're mid-feature on `feat/streaming`. Your team chat lights up: **production is broken** and you're the only one online.
    You need to switch to `main`, ship a hotfix, then resume your half-done feature exactly where you left off.

### ▶️ Steps

```bash
# halfway through writing feat/streaming, with messy uncommitted changes...
git status                                # shows: modified: stream.py, untracked: scratch.txt

git stash push -u -m "WIP: streaming half-done"
                                          # (1) park EVERYTHING (incl. -u = include untracked)
                                          #     Working dir is now clean.

git switch main                           # (2) safely jump to main
# ... fix the bug, commit, push ...
git commit -am "fix: handle null response in /healthz"

git switch feat/streaming                 # (3) back to your branch
git stash list                            # (4) see your parked work
                                          #     stash@{0}: On feat/streaming: WIP: streaming half-done

git stash pop                             # (5) restore the changes (and delete the stash entry)
                                          #     Use `git stash apply` if you want to keep the stash too.
git status                                # back to exactly where you were ✨
```

### 🧠 Use case in the wild

- **PagerDuty interrupts you.** This *will* happen. Stash is your seatbelt.
- **Quick branch hops:** trying out a colleague's branch without committing your scratch work.

### ⚠️ Gotchas

- `git stash` (without `-u`) **skips untracked files** — they stay in your working dir and may collide on the other branch.
- A long-lived stash is a graveyard. `git stash list` periodically and prune with `git stash drop`.

---

## Lab 7 — `amend` vs `revert` — when to use each

| Situation | Tool | Why |
|---|---|---|
| Typo in your **last** commit message, **not pushed yet** | `git commit --amend` | Rewrites the commit in-place. Cheap and safe. |
| Bad code in your **last** commit, **not pushed yet** | edit → `git add` → `git commit --amend --no-edit` | Folds the fix into the same commit. |
| Bad code in a commit that's **already on `origin`** and others may have pulled | `git revert <sha>` | Creates a **new** commit that undoes it. Safe for shared history. |

!!! danger "Never rewrite published history"
    `git commit --amend` and `git rebase` change SHAs. If a commit has been pushed and someone else pulled it,
    rewriting it forces them to deal with conflicting history. Use `git revert` instead — it adds a new "undo" commit.

### ▶️ Steps — amend

```bash
git commit -m "feat: add embeding helper"     # oops, typo "embeding"
git commit --amend -m "feat: add embedding helper"
git log --oneline -1                           # only ONE commit, with corrected message
```

### ▶️ Steps — revert

```bash
# Imagine commit abc1234 introduced a bug, and it's already pushed.
git revert abc1234                             # opens editor to confirm "Revert <msg>"
git log --oneline -2                           # you see TWO commits: the original + the revert
git push                                       # safe to push - nobody's history is rewritten
```

### 🧠 Use case in the wild

- **Amend:** caught a typo before opening the PR — happens constantly.
- **Revert:** prod outage caused by a deploy. Revert is the **fastest rollback** because it's just one commit + a re-deploy.

---

## Lab 8 — Rescue with `git reflog`

!!! example "🌍 Scenario"
    It's 11 pm. You typed `git reset --hard HEAD~3` thinking you were on a junk branch.
    You were on `main`. **Three commits worth of work just vanished from `git log`.**
    Don't panic — they are still there.

### ▶️ Steps

```bash
git reflog                                # (1) shows EVERY HEAD movement of the last ~90 days
                                          #     a1b2c3d HEAD@{0}: reset: moving to HEAD~3
                                          #     e4f5g6h HEAD@{1}: commit: feat: streaming v3   <-- the one we want!
                                          #     ...

git switch -c rescue-main e4f5g6h         # (2) create a rescue branch pointing at the lost commit
git log --oneline -5                      # (3) confirm your work is back

# Decide what to do:
#   - cherry-pick selected commits onto main, OR
#   - reset main to rescue-main if it's entirely missing:
git switch main
git reset --hard rescue-main              # main now matches the rescue snapshot
```

### 🧠 Use case in the wild

- **Recovering after a bad rebase.**
- **Restoring a branch you accidentally `git branch -D`'d.** The branch ref is gone, but the commits are still in reflog for ~90 days.

### ⚠️ Gotchas

- `reflog` is **local-only**. If you cloned fresh, your reflog is empty — you cannot rescue someone else's lost commits this way.
- After ~90 days the unreachable commits get garbage collected by `git gc`. Rescue fast.

---

## Lab 9 — The perfect Python+AI `.gitignore`

!!! example "🌍 Scenario"
    You're building a RAG agent. Your repo will accumulate `__pycache__/`, virtualenvs, downloaded models (100s of MB),
    a Chroma vector DB, OpenAI keys in `.env`… **none of this belongs in Git**.

### ▶️ Create the file

Drop this into `.gitignore` at the repo root:

```gitignore
# --- Python ---
__pycache__/
*.py[cod]
*.egg-info/
.pytest_cache/
.mypy_cache/
.ruff_cache/

# --- Virtual environments ---
.venv/
venv/
env/

# --- Secrets - NEVER commit these ---
.env
.env.*
!.env.example          # keep the template visible
*.pem
*.key

# --- Notebook noise ---
.ipynb_checkpoints/

# --- Vector DBs & cached models (HUGE) ---
.chroma/
chroma_db/
.qdrant/
*.faiss
*.index
models/
.cache/
huggingface/

# --- OS / IDE ---
.DS_Store
Thumbs.db
.vscode/
.idea/

# --- Build output ---
dist/
build/
_site/
```

### ▶️ Apply it to an existing repo

```bash
git rm -r --cached __pycache__ .venv          # (1) un-track stuff that was already committed by mistake
git add .gitignore
git commit -m "chore: comprehensive Python+AI .gitignore"
```

### 🧠 Use case in the wild

- **Stops leaked `.env` keys** — the #1 cause of GitHub secret-scanning alerts.
- **Stops 500 MB models** from being pushed and clogging clones.
- **Keeps `git status` clean** so real changes stand out.

### ⚠️ Gotchas

- `.gitignore` only blocks **untracked** files. Files already tracked must be removed with `git rm --cached`.
- The `!.env.example` line means: "ignore .env*, **except** the example template" — so newcomers see the required variables.

---

## Lab 10 — Tag a semantic release (`v0.1.0`)

!!! example "🌍 Scenario"
    Your RAG demo finally answers questions correctly. You want to mark this commit as **v0.1.0** so future you
    can always check out *this exact snapshot*.

### ▶️ Steps

```bash
git tag -a v0.1.0 -m "v0.1.0 - first working RAG over IT runbooks"
                                          # -a = annotated tag (has metadata, recommended)
                                          # vs lightweight tag: git tag v0.1.0  (just a name)

git tag                                   # list all tags
git show v0.1.0                           # see the tagged commit + message

git push origin v0.1.0                    # tags are NOT pushed by default - push explicitly
git push --tags                           # or push all tags at once
```

### 🔢 Semantic versioning cheat

| Bump | When |
|---|---|
| `MAJOR` (1.x → 2.x) | Breaking changes — old code stops working |
| `MINOR` (1.0 → 1.1) | New features, backwards compatible |
| `PATCH` (1.0.0 → 1.0.1) | Bug fix only, no API changes |

### 🧠 Use case in the wild

- **GitHub Releases** (Phase 10) attach binaries and changelogs to a tag.
- **Docker image tags** (`myapp:v0.1.0`) usually mirror Git tags.
- **`pip install mypkg==0.1.0`** resolves to the wheel built from this tag.

---

## Lab 11 — Cherry-pick a hotfix across branches

!!! example "🌍 Scenario"
    You shipped `v0.1.0` from the `release/v0.1` branch. `main` has moved on with 30 new commits.
    A user reports a crash. You fix it on `main` in commit `abc1234`. Now you need to **also**
    apply that one commit to `release/v0.1` so you can publish `v0.1.1` — without dragging in
    the other 29 unrelated commits.

### ▶️ Steps

```bash
git switch main
# ... fix the bug ...
git commit -am "fix: handle missing OpenAI key gracefully"
git log -1 --format=%H                      # copy the SHA, e.g. abc1234

git switch release/v0.1                     # jump to the release branch
git cherry-pick abc1234                     # apply JUST that commit
                                            # If conflicts arise:
                                            #   - resolve them, git add <files>, then:
                                            #   - git cherry-pick --continue
                                            # Or bail with: git cherry-pick --abort

git tag -a v0.1.1 -m "v0.1.1 - patch: missing API key"
git push origin release/v0.1 v0.1.1
```

### 🧠 Use case in the wild

- **Backporting security fixes** to older supported releases.
- **Pulling one bug fix** from a teammate's WIP branch without taking their other half-done work.

### ⚠️ Gotchas

- Cherry-picks create **new SHAs**. If you ever merge `main` into `release/v0.1` later, Git may see the cherry-picked commit as "different" and try to apply it again. Use `git cherry-pick -x abc1234` to add a `(cherry picked from commit …)` reference — it helps Git and humans understand the relationship.

---

## Lab 12 — Clean history with interactive rebase

!!! example "🌍 Scenario"
    You spent the afternoon hammering on `feat/agent`. Your branch has 5 commits that look like:

    ```
    e5  WIP
    d4  more wip
    c3  fix typo
    b2  actually works now
    a1  feat: start agent loop
    ```

    Your reviewer will hate this. Before opening the PR you want **one clean commit**:

    ```
    a1  feat: add agent loop with tool dispatcher
    ```

### ▶️ Steps

```bash
git switch feat/agent
git log --oneline                          # confirm the 5 commits we want to squash

git rebase -i HEAD~5                       # (1) open the rebase editor for the last 5 commits
```

Your `$EDITOR` opens with:

```text
pick a1 feat: start agent loop
pick b2 actually works now
pick c3 fix typo
pick d4 more wip
pick e5 WIP
```

Change `pick` to `squash` (or `s`) for every commit except the first:

```text
pick   a1 feat: start agent loop
squash b2 actually works now
squash c3 fix typo
squash d4 more wip
squash e5 WIP
```

Save & close. A **second** editor opens to combine the messages — write the final message:

```text
feat: add agent loop with tool dispatcher

- ReAct-style think/act/observe loop
- Pluggable tool registry
- Stops on `Final Answer:` token
```

Save & close. Then:

```bash
git log --oneline                          # ONE commit
git push --force-with-lease                # (2) the SHA changed → force-push needed
                                           # --force-with-lease is SAFER than --force:
                                           # it refuses to overwrite if someone else pushed in the meantime.
```

### 🧠 Use case in the wild

- **Pre-PR cleanup.** Most teams require a clean history before review.
- **Squash-merge alternative:** if your team uses GitHub squash-merge anyway (Phase 10) you can skip this — squash happens at merge time.

### ⚠️ Gotchas

- **Never** interactive-rebase commits that are on `main` and already pulled by others. You'd rewrite their history.
- Always `--force-with-lease`, not `--force`. The "lease" check prevents overwriting your teammate's accidental push.

---

## Capstone — a week in the life of a Git user

!!! quote "Mission brief"
    You're a solo engineer on the `rag-notes` repo. Over one simulated week you'll:
    bootstrap the project, isolate a feature on a branch, get interrupted by a hotfix,
    resolve a conflict, clean up your history, and ship a tagged release.

Do all of this in **one terminal session**. Time-box: 60 min.

### 📅 Monday — bootstrap

```bash
mkdir rag-week && cd rag-week
git init -b main
printf "# rag-week\n" > README.md
# Use the .gitignore from Lab 9 - paste it in manually
git add . && git commit -m "chore: bootstrap"
```

### 📅 Tuesday — feature branch

```bash
git switch -c feat/embedding
printf "def embed(text):\n    return [0.0] * 1536\n" > embed.py
git add embed.py && git commit -m "feat: stub embedding helper"
```

### 📅 Wednesday — interruption + hotfix

```bash
# Mid-feature, prod is down. Stash and switch.
printf "TODO: real OpenAI call\n" >> embed.py
git stash push -u -m "WIP: real embedding call"

git switch main
printf "## Status\n\n![ok](https://img.shields.io/badge/build-ok-green)\n" >> README.md
git commit -am "fix: add health badge"
```

### 📅 Thursday — conflict + resolve

```bash
# Resume the feature branch - meanwhile main edited README.md, and so did the stash.
git switch feat/embedding
git stash pop
echo "## Status - embedding WIP" >> README.md
git commit -am "docs: status section"

git merge main                           # conflict on README.md
# resolve in editor, then:
git add README.md
git commit                               # finish merge
```

### 📅 Friday — squash + tag + release

```bash
git switch main
git merge --no-ff feat/embedding -m "Merge feat/embedding"

# Clean any WIP commits if needed:
# git rebase -i HEAD~5  → squash

git tag -a v0.1.0 -m "v0.1.0 - initial RAG plumbing"
git log --oneline --graph --all -10
```

### ✅ Definition of done

- [ ] `git log --oneline --graph --all` shows a clean week of commits.
- [ ] `git tag` shows `v0.1.0`.
- [ ] `git status` is clean.
- [ ] No `.env` or `__pycache__` ever made it into a commit.
- [ ] You can explain, out loud, what each command in Wednesday's hotfix did and *why*.

---

## 🃏 Cheat sheet — paste this above your desk

```bash
# Start a repo
git init -b main
git add . && git commit -m "chore: init"

# Daily flow
git status                       # what's changed?
git switch -c feat/<name>        # new feature branch
git add -p                       # stage hunks
git commit -m "feat: ..."
git push -u origin feat/<name>

# Inspect
git log --oneline --graph --all
git diff                         # working vs staged
git diff --staged                # staged vs HEAD
git show <sha>

# Undo
git restore <file>               # discard working-dir edits (DANGEROUS)
git restore --staged <file>      # unstage (safe - keeps edits)
git commit --amend               # fix last commit (only if unpushed)
git revert <sha>                 # safe undo for shared history
git reset --hard <sha>           # time travel (DESTRUCTIVE)

# Safety net
git stash push -u -m "WIP"
git stash pop
git reflog                       # everything that ever happened to HEAD

# Branching
git switch <branch>
git merge <branch>
git merge --abort
git rebase main
git rebase -i HEAD~5             # squash / reorder
git cherry-pick <sha>

# Release
git tag -a v0.1.0 -m "first release"
git push --tags
```

---

## 🧠 Quiz answers (Chapter 1)

| Q | Answer | Why |
|---|---|---|
| 1 | `git init` | Creates `.git/` to make a folder a repo |
| 2 | working dir → staging → HEAD | The three trees |
| 3 | `git restore --staged file` | Unstage without losing edits |
| 4 | `git switch -c feat/x` | Modern branch creation |
| 5 | `git commit --amend` | Rewrite the last commit |
| 6 | `git stash` | Park dirty changes safely |
| 7 | `git revert <sha>` | Safe inverse commit; never rewrite shared history |
| 8 | `git reflog` | Time machine of HEAD movements; recovery |
| 9 | fast-forward | Linear catch-up; no merge commit |
| 10 | `HEAD` | The pointer to your current commit (often via a branch) |

---

## ⚠️ Common mistakes (memorise these)

| Mistake | Cost | Fix |
|---|---|---|
| `git reset --hard` without a backup branch | Lose hours of work | `git branch backup-$(date +%s)` before risky ops; rescue with `git reflog` |
| Committing `.env` with API keys | Public key leak ⇒ rotate immediately | `.gitignore` from Lab 9, plus push protection (Phase 16) |
| Merging straight into `main` solo | Habit you'll regret in a team | Always work on a branch and PR — even when solo |
| `git push --force` on a shared branch | Erases teammates' commits | Use `git push --force-with-lease` only on your *own* branches |
| Long-lived feature branches | Merge conflicts grow exponentially | Rebase / merge `main` into your branch **daily** |

---

## ▶️ Next

➡️ **[Phase 10 — GitHub Basics](../Chapter15_GitHub_Basics/index.md)** — take everything you just learned and put it on a remote, with PRs, issues, and releases.
