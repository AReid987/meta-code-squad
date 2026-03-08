# Meta Code Squad — Spec Addendum v2
## Corrections, Missing Systems & Design Decisions
**Date:** 2026-03-06 | **Owner:** Antonio Reid
**Status:** Authoritative — supersedes conflicting sections in master spec and tool inventory

---

## 0. What This Document Covers

Seven categories of gaps and corrections identified in review:

1. Complete verified API key arsenal (no OpenAI, no Anthropic keys)
2. Corrected context window and routing logic (Gemini > Kimi for large context)
3. iFlow CLI — fully documented, now a first-class squad member
4. claude-flow AgentDB / Intelligence Controller — explicitly required
5. Skills system — what is real, what is marketing, how to solve skill bloat
6. Spec-docs repo & constitution — design + structure decision
7. Cross-harness orchestration — BMAD→PRP, PDM/UV, unified context, protocol translation

---

## 1. Verified API Key Arsenal

> No OpenAI API key. No Anthropic API key. Do not route to either in SimpleLLMRouter.

### 1.1 Confirmed Keys (from `notes/blackout/COMPLETE_LLM_API_GUIDE.md`)

| Provider | Key | Free Quota | Rate Limits | Primary Use |
|----------|-----|-----------|-------------|-------------|
| **Mistral** | Yes | 1B req/month | 500K RPM | Bulk orchestration, parallel agents |
| **Groq** | Yes | 14,400 req/day | 30 RPM / 900 RPH | Ultra-fast inference, speed-critical |
| **Cerebras** | Yes | 14,400 req/day (x4 models) | 30 RPM / 900 RPH | High-volume, near-unlimited tokens |
| **VoidAI** | Yes | 125K credits/day (77 models) | Varies | Model variety, daily-rotating discounts |
| **OpenRouter** | Yes | 1,000 req/day | Varies | Diversity, auto-free model rotation |
| **Gemini API** | Yes | 1,500 RPD / 15 RPM | — | Large context (1M-2M), multimodal |
| **GitHub Models** | Yes | Free tier | Rate limited | GPT-4o, Llama, Phi via GitHub auth |
| **Hugging Face** | Yes | Free tier | Rate limited | Research, specialist models |
| **Cloudflare Workers** | Yes | 10K neurons/day | Workers limits | Edge deployment |
| **Z.ai** | Yes | Coding plan quota | Unknown | Code generation CLI + API |
| **Kimi** | Yes | Coding plan (~3x per 5hr) | Per 5hr window | Code generation CLI + API |
| **NVIDIA NIM** | Yes | Unknown — assume generous | Unknown | NIM models (Llama, Mistral variants) |
| **Bonsai** | Yes | Unknown, free | Unknown | Hidden frontier model (GPT-5 or Anthropic) |
| **Giga AI** | Yes | Unknown, free | Unknown | Overflow buffer |

### 1.2 Cerebras is a Standout — Update the Spec

Cerebras was listed as "unknown limits" in the master spec. **Actual limits:**
- 4 production models x 14,400 req/day = **57,600 req/day combined**
- **1M tokens/hour per model** — effectively unlimited token throughput
- `gpt-oss-120b` (65K context), `llama-3.3-70b`, `llama3.1-8b`, `qwen-3-32b`
- This is the best raw throughput provider in the stack. Treat as primary API overflow.

### 1.3 VoidAI Credit Math

125K credits/day. At typical coding model pricing (0.02x input, 0.1x output):
- ~2,400 requests/day at 500 output tokens
- Scales up for smaller outputs, down for large generations
- Daily model list and discounts rotate — SimpleLLMRouter must call `/api/v1/models` at startup

### 1.4 SimpleLLMRouter — What's Already There vs. What's Missing

Repo at `github.com/AReid987/simplellmrouter` already has: Mistral, Groq, Gemini, Cerebras, OpenRouter, VoidAI, Z.ai, Kimi.

**Missing from current `providers.yaml`:** NVIDIA NIM, Bonsai, Giga AI, GitHub Models, Hugging Face, Cloudflare Workers.

These need to be added as provider configs. NVIDIA and Bonsai are highest priority given unknown-but-likely-large quotas.

---

## 2. Context Window Corrections

The original spec over-indexed on Kimi's 128K context window. **Corrected picture:**

| CLI / API | Context Window | Notes |
|-----------|---------------|-------|
| Gemini CLI / Gemini API | **1M – 2M tokens** | Largest in the stack by a massive margin |
| iFlow (Roma model) | 128K | Good for full-repo analysis within iFlow |
| iFlow (Kimi K2) | 128K | Same |
| Kimi Code CLI | 128K (not 256K) | Spec had this wrong |
| Mistral Large | 128K | High-volume API use |
| Cerebras models | 65K | Fast but not long-context |
| Groq | 128K | Fast, not a context play |
| Qwen3 (CLI/API) | **256K** | Larger than Kimi, overlooked in spec |
| Mistral models (many) | **256K** | Multiple Mistral models at 256K |

### Corrected Routing Rule for Context

```
IF context_needed > 200K        → Gemini CLI or Gemini API (1M-2M)
IF context_needed > 64K         → Qwen3 (256K) or Mistral (256K) or Kimi (128K)
IF context_needed <= 64K        → Any provider, optimize for quota/speed
```

**Kimi's actual strengths** (not just context):
- Strong multi-step reasoning and task completion
- Good error recovery in complex workflows
- Often completes multi-step workflows with minimal scaffolding/prompting
- Fast relative to quality
- Skill invocation may differ — does not use `/skill:command` syntax like Claude

---

## 3. iFlow CLI — First-Class Squad Member

### 3.1 What It Is

Free, Alibaba-affiliated, MCP-extensible. Built-in multi-model routing (GLM-5, Roma, Kimi K2, Qwen3, DeepSeek v3). Completely absent from the original spec. **It is not a fallback — it owns specific workflow commands that nothing else replicates as cleanly.**

### 3.2 Install

```bash
npm i -g @iflow-ai/iflow-cli
```

### 3.3 Built-In Commands

| Command | Purpose | Replaces Manual Step |
|---------|---------|---------------------|
| `/init` | Full repo scan + summary context file | Manual AGENT.md bootstrap |
| `/scaffold` | Project scaffolding | Manual turborepo init steps |
| `/qa` | QA workflow — tests, lint, bug scan | Separate forge-quality sweep |
| `/refactor` | Codebase refactor sweep | Manual Kimi/Gemini refactor prompts |
| `/understand` | Full codebase analysis + dependency map | Manual `/init deep` in Claude Code |
| `/mermaid` | Architecture diagram generation | Manual diagram prompting |
| `multi-agent review` | Parallel independent review agents | Sequential review passes |
| `todos-to-issues` | Scan TODOs → create GitHub issues | Manual issue creation |
| `/remember` | Force Letta learning pass | Manual memory consolidation |

### 3.4 Execution Modes

- **Default** — stream + approve at checkpoints
- **Plan** — show full plan before executing (use this for `/scaffold`, `/refactor`)
- **Accepting Edits** — open inline editor during execution
- **YOLO** — auto-execute all steps (use only for `/qa`, `/mermaid`)

### 3.5 Internal Model Routing (iFlow selects automatically)

| Task Type | Model Selected |
|-----------|---------------|
| `/refactor`, `/mermaid` | GLM-5 (fast, general) |
| `/understand`, `/qa` large codebase | Roma (128K, analysis) |
| `/understand --deep`, full-repo `/qa` | Kimi K2 |
| `/scaffold`, config generation | Qwen3 Coder |
| Complex logic in `/refactor` | DeepSeek v3 |

### 3.6 justfile Recipes Enabled by iFlow

```bash
just diagram          # iflow /mermaid --type=architecture
just understand       # iflow /understand --mode plan
just todos-to-issues  # iflow todos-to-issues
just qa               # iflow /qa
just scaffold PKG     # iflow /scaffold packages/PKG
just multi-review     # iflow multi-agent review
```

---

## 4. claude-flow AgentDB & Intelligence Controller

These were **completely absent** from the spec. The `--full` install is not optional — it is the entire intelligence layer.

### 4.1 Install Command (Required — not the basic install)

```bash
# FULL install — required for AgentDB + Intelligence Controller
curl -fsSL https://cdn.jsdelivr.net/gh/ruvnet/claude-flow@main/scripts/install.sh | bash -s -- --full

# Register MCP with Claude Code
claude mcp add ruflo -- npx -y ruflo@latest mcp start

# Initialize AgentDB for project
npx agentdb@latest init $PROJECT_ROOT/agents.db
```

### 4.2 What AgentDB Actually Does

AgentDB v1.3.9 is not just storage. It is a full intelligence layer:

| Component | Description |
|-----------|-------------|
| **29 MCP tools** | Auto-registered with Claude Code on `mcp add` |
| **SONA** | Self-Optimizing Neural Architecture — <0.05ms routing adaptation |
| **EWC++** | Elastic Weight Consolidation — prevents catastrophic forgetting between sessions |
| **HNSW vector search** | <100µs pattern retrieval, O(log n) — semantic memory lookup |
| **ReasoningBank** | 5-phase trajectory learning: RETRIEVE → JUDGE → DISTILL → CONSOLIDATE → ROUTE |
| **9 RL algorithms** | Q-Learning, SARSA, A2C, PPO, DQN, Decision Transformer, MCTS, TD(λ), R-Max |
| **Flash Attention** | 2.49–7.47x speedup on long contexts |
| **Nightly learner daemon** | Runs background memory consolidation every night |
| **Causal reasoning graphs** | Maps cause-effect relationships across sessions |
| **Reflexion memory** | Self-critique loops on past decisions |
| **Skill library** | Semantic search across 42 bundled skills |
| **Merkle proof recall** | Cryptographically verified memory integrity |

### 4.3 The 60+ Bundled Agents

The `--full` install includes 60+ pre-built specialist agents: coder, reviewer, tester, security auditor, architect, documenter, optimizer, debugger, DevOps engineer, and more. These are available as Claude Code slash commands and MCP tools after install.

### 4.4 Required Additions to `just setup`

```bash
# In justfile setup recipe — ADD these:
curl -fsSL https://cdn.jsdelivr.net/gh/ruvnet/claude-flow@main/scripts/install.sh | bash -s -- --full
claude mcp add ruflo -- npx -y ruflo@latest mcp start
npx agentdb@latest init ./agents.db
```

---

## 5. Skills System — Reality Check

### 5.1 Anthropic Skills 2.0 — What Is Real

Announced March 3, 2026. **This is real**, not marketing hype, but the terminology is imprecise:

- **Real:** Skill Creator 2.0 with structured evals (automated tests for skills)
- **Real:** Benchmark mode — tracks pass rates, token usage, elapsed time across runs
- **Real:** A/B comparison — skill vs. no-skill via blind judge agents
- **Real:** Multi-agent eval execution in parallel (no cross-contamination)
- **Real:** Trigger optimization — refines skill descriptions to reduce false activations
- **Marketing hype:** "Regression prevention" — it is **regression detection**, not prevention. You still fix regressions manually. It catches when a skill degrades after a model update.

**Practical implication:** The skill creator evals are worth using for any skill that runs frequently. Run evals when Claude model versions update. Do NOT assume skills self-correct.

### 5.2 The Skill Bloat Problem

You have hundreds of skills in the global environment. Loading all of them into every agent context is:
- Wasteful (token overhead)
- Confusing (agent attention diluted)
- Counterproductive (wrong skill activates for wrong agent)

### 5.3 Solution — Goose "Summon" Pattern Applied Universally

Goose (Block's open-source agent) solves this with lazy/context-aware skill loading:

**How it works:**
1. Skills live in `~/.config/agents/skills/` (global) or `./.agents/skills/` (project)
2. Each skill is a `SKILL.md` with YAML frontmatter: `name`, `description`, `triggers`
3. Agent discovers skills at session start, **does not load them all**
4. Skills activate when: (a) semantic match to request, or (b) explicit `Use the X skill`
5. Skills are lazy-loaded — only the matched skill enters the context window

**Apply this pattern everywhere:**

```
~/.config/agents/skills/           ← global skills (apply to all agents)
  code-review.md
  security-audit.md
  conventional-commits.md
  ...

$PROJECT/.agents/skills/           ← project skills (apply to this project only)
  turborepo-patterns.md
  ruflo-memory.md
  gsd-workflow.md
  loki-gates.md
  ...

$PROJECT/.kiro/steering/           ← Kiro-specific steering files
$PROJECT/.claude/skills/           ← Claude Code skills
$PROJECT/.goose/skills/            ← Goose skills
```

**The cross-agent standard:** SKILL.md format is already the open standard across Claude Desktop, Goose, and Agent Skills-compatible tools. Write skills once in SKILL.md format, symlink or copy to agent-specific dirs.

### 5.4 Skill Sub-Groups by Agent Role

Rather than one giant skill set, partition into focused subsets:

| Group | Skills | Agents That Get It |
|-------|--------|-------------------|
| **core** | conventional-commits, git-hygiene, PR-format | ALL agents |
| **architecture** | ruflo-memory, agentdb-tools, hnsw-query | Claude Code, Kimi |
| **execution** | gsd-workflow, loki-gates, RARV-cycle | Gemini CLI, Kimi, iFlow |
| **quality** | forge-quality, security-audit, test-coverage | All reviewers |
| **scaffold** | turborepo-patterns, pnpm-workspace, pdm-uv | iFlow, Gemini |
| **spec** | PRP-format, bmad-personas, kiro-steering | Kiro, BMAD |
| **memory** | letta-recall, sugar-queue, agentdb-bank | Orchestrators |

---

## 6. Spec-Docs Repository & Constitution

### 6.1 Design Decision

Create a standalone git repo: `aigency-specs` (or similar). This serves as:
- Canonical home for the unified **AI Constitution** (rules all agents follow)
- Template library for all spec doc types
- Per-project versioned docs (each project gets its own directory)

### 6.2 Template Library

Templates to include (flexible — not rigid, just structural starting points):

| Template | Source Inspiration | Notes |
|----------|------------------|-------|
| `project-brief.md` | BMAD | High-level scope, stakeholders, success criteria |
| `prd.md` | BMAD (replace with PRP — see §7) | Standard PRD for human review |
| `prp.md` | BMAD → PRP conversion | Machine-executable requirements prompt |
| `architecture.md` | BMAD | System design, component map, decisions |
| `ux-spec.md` | BMAD | User flows, wireframe descriptions, design tokens |
| `backlog.md` | BMAD | Prioritized stories, acceptance criteria |
| `lean-canvas.md` | Lean Startup | Problem, solution, unique value, channels, revenue |
| `user-persona.md` | UX standard | Name, goals, pain points, behavioral patterns |
| `user-journey-map.md` | UX standard | Stages, actions, emotions, opportunities |
| `design-system.md` | Custom | Tokens, typography, components, patterns |
| `prototype-prompt.md` | Google AI Studio | Self-contained prompt for UI prototyping |
| `constitution.md` | Unified | Agent behavior rules, communication protocols |
| `AGENT.md` | Squad standard | Per-project agent context file |
| `CLAUDE.md` | Claude Code | Claude-specific project context |
| `GEMINI.md` | Gemini CLI | Gemini-specific project context |

### 6.3 Repo Structure

```
aigency-specs/
├── constitution/
│   └── CONSTITUTION.md              ← unified rules all agents follow
├── templates/
│   ├── project-brief.md
│   ├── prp.md                       ← primary: PRP not PRD
│   ├── prd.md                       ← secondary: human-readable PRD
│   ├── architecture.md
│   ├── ux-spec.md
│   ├── backlog.md
│   ├── lean-canvas.md
│   ├── user-persona.md
│   ├── user-journey-map.md
│   ├── design-system.md
│   ├── prototype-prompt.md
│   └── AGENT.md
└── projects/
    ├── aigency-core/
    │   ├── project-brief.md
    │   ├── prp.md
    │   ├── architecture.md
    │   └── ...
    ├── meta-code-squad/
    │   └── ...
    └── project-blackout/
        └── ...
```

### 6.4 just Integration

When running `just new PROJECT_NAME`:
1. Create project directory in monorepo
2. Clone spec templates from `aigency-specs/templates/` into `$PROJECT/docs/`
3. Create `$PROJECT/docs/specs/` pointing to `aigency-specs/projects/PROJECT_NAME/`
4. Run `iflow /init` on the new project directory
5. Run BMAD CLI to initialize personas for the project
6. Run other harness init commands (Loki, Sugar, AgentDB)

Templates are flexible starting points — they never fully determine the output because each project's needs differ. The value is versioning and centralization, not rigidity.

---

## 7. Cross-Harness Orchestration

### 7.1 The Core Problem

Each agent harness has its own protocol:
- BMAD uses personas and conversational planning
- Loki uses RARV cycles and PLAN files
- iFlow uses slash commands
- Kiro uses steering files and spec-driven tasks
- Claude Code uses CLAUDE.md + MCP tools
- Gemini CLI uses GSD phases
- Sugar uses async task queues

**Translating between them manually is friction we cannot sustain.**

### 7.2 Unified Context Layer (Solution)

Every agent harness gets a **shared starter context** on project init:

```
$PROJECT/
├── AGENT.md          ← universal context: read by every harness
├── CLAUDE.md         ← Claude Code specific (imports from AGENT.md)
├── GEMINI.md         ← Gemini CLI specific (imports from AGENT.md)
├── .kiro/
│   └── steering/     ← Kiro steering files (generated from AGENT.md)
├── .loki/
│   └── CONTINUITY.md ← Loki auto-generates this each run
└── .sugar/           ← Sugar async queue state
```

**AGENT.md is the master.** All other context files are derived from or reference it. When you update AGENT.md at a phase boundary, a `just sync-context` command re-derives the harness-specific files.

### 7.3 Protocol Translation Layer

The squad needs a lightweight translation layer. This is what Motia (the event bus already in the spec) handles — but it needs to be explicit:

```
BMAD output (PRD doc)
    ↓ [auto-convert]
PRP (machine-executable prompt)
    ↓ [GSD /gsd:plan-phase]
PLAN files (wave-based atomic tasks)
    ↓ [loki start]
RARV execution cycle
    ↓ [at quota boundary]
SimpleLLMRouter → next available agent
    ↓ [iFlow slash commands as needed]
/scaffold, /qa, /refactor, /understand
    ↓ [memory consolidation]
AgentDB ReasoningBank + Letta memory
```

The `just run PRP_FILE` command should trigger this entire chain.

### 7.4 BMAD → PRP Replacement

BMAD currently outputs a PRD. **We need it to output a PRP instead** (or auto-convert):

- **PRD** = human-readable requirements document (keep for stakeholder review)
- **PRP** = machine-executable requirements prompt (what agents actually consume)
- BMAD CLI should be configured to generate PRP as the primary artifact
- PRD becomes a secondary derived document (for human review)

**Implementation:** Configure the BMAD system prompt / persona instructions to target PRP format. The BMAD CLI `bmad init` command should be added to `just setup`.

### 7.5 Python Venv — PDM + UV Only

**Rule:** All Python virtual environments must use PDM with UV as the resolver. No pip, no poetry, no pipenv, no conda.

```bash
# Correct — required pattern
pdm init                    # creates pyproject.toml
pdm config use-uv true      # use uv as resolver
pdm install                 # installs deps via uv

# In justfile
venv:
    pdm init --python 3.12
    pdm config use-uv true
    pdm install
```

Add to justfile as a gated check: if `pyproject.toml` does not exist, run `pdm init` before any Python tool installs.

### 7.6 pnpm Turbo — No Pre-Created package.json Needed

`pnpm create turbo@latest` and `turbo init` generate `package.json` and `turbo.json` automatically. Do not pre-create them. The justfile should run:

```bash
scaffold:
    pnpm dlx create-turbo@latest . --package-manager pnpm
    # turbo.json and root package.json created automatically
    # then add workspaces
```

If adding Turbo to an existing project: `pnpm add turbo --save-dev` then `pnpm exec turbo init` — same result, files auto-created.

### 7.7 Skill Surfacing in Non-Goose Harnesses

Since Goose's "summon" is the cleanest approach, apply the same lazy-load pattern everywhere:

**For Claude Code:** Add to CLAUDE.md:
```markdown
## Skills
Skills are in .agents/skills/. Load a skill only when explicitly needed or when your task matches its description. Do not load all skills at session start.
```

**For iFlow:** iFlow reads project-level context files. Document skill paths in `iflow.config.json`.

**For Kimi:** Kimi does not use `/skill:command` syntax. Instead, include relevant skill content inline in the task prompt when delegating. The orchestrator (claude-flow or justfile) handles skill injection at delegation time.

**For all others:** The justfile `run` recipe wraps task dispatch with a skill-injection step — reads the task type, selects relevant skill group (see §5.4), injects into the agent's context file before spawning.

---

## 8. Updated Full Stack Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│  SPEC DOCS REPO (aigency-specs)                                 │
│  Constitution + Templates + Per-Project Versioned Docs          │
└────────────────────────────┬────────────────────────────────────┘
                             │ just new PROJECT_NAME
┌────────────────────────────▼────────────────────────────────────┐
│  LAYER 0: QUOTA & ROUTING                                       │
│  SimpleLLMRouter v2 (github.com/AReid987/simplellmrouter)       │
│  Providers: Mistral(1B/mo) | Cerebras(57.6K/day) |             │
│  Groq(14.4K/day) | VoidAI(125K cred/day) | OpenRouter(1K/day)  │
│  Gemini(1.5K/day) | NVIDIA | Bonsai | Giga | Z.ai | Kimi       │
│  GitHub Models | HuggingFace | Cloudflare                       │
│  NO OpenAI. NO Anthropic API.                                   │
└────────────────────────────┬────────────────────────────────────┘
                             │ OpenAI-compatible proxy (:8402)
┌────────────────────────────▼────────────────────────────────────┐
│  LAYER 1: MEMORY & INTELLIGENCE                                 │
│  Ruflo --full (claude-flow v3.5)                                │
│    AgentDB v1.3.9: SONA | EWC++ | HNSW | ReasoningBank         │
│    29 MCP tools registered to Claude Code                       │
│    9 RL algorithms | Flash Attention | Nightly learner          │
│    Skill library (42 skills, semantic search)                   │
│  Letta Code: stateful memory | sleep-time compute | /init deep  │
└────────────────────────────┬────────────────────────────────────┘
                             │ MCP + context
┌────────────────────────────▼────────────────────────────────────┐
│  LAYER 2: ORCHESTRATION                                         │
│  BMAD → PRP | GSD → PLAN files | Loki RARV | Sugar queue       │
│  Unified context: AGENT.md → CLAUDE.md / GEMINI.md / .kiro/    │
│  Skill routing: lazy-load via Goose summon pattern              │
│  Protocol translation: Motia event bus                          │
└────────────────────────────┬────────────────────────────────────┘
                             │ task delegation
┌────────────────────────────▼────────────────────────────────────┐
│  LAYER 3: EXECUTION AGENTS (corrected routing)                  │
│                                                                 │
│  LARGE CONTEXT (>200K):   Gemini CLI / Gemini API (1M-2M)      │
│  LARGE CONTEXT (>64K):    Qwen3 (256K) | Mistral (256K)        │
│  COMPLEX LOGIC:           Claude Code (MCP + AgentDB tools)    │
│  GSD THROUGHPUT:          Gemini CLI (1K/day, 1M ctx)          │
│  WORKFLOW COMMANDS:       iFlow (/scaffold /qa /refactor        │
│                           /understand /mermaid /remember)       │
│  ISSUE-DRIVEN:            Rovo Dev (SWE-bench #1, 41.98%)      │
│  HIGH VOLUME:             Qwen Code CLI (2K/day, 256K ctx)     │
│  SPEC GENERATION:         Kiro CLI (50/mo — sparingly)         │
│  OVERFLOW:                Amp CLI (1K/day, separate pool)      │
│                                                                 │
│  Kimi Code CLI role: Strong reasoning + multi-step workflows    │
│  NOT primarily a context-window play (Gemini wins there)        │
└────────────────────────────┬────────────────────────────────────┘
                             │ API overflow (SimpleLLMRouter auto)
┌────────────────────────────▼────────────────────────────────────┐
│  LAYER 3b: API OVERFLOW POOL                                    │
│  Cerebras (fastest, 57.6K/day) → Mistral (1B/month!)           │
│  → Groq (14.4K/day, ultra-fast) → VoidAI (125K cred/day)      │
│  → OpenRouter (1K/day, auto-free) → NVIDIA NIM                 │
│  → Bonsai (frontier-class) → Giga AI → GitHub Models           │
└─────────────────────────────────────────────────────────────────┘
```

---

## 9. Immediate Action Items for the Spec and Justfile

These must be addressed before the justfile is considered complete:

| # | Action | Priority |
|---|--------|----------|
| 1 | Add AgentDB init + MCP registration to `just setup` | Critical |
| 2 | Change ruflo install to `--full` flag | Critical |
| 3 | Add iFlow install + all iFlow `just` recipes | Critical |
| 4 | Remove all OpenAI/Anthropic API key references from SimpleLLMRouter config | Critical |
| 5 | Add Cerebras, NVIDIA, Bonsai, Giga to `providers.yaml` | High |
| 6 | Fix context routing: Gemini for >200K, Qwen/Mistral for >64K | High |
| 7 | Add `pdm init + pdm config use-uv true` to Python venv recipe | High |
| 8 | Add BMAD CLI init to `just setup` | High |
| 9 | Add `just sync-context` recipe (AGENT.md → derived context files) | High |
| 10 | Create `aigency-specs` repo with template library | Medium |
| 11 | Implement skill sub-groups + lazy-load injection in justfile dispatch | Medium |
| 12 | Wire Motia event bus for BMAD→PRP→GSD→Loki protocol translation | Medium |
| 13 | Add VoidAI daily model check to router startup | Medium |
| 14 | Configure BMAD to output PRP as primary artifact (PRD as secondary) | High |

---

*This addendum is the ground truth for all spec revisions going forward.*
*Next document: Updated justfile incorporating all items in §9.*
