# SimpleLLMRouter v2 — Technical Specification

**Version:** 2.0 | **Date:** 2026-03-09 | **Owner:** Antonio Reid
**Repo:** AReid987/meta-code-squad | **Package:** apps/simplellmrouter/
**Status:** Approved — Implementation in Progress

---

## 1. Overview

SimpleLLMRouter v2 is an OpenAI-compatible LLM gateway that intelligently routes AI inference
requests across 8+ free-tier providers. It runs as a local proxy server at `http://localhost:8080`
and is the central nervous system of the Aigency Meta Code Squad agentic harness.

**Design goals:**
- ~1 billion free tokens/month through intelligent multi-provider quota management
- Sub-100ms routing decisions using local embeddings (no LLM call needed)
- 30-60% token savings via 3-layer semantic caching
- 99.9% uptime through cascade fallback across providers
- Zero vendor lock-in — swap providers without changing client code

---

## 2. Architecture

```
Client (agent / IDE / CLI)
        |
        v
SimpleLLMRouter v2  (:8080)
        |
        +-- Intent Classifier (local embeddings, ~100ms)
        |
        +-- Complexity Scorer (14-dimension, rule-based)
        |
        +-- Cache Layer
        |     +-- L1: In-memory (5 min TTL)
        |     +-- L2: SQLite disk (24 hr TTL)
        |     +-- L3: Semantic similarity (72 hr TTL, hnswlib)
        |
        +-- Routing Engine
        |     +-- Strategy selector (quality/cost/latency/balanced/shuffle)
        |     +-- Quota manager (per-provider circuit breaker)
        |     +-- Cascade fallback (cheapest -> escalate on quality threshold fail)
        |
        +-- OptiLLM Bridge (optional, inference enhancement)
        |
        +-- Provider Adapters
              +-- Anthropic (Claude)
              +-- Google Gemini
              +-- Moonshot Kimi
              +-- OpenAI
              +-- Qwen / Roo
              +-- DeepSeek
              +-- Together AI
              +-- Groq
```

---

## 3. Intent Classification

### 3.1 Intent Categories

| Intent | Description | Preferred Tier |
|--------|-------------|----------------|
| `CODE_REVIEW` | Review existing code for bugs, style, security | STANDARD |
| `BUG_FIX` | Diagnose and fix a specific bug | STANDARD |
| `ARCHITECTURE` | Design systems, plan structures, evaluate tradeoffs | COMPLEX |
| `SECURITY` | Security audits, vulnerability analysis, auth design | COMPLEX |
| `DOCS` | Write or update documentation | SIMPLE |
| `CHAT` | Conversational, general questions | SIMPLE |
| `REASONING` | Multi-step logic, math, complex analysis | COMPLEX |
| `CODE_GEN` | Generate new code from spec | STANDARD |
| `REFACTOR` | Restructure existing code without changing behavior | STANDARD |
| `TEST_GEN` | Generate test cases and test suites | STANDARD |

### 3.2 Classification Method

Uses local sentence-transformer embeddings (no API call):
1. Embed incoming prompt
2. Compute cosine similarity against intent example bank
3. Return top-1 intent + confidence score
4. If confidence < 0.7, fall back to keyword matching

Latency: ~80-120ms on CPU, ~20-40ms on GPU

---

## 4. Complexity Scoring

### 4.1 14 Dimensions

| Dimension | Weight | Description |
|-----------|--------|-------------|
| Code complexity | 0.12 | Lines, nesting depth, cyclomatic complexity |
| Logic steps | 0.10 | Estimated reasoning steps required |
| Context length | 0.10 | Input token count relative to model limits |
| Tool calling | 0.09 | Requires function/tool calls |
| Security sensitivity | 0.09 | Touches auth, secrets, PII |
| Creativity required | 0.08 | Novel solutions vs pattern application |
| Multi-file scope | 0.08 | Spans multiple files or modules |
| Precision required | 0.08 | Low tolerance for error |
| Domain specificity | 0.07 | Requires specialized knowledge |
| Ambiguity level | 0.07 | Underspecified or conflicting requirements |
| Output length | 0.06 | Expected response length |
| Iteration likelihood | 0.06 | Likely to require follow-up |

### 4.2 Score → Tier Mapping

| Score | Tier | Default Provider |
|-------|------|------------------|
| 0.0 - 0.3 | SIMPLE | Qwen / Roo / Groq |
| 0.3 - 0.6 | STANDARD | Moonshot Kimi / DeepSeek |
| 0.6 - 0.8 | COMPLEX | Anthropic Claude / OpenAI |
| 0.8 - 1.0 | REASONING | Gemini 2.5 Pro + OptiLLM |

---

## 5. Caching

### 5.1 L1: In-Memory Cache

- Storage: Python dict (LRU eviction)
- TTL: 5 minutes
- Key: SHA-256(model + messages + temperature)
- Hit rate target: 15-25% (repeated queries in same session)

### 5.2 L2: Disk Cache (SQLite)

- Storage: SQLite at `.cache/router_l2.db`
- TTL: 24 hours
- Key: SHA-256(normalized_prompt + model_tier)
- Normalization: strip whitespace, lowercase, remove timestamps
- Hit rate target: 10-20% (repeated patterns across sessions)

### 5.3 L3: Semantic Cache (hnswlib)

- Storage: hnswlib HNSW index + SQLite payload store
- TTL: 72 hours
- Key: embedding vector (cosine similarity > 0.92 = cache hit)
- Model: all-MiniLM-L6-v2 (384 dimensions)
- Hit rate target: 5-15% (semantically equivalent queries)

### 5.4 Cache Key Normalization

Before hashing for L2, apply:
- Strip leading/trailing whitespace
- Normalize multiple spaces to single space
- Remove date/time references (e.g., "today", "2026-03-09")
- Lowercase system prompts (preserve user message case)

---

## 6. Routing Strategies

### 6.1 Strategy Modes

| Mode | Description | When to Use |
|------|-------------|-------------|
| `quality` | Always route to highest-capability model for tier | Production, critical tasks |
| `cost` | Always route to cheapest model that meets tier | Development, high-volume tasks |
| `latency` | Route to fastest model (lowest p50 latency) | Interactive / streaming use cases |
| `balanced` | Weighted mix of quality, cost, latency | Default |
| `shuffle` | Round-robin across all providers in tier | Load testing, quota distribution |

### 6.2 Cascade Fallback

On provider error or quality threshold failure:
1. Try primary provider for tier
2. On failure (rate limit, error, quality < threshold): try secondary provider
3. On second failure: escalate one tier up
4. On third failure: return error with diagnostic context

---

## 7. Quota Management

### 7.1 Per-Provider Quotas (Free Tiers)

| Provider | RPM | RPD | TPM | TPD |
|----------|-----|-----|-----|-----|
| Anthropic | 5 | 1000 | 20K | 300K |
| Google Gemini | 15 | 1500 | 1M | 50M |
| Moonshot Kimi | 60 | 1000 | 200K | 5M |
| OpenAI | 3 | 200 | 40K | 1M |
| Qwen | 60 | 2000 | 200K | 10M |
| DeepSeek | 60 | 1000 | 500K | 10M |
| Groq | 30 | 14400 | 6K | 500K |
| Together AI | 10 | 500 | 100K | 5M |

### 7.2 Circuit Breaker States

- **CLOSED** (normal): requests pass through
- **OPEN** (failing): requests blocked, routed to fallback
- **HALF-OPEN** (recovery): 1 probe request every 60s to test recovery

Transitions:
- CLOSED → OPEN: 5 consecutive errors OR quota > 90%
- OPEN → HALF-OPEN: 60s cooldown
- HALF-OPEN → CLOSED: successful probe request
- HALF-OPEN → OPEN: failed probe request

---

## 8. OptiLLM Integration

For REASONING tier requests, optionally route through OptiLLM for inference enhancement:

| Technique | Use Case | Overhead |
|-----------|----------|----------|
| Chain-of-Thought (CoT) | Multi-step reasoning | 1.5-2x tokens |
| MCTS | Complex decision trees | 3-5x tokens |
| Self-consistency | High-stakes answers | 3x tokens (majority vote) |
| Best-of-N | Code generation quality | 3-5x tokens |

OptiLLM is optional — configure via `OPTILLM_ENABLED=true` in `.env`.
If OptiLLM is unreachable, router falls through to direct provider.

---

## 9. Textual TUI

### 9.1 Screen Map

| Screen | Key | Contents |
|--------|-----|----------|
| Boot | auto | Animated ASCII logo, version, provider status check |
| Dashboard | `1` | Live request stream, routing decisions, cache hits |
| Quota | `2` | Per-provider quota bars, circuit breaker status |
| Metrics | `3` | Latency p50/p95/p99, token usage, cache hit rates |
| Routing | `4` | Strategy selector, tier overrides, cascade config |
| Cache | `5` | L1/L2/L3 stats, clear controls, hit/miss breakdown |
| Providers | `6` | Provider health, latency, error rates |
| Config | `7` | Live config editor (hot reload on save) |
| Logs | `8` | Scrollable log stream with level filter |

### 9.2 Launch Flags

```bash
python -m simplellmrouter              # start with TUI (default)
python -m simplellmrouter --no-tui    # plain JSON logs
python -m simplellmrouter --port 8080 # custom port
python -m simplellmrouter --strategy balanced  # strategy override
```

---

## 10. API Reference

### POST /v1/chat/completions

OpenAI-compatible. All standard fields supported plus router extensions:

```json
{
  "model": "auto",           // "auto" = router decides; or specify provider/model
  "messages": [...],
  "temperature": 0.7,
  "stream": true,

  // Router extensions (all optional)
  "x-router-strategy": "quality",     // override default strategy
  "x-router-tier": "COMPLEX",         // force tier
  "x-router-no-cache": false,         // bypass cache
  "x-router-optillm": true            // force OptiLLM enhancement
}
```

### GET /v1/metrics

Returns JSON with current router metrics:

```json
{
  "uptime_seconds": 3600,
  "requests_total": 1420,
  "cache_hit_rate": 0.42,
  "token_savings_pct": 0.38,
  "provider_health": { "anthropic": "CLOSED", "gemini": "CLOSED" },
  "quota_usage": { "anthropic": 0.23, "gemini": 0.08 },
  "latency_p95_ms": 87
}
```

### GET /v1/health

```json
{ "status": "ok", "providers_healthy": 7, "providers_degraded": 1 }
```

---

## 11. Configuration

### 11.1 Environment Variables

```bash
# Router
ROUTER_PORT=8080
ROUTER_STRATEGY=balanced
ROUTER_LOG_LEVEL=info
OPTILLM_ENABLED=false
OPTILLM_URL=http://localhost:7070

# Providers
ANTHROPIC_API_KEY=
GOOGLE_GEMINI_API_KEY=
MOONSHOT_KIMI_API_KEY=
OPENAI_API_KEY=
QWEN_API_KEY=
DEEPSEEK_API_KEY=
GROQ_API_KEY=
TOGETHER_API_KEY=
```

### 11.2 Provider Config (providers.json)

```json
{
  "anthropic": {
    "enabled": true,
    "priority": 1,
    "tiers": ["COMPLEX", "REASONING"],
    "models": { "default": "claude-3-5-sonnet-20241022" },
    "quota": { "rpm": 5, "rpd": 1000, "tpm": 20000 },
    "circuit_breaker": { "threshold": 5, "cooldown_s": 60 }
  }
}
```

---

## 12. Testing

### Test Suite Structure

```
tests/
├── test_classifier.py       # Intent classification accuracy
├── test_complexity.py       # Scoring dimension validation
├── test_cache.py            # L1/L2/L3 cache behavior
├── test_quota.py            # Circuit breaker state transitions
├── test_routing.py          # Strategy behavior per tier
├── test_fallback.py         # Cascade fallback sequences
├── test_api.py              # OpenAI-compat API surface
└── test_integration.py      # End-to-end with mock providers
```

### Coverage Targets

| Module | Target |
|--------|--------|
| Intent classifier | 90% |
| Complexity scorer | 85% |
| Cache (all 3 layers) | 90% |
| Quota / circuit breaker | 95% |
| Routing strategies | 85% |
| API surface | 80% |

---

## References

- project-brief-aigency-dev-platform.md
- meta-code-squad-master-system-spec.md
- agentic-tooling-integration-strategy.md
- integrations-spec.md
- OptiLLM GitHub: https://github.com/codelion/optillm
- Letta (formerly MemGPT): https://letta.com
- Textual TUI framework: https://textual.textualize.io