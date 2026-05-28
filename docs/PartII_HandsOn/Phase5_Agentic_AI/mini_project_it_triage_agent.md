# Mini-Project — It Triage Agent

!!! info "Runnable source file"
    **Path:** `Phase5_Agentic_AI/mini_project_it_triage_agent.py`  
    **Phase:** Phase 5 — Agentic AI  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/python-genai-agentic-handbook)) and run it locally.

```python
"""
🏆 PHASE 5 MINI-PROJECT — IT Triage Agent
==========================================

An agent that triages an incoming IT ticket end-to-end:

   1. Classify the ticket (category, priority)
   2. Search the KB for known resolutions
   3. Decide:
        - auto-resolve  → draft a customer reply
        - escalate      → assign to right team + draft handoff note
   4. Log every decision

This is the pattern behind production AI Ops bots.

▶️ Run:
    python mini_project_it_triage_agent.py
"""

from __future__ import annotations
import json
from dataclasses import dataclass, field
from llm_client import chat


# ---------------- Tools the agent can use ----------------
KB = {
    "vpn":      "VPN issues → check AnyConnect, reinstall if needed, contact NetOps.",
    "password": "Password issues → user can self-serve at https://passwords.contoso.com.",
    "printer":  "Printer issues → restart spool service, check toner.",
    "outage":   "Production outage → page on-call SRE immediately.",
}

def search_kb(query: str) -> str:
    for k, v in KB.items():
        if k in query.lower():
            return v
    return "No KB article matched."

TEAMS = {
    "NETWORK":  "NetOps",
    "ACCOUNT":  "IdentityOps",
    "HARDWARE": "DeskSide",
    "SOFTWARE": "AppSupport",
    "OTHER":    "Triage",
}

AUDIT: list[str] = []
def log(msg: str):
    AUDIT.append(msg)
    print("📝", msg)


# ---------------- LLM-powered steps ----------------
CLASSIFY_PROMPT = """You classify IT support tickets.
Respond ONLY with JSON:
{"category":"NETWORK|ACCOUNT|HARDWARE|SOFTWARE|OTHER",
 "priority":"low|medium|high|critical",
 "summary":"<one-line summary>"}"""

DECIDE_PROMPT = """You decide whether to auto-resolve or escalate a ticket.
Auto-resolve only if priority is low/medium AND a KB article clearly covers it.
Respond ONLY with JSON:
{"action":"auto_resolve|escalate","reason":"<short reason>"}"""

REPLY_PROMPT = """You draft a polite, concise reply to a user (3–5 sentences) using the KB note."""
HANDOFF_PROMPT = """You draft a short handoff note (3 bullet points) for the assigned team."""


def classify(ticket: str) -> dict:
    raw = chat(
        [{"role": "system", "content": CLASSIFY_PROMPT},
         {"role": "user",   "content": ticket}],
        temperature=0, response_format={"type": "json_object"})
    try:
        return json.loads(raw)
    except Exception:
        return {"category": "OTHER", "priority": "medium", "summary": ticket[:80]}


def decide(ticket: str, classification: dict, kb_note: str) -> dict:
    raw = chat(
        [{"role": "system", "content": DECIDE_PROMPT},
         {"role": "user", "content":
          f"TICKET: {ticket}\nCLASSIFICATION: {classification}\nKB_NOTE: {kb_note}"}],
        temperature=0, response_format={"type": "json_object"})
    try:
        return json.loads(raw)
    except Exception:
        return {"action": "escalate", "reason": "fallback"}


def draft_reply(ticket: str, kb_note: str) -> str:
    return chat(
        [{"role": "system", "content": REPLY_PROMPT},
         {"role": "user",   "content": f"TICKET: {ticket}\nKB: {kb_note}"}],
        temperature=0.4, max_tokens=300)


def draft_handoff(ticket: str, classification: dict) -> str:
    return chat(
        [{"role": "system", "content": HANDOFF_PROMPT},
         {"role": "user",   "content": f"TICKET: {ticket}\nCLASS: {classification}"}],
        temperature=0.3, max_tokens=300)


# ---------------- The orchestrator (agent loop) ----------------
@dataclass
class TriageResult:
    ticket: str
    classification: dict = field(default_factory=dict)
    kb_note: str = ""
    decision: dict = field(default_factory=dict)
    outcome: str = ""


def triage(ticket: str) -> TriageResult:
    res = TriageResult(ticket=ticket)
    log(f"received: {ticket}")

    res.classification = classify(ticket)
    log(f"classified → {res.classification}")

    res.kb_note = search_kb(ticket)
    log(f"kb       → {res.kb_note}")

    res.decision = decide(ticket, res.classification, res.kb_note)
    log(f"decision → {res.decision}")

    if res.decision.get("action") == "auto_resolve":
        res.outcome = draft_reply(ticket, res.kb_note)
        log("outcome  → auto-replied to user")
    else:
        team = TEAMS.get(res.classification.get("category", "OTHER"), "Triage")
        res.outcome = f"ASSIGNED TO {team}:\n" + draft_handoff(ticket, res.classification)
        log(f"outcome  → escalated to {team}")

    return res


SAMPLES = [
    "User priya@contoso.com forgot her password and cannot log in.",
    "All of production is down — orders failing with 500 errors!",
    "My printer on floor 3 won't print color anymore.",
    "VPN keeps dropping every 2 minutes during meetings.",
]

if __name__ == "__main__":
    for t in SAMPLES:
        print("\n" + "=" * 70)
        r = triage(t)
        print("\n📨 FINAL OUTCOME:\n" + r.outcome)

    print("\n" + "=" * 70)
    print("📊 AUDIT TRAIL:")
    for line in AUDIT:
        print("  -", line)


# ============================================================
# 🎓 EXTENSIONS:
#  1. Persist tickets and decisions to a JSON file ("inbox.json").
#  2. Add a `human_review` step before sending real emails.
#  3. Replace `search_kb` with the Phase 4 RAG system.
#  4. Add cost/step guardrails from Lesson 5.
#  5. Wire your real Send-EscalationEmail.ps1 workflow as the "send" tool.
# ============================================================

```
