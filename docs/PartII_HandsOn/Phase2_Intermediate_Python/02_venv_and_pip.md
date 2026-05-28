# Lesson 2: Virtual Environments & pip

## 📖 Why?
Every AI project needs its own isolated set of libraries.
A **virtual environment** keeps `Project A` (using `langchain 0.1`) from breaking `Project B` (using `langchain 0.2`).

## 💡 Analogy
Like having separate toolboxes for each home project — you don't dump every screw into one drawer.

---

## ✅ Step-by-step (PowerShell)

### 1. Create a venv in this folder
```powershell
cd c:\Scripts\Send-escalationEmail\PythonGenAI_Learning
python -m venv .venv
```

### 2. Activate it
```powershell
.\.venv\Scripts\Activate.ps1
```
> If you see an execution-policy error, run:
> `Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned`

After activation, your prompt shows `(.venv)`.

### 3. Install packages
```powershell
pip install --upgrade pip
pip install requests python-dotenv rich
```

### 4. Save your dependencies
```powershell
pip freeze > requirements.txt
```

### 5. Restore later
```powershell
pip install -r requirements.txt
```

### 6. Deactivate
```powershell
deactivate
```

---

## 🧠 Key commands

| Command | What it does |
|---|---|
| `pip install X` | Install package X |
| `pip install "X==1.2.3"` | Install specific version |
| `pip uninstall X` | Remove a package |
| `pip list` | List installed packages |
| `pip show X` | Show package details |

---

## ✏️ Exercise
1. Create a venv called `.venv` at the workspace root.
2. Activate it.
3. Install `rich` and `requests`.
4. Run `pip freeze > requirements.txt`.
5. Open requirements.txt and inspect it.

