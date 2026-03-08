# meta-code-squad

Autonomous coding squad and meta-orchestration layer for Aigency.

## What This Is

The meta-code-squad is the engine that builds all Aigency products. It is a multi-agent autonomous development system powered by:

- **SimpleLLMRouter v2** — Intelligent LLM routing across Claude, Gemini, Kimi, and others
- **Ruflo (claude-flow v3.5)** — 12 daemon workers, context autopilot, MCP orchestration
- **Letta** — Stateful codebase memory across sessions
- **Sugar AI** — Persistent task queue (Ralph loop, 24/7)
- **Loki Mode** — RARV kanban execution cycle
- **iFlow** — Dependency mapping and architecture context
- **forge-quality** — Code quality enforcer (Biome + custom gates)

## Quick Start

```bash
git clone git@github.com:AReid987/meta-code-squad.git
cd meta-code-squad
just setup   # one-time setup — installs all tools, wires services
just dev     # start everything for a work session
```

## Agent Roles

| Agent | Role | When Used |
|-------|------|--------|
| Gemini CLI | Primary throughput — GSD, tests, config, boilerplate, docs | Default |
| Claude Code | Complex logic, state machines, security, ruflo internals | Complexity ceiling |
| Kimi Code | 128K full-codebase review sweeps | Code review |
| Qwen / Roo / iFlow | Quota overflow buffer | Auto-routed |

## Services

| Service | Port | Purpose |
|---------|------|------|
| SimpleLLMRouter | :8080 | All LLM calls proxy here |
| Letta Server | :8283 | Codebase memory |
| Sugar AI | — | Task queue (Ralph loop) |
| Loki Mode | — | RARV execution cycle |

## Monorepo Structure

```
meta-code-squad/
├── packages/
│   ├── llm-router/         SimpleLLMRouter v2
│   ├── forge-quality/      Code quality enforcer
│   └── lp-gen/             Landing page generator
├── apps/
│   └── (aigency-core — Phase 2+)
├── docs/                   All system documentation
├── .claude/settings.json   Agent teams + env config
├── CLAUDE.md               AI agent constitution
└── justfile                All commands
```

## Phases

| Phase | Status | Scope |
|-------|--------|-------|
| Phase 1 | In Progress | SimpleLLMRouter v2, forge-quality, squad operational |
| Phase 2 | Pending | Aigency Core Platform |
| Phase 3 | Pending | Maestra workflows, agor.live canvas |

## Docs

See `docs/` for full system documentation including master system spec, Ruflo integration guide, tool inventory, and launch guide.