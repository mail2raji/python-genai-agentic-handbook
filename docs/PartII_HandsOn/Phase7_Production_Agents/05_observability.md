# Lesson 5 — Observability

!!! info "Runnable source file"
    **Path:** `Phase7_Production_Agents/05_observability.py`  
    **Phase:** Phase 7 — Production Agents  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/python-genai-agentic-handbook)) and run it locally.

```python
"""
Lesson 5: Observability — logs, traces, metrics for AI agents
================================================================

You can't debug what you can't see. Production agents need 3 pillars:

  1. STRUCTURED LOGS   — machine-parseable JSON; one log per event
  2. TRACES            — spans linking LLM calls / tool calls in one request
  3. METRICS           — counters & histograms exported to Prometheus / Azure Monitor

This file gives you a tiny, dependency-tolerant stack that does ALL three
and degrades gracefully if libraries aren't installed.

📦 INSTALL (recommended):
    pip install structlog opentelemetry-api opentelemetry-sdk \\
                opentelemetry-exporter-otlp prometheus-client

Connect it to your stack:
  - Azure Monitor / App Insights:  pip install azure-monitor-opentelemetry
  - Jaeger / Tempo / Grafana:       OTEL_EXPORTER_OTLP_ENDPOINT=http://collector:4317
  - Plain console:                  unset OTEL_EXPORTER_OTLP_ENDPOINT
"""

from __future__ import annotations
import os
import time
import uuid
import json
import logging
import functools
import contextvars
from contextlib import contextmanager
from llm_client import chat


# ----------------------------------------------------------------
# (1) STRUCTURED LOGS
# ----------------------------------------------------------------
# Every log line is JSON with a trace_id, so you can correlate logs
# with traces in any backend.

trace_id_var = contextvars.ContextVar("trace_id", default="-")
user_id_var  = contextvars.ContextVar("user_id",  default="-")


class JsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        payload = {
            "ts":      time.strftime("%Y-%m-%dT%H:%M:%S", time.gmtime(record.created)),
            "level":   record.levelname,
            "msg":     record.getMessage(),
            "logger":  record.name,
            "trace_id": trace_id_var.get(),
            "user_id":  user_id_var.get(),
        }
        # Anything passed via extra=... is merged in
        for k, v in record.__dict__.get("extra_fields", {}).items():
            payload[k] = v
        return json.dumps(payload, default=str)


def get_logger(name: str = "agent") -> logging.Logger:
    log = logging.getLogger(name)
    if log.handlers:
        return log
    h = logging.StreamHandler()
    h.setFormatter(JsonFormatter())
    log.addHandler(h)
    log.setLevel(os.getenv("LOG_LEVEL", "INFO"))
    log.propagate = False
    return log


def log_event(log: logging.Logger, level: str, msg: str, **fields):
    """Helper to log with structured extra fields."""
    getattr(log, level.lower())(msg, extra={"extra_fields": fields})


# ----------------------------------------------------------------
# (2) TRACES (OpenTelemetry)
# ----------------------------------------------------------------
# Falls back to a no-op tracer if OTel isn't installed.
try:
    from opentelemetry import trace
    from opentelemetry.sdk.trace import TracerProvider
    from opentelemetry.sdk.trace.export import (
        BatchSpanProcessor, ConsoleSpanExporter,
    )
    from opentelemetry.sdk.resources import Resource

    provider = TracerProvider(resource=Resource.create({"service.name": "demo-agent"}))
    # Console exporter is great for local dev; swap for OTLP in prod
    if os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT"):
        from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
        provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter()))
    else:
        provider.add_span_processor(BatchSpanProcessor(ConsoleSpanExporter()))
    trace.set_tracer_provider(provider)
    tracer = trace.get_tracer(__name__)
    HAVE_OTEL = True
except Exception as e:
    print(f"(otel not available: {e}) — using no-op tracer")
    HAVE_OTEL = False

    class _NoopSpan:
        def __enter__(self): return self
        def __exit__(self, *a): return False
        def set_attribute(self, *a, **k): pass
        def record_exception(self, *a, **k): pass
        def set_status(self, *a, **k): pass

    class _NoopTracer:
        def start_as_current_span(self, *a, **k): return _NoopSpan()

    tracer = _NoopTracer()


@contextmanager
def span(name: str, **attributes):
    """Convenience wrapper to start a span with attributes."""
    with tracer.start_as_current_span(name) as s:
        for k, v in attributes.items():
            s.set_attribute(k, v)
        try:
            yield s
        except Exception as ex:
            s.record_exception(ex)
            raise


# ----------------------------------------------------------------
# (3) METRICS (Prometheus)
# ----------------------------------------------------------------
try:
    from prometheus_client import Counter, Histogram, start_http_server
    LLM_CALLS  = Counter("agent_llm_calls_total", "LLM calls", ["model", "outcome"])
    LLM_TOKENS = Counter("agent_llm_tokens_total", "Tokens", ["model", "kind"])
    LLM_COST   = Counter("agent_llm_cost_usd_total", "Cost in USD", ["model"])
    LLM_LATENCY = Histogram("agent_llm_latency_seconds", "LLM latency", ["model"])
    TOOL_CALLS  = Counter("agent_tool_calls_total", "Tool calls", ["tool", "outcome"])
    HAVE_PROM = True
except Exception:
    HAVE_PROM = False
    class _Noop:
        def labels(self, *a, **k): return self
        def inc(self, *a, **k): pass
        def observe(self, *a, **k): pass
    LLM_CALLS = LLM_TOKENS = LLM_COST = LLM_LATENCY = TOOL_CALLS = _Noop()


# ----------------------------------------------------------------
# Instrumented LLM + tool decorators
# ----------------------------------------------------------------
INPUT_USD_PER_1K  = float(os.getenv("PRICE_INPUT",  "0.00015"))
OUTPUT_USD_PER_1K = float(os.getenv("PRICE_OUTPUT", "0.00060"))


def _estimate_tokens(text: str) -> int:
    try:
        import tiktoken
        return len(tiktoken.get_encoding("cl100k_base").encode(text))
    except Exception:
        return max(1, len(text) // 4)


log = get_logger()


def instrumented_chat(messages, model="gpt-4o-mini", **kw) -> str:
    """Wraps chat() with span + metrics + structured log."""
    prompt_text = "".join(m.get("content", "") for m in messages)
    in_tok = _estimate_tokens(prompt_text)

    with span("llm.chat", **{"llm.model": model, "llm.input_tokens": in_tok}) as s:
        t0 = time.perf_counter()
        try:
            reply = chat(messages, **kw)
            out_tok = _estimate_tokens(reply)
            dur = time.perf_counter() - t0
            usd = in_tok * INPUT_USD_PER_1K / 1000 + out_tok * OUTPUT_USD_PER_1K / 1000

            s.set_attribute("llm.output_tokens", out_tok)
            s.set_attribute("llm.cost_usd", usd)
            s.set_attribute("llm.latency_ms", dur * 1000)

            LLM_CALLS.labels(model, "ok").inc()
            LLM_TOKENS.labels(model, "in").inc(in_tok)
            LLM_TOKENS.labels(model, "out").inc(out_tok)
            LLM_COST.labels(model).inc(usd)
            LLM_LATENCY.labels(model).observe(dur)

            log_event(log, "info", "llm.chat",
                      model=model, in_tok=in_tok, out_tok=out_tok,
                      latency_ms=round(dur * 1000, 1), cost_usd=round(usd, 6))
            return reply
        except Exception as e:
            LLM_CALLS.labels(model, "error").inc()
            log_event(log, "error", "llm.chat.failed", err=str(e))
            raise


def instrument_tool(name: str):
    """Decorator: wrap any Python tool with a span + metric + log."""
    def wrap(fn):
        @functools.wraps(fn)
        def inner(*args, **kwargs):
            with span(f"tool.{name}", **{"tool.name": name,
                                         "tool.args": json.dumps(kwargs)[:200]}) as s:
                t0 = time.perf_counter()
                try:
                    result = fn(*args, **kwargs)
                    dur = time.perf_counter() - t0
                    s.set_attribute("tool.latency_ms", dur * 1000)
                    TOOL_CALLS.labels(name, "ok").inc()
                    log_event(log, "info", "tool.ok", tool=name,
                              latency_ms=round(dur * 1000, 1))
                    return result
                except Exception as e:
                    TOOL_CALLS.labels(name, "error").inc()
                    log_event(log, "error", "tool.error", tool=name, err=str(e))
                    raise
        return inner
    return wrap


# ----------------------------------------------------------------
# Per-request context
# ----------------------------------------------------------------
@contextmanager
def request_scope(user_id: str):
    """Set up trace_id + user_id for one logical request."""
    tid = str(uuid.uuid4())
    t1 = trace_id_var.set(tid)
    t2 = user_id_var.set(user_id)
    try:
        with span("request", **{"user.id": user_id, "trace_id": tid}):
            yield tid
    finally:
        trace_id_var.reset(t1)
        user_id_var.reset(t2)


# ----------------------------------------------------------------
# Demo
# ----------------------------------------------------------------
@instrument_tool("search_kb")
def search_kb(query: str) -> str:
    facts = {
        "vpn": "Cisco AnyConnect, host vpn.contoso.com",
        "password": "14+ chars, reset at https://passwords.contoso.com",
    }
    for k, v in facts.items():
        if k in query.lower():
            return v
    return "no match"


def run_demo():
    if HAVE_PROM and os.getenv("PROM_PORT"):
        port = int(os.getenv("PROM_PORT"))
        start_http_server(port)
        print(f"📈 Prometheus exporter on :{port}/metrics")

    with request_scope(user_id="u-42") as tid:
        log_event(log, "info", "request.start", question="vpn login?")
        kb = search_kb("VPN login")
        answer = instrumented_chat(
            [
                {"role": "system", "content": "Answer using ONLY the KB."},
                {"role": "user",   "content": f"KB: {kb}\n\nQ: How do I log into the VPN?"},
            ],
            temperature=0,
        )
        log_event(log, "info", "request.done", answer=answer[:120])
        print("\nANSWER:", answer)


if __name__ == "__main__":
    run_demo()


# ============================================================
# 🧠 OBSERVABILITY CHECKLIST
#   - [ ] Every request gets a UUID trace_id propagated through logs + spans
#   - [ ] Every LLM call: model, in_tok, out_tok, latency_ms, cost_usd
#   - [ ] Every tool call: tool name, args (sanitized!), outcome
#   - [ ] Errors logged with full exception (but never log secrets/PII)
#   - [ ] Sample full prompts at low rate (e.g., 1%) for debugging
#   - [ ] SLO dashboards: latency p95, error rate, $/request
#   - [ ] Alerts: $/hour > budget, hallucination_rate > X (from eval)
# ============================================================

```
