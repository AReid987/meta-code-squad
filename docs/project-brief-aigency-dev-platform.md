# Project Brief — Aigency Developer Platform
## SimpleLLMRouter v2 + @aigency/forge-quality

**Version:** 1.0 | **Date:** 2026-03-05 | **Owner:** Antonio Reid
**Monorepo:** aigency/ (Turborepo) | **Status:** Approved — Begin Implementation

---

## 1. Executive Summary

Two open-source packages that together form the foundation of Aigency's autonomous development
platform — and a standalone toolkit any developer can adopt.

**SimpleLLMRouter v2** is an intelligent LLM gateway that routes AI requests across 8+ free-tier
providers using semantic intent detection, 14-dimension complexity scoring, and 3-layer caching.
It gives Aigency's Meta Code Squad approximately 1 billion free tokens per month with sub-100ms
routing decisions and a polished Textual TUI for live monitoring.

**@aigency/forge-quality** is a plug-and-play commit-quality package for Turborepo (and any
Node/Python project) that enforces conventional commits, auto-fixes lint and formatting, runs
type checks and tests on every commit, gates on coverage thresholds, and hard-blocks sensitive
data from ever reaching a repository — all from a single `pnpm add` or `npx forge init`.

Together they answer: *how does a solo founder or small team ship production-quality autonomous
AI at scale, for free, with zero compromises on code hygiene?*

---

## 2. The Problem

### 2.1 The LLM Cost Problem
Running autonomous AI agents 24/7 on paid API tiers is cost-prohibitive for early-stage teams.
Free tiers exist across 8+ major providers (Gemini, OpenAI, Anthropic, DeepSeek, Together,
Groq, Mistral, Cohere) but each has different rate limits, request caps, and capability profiles.
Managing quota manually across providers is operationally impossible at scale. Hitting a rate
limit mid-task crashes autonomous workflows.

**No existing free solution** intelligently multiplies these quotas with complexity-aware routing,
semantic caching, and a live monitoring interface. LiteLLM is close but costs money at scale.
RouteLLM is research-grade. OpenRouter exposes your traffic to a third party.

### 2.2 The Code Quality Problem
Every new project starts with 2-4 hours of boilerplate: setting up ESLint, Prettier, TypeScript
config, husky hooks, commitlint, test runners, coverage thresholds, and secret scanning — then
wiring them all together. In a monorepo with 5+ packages, this multiplies.

More critically, most teams wire quality gates into CI — meaning broken code, untested functions,
and exposed secrets only get caught after a push. In an AI-assisted development workflow where
agents generate code rapidly, shift-left quality enforcement is not optional: it is the
difference between a trustworthy autonomous system and a liability.

**No existing package** combines git initialization, GitHub repo creation, conventional commits,
multi-layer linting, type checking, test coverage enforcement, and security scanning into a
single installable, configurable unit.

---

## 3. The Solution

### 3.1 SimpleLLMRouter v2

An OpenAI-compatible proxy server that sits in front of all LLM calls and makes intelligent
routing decisions in under 100ms. Key capabilities:

- **Semantic intent detection** — classifies request intent (code review, bug fix, architecture,
  docs, chat, reasoning) using local embeddings in ~100ms, no LLM call needed
- **14-dimension complexity scoring** — scores each request on code, logic, creativity, safety,
  tool-calling, context length, and 8 other dimensions to determine model tier
- **3-layer caching** — in-memory (5min), disk/SQLite (24h), semantic similarity (72h) — targets
  30-60% token savings on agentic workloads
- **Cascade fallback** — tries cheapest model first, escalates only when quality threshold not met
- **5 routing strategies** — quality, cost, latency, balanced, simple-shuffle — switchable live
- **Quota management** — tracks usage per provider, circuit-breaks failing providers, prevents
  quota exhaustion with configurable warning/hard-stop thresholds
- **OptiLLM integration** — routes COMPLEX/REASONING requests through inference enhancement
  (chain-of-thought, MCTS, self-consistency) for 2-10x quality improvement at zero cost
- **Textual TUI** — 9-screen terminal dashboard: boot animation, live inference stream with
  decision trees, quota charts, metrics deep-dive, live config editing

### 3.2 @aigency/forge-quality

A Turborepo package (also usable standalone) that installs and wires the full commit lifecycle:

- **`forge init`** — one command: git init, gh repo create, branch protection, all tooling
- **pre-commit hooks** — parallel: format/lint auto-fix → type check → secret scan → tests
  → coverage delta check
- **commit-msg validation** — commitlint with conventional commit enforcement
- **pre-push gates** — full type check, full test suite, full security audit, PR size check
- **`forge pr`** — auto-generates PR description from commit history with coverage/test summary
- **`forge commit`** — interactive commitizen prompt for conventional commit messages
- **Security-first** — gitleaks + detect-secrets hard-block on every commit; semgrep SAST on push
- **Auto-fix cascade** — fixes what it can (formatting, lint), exits cleanly on what it cannot
- **Three install modes** — per-project, global dev environment, or one-line project bootstrap

---

## 4. Target Users

### Primary: Antonio Reid (Aigency)
Using both packages to power the Aigency Meta Code Squad autonomous development workflow.
The router multiplies free-tier quota; forge-quality enforces hygiene as agents generate code.

### Secondary — SimpleLLMRouter v2
- **Solo developers and small teams** running self-hosted AI workflows who cannot afford
  paid API tiers at scale
- **Open source AI builders** who want provider redundancy and intelligent routing without
  vendor lock-in
- **Hobbyists** running local AI setups who want free-tier cloud fallback with a beautiful TUI

### Secondary — @aigency/forge-quality
- **Engineering teams** adopting conventional commits and shift-left quality practices
- **Monorepo maintainers** who want a single shareable quality config across all packages
- **AI-assisted development teams** where agents generate code rapidly and quality gates must
  be automatic
- **Solo developers** who want professional git hygiene without 4 hours of setup

---

## 5. Success Metrics

### SimpleLLMRouter v2
| Metric | Target |
|--------|--------|
| Routing decision latency | < 100ms p95 |
| Cache hit rate (agentic workloads) | > 40% |
| Token savings vs no-cache baseline | > 30% |
| Provider failover success rate | > 99.5% |
| TUI boot time | < 3 seconds |
| GitHub stars (6 months post-launch) | 500+ |

### @aigency/forge-quality
| Metric | Target |
|--------|--------|
| `forge init` completion time | < 60 seconds |
| Pre-commit hook execution time | < 30 seconds |
| False positive secret scan rate | < 1% |
| Coverage threshold pass rate | 100% (gates block below threshold) |
| npm weekly downloads (3 months post-launch) | 1,000+ |
| GitHub stars (6 months post-launch) | 300+ |

---

## 6. Scope

### In Scope — v1.0

**SimpleLLMRouter v2:**
- Fix QuotaTracker wiring and circuit breaker (critical bugs)
- Implement 3-layer cache (L1 memory, L2 disk, L3 semantic)
- Semantic intent detection layer
- Cascade fallback routing
- 5 routing strategy modes
- Memory-augmented routing (learn from history)
- OptiLLM integration (optional inference enhancement)
- Prompt template system (native Handlebars-style)
- SSE metrics stream endpoint
- Full Textual TUI — all 9 screens
- Comprehensive test suite (classifier, cache, quota, routing strategies)
- Docker Compose for full stack
- MIT licensed, documented, open-sourceable

**@aigency/forge-quality:**
- `forge init` command with full 11-step setup sequence
- All 4 git hooks (pre-commit, commit-msg, pre-push, post-commit)
- Shareable configs: ESLint, Prettier, TypeScript, commitlint, Ruff, Mypy
- `forge commit` (commitizen wrapper)
- `forge pr` (PR description generator)
- `forge check` (run all checks without committing)
- `forge audit` (full security scan on demand)
- Turborepo package structure
- Global install mode
- Support: TypeScript, Python, fullstack (both)
- MIT licensed, documented, open-sourceable

### Out of Scope — v1.0
- GUI (web dashboard) — TUI only
- Paid tier management
- Multi-tenant / team shared routing
- DSPy prompt optimization (Phase 3)
- Motia workflow integration (Phase 3)
- Java/Go/Rust support in forge-quality
- forge-quality for GitLab or Bitbucket

---

## 7. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Free tier APIs change limits | HIGH | HIGH | Quota config is external JSON — update without code change. Circuit breaker protects against sudden changes. |
| Secret scan false positives | MEDIUM | MEDIUM | Allowlist config (.gitleaks.toml), `--allow` flag for known false positives |
| Pre-commit hooks too slow | MEDIUM | HIGH | Lefthook parallel execution; only run tests on changed files in pre-commit |
| Textual TUI breaks in minimal terminals | LOW | MEDIUM | Graceful degradation: `--no-tui` flag falls back to plain JSON logs |
| OptiLLM unavailable | LOW | LOW | Optional: router falls through to direct provider if OptiLLM unreachable |
| hnswlib embedding cold start | LOW | MEDIUM | Lazy load L3 cache; L1/L2 serve requests while L3 warms up |

---

## 8. Monorepo Structure

```
aigency/                              <- Turborepo root
├── packages/
│   ├── forge-quality/               <- @aigency/forge-quality
│   └── tsconfig/                    <- shared TypeScript config
├── apps/
│   ├── simplellmrouter/             <- SimpleLLMRouter v2 (TypeScript)
│   └── router-tui/                  <- Textual TUI (Python)
├── turbo.json
├── pnpm-workspace.yaml
└── package.json
```

---

## 9. Dependencies

### SimpleLLMRouter v2
- Python 3.11+
- FastAPI + uvicorn
- litellm (provider abstraction)
- hnswlib (vector similarity for L3 cache)
- SQLite (L2 disk cache)
- Textual (TUI framework)
- OptiLLM (optional, inference enhancement)
- Letta SDK (memory integration)

### @aigency/forge-quality
- Node.js 20+
- pnpm 8+
- lefthook (git hooks)
- commitlint + commitizen
- ESLint + Prettier
- TypeScript
- Vitest (test runner)
- gitleaks + detect-secrets (secret scanning)
- semgrep (SAST)
- Ruff + Mypy (Python linting)

---

## 10. Timeline

| Phase | Deliverable | Target |
|-------|-------------|--------|
| Phase 1 | SimpleLLMRouter v2 core (router, cache, quota) | Sprint 1 |
| Phase 2 | forge-quality package + Textual TUI | Sprint 2 |
| Phase 3 | OptiLLM + DSPy + Motia integrations | Sprint 3 |
| Phase 4 | Open source launch + documentation | Sprint 4 |

---

## References

- meta-code-squad-master-system-spec.md
- meta-code-squad-addendum-v2.md
- agentic-tooling-integration-strategy.md
- architecture-aigency-dev-platform.md