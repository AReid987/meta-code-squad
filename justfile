# meta-code-squad/justfile
# Root: /Users/antonioreid/CODE/00_PROJECTS/meta-code-squad
# Run `just` to see all available recipes

set dotenv-load := true
set shell := ["zsh", "-cu"]

PROJECT_ROOT := "/Users/antonioreid/CODE/00_PROJECTS/meta-code-squad"
PYTHON_VENV  := PROJECT_ROOT + "/.venv"
ROUTER_PORT  := "8080"
LETTA_PORT   := "8283"

# ┌── DEFAULT: show all recipes ────────────────────────────────────────────────────
default:
	@just --list

# ╔════════════════════════════════════════════════════════════════════════════╗
# SECTION 1: ONE-TIME SETUP (run once after cloning)
# ╚════════════════════════════════════════════════════════════════════════════╝

# Full stack setup — run once
setup:
	@echo "\n┃┃┃ Meta Code Squad — Full Stack Setup ┃┃┃\n"
	just _check-prereqs
	just _create-venv
	just _install-letta
	just _install-simplellmrouter
	just _set-env
	just init-rufflo
	just init-letta
	just init-sugar
	just init-loki
	just init-monorepo
	just configure-hooks
	just doctor
	@echo "\n✓ Setup complete. Run: just dev\n"

# Wire all git hooks and Claude settings (run once after setup)
configure-hooks:
	@echo "↓ Writing .claude/settings.json..."
	mkdir -p {{PROJECT_ROOT}}/.claude
	echo '{\n  "env": {\n    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1",\n    "SIMPLELLMROUTER_URL": "http://localhost:{{ROUTER_PORT}}",\n    "LETTA_SERVER": "http://localhost:{{LETTA_PORT}}"\n  },\n  "hooks": {\n    "on_session_start": ["just _hook-session-start"],\n    "on_task_dispatch": ["just _hook-task-dispatch"],\n    "on_edit": ["just _hook-on-edit"],\n    "on_commit": ["just _hook-on-commit"]\n  }\n}' > {{PROJECT_ROOT}}/.claude/settings.json
	@echo "✓ .claude/settings.json written"
	@echo "↓ Installing git hooks..."
	just _install-git-hooks
	@echo "✓ Hooks configured"

# ╔════════════════════════════════════════════════════════════════════════════╗
# SECTION 2: DAILY DRIVER (run every session)
# ╚════════════════════════════════════════════════════════════════════════════╝

# Start everything for a work session
dev:
	@echo "\n┃┃┃ Meta Code Squad — Starting Dev Environment ┃┃┃\n"
	just doctor
	@echo "↓ Starting core services..."
	just start-router
	just start-letta
	@echo "↓ Starting agent UIs..."
	just start-rufflo
	just start-sugar
	@echo "✓ All systems operational. Run: just status\n"

# Quick health check
status:
	@echo "═══ Service Status ═══"
	@just _status-router
	@just _status-letta
	@just _status-rufflo
	@just _status-sugar
	@echo ""

# System diagnostic (runs before dev)
doctor:
	@echo "→ Running system diagnostics..."
	@command -v python3 >/dev/null 2>&1 || echo "⚠ Python3 not found"
	@command -v uv >/dev/null 2>&1 || echo "⚠ uv not found"
	@command -v node >/dev/null 2>&1 || echo "⚠ Node.js not found"
	@command -v pnpm >/dev/null 2>&1 || echo "⚠ pnpm not found"
	@command -v docker >/dev/null 2>&1 || echo "⚠ Docker not found"
	@[ -d "{{PYTHON_VENV}}" ] && echo "✓ Python venv exists" || echo "⚠ venv missing"
	@[ -f ".env" ] && echo "✓ .env exists" || echo "⚠ .env missing (run: just _set-env)"
	@just _check-letta
	@just _check-simplellmrouter
	@echo "✓ Diagnostics complete\n"

# ╔════════════════════════════════════════════════════════════════════════════╗
# SECTION 3: SERVICE LIFECYCLE
# ╚════════════════════════════════════════════════════════════════════════════╝

# ┌── simplellmrouter ──────────────────────────────────────────────────────────

# Start simplellmrouter (port {{ROUTER_PORT}})
start-router:
	@echo "↓ Starting simplellmrouter on port {{ROUTER_PORT}}..."
	@just _check-port {{ROUTER_PORT}} "simplellmrouter"
	#!/usr/bin/env zsh
	source {{PYTHON_VENV}}/bin/activate
	cd {{PROJECT_ROOT}}/packages/simplellmrouter
	python -m simplellmrouter.server --port {{ROUTER_PORT}} > /tmp/simplellmrouter.log 2>&1 &
	echo $! > /tmp/simplellmrouter.pid
	echo "✓ Router started (PID: $(cat /tmp/simplellmrouter.pid))"

# Stop simplellmrouter
stop-router:
	@echo "↓ Stopping simplellmrouter..."
	@[ -f /tmp/simplellmrouter.pid ] && kill $(cat /tmp/simplellmrouter.pid) && rm /tmp/simplellmrouter.pid || echo "Not running"

# ┌── letta ────────────────────────────────────────────────────────────────────

# Start letta server (port {{LETTA_PORT}})
start-letta:
	@echo "↓ Starting letta server on port {{LETTA_PORT}}..."
	@just _check-port {{LETTA_PORT}} "letta"
	#!/usr/bin/env zsh
	source {{PYTHON_VENV}}/bin/activate
	letta server --port {{LETTA_PORT}} > /tmp/letta.log 2>&1 &
	echo $! > /tmp/letta.pid
	echo "✓ Letta started (PID: $(cat /tmp/letta.pid))"

# Stop letta server
stop-letta:
	@echo "↓ Stopping letta..."
	@[ -f /tmp/letta.pid ] && kill $(cat /tmp/letta.pid) && rm /tmp/letta.pid || echo "Not running"

# ┌── rufflo (Browser Agent UI) ───────────────────────────────────────────────

# Start rufflo dev server
start-rufflo:
	@echo "↓ Starting rufflo (Browser Agent UI)..."
	#!/usr/bin/env zsh
	cd {{PROJECT_ROOT}}/agents/rufflo
	pnpm dev > /tmp/rufflo.log 2>&1 &
	echo $! > /tmp/rufflo.pid
	echo "✓ Rufflo started (PID: $(cat /tmp/rufflo.pid))"

# Stop rufflo
stop-rufflo:
	@echo "↓ Stopping rufflo..."
	@[ -f /tmp/rufflo.pid ] && kill $(cat /tmp/rufflo.pid) && rm /tmp/rufflo.pid || echo "Not running"

# ┌── sugar (TUI orchestrator) ────────────────────────────────────────────────

# Start sugar TUI
start-sugar:
	@echo "↓ Starting sugar (TUI orchestrator)..."
	#!/usr/bin/env zsh
	cd {{PROJECT_ROOT}}/agents/sugar
	pnpm dev > /tmp/sugar.log 2>&1 &
	echo $! > /tmp/sugar.pid
	echo "✓ Sugar started (PID: $(cat /tmp/sugar.pid))"

# Stop sugar
stop-sugar:
	@echo "↓ Stopping sugar..."
	@[ -f /tmp/sugar.pid ] && kill $(cat /tmp/sugar.pid) && rm /tmp/sugar.pid || echo "Not running"

# ┌── ALL ──────────────────────────────────────────────────────────────────────

# Stop all running services
stop-all:
	just stop-router
	just stop-letta
	just stop-rufflo
	just stop-sugar
	@echo "✓ All services stopped"

# Restart everything
restart:
	just stop-all
	sleep 2
	just dev

# ╔════════════════════════════════════════════════════════════════════════════╗
# SECTION 4: AGENT INITIALIZATION (run once per agent)
# ╚════════════════════════════════════════════════════════════════════════════╝

# Initialize rufflo agent
init-rufflo:
	@echo "↓ Initializing rufflo..."
	cd {{PROJECT_ROOT}}/agents/rufflo && pnpm install
	@echo "✓ Rufflo initialized"

# Initialize letta agent (non-interactive)
init-letta:
	@echo "↓ Initializing letta..."
	#!/usr/bin/env zsh
	source {{PYTHON_VENV}}/bin/activate
	letta configure --default || true
	@echo "✓ Letta initialized"

# Initialize sugar TUI
init-sugar:
	@echo "↓ Initializing sugar..."
	cd {{PROJECT_ROOT}}/agents/sugar && pnpm install
	@echo "✓ Sugar initialized"

# Initialize loki (logs aggregator)
init-loki:
	@echo "↓ Initializing loki..."
	cd {{PROJECT_ROOT}}/agents/loki && pnpm install
	@echo "✓ Loki initialized"

# Initialize monorepo root dependencies
init-monorepo:
	@echo "↓ Installing root dependencies..."
	cd {{PROJECT_ROOT}} && pnpm install
	@echo "✓ Monorepo root initialized"

# ╔════════════════════════════════════════════════════════════════════════════╗
# SECTION 5: DEVELOPMENT HELPERS
# ╚════════════════════════════════════════════════════════════════════════════╝

# Run all linters/formatters
lint:
	@echo "↓ Running linters..."
	cd {{PROJECT_ROOT}} && pnpm lint
	@echo "✓ Lint complete"

# Format code
fmt:
	cd {{PROJECT_ROOT}} && pnpm format
	@echo "✓ Format complete"

# Run tests
test:
	@echo "↓ Running tests..."
	cd {{PROJECT_ROOT}} && pnpm test
	@echo "✓ Tests complete"

# Clean build artifacts
clean:
	@echo "↓ Cleaning build artifacts..."
	find {{PROJECT_ROOT}} -type d -name "node_modules" -prune -exec rm -rf {} \;
	find {{PROJECT_ROOT}} -type d -name "dist" -prune -exec rm -rf {} \;
	find {{PROJECT_ROOT}} -type d -name ".turbo" -prune -exec rm -rf {} \;
	find {{PROJECT_ROOT}} -type d -name "__pycache__" -prune -exec rm -rf {} \;
	@echo "✓ Clean complete"

# View logs for a service (usage: just logs <service>)
logs service:
	@tail -f /tmp/{{service}}.log

# ╔════════════════════════════════════════════════════════════════════════════╗
# SECTION 6: PRIVATE HELPERS (prefixed with _)
# ╚════════════════════════════════════════════════════════════════════════════╝

# Check system prerequisites
_check-prereqs:
	@echo "→ Checking prerequisites..."
	@command -v python3 >/dev/null 2>&1 || (echo "❌ Python3 required" && exit 1)
	@command -v uv >/dev/null 2>&1 || (echo "❌ uv required — install: curl -LsSf https://astral.sh/uv/install.sh | sh" && exit 1)
	@command -v node >/dev/null 2>&1 || (echo "❌ Node.js required" && exit 1)
	@command -v pnpm >/dev/null 2>&1 || (echo "❌ pnpm required" && exit 1)
	@echo "✓ Prerequisites OK"

# Create Python virtual environment
_create-venv:
	@echo "→ Creating Python venv..."
	@[ -d "{{PYTHON_VENV}}" ] && echo "  ✓ Virtual environment exists"
	uv venv {{PYTHON_VENV}}
	@echo "✓ venv created"

# Install letta
_install-letta:
	@echo "→ Installing Letta..."
	uv pip install --python {{PYTHON_VENV}}/bin/python letta
	@echo "✓ Letta installed"

# Install simplellmrouter from local package
_install-simplellmrouter:
	@echo "→ Installing SimpleLLMRouter dependencies..."
	cd {{PROJECT_ROOT}}/packages/simplellmrouter && pnpm install
	@echo "✓ SimpleLLMRouter dependencies installed"

# Create .env file
_set-env:
	@echo "↓ Creating .env file..."
	@[ -f ".env" ] && echo "✓ .env already exists" || cp .env.example .env

# Install git hooks
_install-git-hooks:
	@echo "↓ Installing git hooks..."
	mkdir -p {{PROJECT_ROOT}}/.git/hooks
	echo '#!/bin/sh\njust _hook-pre-commit' > {{PROJECT_ROOT}}/.git/hooks/pre-commit
	chmod +x {{PROJECT_ROOT}}/.git/hooks/pre-commit
	@echo "✓ Git hooks installed"

# Check if port is available
_check-port port service:
	@lsof -ti:{{port}} >/dev/null 2>&1 && echo "⚠ Port {{port}} ({{service}}) already in use" || true

# Status checkers
_status-router:
	@[ -f /tmp/simplellmrouter.pid ] && echo "✓ Router (PID: $(cat /tmp/simplellmrouter.pid))" || echo "✗ Router not running"

_status-letta:
	@[ -f /tmp/letta.pid ] && echo "✓ Letta (PID: $(cat /tmp/letta.pid))" || echo "✗ Letta not running"

_status-rufflo:
	@[ -f /tmp/rufflo.pid ] && echo "✓ Rufflo (PID: $(cat /tmp/rufflo.pid))" || echo "✗ Rufflo not running"

_status-sugar:
	@[ -f /tmp/sugar.pid ] && echo "✓ Sugar (PID: $(cat /tmp/sugar.pid))" || echo "✗ Sugar not running"

# Doctor checkers
_check-letta:
	@{{PYTHON_VENV}}/bin/letta --version >/dev/null 2>&1 && echo "✓ letta installed" || echo "⚠ letta not installed (run: just _install-letta)"

_check-simplellmrouter:
	@[ -d "{{PROJECT_ROOT}}/packages/simplellmrouter" ] && echo "✓ simplellmrouter package exists" || echo "⚠ packages/simplellmrouter missing"

# Git hook: pre-commit
_hook-pre-commit:
	@echo "→ Running pre-commit checks..."
	just lint
	just test
	@echo "✓ Pre-commit passed"

# Claude hooks
_hook-session-start:
	@echo "→ [HOOK] Session started at $(date)"
	just doctor

_hook-task-dispatch:
	@echo "→ [HOOK] Task dispatched at $(date)"

_hook-on-edit:
	@echo "→ [HOOK] File edited at $(date)"

_hook-on-commit:
	@echo "→ [HOOK] Commit at $(date)"
	just lint
