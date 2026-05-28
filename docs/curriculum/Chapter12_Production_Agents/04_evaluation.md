# Lesson 4 — Evaluation

!!! info "Runnable source file"
    **Path:** `Chapter12_Production_Agents/04_evaluation.py`  
    **Phase:** Phase 7 — Production Agents  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/genai-agentic-ai-handbook)) and run it locally.

```python
"""
Lesson 4: Evaluating Agents — accuracy, hallucination, cost
=============================================================

You can't ship what you can't measure. This module builds a tiny
but production-shaped EVAL HARNESS for agents.

We score every test case on 5 axes:

  1. EXACT / SUBSTRING accuracy   — did the answer contain the right info?
  2. SEMANTIC accuracy            — cosine similarity to reference answer
  3. LLM-as-judge accuracy        — model rates correctness 0–1 (with rationale)
  4. GROUNDEDNESS (hallucination) — is every answer claim supported by the provided context?
  5. COST + LATENCY               — tokens, $, p50/p95 latency

We also compute a final scorecard you can run in CI.

📦 INSTALL:
    pip install rapidfuzz tiktoken
    # Optional: pip install ragas datasets   (Ragas is the de-facto RAG eval lib)

▶️ Run:
    python 04_evaluation.py
"""

from __future__ import annotations
import os
import json
import time
import statistics
import numpy as np
from dataclasses import dataclass, field, asdict
from llm_client import chat, embed


# ----------------------------------------------------------------
# Token + cost helpers (override prices for your real model)
# ----------------------------------------------------------------
INPUT_USD_PER_1K  = float(os.getenv("PRICE_INPUT",  "0.00015"))   # gpt-4o-mini
OUTPUT_USD_PER_1K = float(os.getenv("PRICE_OUTPUT", "0.00060"))


def count_tokens(text: str) -> int:
    try:
        import tiktoken
        return len(tiktoken.get_encoding("cl100k_base").encode(text))
    except Exception:
        return max(1, len(text) // 4)


def cost_usd(input_text: str, output_text: str) -> float:
    return (
        count_tokens(input_text) * INPUT_USD_PER_1K / 1000.0
        + count_tokens(output_text) * OUTPUT_USD_PER_1K / 1000.0
    )


# ----------------------------------------------------------------
# Individual scorers
# ----------------------------------------------------------------
def substring_score(answer: str, expected_keywords: list[str]) -> float:
    """1.0 if every expected keyword appears (case-insensitive), else fraction."""
    if not expected_keywords:
        return 1.0
    a = answer.lower()
    hits = sum(1 for kw in expected_keywords if kw.lower() in a)
    return hits / len(expected_keywords)


def fuzzy_score(answer: str, reference: str) -> float:
    try:
        from rapidfuzz import fuzz
        return fuzz.token_set_ratio(answer, reference) / 100.0
    except ImportError:
        # Fallback: simple Jaccard over words
        a, b = set(answer.lower().split()), set(reference.lower().split())
        return len(a & b) / max(1, len(a | b))


def semantic_score(answer: str, reference: str) -> float:
    a, b = embed(answer), embed(reference)
    a, b = np.array(a), np.array(b)
    return float(np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b) + 1e-9))


JUDGE_SYSTEM = """You are an impartial grader.
You will be given a QUESTION, a REFERENCE answer, and a CANDIDATE answer.
Output ONLY JSON: {"score": 0.0-1.0, "reason": "<one sentence>"}
- 1.0  = candidate fully answers and is factually correct.
- 0.5  = partial / missing key info.
- 0.0  = wrong or refuses to answer when it should not.
"""

def llm_judge_score(question: str, candidate: str, reference: str) -> tuple[float, str]:
    raw = chat(
        [
            {"role": "system", "content": JUDGE_SYSTEM},
            {"role": "user",
             "content": f"QUESTION: {question}\nREFERENCE: {reference}\nCANDIDATE: {candidate}"},
        ],
        temperature=0,
        response_format={"type": "json_object"},
    )
    try:
        data = json.loads(raw)
        return float(data.get("score", 0)), str(data.get("reason", ""))
    except Exception:
        return 0.0, f"unparseable judge output: {raw[:120]}"


GROUNDEDNESS_SYSTEM = """You are a strict groundedness checker.
You receive CONTEXT and an ANSWER. Decide what fraction of the ANSWER's
factual claims are directly supported by the CONTEXT.
Output ONLY JSON: {"score": 0.0-1.0, "unsupported_claims": ["..."]}.
A claim about general knowledge that is uncontroversial counts as supported.
"""

def groundedness_score(context: str, answer: str) -> tuple[float, list[str]]:
    raw = chat(
        [
            {"role": "system", "content": GROUNDEDNESS_SYSTEM},
            {"role": "user", "content": f"CONTEXT:\n{context}\n\nANSWER:\n{answer}"},
        ],
        temperature=0,
        response_format={"type": "json_object"},
    )
    try:
        data = json.loads(raw)
        return float(data.get("score", 0)), list(data.get("unsupported_claims", []))
    except Exception:
        return 0.0, ["unparseable"]


# ----------------------------------------------------------------
# Eval data structures
# ----------------------------------------------------------------
@dataclass
class TestCase:
    id: str
    question: str
    reference: str
    keywords: list[str] = field(default_factory=list)
    context:  str = ""          # for groundedness; can be empty


@dataclass
class CaseResult:
    id: str
    answer: str
    substring: float
    fuzzy: float
    semantic: float
    judge: float
    judge_reason: str
    grounded: float
    unsupported: list[str]
    latency_ms: float
    cost_usd: float


# ----------------------------------------------------------------
# Plug in YOUR agent here. We wrap a tiny RAG-style call for the demo.
# Replace this function with your real agent's `answer(question, context)`.
# ----------------------------------------------------------------
def agent_under_test(question: str, context: str) -> str:
    msgs = [
        {"role": "system", "content":
         "Answer using ONLY the provided CONTEXT. If the answer isn't there, say 'I don't know'."},
        {"role": "user", "content": f"CONTEXT:\n{context}\n\nQUESTION: {question}"},
    ]
    return chat(msgs, temperature=0)


# ----------------------------------------------------------------
# The harness
# ----------------------------------------------------------------
def evaluate(cases: list[TestCase]) -> dict:
    results: list[CaseResult] = []
    for tc in cases:
        t0 = time.perf_counter()
        prompt_text = tc.context + tc.question
        answer = agent_under_test(tc.question, tc.context)
        latency_ms = (time.perf_counter() - t0) * 1000

        sub = substring_score(answer, tc.keywords)
        fz  = fuzzy_score(answer, tc.reference)
        sem = semantic_score(answer, tc.reference)
        jud, jud_reason = llm_judge_score(tc.question, answer, tc.reference)
        grd, unsup = groundedness_score(tc.context, answer) if tc.context else (1.0, [])
        usd = cost_usd(prompt_text, answer)

        r = CaseResult(
            id=tc.id, answer=answer,
            substring=sub, fuzzy=fz, semantic=sem,
            judge=jud, judge_reason=jud_reason,
            grounded=grd, unsupported=unsup,
            latency_ms=latency_ms, cost_usd=usd,
        )
        results.append(r)
        print(f"  {tc.id}  sub={sub:.2f} sem={sem:.2f} judge={jud:.2f} "
              f"grd={grd:.2f}  {latency_ms:6.0f}ms  ${usd:.6f}")

    # Aggregate scorecard
    def avg(xs): return sum(xs) / len(xs) if xs else 0.0
    def pct(xs, p): return statistics.quantiles(xs, n=100)[p - 1] if len(xs) >= 2 else (xs[0] if xs else 0)

    scorecard = {
        "n": len(results),
        "avg_substring":   round(avg([r.substring for r in results]), 3),
        "avg_fuzzy":       round(avg([r.fuzzy for r in results]), 3),
        "avg_semantic":    round(avg([r.semantic for r in results]), 3),
        "avg_judge":       round(avg([r.judge for r in results]), 3),
        "avg_grounded":    round(avg([r.grounded for r in results]), 3),
        "p50_latency_ms":  round(pct([r.latency_ms for r in results], 50), 1),
        "p95_latency_ms":  round(pct([r.latency_ms for r in results], 95), 1),
        "total_cost_usd":  round(sum(r.cost_usd for r in results), 6),
        "hallucination_rate": round(
            sum(1 for r in results if r.unsupported) / max(1, len(results)), 3
        ),
        "details": [asdict(r) for r in results],
    }
    return scorecard


# ----------------------------------------------------------------
# A small test set tied to the IT-support domain we've been using
# ----------------------------------------------------------------
KB = """[vpn.md] Our VPN is Cisco AnyConnect; host vpn.contoso.com; sign in with Entra ID.
[password.md] Passwords must be 14+ chars with upper/lower/digit/symbol. Reset at https://passwords.contoso.com.
[office.md] HQ is open 8am-6pm Mon-Fri and is closed on US federal holidays."""

CASES = [
    TestCase(
        id="C1",
        question="How do I sign into the VPN?",
        reference="Use Cisco AnyConnect, host vpn.contoso.com, with your Entra ID credentials.",
        keywords=["AnyConnect", "Entra"],
        context=KB,
    ),
    TestCase(
        id="C2",
        question="What's the minimum password length?",
        reference="14 characters with upper/lower/digit/symbol.",
        keywords=["14"],
        context=KB,
    ),
    TestCase(
        id="C3",
        question="Who is the CEO of the company?",   # not in context → must say 'I don't know'
        reference="I don't know based on the provided context.",
        keywords=["don't know"],
        context=KB,
    ),
]


# ----------------------------------------------------------------
# CI-friendly gate: fail if any threshold is violated
# ----------------------------------------------------------------
THRESHOLDS = {
    "avg_judge":          0.70,
    "avg_grounded":       0.80,
    "hallucination_rate": 0.20,  # lower is better
    "p95_latency_ms":     8000,
}

def check_thresholds(card: dict) -> list[str]:
    failures = []
    if card["avg_judge"]          < THRESHOLDS["avg_judge"]:
        failures.append(f"avg_judge {card['avg_judge']} < {THRESHOLDS['avg_judge']}")
    if card["avg_grounded"]       < THRESHOLDS["avg_grounded"]:
        failures.append(f"avg_grounded {card['avg_grounded']} < {THRESHOLDS['avg_grounded']}")
    if card["hallucination_rate"] > THRESHOLDS["hallucination_rate"]:
        failures.append(f"hallucination_rate {card['hallucination_rate']} > {THRESHOLDS['hallucination_rate']}")
    if card["p95_latency_ms"]     > THRESHOLDS["p95_latency_ms"]:
        failures.append(f"p95_latency {card['p95_latency_ms']}ms > {THRESHOLDS['p95_latency_ms']}ms")
    return failures


if __name__ == "__main__":
    print("Running eval...")
    card = evaluate(CASES)

    print("\n📊 SCORECARD")
    for k, v in card.items():
        if k != "details":
            print(f"  {k:22} {v}")

    failed = check_thresholds(card)
    if failed:
        print("\n❌ Thresholds violated:")
        for f in failed:
            print("  -", f)
        # In CI, exit with non-zero to fail the build:
        # sys.exit(1)
    else:
        print("\n✅ All thresholds passed.")


# ============================================================
# 🧠 EVAL PRINCIPLES TO REMEMBER
#
# 1. Build a "golden set" of 30–100 hand-curated cases per use case.
#    Update it whenever production surprises you.
# 2. Use MULTIPLE scorers. Any single metric can be gamed.
# 3. Track regressions in CI — block merges that violate thresholds.
# 4. Track DRIFT in production: re-run eval weekly on a sample.
# 5. For RAG: also test RETRIEVAL quality separately (recall@k).
# 6. For agents with tools: add tool-trajectory evals
#    (was the right sequence of tools called?).
# 7. Use Ragas / DeepEval / LangSmith / Azure AI Evaluation in production —
#    they give you nicer UIs, but the math is what you just saw.
# ============================================================

```
