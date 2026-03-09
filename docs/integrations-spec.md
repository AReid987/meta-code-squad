# Aigency Integrations Spec v1.0

> Part of the Aigency Dev Platform architecture documentation.
> Defines all external service integrations, API patterns, and authentication strategies.

---

## Overview

The Aigency platform integrates with external services across four categories:

1. **AI / LLM Providers** — All routed through SimpleLLMRouter
2. **Developer Tooling** — GitHub, Linear, Notion
3. **Communication** — Telegram, Discord, Slack, Gmail
4. **Data & Infrastructure** — Supabase, Google Workspace, Airtable

All integrations follow a consistent pattern:
- OAuth connections managed by Nebula AI
- Credentials stored as environment variables, never hardcoded
- Agents never call provider APIs directly — always through the router or a dedicated agent

---

## 1. AI / LLM Provider Integrations

All LLM calls route through SimpleLLMRouter v2 at `http://localhost:8080`.

| Provider | Models | Usage | Auth |
|----------|--------|-------|------|
| Anthropic | claude-3-5-sonnet, claude-3-opus | Complex logic, state machines (Ruflo/CLAUDE) | API key via env |
| Google Gemini | gemini-2.5-pro | Architecture, large-context synthesis | API key via env |
| Moonshot Kimi | kimi-latest | Active coding, code review sweeps | API key via env |
| OpenAI | gpt-4o, gpt-4o-mini | Overflow routing, embeddings | API key via env |
| Qwen / Roo | qwen-coder | Quota overflow buffer | API key via env |
| Letta | Internal | Stateful memory agent at :8283 | Local server |

### Routing Rules Summary

```
Complex logic / security / state machines      -->  Anthropic (Claude)
Architecture / planning / synthesis            -->  Google Gemini 2.5 Pro
Active coding / multi-step execution           -->  Moonshot Kimi
Quota overflow                                 -->  Qwen / Roo / iFlow
Embeddings / fast lookups                      -->  OpenAI
```

---

## 2. Developer Tooling

### GitHub
- Account: AReid987 | Auth: OAuth via Nebula | Agent: github-agent
- Primary repos: aigency-specs, meta-code-squad, simplellmrouter
- All code changes via PR — no direct pushes to main
- CI on every PR: lint, typecheck, CodeQL security scan

### Linear
- Account: read.musik@gmail.com | Auth: OAuth via Nebula | Agent: linear-oauth-agent
- Sprint tracking, backlog management, issue lifecycle
- Issues auto-link to PRs via branch naming convention

### Notion
- Account: read.musik@gmail.com | Auth: OAuth via Nebula | Agent: notion-agent
- Architecture specs, project wiki
- Decision log mirrors `.planning/ledger.md`

---

## 3. Communication

### Telegram
- Bot: @AigencyBot | Agent: telegram-agent
- Real-time notifications, command interface, handoff alerts
- Commands: `/status`, `/deploy`, `/logs <service>`

### Discord
- Server: Aigency Dev | Agent: discord-agent
- Channels: `#dev-logs`, `#code-review`, `#planning`

### Slack
- Workspace: Aigency HQ | Auth: OAuth via Nebula
- Weekly sprint summaries, critical production alerts

### Gmail
- Account: read.musik@gmail.com | Auth: OAuth via Nebula | Agent: gmail-agent
- External notifications, calendar invites, audit logs

---

## 4. Data & Infrastructure

### Supabase
- Project: aigency-prod | Auth: Service role key via env
- PostgreSQL DB, real-time subscriptions, auth backend
- Key tables: `projects`, `tasks`, `memory_snapshots`, `audit_log`

### Google Workspace
- Auth: OAuth via Nebula
- Google Drive, Sheets, Calendar

### Airtable
- Base: Aigency Meta | Auth: API key via env
- Tables: Projects, Decisions, Integrations

---

## Authentication & Secrets

```bash
# AI Providers
ANTHROPIC_API_KEY=
GOOGLE_GEMINI_API_KEY=
MOONSHOT_KIMI_API_KEY=
OPENAI_API_KEY=
QWEN_API_KEY=

# Developer Tooling (OAuth via Nebula)
GITHUB_OAUTH_TOKEN=
LINEAR_OAUTH_TOKEN=
NOTION_OAUTH_TOKEN=

# Communication
TELEGRAM_BOT_TOKEN=
DISCORD_BOT_TOKEN=
SLACK_OAUTH_TOKEN=
GMAIL_OAUTH_TOKEN=

# Infrastructure
SUPABASE_URL=
SUPABASE_SERVICE_ROLE_KEY=
AIRTABLE_API_KEY=
GOOGLE_WORKSPACE_OAUTH_TOKEN=
```

---

## Rate Limits & Fallback

| Service | Rate Limit | Fallback |
|---------|------------|----------|
| Anthropic | 50 req/min | Queue in Supabase, retry with backoff |
| GitHub API | 5000 req/hour | Cache responses, batch mutations |
| Linear API | 100 req/min | Queue updates, sync every 5 min |
| Telegram Bot | 30 msg/sec | Queue messages, send in batches |

---

## Adding a New Integration

1. Document in this spec
2. Add OAuth connection via Nebula or store API key in `.env`
3. Create dedicated agent if complex
4. Update `docs/simplellmrouter-v2-spec.md` if routing LLM calls
5. Add rate limit handling and fallback strategy
6. Update `.planning/ledger.md` with decision rationale