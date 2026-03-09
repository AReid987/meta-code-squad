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
	@echo "\n✓ Dev environment ready. Services running:\n"
	@echo "  • SimpleLLMRouter → http://localhost:{{ROUTER_PORT}}"
	@echo "  • Letta Server    → http://localhost:{{LETTA_PORT}}\n"
	@echo "Run 'just stop' to shut down.\n"

# Stop all services
stop:
	@echo "↓ Stopping services..."
	just stop-router
	just stop-letta
	@echo "✓ All services stopped"

# Health check for all critical components
doctor:
	@echo "\n🩺 Running system health check...\n"
	just _check-prereqs
	just _check-venv
	just _check-router
	just _check-letta
	@echo "✓ All checks passed\n"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# SECTION 3: SERVICE MANAGEMENT
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Start SimpleLLMRouter
start-router:
	@echo "↓ Starting SimpleLLMRouter on port {{ROUTER_PORT}}..."
	#!/usr/bin/env zsh
	set -euo pipefail
	cd {{PROJECT_ROOT}}/packages/simplellmrouter
	source {{PYTHON_VENV}}/bin/activate
	nohup python -m simplellmrouter.server --port {{ROUTER_PORT}} > /tmp/router.log 2>&1 &
	echo $! > /tmp/router.pid
	echo "✓ Router started (PID: $(cat /tmp/router.pid))"

# Stop SimpleLLMRouter
stop-router:
	@if [ -f /tmp/router.pid ]; then \
		kill $(cat /tmp/router.pid) 2>/dev/null || true; \
		rm -f /tmp/router.pid; \
		echo "✓ Router stopped"; \
	else \
		echo "⚠ Router not running"; \
	fi

# Start Letta server
start-letta:
	@echo "↓ Starting Letta server on port {{LETTA_PORT}}..."
	#!/usr/bin/env zsh
	set -euo pipefail
	source {{PYTHON_VENV}}/bin/activate
	nohup letta server --port {{LETTA_PORT}} > /tmp/letta.log 2>&1 &
	echo $! > /tmp/letta.pid
	echo "✓ Letta started (PID: $(cat /tmp/letta.pid))"

# Stop Letta server
stop-letta:
	@if [ -f /tmp/letta.pid ]; then \
		kill $(cat /tmp/letta.pid) 2>/dev/null || true; \
		rm -f /tmp/letta.pid; \
		echo "✓ Letta stopped"; \
	else \
		echo "⚠ Letta not running"; \
	fi

# ╔══════════════════════════════════════════════════════════════════════════════╗
# SECTION 4: AGENT INITIALIZATION
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Initialize Rufflo (Python quality agent)
init-rufflo:
	@echo "↓ Initializing Rufflo agent..."
	@mkdir -p {{PROJECT_ROOT}}/agents/rufflo
	@if [ ! -f "{{PROJECT_ROOT}}/agents/rufflo/agent.json" ]; then \
		printf '{\n  "name": "Rufflo",\n  "role": "Python Quality Agent",\n  "capabilities": [\n    "ruff check",\n    "ruff format",\n    "type checking",\n    "dependency management"\n  ],\n  "triggers": [\n    "on_edit:*.py",\n    "on_commit:*.py"\n  ]\n}\n' > {{PROJECT_ROOT}}/agents/rufflo/agent.json; \
	fi
	@if [ ! -f "{{PROJECT_ROOT}}/agents/rufflo/README.md" ]; then \
		printf '# Rufflo - Python Quality Agent\n\nAutomated Python code quality enforcement using Ruff.\n\n## Capabilities\n- Lint Python files with `ruff check`\n- Format code with `ruff format`\n- Run on edit and commit hooks\n\n## Usage\nRufflo runs automatically via Claude hooks.\n' > {{PROJECT_ROOT}}/agents/rufflo/README.md; \
	fi
	@echo "✓ Rufflo initialized at agents/rufflo"

# Initialize Letta agent (non-interactive)
init-letta:
	@echo "↓ Initializing Letta agent config..."
	@mkdir -p {{PROJECT_ROOT}}/agents/letta
	@if [ ! -f "{{PROJECT_ROOT}}/agents/letta/agent.json" ]; then \
		printf '{\n  "name": "Letta",\n  "role": "Memory Agent",\n  "backend": "openai",\n  "port": {{LETTA_PORT}},\n  "capabilities": [\n    "persistent memory",\n    "multi-agent coordination",\n    "tool use"\n  ]\n}\n' > {{PROJECT_ROOT}}/agents/letta/agent.json; \
	fi
	@echo "✓ Letta agent config written (start server with: just start-letta)"

# Initialize Sugar (JSON formatting agent)
init-sugar:
	@echo "↓ Initializing Sugar agent..."
	@mkdir -p {{PROJECT_ROOT}}/agents/sugar
	@if [ ! -f "{{PROJECT_ROOT}}/agents/sugar/agent.json" ]; then \
		printf '{\n  "name": "Sugar",\n  "role": "JSON Formatting Agent",\n  "capabilities": ["JSON validation", "pretty printing"],\n  "triggers": ["on_edit:*.json"]\n}\n' > {{PROJECT_ROOT}}/agents/sugar/agent.json; \
	fi
	@echo "✓ Sugar initialized at agents/sugar"

# Initialize Loki (logging/monitoring agent)
init-loki:
	@echo "↓ Initializing Loki agent..."
	@mkdir -p {{PROJECT_ROOT}}/agents/loki
	@if [ ! -f "{{PROJECT_ROOT}}/agents/loki/agent.json" ]; then \
		printf '{\n  "name": "Loki",\n  "role": "Logging & Monitoring Agent",\n  "capabilities": ["log aggregation", "error tracking"],\n  "triggers": ["on_session_start"]\n}\n' > {{PROJECT_ROOT}}/agents/loki/agent.json; \
	fi
	@echo "✓ Loki initialized at agents/loki"

# Initialize monorepo tooling
init-monorepo:
	@echo "↓ Setting up monorepo structure..."
	@if [ ! -f "{{PROJECT_ROOT}}/pyproject.toml" ]; then \
		printf '[tool.ruff]\nline-length = 88\ntarget-version = "py311"\n\n[tool.ruff.lint]\nselect = ["E", "F", "I", "N", "W", "UP"]\nignore = []\n\n[tool.ruff.format]\nquote-style = "double"\nindent-style = "space"\n' > {{PROJECT_ROOT}}/pyproject.toml; \
	fi
	@echo "✓ Monorepo configured"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# SECTION 5: INTERNAL HELPERS (prefixed with _)
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Check prerequisites
_check-prereqs:
	@echo "→ Checking prerequisites..."
	@command -v python3 >/dev/null 2>&1 || { echo "❌ python3 not found"; exit 1; }
	@command -v uv >/dev/null 2>&1 || { echo "❌ uv not found — install: curl -LsSf https://astral.sh/uv/install.sh | sh"; exit 1; }
	@command -v pnpm >/dev/null 2>&1 || { echo "❌ pnpm not found — install: npm install -g pnpm"; exit 1; }
	@command -v just >/dev/null 2>&1 || { echo "❌ just not found"; exit 1; }
	@command -v git >/dev/null 2>&1 || { echo "❌ git not found"; exit 1; }
	@echo "✓ Prerequisites OK"

# Create Python virtual environment via uv
_create-venv:
	@echo "→ Creating Python venv..."
	@if [ ! -d "{{PYTHON_VENV}}" ]; then \
		uv venv {{PYTHON_VENV}}; \
		echo "✓ venv created"; \
	else \
		echo "  ✓ Virtual environment exists"; \
	fi

# Install Letta via uv pip
_install-letta:
	@echo "→ Installing Letta..."
	uv pip install --python {{PYTHON_VENV}}/bin/python letta
	@echo "✓ Letta installed"

# Clone and install simplellmrouter (TypeScript repo) into packages/
_install-simplellmrouter:
	@echo "→ Installing SimpleLLMRouter..."
	@[ -d "{{PROJECT_ROOT}}/packages/simplellmrouter" ] || \
		git clone https://github.com/AReid987/simplellmrouter.git {{PROJECT_ROOT}}/packages/simplellmrouter
	@if ! grep -q '^packages:' {{PROJECT_ROOT}}/packages/simplellmrouter/pnpm-workspace.yaml 2>/dev/null; then \
		printf "\npackages:\n  - '.'\n" >> {{PROJECT_ROOT}}/packages/simplellmrouter/pnpm-workspace.yaml; \
	fi
	cd {{PROJECT_ROOT}}/packages/simplellmrouter && pnpm install
	@echo "✓ SimpleLLMRouter installed"

# Set up .env file
_set-env:
	@if [ ! -f "{{PROJECT_ROOT}}/.env" ]; then \
		echo "↓ Creating .env file..."; \
		printf 'ROUTER_PORT={{ROUTER_PORT}}\nLETTA_PORT={{LETTA_PORT}}\n' > {{PROJECT_ROOT}}/.env; \
		echo "✓ .env created"; \
	else \
		echo "✓ .env already exists"; \
	fi

# Check if venv exists
_check-venv:
	@if [ -d "{{PYTHON_VENV}}" ]; then \
		echo "✓ Virtual environment exists"; \
	else \
		echo "❌ Virtual environment missing. Run: just setup"; \
		exit 1; \
	fi

# Check if router is running
_check-router:
	@if [ -f /tmp/router.pid ] && kill -0 $(cat /tmp/router.pid) 2>/dev/null; then \
		echo "✓ Router running (PID: $(cat /tmp/router.pid))"; \
	else \
		echo "⚠ Router not running (run: just start-router)"; \
	fi

# Check if Letta is running
_check-letta:
	@if [ -f /tmp/letta.pid ] && kill -0 $(cat /tmp/letta.pid) 2>/dev/null; then \
		echo "✓ Letta running (PID: $(cat /tmp/letta.pid))"; \
	else \
		echo "⚠ Letta not running (run: just start-letta)"; \
	fi

# Install git hooks
_install-git-hooks:
	@echo "↓ Installing git hooks..."
	@mkdir -p {{PROJECT_ROOT}}/.git/hooks
	@printf '#!/usr/bin/env zsh\njust _hook-on-commit\n' > {{PROJECT_ROOT}}/.git/hooks/pre-commit
	@chmod +x {{PROJECT_ROOT}}/.git/hooks/pre-commit
	@echo "✓ Git hooks installed"

# Hook: session start
_hook-session-start:
	@echo "🪝 Session start hook triggered"
	@just doctor

# Hook: task dispatch
_hook-task-dispatch:
	@echo "🪝 Task dispatch hook triggered"

# Hook: on edit
_hook-on-edit:
	@echo "🪝 Edit hook triggered"

# Hook: on commit
_hook-on-commit:
	@echo "🪝 Commit hook triggered"
	#!/usr/bin/env zsh
	set -euo pipefail
	source {{PYTHON_VENV}}/bin/activate
	cd {{PROJECT_ROOT}}
	ruff check --fix .
	ruff format .
