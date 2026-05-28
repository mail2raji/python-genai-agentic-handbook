# Phase 0 — Exercise answers

### Drill 1 — Four versions

```powershell
git --version       # git version 2.46.x
gh --version        # gh version 2.59.0 (...)
code --version      # 1.94.x or newer
python --version    # Python 3.11.x or newer
```

If any of these fail, re-run the install in [SETUP.md](../../SETUP.md).

### Drill 2 — `gh auth status`

```text
github.com
  ✓ Logged in to github.com account mail2raji (oauth_token)
  - Active account: true
  - Git operations protocol: https
  - Token: gho_************************************
  - Token scopes: 'gist', 'read:org', 'repo', 'workflow'
```

You should see your own GitHub handle, not `mail2raji`.

### Drill 3 — `gh copilot explain`

```powershell
gh copilot explain "git rebase --autosquash"
```

Expected: a multi-line explanation describing how `--autosquash` consumes commit messages that start with `fixup!` / `squash!` and reorders them automatically.

### Drill 4 — Copilot completion

The completion you should accept:

```python
def reverse_string(s: str) -> str:
    """Return the input string reversed."""
    return s[::-1]
```

If Copilot does not respond:
- Check the bottom-right status bar — it must say *Copilot*.
- `gh auth status` must show you logged in.
- Reload window (`Ctrl+Shift+P` → *Developer: Reload Window*).
