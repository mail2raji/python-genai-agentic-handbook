# 📖 GenAI & Agentic AI Handbook

> **Read it online → <https://mail2raji.github.io/python-genai-agentic-handbook/>**

A beginner-to-advanced curriculum that takes you from *"what is an LLM?"* all the way to building multi-agent systems with **LangChain, LangGraph and CrewAI**.

19 lessons across 5 modules, every one with a 5-year-old-friendly story, real-world scenario, fully-explained code, exercises, and worked solutions.

---

## 📚 What's in this repo

| Path | What it is |
|---|---|
| [`docs/`](docs/) | All curriculum content — homepage, [SETUP](docs/SETUP.md), and the 5 modules |
| [`mkdocs.yml`](mkdocs.yml) | MkDocs Material site config (theme, navigation) |
| [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml) | Auto-publishes the book to GitHub Pages on every push to `main` |
| [`requirements-docs.txt`](requirements-docs.txt) | Packages used to build the book |
| [`requirements.txt`](requirements.txt) | Packages used by the lesson code (OpenAI, LangChain, etc.) |
| [`PUBLISH.md`](PUBLISH.md) | Step-by-step guide to publish or preview the book |

---

## 🚀 Quick start

**Read offline:** open [`docs/index.md`](docs/index.md), then [`docs/SETUP.md`](docs/SETUP.md), then work through the modules in order.

**Publish online:** see **[PUBLISH.md](PUBLISH.md)** — three commands and a one-time GitHub Pages setting.

**Preview locally:**

```powershell
pip install -r requirements-docs.txt
mkdocs serve     # then open http://127.0.0.1:8000
```

---

## 📝 License

Free to read, fork, and teach with. Attribution appreciated.
