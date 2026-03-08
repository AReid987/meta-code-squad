# llm-router

SimpleLLMRouter v2 — intelligent LLM request routing for the Meta Code Squad.

## Overview

Routes LLM requests to the optimal model based on task type, cost, latency, and capability requirements.
Part of the meta-code-squad monorepo.

## Status

Scaffolded. Implementation tracked in docs/simplellmrouter-v2-spec.md (in aigency-specs repo).

## Quick Start

```bash
just router-start
```

## Structure

```
llm-router/
├── README.md
├── pyproject.toml   # (coming)
├── src/
│   └── llm_router/
└── tests/
```

## Key Features (planned)

- OpenAI-compatible proxy on port 8080
- 14-dimension complexity classifier
- Semantic intent detection
- 5 routing strategies (quality, cost, latency, balanced, simple-shuffle)
- 3-layer semantic cache (L1 memory, L2 disk, L3 semantic)
- Quota tracker + circuit breaker per provider
- Textual TUI with 9 screens
- OptiLLM inference boosting