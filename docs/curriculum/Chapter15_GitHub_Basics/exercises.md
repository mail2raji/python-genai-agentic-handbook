# Phase 10 — GitHub Basics · 🧪 Lab Pack

> **Mission:** Take Phase 9's local Git skills and put them on a real **remote** — with pull requests,
> issue templates, releases, branch protection, project boards and discussions.
> By the end you'll have a public `rag-notes` repo on GitHub that *feels* professional.

!!! abstract "How this lab pack works"
    Every lab follows the same beat as Phase 9:

    1. **🌍 Scenario** — the real-world situation
    2. **🎯 Why this matters** — the skill you build
    3. **▶️ Steps** — annotated `gh` CLI commands (with web-UI alternative)
    4. **✅ Expected result** — what success looks like
    5. **🧠 Use case in the wild** — real teams that use this exact flow
    6. **⚠️ Gotchas** — what bites beginners

!!! note "Tooling — install `gh` CLI first"
    All labs prefer the [GitHub CLI (`gh`)](https://cli.github.com/) so they're scriptable.
    Install it via Phase 8's Setup lab, then run:

    ```bash
    gh auth login                     # one-time browser auth
    gh auth status                    # confirm you're signed in
    gh repo list --limit 5            # smoke test
    ```

---

## 🧭 Lab roadmap

| # | Lab | Difficulty | Time | What you'll do |
|---|-----|:---:|:---:|---|
| 1 | [Repo bootstrap with `gh repo create`](#lab-1-repo-bootstrap-with-gh-repo-create) | ⭐ | 10 min | One-command public repo with README + LICENSE + .gitignore |
| 2 | [Your first PR from the CLI](#lab-2-your-first-pr-from-the-cli) | ⭐⭐ | 15 min | Push a branch, open a PR, set reviewers |
| 3 | [Review → Squash-merge → Delete branch](#lab-3-review-squash-merge-delete-branch) | ⭐⭐ | 15 min | The 3-line CLI PR flow every team uses |
| 4 | [Issue templates with forms](#lab-4-issue-templates-with-forms) | ⭐⭐ | 20 min | `.yml` issue forms with dropdowns + required fields |
| 5 | [Tagged release with auto-notes](#lab-5-tagged-release-with-auto-generated-notes) | ⭐⭐ | 15 min | `gh release create` with `--generate-notes` |
| 6 | [Project board (v2) for sprint tracking](#lab-6-project-board-v2-for-sprint-tracking) | ⭐⭐⭐ | 20 min | Custom fields, automation, linked PRs |
| 7 | [Branch protection rules](#lab-7-branch-protection-rules) | ⭐⭐⭐ | 15 min | Require PR + reviews + green CI before merging `main` |
| 8 | [CODEOWNERS for auto-review](#lab-8-codeowners-for-auto-review) | ⭐⭐ | 10 min | Auto-request reviews from path-matched teams |
| 9 | [Fork + upstream sync (OSS flow)](#lab-9-fork-upstream-sync-oss-flow) | ⭐⭐⭐ | 20 min | Contribute to someone else's repo cleanly |
| 10 | [GitHub Discussions](#lab-10-github-discussions) | ⭐⭐ | 10 min | Enable Q&A, post a welcome thread |
| 11 | [Label strategy + auto-triage](#lab-11-label-strategy-auto-triage) | ⭐⭐ | 15 min | A real label palette + a triage Action |
| 12 | [Link issues, PRs and commits the smart way](#lab-12-link-issues-prs-and-commits-the-smart-way) | ⭐⭐ | 10 min | `Closes #42`, `Fixes`, autolinks, cross-repo refs |
| 🏁 | [**Capstone — open-source a tiny tool, end-to-end**](#capstone-open-source-a-tiny-tool-end-to-end) | ⭐⭐⭐⭐ | 90 min | All 12 skills in one realistic flow |

---

## 🧠 Mental model — what GitHub adds on top of Git

| Git (local) | GitHub (cloud, social) |
|---|---|
| Commits, branches, tags | Pull Requests (PRs), Releases, Reviews |
| `git remote` (a URL) | Repositories with permissions, issues, wikis, projects |
| `git log` | Activity feed, Insights, contributors graph |
| Nothing for discussion | Issues, Discussions, comments on lines of code |
| You alone enforce process | Branch protection, CODEOWNERS, required checks, GHAS |

**One-line summary:** *Git is the engine. GitHub is the workshop — with chairs, whiteboards, and a security guard.*

---

## Lab 1 — Repo bootstrap with `gh repo create`

!!! example "🌍 Scenario"
    You finally want to share your local `rag-notes` repo with the world.
    Instead of 12 clicks in the browser, do it in **one command** so the action is *reproducible*.

### ▶️ Steps

```bash
cd rag-notes                       # the local repo from Phase 9 Lab 1

gh repo create mail2raji/rag-notes \
  --public \                       # (1) public visibility (use --private for a closed repo)
  --source=. \                     # (2) the local folder we want to push
  --remote=origin \                # (3) wire it up as the 'origin' remote
  --push \                         # (4) push the current branch immediately
  --description "Personal RAG knowledge base" \
  --license MIT                    # (5) add a LICENSE file (only if not present)

# If the local repo already has commits, that's it. Otherwise:
# gh repo create mail2raji/rag-notes --public --add-readme --license MIT --gitignore Python --clone
```

### ✅ Expected result

```bash
gh repo view --web                 # opens https://github.com/mail2raji/rag-notes in your browser
git remote -v                      # origin -> git@github.com:mail2raji/rag-notes.git (fetch)
                                   # origin -> git@github.com:mail2raji/rag-notes.git (push)
```

### 🧠 Use case in the wild

- **Open-sourcing a script** in 30 seconds during a meeting demo.
- **Standardising new microservice repos** — wrap this command in a shell template so every team repo starts the same way.

### ⚠️ Gotchas

- `--source=.` requires the local folder to already be a Git repo with at least one commit. Run `git log -1` first.
- Pick the license **before** you accept your first external contribution — it's painful to add later.

---

## Lab 2 — Your first PR from the CLI

!!! example "🌍 Scenario"
    You added a `query.py` script on a branch. You want a reviewable PR — not a direct push to `main`.

### ▶️ Steps

```bash
git switch -c feat/query                       # (1) feature branch
# ... write query.py ...
git add query.py
git commit -m "feat: add semantic query CLI"

git push -u origin feat/query                  # (2) -u sets upstream so future `git push` works bare

gh pr create \
  --base main \                                # target branch
  --title "feat: semantic query CLI" \
  --body "Adds a tiny CLI that takes --question and prints the top-3 RAG hits." \
  --assignee @me \
  --label feature \
  --draft                                      # (3) open as DRAFT until CI is green
                                               #     Drop --draft when ready for review

gh pr view --web                               # (4) open the PR in your browser
```

### 🤝 The `--fill` shortcut

If your commit messages are already great, replace `--title`/`--body` with `--fill` and `gh` will use them:

```bash
gh pr create --fill --base main
```

### 🧠 Use case in the wild

- **Trunk-based dev with short-lived branches:** every change goes through a PR, even a 2-line fix. The audit trail is gold during incident reviews.
- **Draft PRs as "look at this idea":** open a draft to ask for feedback *before* you finish the work.

### ⚠️ Gotchas

- If `gh pr create` says "no commits between main and feat/query", you forgot to `git push` first — the remote branch is empty.
- Use **descriptive titles**. GitHub's email digest only shows the title — "fix" tells nobody anything.

---

## Lab 3 — Review → Squash-merge → Delete branch

!!! example "🌍 Scenario"
    Your draft PR is now ready. You (or a teammate) reviewed it. Time to land it on `main` with a clean history.

### ▶️ Steps

```bash
gh pr ready                                    # (1) flip the draft PR to "ready for review"

gh pr review --approve -b "LGTM - merging"     # (2) approve (you can't approve your own PR
                                               #     on protected repos; use --comment instead)

gh pr merge --squash --delete-branch           # (3) the magic line:
                                               #   --squash         = collapse all PR commits into one
                                               #   --delete-branch  = clean up the remote branch
                                               # Alternatives:
                                               #   --merge   = traditional merge commit
                                               #   --rebase  = replay PR commits onto main, linear history

git switch main                                # (4) back to main locally
git pull --prune                               # (5) pull the squashed commit and prune the deleted branch
git branch -d feat/query                       # (6) delete the local branch (-D if it errors)
```

### 🎨 Merge strategies — pick wisely

| Strategy | History looks like | Best for |
|---|---|---|
| **Squash** (recommended for most teams) | 1 commit per PR on `main` | Easy revert, clean `git log` |
| **Merge commit** | Branch's commits + a merge commit | When intermediate commits matter |
| **Rebase** | Branch commits replayed linearly | Linear-history zealots |

### 🧠 Use case in the wild

- **Squash is the de-facto default** at Google, Meta, Microsoft, GitHub itself. Each PR ⇒ one revertable commit on `main`.
- **Branch hygiene:** auto-delete merged branches keeps the branch list scannable.

### ⚠️ Gotchas

- After a squash-merge, your local feature branch is "behind" main *and* unmergeable history. `git branch -d` may need `-D` to force-delete.

---

## Lab 4 — Issue templates with forms

!!! example "🌍 Scenario"
    Strangers open issues that say "it doesn't work" with no version, no logs, no repro. You want a **bug report form** with required fields:
    OS, Python version, repro steps. Same for feature requests.

### ▶️ Step 1 — create the bug form

Create `.github/ISSUE_TEMPLATE/bug_report.yml`:

```yaml
name: 🐛 Bug Report
description: Something is broken or behaving unexpectedly.
title: "[Bug]: "
labels: ["bug", "needs-triage"]
assignees:
  - mail2raji
body:
  - type: markdown
    attributes:
      value: |
        Thanks for filing a bug! Please fill in **every** field — incomplete reports get auto-closed.

  - type: input
    id: version
    attributes:
      label: rag-notes version
      description: "Run `python -m rag_notes --version` and paste the output."
      placeholder: "0.3.1"
    validations:
      required: true

  - type: dropdown
    id: os
    attributes:
      label: Operating system
      options:
        - Windows 11
        - macOS (Apple Silicon)
        - macOS (Intel)
        - Ubuntu / Debian
        - Other Linux
    validations:
      required: true

  - type: textarea
    id: steps
    attributes:
      label: Steps to reproduce
      description: Numbered steps + the **exact** command you ran.
      value: |
        1.
        2.
        3.
      render: markdown
    validations:
      required: true

  - type: textarea
    id: logs
    attributes:
      label: Relevant logs / stack trace
      description: Paste the error output. It will be formatted as code automatically.
      render: shell
    validations:
      required: false

  - type: checkboxes
    id: checks
    attributes:
      label: Pre-flight
      options:
        - label: I searched existing issues for duplicates
          required: true
        - label: I am on the latest release
          required: true
```

### ▶️ Step 2 — create the feature form

Create `.github/ISSUE_TEMPLATE/feature_request.yml`:

```yaml
name: ✨ Feature Request
description: Suggest an improvement or new capability.
title: "[Feature]: "
labels: ["feature", "needs-triage"]
body:
  - type: textarea
    id: problem
    attributes:
      label: What problem does this solve?
      placeholder: "Today I have to ... and it's painful because ..."
    validations:
      required: true
  - type: textarea
    id: proposal
    attributes:
      label: Proposed solution
    validations:
      required: true
  - type: textarea
    id: alternatives
    attributes:
      label: Alternatives considered
```

### ▶️ Step 3 — commit & verify

```bash
git add .github/ISSUE_TEMPLATE/
git commit -m "chore: add issue templates"
git push

gh issue create --web                          # opens the chooser - confirm both forms appear
```

### 🧠 Use case in the wild

- **Triage time drops by 80%** when reporters supply structured info up-front.
- **Required `version` field** means you instantly know if a bug is already fixed in `main`.

### ⚠️ Gotchas

- Templates are *folder-sensitive*: must be in `.github/ISSUE_TEMPLATE/` (singular `TEMPLATE`, plural `ISSUE_TEMPLATEs` does not work).
- `validations.required: true` is *not enforced* in the API — only the web form. Programmatic issues can skip fields.

---

## Lab 5 — Tagged release with auto-generated notes

!!! example "🌍 Scenario"
    Phase 9 Lab 10 created the **tag** `v0.1.0`. Now turn it into a **GitHub Release** with downloadable assets
    and changelog notes generated from your PR titles.

### ▶️ Steps

```bash
# Make sure the tag is pushed (Phase 9 Lab 10)
git push origin v0.1.0

gh release create v0.1.0 \
  --title "v0.1.0 - First working RAG demo" \
  --generate-notes \                           # (1) auto-build changelog from PRs since last release
  --latest                                     # (2) mark this as the "Latest" release on the repo page

# Attach a binary or PDF?
gh release upload v0.1.0 ./dist/rag-notes-0.1.0-py3-none-any.whl
```

### 🧠 Use case in the wild

- **Automated changelog** = no more "what was in this release?" confusion.
- **Pre-release flag:** add `--prerelease` for `v0.2.0-rc1` so it doesn't show as "Latest".

### ⚠️ Gotchas

- `--generate-notes` only works if you've been **squash-merging PRs** (Lab 3) with descriptive titles — the notes are essentially `PR title - @author`.
- Releases are immutable. To fix a typo in the notes, delete and recreate (`gh release delete v0.1.0`).

---

## Lab 6 — Project board (v2) for sprint tracking

!!! example "🌍 Scenario"
    You and 2 other contributors will work on `rag-notes` for the next 2 weeks. You want a **kanban board** —
    "Backlog → In Progress → In Review → Done" — that **automatically** moves cards when PRs change state.

### ▶️ Steps

```bash
# (1) Create the project
gh project create --owner mail2raji --title "RAG Notes Roadmap"
# Note the project number it prints, e.g. 7
PROJ=7

# (2) Add a 'Status' field (single-select)
gh project field-create $PROJ --owner mail2raji \
  --name "Status" --data-type SINGLE_SELECT \
  --single-select-options "Backlog,In Progress,In Review,Done"

# (3) Add a 'Sprint' iteration field
gh project field-create $PROJ --owner mail2raji \
  --name "Sprint" --data-type ITERATION

# (4) Add an existing issue to the board
gh issue list --json number --jq '.[].number' | head -5 | \
  xargs -I{} gh project item-add $PROJ --owner mail2raji \
    --url https://github.com/mail2raji/rag-notes/issues/{}
```

### 🤖 Automate card movement (web UI)

In the project's **Workflows** tab:

1. **"Auto-add to project"** → when an issue/PR is opened, add it with Status=Backlog.
2. **"Item closed"** → when an issue closes, set Status=Done.
3. **"Pull request merged"** → set Status=Done.

### 🧠 Use case in the wild

- **2-week sprints** with the Iteration field gives you burndown charts for free.
- **Cross-repo board:** one project can track issues from `rag-notes`, `rag-api`, and `rag-docs` together.

### ⚠️ Gotchas

- Project v2 ≠ Project (classic). Classic is deprecated — always use v2.
- Permissions are *separate* from the repo: a teammate with repo write may still need project write.

---

## Lab 7 — Branch protection rules

!!! example "🌍 Scenario"
    A teammate accidentally pushed to `main` and bypassed review. Never again. You want:

    - No direct pushes to `main`
    - PRs require at least 1 approving review
    - CI (`build`) must be green
    - Stale approvals dismissed when new commits arrive

### ▶️ Steps via API (scriptable)

```bash
gh api -X PUT repos/mail2raji/rag-notes/branches/main/protection \
  --input - <<'JSON'
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["build"]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true,
    "required_approving_review_count": 1
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_linear_history": true,
  "required_conversation_resolution": true
}
JSON
```

### ▶️ Or via web UI

`Settings → Branches → Add branch protection rule`:

| Setting | Value | Why |
|---|---|---|
| Branch name pattern | `main` | Apply to `main` |
| ✅ Require PR before merging | 1 approval | Forces review |
| ✅ Dismiss stale approvals | on | Re-approve after new pushes |
| ✅ Require status checks | `build` | No broken merges |
| ✅ Require linear history | on | Forbids merge commits — squash/rebase only |
| ✅ Do not allow bypassing | on | Even admins follow the rules |
| ✅ Require conversation resolution | on | All review comments resolved before merge |

### 🧠 Use case in the wild

- **Compliance / SOC2:** auditors want evidence that production code went through review. Branch protection is the evidence.
- **Open source:** stops contributors from sneaking unreviewed code into your trusted branch.

### ⚠️ Gotchas

- If you turn on "Require status checks" but the check has never run, **nobody can merge** until the check executes once. Trigger it with an empty commit: `git commit --allow-empty -m "ci: trigger checks" && git push`.

---

## Lab 8 — CODEOWNERS for auto-review

!!! example "🌍 Scenario"
    Your repo has a `security/` folder (auth code) and an `infra/` folder (Terraform).
    Whenever **any** PR touches those paths, you want the security team and the SRE team
    automatically requested as reviewers — without anyone having to remember.

### ▶️ Step 1 — create the file

Create `.github/CODEOWNERS`:

```text
# Default owners for everything
*                       @mail2raji

# Security-sensitive code → security team
/security/              @org/security-team
auth/**                 @org/security-team

# Infrastructure → SRE team
/infra/**               @org/sre-team
*.tf                    @org/sre-team

# Docs only → tech writers (lighter review)
*.md                    @org/docs-team
docs/**                 @org/docs-team

# AI model code → ML team (multiple owners allowed)
/agents/**              @mail2raji @org/ml-team
```

### ▶️ Step 2 — enforce it

Combine with branch protection (Lab 7):

- Enable **"Require review from Code Owners"** in the branch rule.
- Now PRs touching `security/` *cannot* merge until `@org/security-team` approves.

### 🧠 Use case in the wild

- **Distributing review load:** core maintainers stop being the bottleneck for every PR.
- **Compliance:** ML model changes legally need an ML lead's sign-off → CODEOWNERS does that automatically.

### ⚠️ Gotchas

- The user/team in CODEOWNERS must have **push access** to the repo, otherwise the rule is silently ignored.
- The **last matching rule wins** — order matters. Specific paths go *after* the wildcards.

---

## Lab 9 — Fork + upstream sync (OSS flow)

!!! example "🌍 Scenario"
    You spotted a typo in the [`langchain-ai/langchain`](https://github.com/langchain-ai/langchain) docs.
    You don't have write access, so the workflow is:
    **fork → clone → branch → fix → push → PR to upstream**.
    Later you need to pull upstream changes into your fork.

### ▶️ Steps

```bash
# (1) Fork in one command
gh repo fork langchain-ai/langchain --clone --remote
# This:
#   - forks to mail2raji/langchain
#   - clones it to ./langchain
#   - adds the original as the 'upstream' remote

cd langchain
git remote -v
# origin     https://github.com/mail2raji/langchain.git (fetch/push)
# upstream   https://github.com/langchain-ai/langchain.git (fetch/push)

# (2) Make the fix on a branch
git switch -c docs/fix-typo
# ... edit the docs ...
git commit -am "docs: fix typo in agents.md"
git push -u origin docs/fix-typo

# (3) Open a PR against the UPSTREAM repo
gh pr create --repo langchain-ai/langchain --fill

# (4) Keep your fork in sync (do this BEFORE every new contribution)
git switch main
git fetch upstream
git merge upstream/main             # or: git rebase upstream/main
git push origin main
```

### 🛠️ The web shortcut

GitHub's **"Sync fork"** button on your fork's homepage does the `fetch + merge + push` in one click.

### 🧠 Use case in the wild

- **Every OSS contribution ever** uses this exact flow.
- **Internal forks:** at large companies you may fork an internal repo to maintain a vendor-customised version.

### ⚠️ Gotchas

- Long-lived forks rot fast. Sync **before** you start a new branch, not after — otherwise your PR will conflict.
- Don't commit directly to `main` on your fork — keep it pristine, mirroring upstream, so syncing never conflicts.

---

## Lab 10 — GitHub Discussions

!!! example "🌍 Scenario"
    Users keep opening **issues** that are actually questions ("how do I…?"). Issues are for bugs/features.
    Move conversation to **Discussions** — a Q&A forum scoped to your repo.

### ▶️ Steps

```bash
# (1) Enable Discussions (one-time)
gh api -X PATCH repos/mail2raji/rag-notes \
  -f has_discussions=true

# (2) Convert an existing issue into a discussion (web UI: issue → ... → "Convert to discussion")
# CLI list:
gh api repos/mail2raji/rag-notes/discussions/categories

# (3) Create a welcome discussion
gh api repos/mail2raji/rag-notes/discussions \
  -f title="👋 Welcome — say hi" \
  -f body="Introduce yourself, share what you're building with rag-notes." \
  -F category_id=DIC_kwDOxxx                   # ← from step 2
```

### 🗂️ Categories worth having

| Category | Format | Use |
|---|---|---|
| **Announcements** | Anyone reads, only maintainers post | Release notes, breaking-change warnings |
| **Q&A** | Threaded, has "marked answer" | Support questions |
| **Show and tell** | Free-form | User projects built on your tool |
| **Ideas** | Has upvotes | Future features (before they become issues) |

### 🧠 Use case in the wild

- **Issue trackers stay clean** for actual bugs.
- **Q&A category** answers index in Google → fewer repeat questions for you.

---

## Lab 11 — Label strategy + auto-triage

!!! example "🌍 Scenario"
    Every issue should be triaged within 24 h. You want a consistent **label palette** and an Action that
    auto-labels new issues by keyword.

### 🎨 Recommended label palette

| Label | Colour | Use |
|---|---|---|
| `bug` | red `#d73a4a` | Confirmed defect |
| `feature` | green `#0e8a16` | New capability |
| `docs` | blue `#0075ca` | Documentation only |
| `good first issue` | purple `#7057ff` | Beginner-friendly |
| `help wanted` | teal `#008672` | Want community PRs |
| `needs-triage` | yellow `#fbca04` | Not yet reviewed by a maintainer |
| `blocked` | dark red `#b60205` | Waiting on something external |
| `wontfix` | grey `#cccccc` | Decided not to fix; closed |

### ▶️ Create them all at once

```bash
gh label create bug              --color d73a4a --description "Something isn't working"      --force
gh label create feature          --color 0e8a16 --description "New functionality"             --force
gh label create docs             --color 0075ca --description "Documentation"                 --force
gh label create "good first issue" --color 7057ff --description "Good for newcomers"          --force
gh label create "help wanted"    --color 008672 --description "Extra attention needed"        --force
gh label create needs-triage     --color fbca04 --description "Awaiting maintainer review"   --force
gh label create blocked          --color b60205 --description "Blocked on external work"     --force
gh label create wontfix          --color cccccc --description "This will not be worked on"   --force
```

### 🤖 Auto-label new issues (`.github/workflows/triage.yml`)

```yaml
name: Triage
on:
  issues:
    types: [opened]
permissions:
  issues: write
jobs:
  label:
    runs-on: ubuntu-latest
    steps:
      - uses: github/issue-labeler@v3.4
        with:
          repo-token: ${{ secrets.GITHUB_TOKEN }}
          configuration-path: .github/labeler.yml
          enable-versioned-regex: 0
```

`.github/labeler.yml`:

```yaml
bug:
  - '(?i)(error|exception|traceback|crash|broken)'
docs:
  - '(?i)(typo|readme|documentation|docstring)'
feature:
  - '(?i)(feature request|would be nice|please add)'
```

### 🧠 Use case in the wild

- **OSS maintainers** sleep better when triage is automatic.
- **Internal repos:** the `blocked` label feeds Slack reminders so nothing stalls silently.

---

## Lab 12 — Link issues, PRs and commits the smart way

!!! example "🌍 Scenario"
    You fixed issue #42 in a PR. You want the PR to **auto-close** the issue when it merges,
    and you want the issue page to show a link back to the PR.

### 🔑 The magic keywords

In your **PR description** (or any commit message), use any of these followed by `#<issue-number>`:

```text
Closes #42
Fixes #42
Resolves #42
```

When the PR merges, GitHub:

1. ✅ Closes issue #42 automatically
2. 🔗 Adds a "linked pull request" badge on the issue
3. 📜 Includes a "Closes #42" line in the merge commit

### 🌐 Cross-repo / cross-org links

```text
Closes mail2raji/rag-docs#17
Closes github.com/other-org/other-repo#5
```

### 💬 Inline references (don't auto-close)

Anywhere in a comment, PR body, or issue, you can write:

| Pattern | Result |
|---|---|
| `#42` | Link to issue/PR #42 in this repo |
| `org/repo#42` | Link in a different repo |
| `abc1234` | Link to commit abc1234 |
| `@username` | Mention (sends notification) |
| `@org/team` | Mention a team |

### 🧠 Use case in the wild

- **Release notes** built from squash-merged PRs reference issues automatically.
- **Sprint demos:** opening the Closed Issues tab shows what shipped — no spreadsheet needed.

---

## Capstone — open-source a tiny tool, end-to-end

!!! quote "Mission brief"
    Take `rag-notes` from a folder on your laptop to a fully professional public repo:
    branch-protected, with templates, labels, a project board, a release, and an open PR
    from a friend's fork.

Time-box: 90 min. Solo is fine — play both "maintainer" and "contributor".

### 🗺️ Steps

1. **Bootstrap (Lab 1):** `gh repo create mail2raji/rag-notes --public --source=. --push --license MIT`.
2. **Templates (Lab 4):** add `bug_report.yml` + `feature_request.yml`.
3. **Labels (Lab 11):** apply the 8-label palette.
4. **CODEOWNERS (Lab 8):** set yourself as default owner.
5. **Branch protection (Lab 7):** require 1 approval + linear history.
6. **Project board (Lab 6):** create a Roadmap with Status + Sprint fields.
7. **Open 3 issues** using the new templates — 1 bug, 1 feature, 1 docs.
8. **Fix the docs issue:**
   - `git switch -c docs/fix-readme`
   - Edit, commit with message `docs: clarify install steps\n\nCloses #3`.
   - `gh pr create --fill`.
   - Approve (or `--comment`) and `gh pr merge --squash --delete-branch`.
9. **Verify** issue #3 auto-closed and the project board moved its card to Done.
10. **Release (Lab 5):** tag `v0.1.0` and `gh release create v0.1.0 --generate-notes`.
11. **Discussions (Lab 10):** enable + post a "👋 welcome" thread.
12. **Brag:** share your repo URL with a friend, ask them to fork (Lab 9) and open a PR.

### ✅ Definition of done

- [ ] Repo home page shows: README, LICENSE, badges, last release `v0.1.0`.
- [ ] Issues tab shows 3 labelled issues; one is closed and linked to a merged PR.
- [ ] `Settings → Branches` shows the `main` protection rule.
- [ ] Project board has at least 1 card in Done.
- [ ] Discussions tab is enabled with a welcome thread.
- [ ] You can explain — out loud — what *each* of the above 12 labs gave you.

---

## 🧠 Quiz answers (Chapter 2)

| Q | Answer | Why |
|---|---|---|
| 1 | Fork | Server-side copy under your namespace; preserves connection to upstream |
| 2 | PR | Proposal to merge two branches; carries review + discussion |
| 3 | Squash merge | Collapses N commits into 1; clean history |
| 4 | `CODEOWNERS` | Auto-requests reviews from path-matched teams |
| 5 | Draft PR | Communicates intent without requesting review yet |
| 6 | Discussions | Long-form Q&A, not bug tracking |
| 7 | Tags vs Releases | Tag = git ref; Release = GitHub object on top of a tag |
| 8 | Project (v2) | Cross-repo task board with custom fields |
| 9 | `.github/PULL_REQUEST_TEMPLATE.md` | Default PR body template |
| 10 | Notifications | Watch / Participating / All-activity; default per-repo |

### 💡 Bonus tip

When you delete a branch on merge, GitHub still preserves it via the PR's **"Restore branch"** button for 90 days. Useful safety net.

---

## 🃏 Cheat sheet — `gh` CLI essentials

```bash
# Auth
gh auth login
gh auth status

# Repos
gh repo create <name> --public --source=. --push --license MIT
gh repo view --web
gh repo clone <owner>/<name>
gh repo fork <owner>/<name> --clone --remote

# Pull requests
gh pr create --fill --base main
gh pr list
gh pr view <num> --web
gh pr checks <num>
gh pr review --approve -b "LGTM"
gh pr merge <num> --squash --delete-branch

# Issues
gh issue create --title "..." --body "..." --label bug
gh issue list --label bug --state open
gh issue close <num>

# Releases
gh release create v0.1.0 --generate-notes --latest
gh release upload v0.1.0 ./dist/*.whl

# Labels (bulk)
gh label create <name> --color RRGGBB --description "..." --force

# Projects (v2)
gh project list --owner <user>
gh project create --owner <user> --title "..."

# Workflow runs
gh run list
gh run watch <id>
gh run download <id> --name <artifact>
```

---

## ▶️ Next

➡️ **[Phase 11 — Intermediate Git](../Chapter16_Intermediate_Git/index.md)** — rebase, bisect, worktrees, submodules, partial clones.
