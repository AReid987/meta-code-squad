# meta-code-squad/justfile
# Root: /Users/antonioreid/CODE/00_PROJECTS/meta-code-squad
# Run `just` to see all available recipes

set dotenv-load := true
set shell := ["zsh", "-cu"]

PROJECT_ROOT := "/Users/antonioreid/CODE/00_PROJECTS/meta-code-squad"
PYTHON_VENV  := PROJECT_ROOT + "/.venv"
ROUTER_PORT  := "8080"
LETTA_PORT   := "8283"

# ┌── DEFAULT: show all recipes ─────────────────────────────────────────────────
default:
	@just --list

# ╔══════════════════════════════════════════════════════════════════════════════╗
# SECTION 1: ONE-TIME SETUP (run once after cloning)
# ╚══════════════════════════════════════════════════════════════════════════════╝

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
	printf '{\n  "env": {\n    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1",\n    "SIMPLELLMROUTER_URL": "http://localhost:{{ROUTER_PORT}}",\n    "LETTA_SERVER": "http://localhost:{{LETTA_PORT}}"\n  },\n  "hooks": {\n    "on_session_start": ["just _hook-session-start"],\n    "on_task_dispatch": ["just _hook-task-dispatch"],\n    "on_edit": ["just _hook-on-edit"],\n    "on_commit": ["just _hook-on-commit"]\n  }\n}\n' > {{PROJECT_ROOT}}/.claude/settings.json
	@echo "✓ .claude/settings.json written"
	@echo "↓ Installing git hooks..."
	just _install-git-hooks
	@echo "✓ Hooks configured"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# SECTION 2: DAILY DRIVER (run every session)
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Start everything for a work session
dev:
	@echo "\n┃┃┃ Meta Code Squad — Starting Dev Environment ┃┃┃\n"
	just doctor
	@echo "↓ Starting core services..."
	just start-router
	just start-letta
	@echo "\n✓ All services running. Next:\n  • Open Claude Desktop\n  • Set SIMPLELLMROUTER_URL → http://localhost:{{ROUTER_PORT}}\n  • Set LETTA_SERVER → http://localhost:{{LETTA_PORT}}\n"

# Stop all services (router + Letta + Docker logs)
stop:
	@echo "↓ Stopping all services..."
	-@lsof -ti:{{ROUTER_PORT}} | xargs -r kill -9 2>/dev/null || true
	-@lsof -ti:{{LETTA_PORT}} | xargs -r kill -9 2>/dev/null || true
	@echo "✓ All services stopped"

# Check if all required services/tools are healthy
doctor:
	@echo "\n↓ Running health checks...\n"
	@command -v python3 >/dev/null 2>&1 && echo "✓ python3" || echo "✗ python3 missing"
	@command -v just >/dev/null 2>&1 && echo "✓ just" || echo "✗ just missing"
	@command -v pnpm >/dev/null 2>&1 && echo "✓ pnpm" || echo "✗ pnpm missing"
	@[ -d {{PYTHON_VENV}} ] && echo "✓ venv at {{PYTHON_VENV}}" || echo "✗ venv missing (run: just setup)"
	@[ -f {{PROJECT_ROOT}}/.env ] && echo "✓ .env file" || echo "⚠  .env file missing (see .env.template)"
	@echo ""

# ╔══════════════════════════════════════════════════════════════════════════════╗
# SECTION 3: SERVICE CONTROL (router + Letta)
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Start SimpleLLMRouter in foreground (logs to terminal)
start-router:
	@echo "↓ Starting SimpleLLMRouter on port {{ROUTER_PORT}}..."
	@if lsof -ti:{{ROUTER_PORT}} >/dev/null 2>&1; then \
		echo "⚠  Port {{ROUTER_PORT}} already in use. Stopping existing process..."; \
		kill -9 $(lsof -ti:{{ROUTER_PORT}}); \
		sleep 1; \
	fi
	cd {{PROJECT_ROOT}}/packages/simplellmrouter && pnpm dev

# Start Letta server in foreground (logs to terminal)
start-letta:
	@echo "↓ Starting Letta server on port {{LETTA_PORT}}..."
	@if lsof -ti:{{LETTA_PORT}} >/dev/null 2>&1; then \
		echo "⚠  Port {{LETTA_PORT}} already in use. Stopping existing process..."; \
		kill -9 $(lsof -ti:{{LETTA_PORT}}); \
		sleep 1; \
	fi
	source {{PYTHON_VENV}}/bin/activate && letta server --host 0.0.0.0 --port {{LETTA_PORT}}

# Stop SimpleLLMRouter
stop-router:
	@echo "↓ Stopping SimpleLLMRouter..."
	-@lsof -ti:{{ROUTER_PORT}} | xargs -r kill -9 2>/dev/null || true
	@echo "✓ Router stopped"

# Stop Letta server
stop-letta:
	@echo "↓ Stopping Letta..."
	-@lsof -ti:{{LETTA_PORT}} | xargs -r kill -9 2>/dev/null || true
	@echo "✓ Letta stopped"

# Tail SimpleLLMRouter logs
logs-router:
	@tail -f {{PROJECT_ROOT}}/logs/router.log

# Tail Letta server logs
logs-letta:
	@tail -f {{PROJECT_ROOT}}/logs/letta.log

# ╔══════════════════════════════════════════════════════════════════════════════╗
# SECTION 4: TESTING & VALIDATION
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Run all tests (router + letta + rufflo)
test:
	@echo "\n↓ Running all tests...\n"
	just test-router
	just test-letta
	just test-rufflo
	@echo "\n✓ All tests passed\n"

# Test SimpleLLMRouter (pytest)
test-router:
	@echo "↓ Testing SimpleLLMRouter..."
	@cd {{PROJECT_ROOT}}/packages/simplellmrouter && {{PYTHON_VENV}}/bin/pytest tests/ -v

# Test Letta integration
test-letta:
	@echo "↓ Testing Letta..."
	@cd {{PROJECT_ROOT}}/packages/letta && {{PYTHON_VENV}}/bin/pytest tests/ -v

# Test Rufflo (py + TS linters)
test-rufflo:
	@echo "↓ Testing Rufflo..."
	@cd {{PROJECT_ROOT}}/packages/rufflo && {{PYTHON_VENV}}/bin/pytest tests/ -v

# Ping SimpleLLMRouter health endpoint
ping-router:
	@curl -s http://localhost:{{ROUTER_PORT}}/health | jq .

# Ping Letta server health endpoint
ping-letta:
	@curl -s http://localhost:{{LETTA_PORT}}/health | jq .

# ╔══════════════════════════════════════════════════════════════════════════════╗
# SECTION 5: LINTING, FORMATTING & HOOKS
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Run all formatters (Python + TS + Markdown)
fmt:
	@echo "↓ Formatting all code..."
	just fmt-py
	just fmt-ts
	@echo "✓ All code formatted"

# Format Python with ruff
fmt-py:
	@echo "↓ Formatting Python..."
	@{{PYTHON_VENV}}/bin/ruff format .
	@{{PYTHON_VENV}}/bin/ruff check --fix .

# Format TypeScript/JS with prettier
fmt-ts:
	@echo "↓ Formatting TypeScript/JS..."
	@pnpm prettier --write "**/*.{ts,tsx,js,jsx,json,md}"

# Lint Python with ruff
lint-py:
	@echo "↓ Linting Python..."
	@{{PYTHON_VENV}}/bin/ruff check .

# Lint TypeScript with ESLint
lint-ts:
	@echo "↓ Linting TypeScript..."
	@pnpm eslint "**/*.{ts,tsx}"

# Type-check Python with pyright
type-check-py:
	@echo "↓ Type-checking Python..."
	@{{PYTHON_VENV}}/bin/pyright

# Type-check TypeScript
type-check-ts:
	@echo "↓ Type-checking TypeScript..."
	@pnpm tsc --noEmit

# ╔══════════════════════════════════════════════════════════════════════════════╗
# SECTION 6: OBSERVABILITY (Loki + Grafana)
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Initialize Loki for centralized logging
init-loki:
	@echo "↓ Initializing Loki..."
	@mkdir -p {{PROJECT_ROOT}}/observability/loki
	@if [ ! -f {{PROJECT_ROOT}}/observability/loki/config.yml ]; then \
		printf 'auth_enabled: false\n\nserver:\n  http_listen_port: 3100\n\ningester:\n  lifecycler:\n    ring:\n      kvstore:\n        store: inmemory\n      replication_factor: 1\n  chunk_idle_period: 5m\n  chunk_retain_period: 30s\n\nschema_config:\n  configs:\n    - from: 2020-05-15\n      store: boltdb\n      object_store: filesystem\n      schema: v11\n      index:\n        prefix: index_\n        period: 168h\n\nstorage_config:\n  boltdb:\n    directory: /tmp/loki/index\n  filesystem:\n    directory: /tmp/loki/chunks\n' > {{PROJECT_ROOT}}/observability/loki/config.yml; \
	fi
	@echo "✓ Loki config written to observability/loki/config.yml"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# SECTION 7: MONOREPO MANAGEMENT
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Initialize monorepo structure (pnpm workspace + tsconfig references)
init-monorepo:
	@echo "↓ Initializing monorepo..."
	@if [ ! -f {{PROJECT_ROOT}}/pnpm-workspace.yaml ]; then \
		printf 'packages:\n  - "packages/*"\n' > {{PROJECT_ROOT}}/pnpm-workspace.yaml; \
	fi
	@if [ ! -f {{PROJECT_ROOT}}/tsconfig.json ]; then \
		printf '{\n  "compilerOptions": {\n    "target": "ES2022",\n    "module": "ESNext",\n    "moduleResolution": "bundler",\n    "esModuleInterop": true,\n    "skipLibCheck": true,\n    "strict": true\n  },\n  "references": [\n    { "path": "./packages/simplellmrouter" }\n  ]\n}\n' > {{PROJECT_ROOT}}/tsconfig.json; \
	fi
	@echo "✓ Monorepo initialized (pnpm-workspace.yaml + tsconfig.json)"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# SECTION 8: RUFFLO (PY+TS LINTER)
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Initialize Rufflo (dual-language linter)
init-rufflo:
	@echo "↓ Initializing Rufflo..."
	@mkdir -p {{PROJECT_ROOT}}/packages/rufflo
	@if [ ! -f {{PROJECT_ROOT}}/packages/rufflo/pyproject.toml ]; then \
		printf '[tool.ruff]\ntarget-version = "py311"\nline-length = 100\n\n[tool.ruff.lint]\nselect = ["E", "F", "I", "N", "UP", "RUF"]\n' > {{PROJECT_ROOT}}/packages/rufflo/pyproject.toml; \
	fi
	@echo "✓ Rufflo initialized at packages/rufflo"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# SECTION 9: SUGAR (CLI CONVENIENCE HELPERS)
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Initialize Sugar CLI
init-sugar:
	@echo "↓ Initializing Sugar CLI..."
	@mkdir -p {{PROJECT_ROOT}}/packages/sugar
	@if [ ! -f {{PROJECT_ROOT}}/packages/sugar/cli.py ]; then \
		printf '#!/usr/bin/env python3\n"""Sugar CLI — quick helpers for Meta Code Squad."""\nimport sys\n\ndef main():\n    print("Sugar CLI v0.1.0")\n    sys.exit(0)\n\nif __name__ == "__main__":\n    main()\n' > {{PROJECT_ROOT}}/packages/sugar/cli.py; \
		chmod +x {{PROJECT_ROOT}}/packages/sugar/cli.py; \
	fi
	@echo "✓ Sugar CLI initialized at packages/sugar/cli.py"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# SECTION 10: LETTA INITIALIZATION
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Initialize Letta config (first-time setup)
init-letta:
	@echo "↓ Initializing Letta..."
	@mkdir -p {{PROJECT_ROOT}}/packages/letta
	@if [ ! -f {{PROJECT_ROOT}}/packages/letta/config.json ]; then \
		printf '{\n  "server": {\n    "host": "0.0.0.0",\n    "port": {{LETTA_PORT}}\n  }\n}\n' > {{PROJECT_ROOT}}/packages/letta/config.json; \
	fi
	@echo "✓ Letta config written to packages/letta/config.json"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# SECTION 11: INTERNAL HELPERS (prefixed with _)
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Check for required tools
_check-prereqs:
	@echo "↓ Checking prerequisites..."
	@command -v python3 >/dev/null 2>&1 || { echo "✗ python3 not found. Install Python 3.11+"; exit 1; }
	@command -v pnpm >/dev/null 2>&1 || { echo "✗ pnpm not found. Install: npm i -g pnpm"; exit 1; }
	@command -v just >/dev/null 2>&1 || { echo "✗ just not found. Install: brew install just"; exit 1; }
	@echo "✓ All prerequisites installed"

# Create Python virtual environment
_create-venv:
	@echo "↓ Creating virtual environment..."
	@python3 -m venv {{PYTHON_VENV}}
	@{{PYTHON_VENV}}/bin/pip install --upgrade pip setuptools wheel
	@echo "✓ Virtual environment created at {{PYTHON_VENV}}"

# Install Letta in venv
_install-letta:
	@echo "↓ Installing Letta..."
	@{{PYTHON_VENV}}/bin/pip install letta
	@echo "✓ Letta installed"

# Install SimpleLLMRouter package in editable mode
_install-simplellmrouter:
	@echo "↓ Installing SimpleLLMRouter..."
	@cd {{PROJECT_ROOT}}/packages/simplellmrouter && {{PYTHON_VENV}}/bin/pip install -e .
	@echo "✓ SimpleLLMRouter installed in editable mode"

# Write .env file from template
_set-env:
	@echo "↓ Writing .env file..."
	@if [ ! -f {{PROJECT_ROOT}}/.env ]; then \
		printf 'SIMPLELLMROUTER_URL=http://localhost:{{ROUTER_PORT}}\nLETTA_SERVER=http://localhost:{{LETTA_PORT}}\n' > {{PROJECT_ROOT}}/.env; \
		echo "✓ .env file created (edit as needed)"; \
	else \
		echo "⚠  .env already exists, skipping"; \
	fi

# Install git hooks (pre-commit, pre-push)
_install-git-hooks:
	@mkdir -p {{PROJECT_ROOT}}/.git/hooks
	@printf '#!/bin/sh\njust _hook-pre-commit\n' > {{PROJECT_ROOT}}/.git/hooks/pre-commit
	@chmod +x {{PROJECT_ROOT}}/.git/hooks/pre-commit
	@printf '#!/bin/sh\njust _hook-pre-push\n' > {{PROJECT_ROOT}}/.git/hooks/pre-push
	@chmod +x {{PROJECT_ROOT}}/.git/hooks/pre-push
	@echo "✓ Git hooks installed"

# Hook: session start (called by Claude)
_hook-session-start:
	@echo "[HOOK] Session started at $(date)"
	@just doctor

# Hook: task dispatch (called by Claude)
_hook-task-dispatch:
	@echo "[HOOK] Task dispatched at $(date)"

# Hook: on edit (called by Claude)
_hook-on-edit:
	@echo "[HOOK] File edited at $(date)"

# Hook: on commit (called by Claude)
_hook-on-commit:
	@echo "[HOOK] Commit triggered at $(date)"

# Hook: pre-commit (git hook)
_hook-pre-commit:
	@echo "[GIT HOOK] Running pre-commit checks..."
	just lint-py
	just lint-ts

# Hook: pre-push (git hook)
_hook-pre-push:
	@echo "[GIT HOOK] Running pre-push checks..."
	just test
