# Memory Architecture — Aigency Platform

> Part of the Aigency Dev Platform architecture documentation.
> Implements the memory management principles from `constitutions/AI-CODER-CONSTITUTION.md` Section 5.
> See also: `architecture/agentic-tooling-integration-strategy.md` for tooling context.

---

## Overview

AI agents have a "Context Window" — a hard limit on how much they can hold in working memory at once. To build a large, coherent system across multiple agents and sessions, memory must be managed across three distinct tiers — analogous to CPU registers, RAM, and a hard drive.

```
Tier 1: Volatile (CONTINUITY)    — What am I doing right now?
Tier 2: Long-Term (LEDGERS)       — What decisions have been made?
Tier 3: On-Demand (SKILLS)        — What do I need to know for this specific task?
```

---

## Tier 1: Volatile Memory (CONTINUITY)

**Analogy:** CPU registers / RAM
**Lifespan:** Current session only
**Owner:** All agents (write); Ruflo (compaction)

### Purpose
Track immediate execution state so agents do not lose position mid-task or between turns.

### Implementation

| File | Contents | Updated By |
|------|----------|------------|
| `.planning/continuity.md` | Current task, last action, last error, next step | Every agent after each action |
| `.planning/handoffs/<timestamp>.md` | Inter-agent state transfer | Sending agent |
| Ruflo context compaction | Automatic summarization when context approaches limit | Ruflo daemon |

### Schema: continuity.md

```markdown
## Current Task
[What the agent is currently executing]

## Last Action
[What was just done — file written, command run, etc.]

## Last Output / Error
[Result or error from last action]

## Next Step
[What to do next]

## Blockers
[Anything blocking progress — empty if none]
```

### Rules
- Every agent MUST update `continuity.md` after each action.
- On session start, read `continuity.md` before reading anything else.
- Ruflo fires compaction automatically when context exceeds 80% of window.

---

## Tier 2: Long-Term Memory (LEDGERS)

**Analogy:** Hard drive / database
**Lifespan:** Permanent (git-tracked)
**Owner:** Letta Code (primary); all agents (append)

### Purpose
Maintain a permanent, queryable record of every architectural decision, so any new agent (or human) can be "briefed" on the full project history instantly.

### Implementation

| Store | Technology | Contents |
|-------|------------|----------|
| `.planning/ledger.md` | Markdown (git-tracked) | Chronological decision log |
| `.letta/memory/` | Letta memory blocks | Semantic codebase knowledge |
| Letta server (:8283) | Letta stateful agent | Cross-session queryable memory |

### Schema: ledger.md entry

```markdown
## [YYYY-MM-DD HH:MM] Decision: [Short title]
**Agent:** [Who made the decision]
**Context:** [What problem was being solved]
**Decision:** [What was decided]
**Rationale:** [Why this approach over alternatives]
**Source Doc:** [Link to RFC, PR, or issue if applicable]
```

### Rules
- Letta Code writes decision entries after every major choice.
- All agents can append entries (but only Letta Code consolidates).
- Ledger is git-tracked and survives session boundaries.

---

## Tier 3: On-Demand Memory (SKILLS)

**Analogy:** External documentation / reference manuals
**Lifespan:** Static (version-controlled)
**Owner:** All agents (read); humans (write)

### Purpose
Provide "just-in-time" reference material when a specific skill or context is needed, without loading the entire system into every agent's context window.

### Implementation

| Store | Contents | Access Pattern |
|-------|----------|----------------|
| `constitutions/` | Core principles, coding standards, security policies | Loaded by Ruflo at session start |
| `docs/` | Architecture specs, API references, integration guides | Loaded on-demand via semantic search |
| `.letta/skills/` | Reusable code snippets, patterns, templates | Queried by Letta when relevant |

### Schema: skills directory

```
.letta/skills/
├── typescript-patterns.md
├── prisma-migrations.md
├── github-actions-templates.md
└── security-checklist.md
```

### Rules
- Skills are never loaded proactively — only fetched when needed.
- Letta maintains a semantic index of all skills for fast retrieval.
- Skills are human-authored, agent-consumed.

---

## Memory Lifecycle Example

1. **Ruflo reads `continuity.md`** → sees current task is "Add user authentication"
2. **Ruflo queries Letta** → retrieves past decision on auth strategy (from `ledger.md`)
3. **Ruflo fetches skill** → loads `typescript-patterns.md` for JWT implementation
4. **Ruflo executes action** → writes code, updates `continuity.md` with next step
5. **Letta Code reviews** → appends decision to `ledger.md` if architecture changed
6. **Handoff to GEMINI** → writes `handoffs/20260309-auth-review.md` for next agent
7. **Context nears limit** → Ruflo compacts session history into summary, preserves `continuity.md`

---

## Anti-Patterns to Avoid

- Do NOT store volatile state in git-tracked files (pollutes history)
- Do NOT load all docs into every agent's context upfront
- Do NOT let agents "forget" what they were doing between turns
- Do NOT make decisions without recording rationale

---

## References

- AI Coder Constitution Section 5: Memory Management
- Agentic Tooling Integration Strategy
- SimpleLLMRouter v2 Spec
- Letta Memory API Documentation (external)