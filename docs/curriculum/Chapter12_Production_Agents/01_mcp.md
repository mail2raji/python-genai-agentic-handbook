# Lesson 1: MCP — Model Context Protocol

## 🤔 What problem does MCP solve?

Every agent eventually needs to **read & write external systems**: files, databases, GitHub, Jira, your PowerShell scripts, Azure resources, internal APIs.

Without MCP, every team writes its own glue:
- Tools live inside each agent app.
- LangChain has one tool format, AutoGen another, Semantic Kernel another.
- An "Outlook tool" you wrote can't be reused by another agent.

**MCP (Model Context Protocol)** is an open standard introduced by Anthropic in 2024 and adopted across the industry (Anthropic, OpenAI, Microsoft Copilot, VS Code, Cursor, Cline, etc.) that defines:

> A standard way for AI clients (agents) to discover and call tools, read resources, and use prompts exposed by external **servers**.

Think **"USB-C for AI tools"**.

---

## 🧩 Core concepts

| Concept | Meaning |
|---|---|
| **MCP Server** | A process that exposes tools, resources, and prompts. Examples: Filesystem, GitHub, PostgreSQL, Azure, your own. |
| **MCP Client** | The agent/IDE that calls the server. Examples: Claude Desktop, VS Code Copilot, Cursor, your custom agent. |
| **Tools** | Functions the LLM can call (`read_file`, `create_issue`). |
| **Resources** | Read-only data (a file's contents, a DB row). Identified by URI. |
| **Prompts** | Reusable, server-defined prompt templates. |
| **Transports** | How client ↔ server talk: `stdio` (local subprocess), `streamable HTTP` (remote). |

---

## 🔄 Flow

```
┌──────────────┐   JSON-RPC over stdio/HTTP   ┌──────────────┐
│  MCP Client  │  ────────────────────────►   │  MCP Server  │
│  (your agent)│                              │ (tools/data) │
│              │  ◄────────────────────────   │              │
└──────────────┘   {tools, results, etc.}     └──────────────┘
```

1. Client connects, lists capabilities.
2. Client calls `tools/list`, `resources/list`, `prompts/list`.
3. When the LLM decides "I need to do X", the agent calls `tools/call`.
4. Server runs the function and returns the result.

---

## 🆚 MCP vs OpenAI function calling vs LangChain tools

| | OpenAI function calling | LangChain tools | **MCP** |
|---|---|---|---|
| Tool location | Inside your app | Inside your app | **External process, reusable** |
| Standard | Vendor-specific | Library-specific | **Open standard** |
| Discovery | Manual | Manual | **Dynamic** |
| Reuse across teams | ❌ | ❌ | **✅** |
| Hot-swap servers | ❌ | ❌ | **✅** |

You don't replace function calling — **you wrap it**. Your agent still uses function calling to talk to the LLM, but the *implementation* of those tools lives in MCP servers.

---

## 🌍 Real-world examples

- **Anthropic's reference servers**: filesystem, GitHub, Slack, Postgres, Brave search.
- **Microsoft**: Azure MCP server (exposes 50+ Azure tools — what's lighting up the tools in this very workspace!).
- **VS Code Copilot**: discovers MCP servers via `mcp.json`, then surfaces their tools to chat.
- **Cursor / Cline**: same model — bring your own server.

---

## 🛠️ When SHOULD you build an MCP server?

✅ You have internal systems (your PowerShell scripts!) that multiple AI clients should use.
✅ You want one team to own the tool, others to consume it.
✅ You want to swap the LLM provider without re-implementing tools.

❌ You're prototyping a one-off agent → just use function calling.

---

## 🔐 Security notes (critical!)

- MCP servers run with **YOUR** privileges. Treat them like CLI tools.
- Always **scope** what each server can touch (e.g., filesystem server: only `/data`, not `C:\`).
- Validate arguments — never `eval()` user-provided strings.
- For remote (HTTP) servers: require auth (OAuth2/JWT), use TLS.
- Audit-log every `tools/call`.

Continue to **`02_mcp_server_and_client.py`** to see real code.

