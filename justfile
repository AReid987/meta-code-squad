# meta-code-squad/justfile
# Root: /Users/antonioreid/CODE/00_PROJECTS/meta-code-squad
# Run `just` to see all available recipes

set dotenv-load := true
set shell := ["zsh", "-cu"]

PROJECT_ROOT := "/Users/antonioreid/CODE/00_PROJECTS/meta-code-squad"
PYTHON_VENV  := PROJECT_ROOT + "/.venv"
ROUTER_PORT  := "8080"
LETTA_PORT   := "8283"

# ┌── DEFAULT: show all recipes ──────────────────────────────────────────────────
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
	just _install-rufflo
	just _install-iflow
	just _install-agentdb
	just _install-loki
	just _install-sugar
	just _install-kimi
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

# ╔══════════════════════════════════════════════════════════════════════════════╗
# SECTION 2: DAILY DRIVER (run every session)
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Start everything for a work session
dev:
	@echo "\n┃┃┃ Starting Meta Code Squad — Dev Mode ┃┃┃\n"
	just _check-services
	just start-router
	just start-letta
	@echo "\n✓ Dev stack ready. Router: http://localhost:{{ROUTER_PORT}} | Letta: http://localhost:{{LETTA_PORT}}\n"

# Full system health check
doctor:
	@echo "\n🩺 Running system diagnostics...\n"
	just _check-prereqs
	just _check-venv
	just _check-simplellmrouter
	just _check-letta
	just _check-services
	@echo "\n✓ All checks passed\n"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# SECTION 3: SERVICE MANAGEMENT
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Start SimpleLLMRouter
start-router:
	@echo "↓ Starting SimpleLLMRouter on port {{ROUTER_PORT}}..."
	@if lsof -ti:{{ROUTER_PORT}} > /dev/null 2>&1; then \
		echo "⚠ Port {{ROUTER_PORT}} already in use"; \
	else \
		cd {{PROJECT_ROOT}}/services/simplellmrouter && \
		source {{PYTHON_VENV}}/bin/activate && \
		uvicorn app.main:app --host 0.0.0.0 --port {{ROUTER_PORT}} --reload & \
		echo "✓ Router started"; \
	fi

# Stop SimpleLLMRouter
stop-router:
	@echo "↓ Stopping SimpleLLMRouter..."
	@lsof -ti:{{ROUTER_PORT}} | xargs kill -9 2>/dev/null || echo "Router not running"
	@echo "✓ Router stopped"

# Start Letta server
start-letta:
	@echo "↓ Starting Letta on port {{LETTA_PORT}}..."
	@if lsof -ti:{{LETTA_PORT}} > /dev/null 2>&1; then \
		echo "⚠ Port {{LETTA_PORT}} already in use"; \
	else \
		source {{PYTHON_VENV}}/bin/activate && \
		letta server --port {{LETTA_PORT}} & \
		echo "✓ Letta started"; \
	fi

# Stop Letta server
stop-letta:
	@echo "↓ Stopping Letta..."
	@lsof -ti:{{LETTA_PORT}} | xargs kill -9 2>/dev/null || echo "Letta not running"
	@echo "✓ Letta stopped"

# Stop all services
stop-all:
	just stop-router
	just stop-letta
	@echo "\n✓ All services stopped\n"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# SECTION 4: INITIALIZATION (run once per service)
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Initialize Rufflo
init-rufflo:
	@echo "↓ Initializing Rufflo..."
	@if [ ! -f {{PROJECT_ROOT}}/packages/rufflo/pyproject.toml ]; then \
		echo "⚠ Rufflo not found. Run: just _install-rufflo"; \
		exit 1; \
	fi
	source {{PYTHON_VENV}}/bin/activate && cd {{PROJECT_ROOT}}/packages/rufflo && uv pip install -e .
	@echo "✓ Rufflo initialized"

# Initialize Letta (non-interactive — skips wizard, uses env vars)
init-letta:
	@echo "↓ Initializing Letta..."
	source {{PYTHON_VENV}}/bin/activate && letta configure --default
	@echo "✓ Letta initialized"

# Initialize Sugar
init-sugar:
	@echo "↓ Initializing Sugar..."
	@if [ ! -f {{PROJECT_ROOT}}/packages/sugar/pyproject.toml ]; then \
		echo "⚠ Sugar not found. Run: just _install-sugar"; \
		exit 1; \
	fi
	source {{PYTHON_VENV}}/bin/activate && cd {{PROJECT_ROOT}}/packages/sugar && uv pip install -e .
	@echo "✓ Sugar initialized"

# Initialize Loki
init-loki:
	@echo "↓ Initializing Loki..."
	@if [ ! -d {{PROJECT_ROOT}}/packages/loki ]; then \
		echo "⚠ Loki not found. Run: just _install-loki"; \
		exit 1; \
	fi
	@echo "✓ Loki initialized"

# Initialize monorepo dependencies
init-monorepo:
	@echo "↓ Installing monorepo dependencies..."
	source {{PYTHON_VENV}}/bin/activate && uv pip install -e "{{PROJECT_ROOT}}[dev]"
	@echo "✓ Monorepo dependencies installed"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# SECTION 5: PRIVATE RECIPES (internal use)
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Check prerequisites
_check-prereqs:
	@echo "↓ Checking prerequisites..."
	@command -v python3 >/dev/null 2>&1 || { echo "❌ python3 required"; exit 1; }
	@command -v git >/dev/null 2>&1 || { echo "❌ git required"; exit 1; }
	@command -v uv >/dev/null 2>&1 || { echo "❌ uv required (curl -LsSf https://astral.sh/uv/install.sh | sh)"; exit 1; }
	@echo "✓ Prerequisites OK"

# Create Python virtual environment
_create-venv:
	@echo "↓ Creating virtual environment..."
	@if [ ! -d {{PYTHON_VENV}} ]; then \
		uv venv {{PYTHON_VENV}}; \
		echo "✓ Virtual environment created"; \
	else \
		echo "✓ Virtual environment exists"; \
	fi

# Check virtual environment
_check-venv:
	@echo "↓ Checking virtual environment..."
	@if [ ! -d {{PYTHON_VENV}} ]; then \
		echo "❌ Virtual environment not found. Run: just setup"; \
		exit 1; \
	fi
	@echo "✓ Virtual environment OK"

# Check SimpleLLMRouter is cloned
_check-simplellmrouter:
	@echo "↓ Checking SimpleLLMRouter..."
	@if [ ! -d {{PROJECT_ROOT}}/services/simplellmrouter ]; then \
		echo "❌ SimpleLLMRouter not found. Run: just _install-simplellmrouter"; \
		exit 1; \
	fi
	@echo "✓ SimpleLLMRouter OK"

# Check Letta is installed
_check-letta:
	@echo "↓ Checking Letta..."
	@source {{PYTHON_VENV}}/bin/activate && command -v letta >/dev/null 2>&1 || { echo "❌ letta not found. Run: just _install-letta"; exit 1; }
	@echo "✓ Letta OK"

# Check running services
_check-services:
	@echo "↓ Checking services..."
	@lsof -ti:{{ROUTER_PORT}} > /dev/null 2>&1 && echo "✓ Router running on {{ROUTER_PORT}}" || echo "○ Router not running"
	@lsof -ti:{{LETTA_PORT}} > /dev/null 2>&1 && echo "✓ Letta running on {{LETTA_PORT}}" || echo "○ Letta not running"

# Install Rufflo
_install-rufflo:
	@echo "↓ Installing Rufflo..."
	@if [ ! -d {{PROJECT_ROOT}}/packages/rufflo ]; then \
		git clone https://github.com/AReid987/rufflo.git {{PROJECT_ROOT}}/packages/rufflo; \
	fi
	@echo "✓ Rufflo installed"

# Install iFlow
_install-iflow:
	@echo "↓ Installing iFlow..."
	@if [ ! -d {{PROJECT_ROOT}}/packages/iflow ]; then \
		git clone https://github.com/AReid987/iflow.git {{PROJECT_ROOT}}/packages/iflow; \
		fi
	@echo "✓ iFlow installed"

# Install AgentDB
_install-agentdb:
	@echo "↓ Installing AgentDB..."
	@if [ ! -d {{PROJECT_ROOT}}/packages/agentdb ]; then \
		git clone https://github.com/AReid987/agentdb.git {{PROJECT_ROOT}}/packages/agentdb; \
	fi
	@echo "✓ AgentDB installed"

# Install Loki
_install-loki:
	@echo "↓ Installing Loki..."
	@if [ ! -d {{PROJECT_ROOT}}/packages/loki ]; then \
		git clone https://github.com/AReid987/loki.git {{PROJECT_ROOT}}/packages/loki; \
	fi
	@echo "✓ Loki installed"

# Install Sugar
_install-sugar:
	@echo "↓ Installing Sugar..."
	@if [ ! -d {{PROJECT_ROOT}}/packages/sugar ]; then \
		git clone https://github.com/AReid987/sugar.git {{PROJECT_ROOT}}/packages/sugar; \
	fi
	@echo "✓ Sugar installed"

# Install Kimi
_install-kimi:
	@echo "↓ Installing Kimi..."
	@if [ ! -d {{PROJECT_ROOT}}/packages/kimi ]; then \
		git clone https://github.com/AReid987/kimi.git {{PROJECT_ROOT}}/packages/kimi; \
	fi
	@echo "✓ Kimi installed"

# Install Letta
_install-letta:
	@echo "↓ Installing Letta..."
	source {{PYTHON_VENV}}/bin/activate && uv pip install letta
	@echo "✓ Letta installed"

# Install SimpleLLMRouter
_install-simplellmrouter:
	@echo "↓ Installing SimpleLLMRouter..."
	@if [ ! -d {{PROJECT_ROOT}}/services/simplellmrouter ]; then \
		git clone https://github.com/AReid987/simplellmrouter.git {{PROJECT_ROOT}}/services/simplellmrouter; \
	fi
	source {{PYTHON_VENV}}/bin/activate && cd {{PROJECT_ROOT}}/services/simplellmrouter && uv pip install -e .
	@echo "✓ SimpleLLMRouter installed"

# Set environment variables
_set-env:
	@echo "↓ Setting environment variables..."
	@if [ ! -f {{PROJECT_ROOT}}/.env ]; then \
		touch {{PROJECT_ROOT}}/.env; \
		echo "ROUTER_PORT={{ROUTER_PORT}}" >> {{PROJECT_ROOT}}/.env; \
		echo "LETTA_PORT={{LETTA_PORT}}" >> {{PROJECT_ROOT}}/.env; \
		echo "✓ .env file created"; \
	else \
		echo "✓ .env file exists"; \
	fi

# Install git hooks
_install-git-hooks:
	@echo "↓ Installing git hooks..."
	@mkdir -p {{PROJECT_ROOT}}/.git/hooks
	@echo '#!/bin/sh\njust _hook-pre-commit' > {{PROJECT_ROOT}}/.git/hooks/pre-commit
	@chmod +x {{PROJECT_ROOT}}/.git/hooks/pre-commit
	@echo "✓ Git hooks installed"

# Hook: session start
_hook-session-start:
	@echo "🎬 Session started"

# Hook: task dispatch
_hook-task-dispatch:
	@echo "📤 Task dispatched"

# Hook: on edit
_hook-on-edit:
	@echo "✏️  File edited"

# Hook: on commit
_hook-on-commit:
	@echo "💾 Committed"

# Hook: pre-commit
_hook-pre-commit:
	@echo "↓ Running pre-commit checks..."
	source {{PYTHON_VENV}}/bin/activate && ruff check .
	@echo "✓ Pre-commit checks passed"
