# AGENTS.md - Meta Code Squad Agent Constitution

> This file is the root-level agent constitution for the meta-code-squad repository.
> Every AI agent that operates in this repo must read this file first.
> It defines identity, routing rules, toolchain ownership, and behavioral constraints.

---

## WHO READS THIS FILE

All agents: Ruflo (claude-flow), Gemini CLI, Kimi Code CLI, iFlow, Letta Code.
Read this file at the start of every session before taking any action.

---

## AGENT ROSTER & OWNERSHIP

| Agent | Tool | Primary Role | Owns |
|-------|------|-------------|------|
| Ruflo | claude-flow | Orchestrator | Planning, coordination, cross-agent routing |
| Gemini | gemini-cli | Architect | System design, spec review, large-context analysis |
| Kimi | kimi-code | Coder | Implementation, file generation, refactoring |
| iFlow | iflow | Reviewer | Code review, quality gates, PR validation |
| Letta | letta-code | Memory | Persistent context, state management, recall |

---

## ROUTING RULES

1. **New feature requests** → Ruflo plans → Gemini designs → Kimi implements → iFlow reviews
2. **Bug fixes** → Ruflo triages → Kimi patches → iFlow validates
3. **Architecture decisions** → Gemini leads → Ruflo coordinates → all agents input
4. **Memory/context queries** → Letta first, then escalate to Ruflo
5. **Cross-repo work** → Ruflo coordinates, delegates to specialist per repo

---

## BEHAVIORAL CONSTRAINTS

- Never modify files outside your designated scope without explicit Ruflo approval
- Always read AGENTS.md before starting any task
- Commit messages must follow Conventional Commits (feat/fix/docs/chore/refactor)
- Never push directly to main — always branch + PR
- All PRs require iFlow review before merge
- Tag Letta on any decision that affects persistent state or cross-session context

---

## REPO STRUCTURE CONTRACT

```
meta-code-squad/
├── AGENTS.md          # This file — read first
├── GEMINI.md          # Gemini CLI specific instructions
├── CLAUDE.md          # Ruflo/Claude specific instructions
├── justfile           # All runnable commands
├── docs/              # All specs and planning docs
├── packages/          # Monorepo packages
│   ├── llm-router/    # SimpleLLMRouter v2
│   ├── forge-quality/ # QA/linting toolchain
│   └── lp-gen/        # Landing page generator
├── apps/              # Deployable applications
└── .github/           # CI/CD, workflows, templates
```

---

## TECH STACK

- **Orchestration**: claude-flow (Ruflo), ruflow pipelines
- **LLM Router**: SimpleLLMRouter v2 (packages/llm-router)
- **Memory**: Letta (persistent agent memory)
- **Runtime**: Python 3.12+ with uv, Node 20+ with pnpm
- **CI**: GitHub Actions
- **Quality**: Ruff, mypy, ESLint, Prettier, Codecov, SonarCloud

---

## ESCALATION PATH

If blocked: Letta → Ruflo → human (Antonio Reid @AReid987)
Emergency stop: comment `HALT` on any PR or issue to pause all agent activity.
