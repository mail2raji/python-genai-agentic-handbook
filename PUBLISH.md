# 📖 Publishing this curriculum as a book on GitHub Pages

This folder is already wired up to publish as a Material-themed online book at:

> **https://mail2raji.github.io/python-genai-agentic-handbook/**

The book is built with **[MkDocs Material](https://squidfunk.github.io/mkdocs-material/)** and auto-deployed by **GitHub Actions** whenever you push to `main`.

---

## 🧭 What you'll do (one-time setup)

1. Push these files to the empty repo `python-genai-agentic-handbook`.
2. Enable GitHub Pages → "GitHub Actions" as the source.
3. Push commits → site rebuilds & redeploys automatically.

---

## 🚀 Step 1 — Push the curriculum to GitHub

Open a terminal in this folder (`GenAI_Agentic_AI_Curriculum/`) and run:

```powershell
# 1. Initialise a fresh repo
git init -b main

# 2. Stage everything except build outputs (.gitignore handles that)
git add .
git commit -m "Initial commit: GenAI & Agentic AI curriculum"

# 3. Wire it to the GitHub repo
git remote add origin https://github.com/mail2raji/python-genai-agentic-handbook.git

# 4. Push (force the first time if the repo already has a default README)
git push -u origin main --force
```

> ⚠️ `--force` only on the **first** push to overwrite GitHub's auto-generated README. After that, use plain `git push`.

---

## 🛠 Step 2 — Enable GitHub Pages

1. Open the repo in your browser → **Settings** → **Pages**.
2. Under **Build and deployment → Source**, choose **GitHub Actions**.
3. (No further form to fill — the workflow at `.github/workflows/deploy.yml` does the rest.)

That's it. The first deploy starts the moment you pushed in Step 1.

---

## 🔄 Step 3 — Watch it build

1. Go to the **Actions** tab on GitHub.
2. You'll see a workflow run named *"Deploy book to GitHub Pages"*.
3. After ~1–2 minutes both jobs (`build` ▸ `deploy`) turn green.
4. Open: <https://mail2raji.github.io/python-genai-agentic-handbook/> 🎉

---

## ✏️ Step 4 — Edit and re-publish

Any time you want to change a lesson:

```powershell
# Edit a markdown file, e.g.
notepad Module1_GenAI_Foundations/01_Introduction_to_GenAI.md

# Commit & push
git add .
git commit -m "Improve lesson 1.1 examples"
git push
```

GitHub Actions rebuilds and republishes in about a minute.

---

## 👀 Preview locally (optional)

```powershell
# Install build deps into your venv
pip install -r requirements-docs.txt

# Serve at http://127.0.0.1:8000 with hot-reload
mkdocs serve
```

Edit any `.md` file and your browser refreshes automatically.

---

## 🗂 What each file does

| File | Purpose |
|---|---|
| [mkdocs.yml](mkdocs.yml) | Site config: theme, navigation, markdown plugins |
| [.github/workflows/deploy.yml](.github/workflows/deploy.yml) | CI pipeline that builds and publishes |
| [requirements-docs.txt](requirements-docs.txt) | Pip packages used by the build job |
| [requirements.txt](requirements.txt) | Runtime packages for the lessons (separate concern) |
| [.gitignore](.gitignore) | Keeps `_site/`, venvs, caches out of the repo |

---

## 🎨 Want a different theme or layout?

- **Different colours / fonts** → edit `theme.palette` and `theme.font` in [mkdocs.yml](mkdocs.yml).
- **Different sidebar order** → reorder the `nav:` block in [mkdocs.yml](mkdocs.yml).
- **Different theme entirely** → swap `theme.name` to `readthedocs`, or install a Jekyll theme such as Just the Docs.

---

## 🆘 Troubleshooting

| Symptom | Fix |
|---|---|
| Action fails with *"Pages site failed to create"* | First enable Pages → "GitHub Actions" (Step 2). Re-run the workflow. |
| Internal links 404 on the published site | Make sure links use the **same case** as the file names (Linux runners are case-sensitive). |
| Build error *"file not in nav"* | Add the new `.md` file to `nav:` in `mkdocs.yml`, or remove `--strict` from the workflow. |
| Site published but stuck on old version | Hard-refresh (`Ctrl+F5`) or clear browser cache; CDN updates within a few minutes. |

---

Happy publishing! 🚀
