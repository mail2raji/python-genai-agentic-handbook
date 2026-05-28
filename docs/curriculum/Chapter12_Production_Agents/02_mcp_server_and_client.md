# Lesson 2 — Mcp Server And Client

!!! info "Runnable source file"
    **Path:** `Chapter12_Production_Agents/02_mcp_server_and_client.py`  
    **Phase:** Phase 7 — Production Agents  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/genai-agentic-ai-handbook)) and run it locally.

```python
"""
Lesson 2: A real MCP server + client in Python
================================================

Two roles in one file — toggle with command-line arg.

▶️ Run the SERVER (in one terminal):
    python 02_mcp_server_and_client.py server

▶️ Run the CLIENT (in another terminal):
    python 02_mcp_server_and_client.py client

The client connects to the server via stdio, lists tools,
calls one, and prints the result.

📦 INSTALL:
    pip install mcp

📖 Docs:
    https://modelcontextprotocol.io/
    https://github.com/modelcontextprotocol/python-sdk
"""

from __future__ import annotations
import sys
import os
import asyncio
import json


# =================================================================
#  SERVER SIDE — exposes 3 tools mapped to your real workspace
# =================================================================
async def run_server():
    """
    A tiny MCP server exposing safe, scoped tools over the workspace.
    All file ops are constrained to ROOT_DIR — a key security pattern.
    """
    try:
        from mcp.server import Server
        from mcp.server.stdio import stdio_server
        import mcp.types as types
    except ImportError:
        print("Please install:  pip install mcp", file=sys.stderr)
        sys.exit(1)

    ROOT_DIR = os.path.abspath(
        os.path.join(os.path.dirname(__file__), "..", "..")
    )  # = c:\Scripts\Send-escalationEmail

    server = Server("send-escalation-tools")

    @server.list_tools()
    async def list_tools() -> list[types.Tool]:
        return [
            types.Tool(
                name="list_scripts",
                description="List PowerShell scripts in the workspace.",
                inputSchema={"type": "object", "properties": {}},
            ),
            types.Tool(
                name="read_script",
                description="Read the contents of a single .ps1 file by name.",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "name": {
                            "type": "string",
                            "description": "Filename like 'Send-EscalationEmail.ps1'.",
                        }
                    },
                    "required": ["name"],
                },
            ),
            types.Tool(
                name="search_scripts",
                description="Case-insensitive grep across all .ps1 files. Returns matching filenames + first line.",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "needle": {"type": "string", "description": "Substring to search for."}
                    },
                    "required": ["needle"],
                },
            ),
        ]

    def _safe_path(name: str) -> str:
        """Reject anything that escapes ROOT_DIR or isn't a .ps1 file."""
        if "/" in name or "\\" in name or ".." in name:
            raise ValueError("Only bare filenames are allowed.")
        if not name.lower().endswith(".ps1"):
            raise ValueError("Only .ps1 files can be read.")
        p = os.path.abspath(os.path.join(ROOT_DIR, name))
        if not p.startswith(ROOT_DIR):
            raise ValueError("Path escapes workspace.")
        return p

    @server.call_tool()
    async def call_tool(name: str, arguments: dict) -> list[types.TextContent]:
        # Every call returns a list of content blocks — required by the protocol
        try:
            if name == "list_scripts":
                files = sorted(f for f in os.listdir(ROOT_DIR) if f.endswith(".ps1"))
                payload = {"count": len(files), "files": files}

            elif name == "read_script":
                path = _safe_path(arguments["name"])
                with open(path, "r", encoding="utf-8", errors="ignore") as f:
                    text = f.read()
                # Cap to 8 KB to avoid token blowups
                payload = {"name": arguments["name"], "content": text[:8000]}

            elif name == "search_scripts":
                needle = arguments["needle"].lower()
                hits = []
                for fn in os.listdir(ROOT_DIR):
                    if not fn.endswith(".ps1"):
                        continue
                    try:
                        with open(os.path.join(ROOT_DIR, fn),
                                  "r", encoding="utf-8", errors="ignore") as f:
                            text = f.read()
                    except Exception:
                        continue
                    if needle in text.lower():
                        first = next((ln for ln in text.splitlines() if ln.strip()), "")
                        hits.append({"file": fn, "first_line": first[:120]})
                payload = {"needle": arguments["needle"], "hits": hits}

            else:
                payload = {"error": f"Unknown tool {name}"}

            return [types.TextContent(type="text", text=json.dumps(payload, indent=2))]

        except Exception as e:
            return [types.TextContent(type="text",
                                       text=json.dumps({"error": str(e)}))]

    async with stdio_server() as (read_stream, write_stream):
        print("[server] ready on stdio", file=sys.stderr)
        await server.run(read_stream, write_stream, server.create_initialization_options())


# =================================================================
#  CLIENT SIDE — launches the server as a subprocess and talks to it
# =================================================================
async def run_client():
    try:
        from mcp import ClientSession, StdioServerParameters
        from mcp.client.stdio import stdio_client
    except ImportError:
        print("Please install:  pip install mcp", file=sys.stderr)
        sys.exit(1)

    params = StdioServerParameters(
        command=sys.executable,
        args=[os.path.abspath(__file__), "server"],
    )

    async with stdio_client(params) as (read, write):
        async with ClientSession(read, write) as session:
            await session.initialize()

            tools = await session.list_tools()
            print("\n🛠️  Discovered tools:")
            for t in tools.tools:
                print(f"  - {t.name}: {t.description}")

            print("\n▶️  Calling list_scripts...")
            result = await session.call_tool("list_scripts", arguments={})
            print(result.content[0].text)

            print("\n▶️  Calling search_scripts (needle='Send-MailMessage')...")
            result = await session.call_tool(
                "search_scripts", arguments={"needle": "Send-MailMessage"}
            )
            print(result.content[0].text)


if __name__ == "__main__":
    role = sys.argv[1] if len(sys.argv) > 1 else "client"
    if role == "server":
        asyncio.run(run_server())
    else:
        asyncio.run(run_client())


# ============================================================
# 🧠 What you just saw:
#   - A real MCP server exposing 3 tools over your workspace.
#   - Security: filename validation + ROOT_DIR sandboxing + size caps.
#   - A client that discovers tools dynamically.
#
# Plug this server into VS Code by adding to your mcp.json:
#   {
#     "servers": {
#       "send-escalation-tools": {
#         "command": "python",
#         "args": ["c:/Scripts/Send-escalationEmail/PythonGenAI_Learning/Chapter12_Production_Agents/02_mcp_server_and_client.py", "server"]
#       }
#     }
#   }
# ============================================================

```
