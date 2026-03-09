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

# Full stack setup – run once
setup:
	@echo "\n┃┃┃ Meta Code Squad – Full Stack Setup ┃┃┃\n"
	just _check-prereqs
	just _create-venv
	just _install-ruflo
	just _install-iflow
	just _install-agentdb
	just _install-loki
	just _install-sugar
	just _install-kimi
	just _install-letta
	just _install-simplellmrouter
	just _set-env
	just init-ruflo
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
	@echo "\n┃┃┃ Starting Meta Code Squad – All Services ┃┃┃\n"
	just _check-services
	just _start-router
	just _start-letta
	@echo "\n✓ All services running. Run 'just stop' when done.\n"

# Stop all running services
stop:
	@echo "\n↓ Stopping all services...\n"
	-pkill -f simplellmrouter
	-pkill -f "letta server"
	@echo "✓ All services stopped\n"

# Health check all services
status:
	@echo "\n── Service Status ──\n"
	@echo "SimpleLLMRouter ({{ROUTER_PORT}}): $(curl -s http://localhost:{{ROUTER_PORT}}/health > /dev/null && echo '✓ running' || echo '✗ down')"
	@echo "Letta Server ({{LETTA_PORT}}):     $(curl -s http://localhost:{{LETTA_PORT}}/v1/health > /dev/null && echo '✓ running' || echo '✗ down')\n"

# Run full test suite
test:
	@echo "\n↓ Running all tests...\n"
	pdm run pytest tests/ -v
	@echo "\n✓ Tests complete\n"

# Format all code
fmt:
	@echo "\n↓ Formatting code...\n"
	pdm run black .
	pdm run isort .
	@echo "\n✓ Formatting complete\n"

# Lint all code
lint:
	@echo "\n↓ Linting code...\n"
	pdm run flake8 .
	pdm run mypy .
	@echo "\n✓ Linting complete\n"

# Run system health check
doctor:
	@echo "\n── System Health Check ──\n"
	@command -v just > /dev/null && echo "✓ just" || echo "✗ just (install: https://just.systems)"
	@command -v python3 > /dev/null && echo "✓ python3" || echo "✗ python3"
	@command -v uv > /dev/null && echo "✓ uv" || echo "✗ uv (install: https://docs.astral.sh/uv)"
	@command -v pdm > /dev/null && echo "✓ pdm" || echo "✗ pdm (install: https://pdm-project.org)"
	@command -v pnpm > /dev/null && echo "✓ pnpm" || echo "✗ pnpm (install: npm i -g pnpm)"
	@command -v claude > /dev/null && echo "✓ claude" || echo "✗ claude (install: npm i -g @anthropic-ai/claude-code)"
	@command -v gemini > /dev/null && echo "✓ gemini" || echo "✗ gemini (install: npm i -g @google/gemini-cli)"
	@command -v ruflo > /dev/null && echo "✓ ruflo" || echo "✗ ruflo (run: just _install-ruflo)"
	@command -v iflow > /dev/null && echo "✓ iflow" || echo "✗ iflow (run: just _install-iflow)"
	@command -v loki > /dev/null && echo "✓ loki" || echo "✗ loki (run: just _install-loki)"
	@command -v sugar > /dev/null && echo "✓ sugar" || echo "✗ sugar (run: just _install-sugar)"
	@command -v letta > /dev/null && echo "✓ letta" || echo "✗ letta (run: just _install-letta)"
	@command -v kimi > /dev/null && echo "✓ kimi" || echo "✗ kimi (run: just _install-kimi)"
	@command -v simplellmrouter > /dev/null && echo "✓ simplellmrouter" || echo "✗ simplellmrouter (run: just _install-simplellmrouter)"
	@test -f {{PROJECT_ROOT}}/.env && echo "✓ .env" || echo "✗ .env (run: just _set-env)"
	@test -d {{PYTHON_VENV}} && echo "✓ venv" || echo "✗ venv (run: just _create-venv)"
	@echo ""

# ╔══════════════════════════════════════════════════════════════════════════════╗
# SECTION 3: INITIALIZATION (run after install)
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Initialize Ruflo (run after _install-ruflo)
init-ruflo:
	@echo "→ Initializing Ruflo in hive mode..."
	cd {{PROJECT_ROOT}} && pnpm dlx ruflo@latest init --mode=hive
	claude mcp add ruflo -- pnpm dlx ruflo@latest mcp start
	@echo "✓ Ruflo initialized"

# Initialize Letta (run after _install-letta)
init-letta:
	@echo "→ Initializing Letta..."
	letta quickstart --backend postgres
	@echo "✓ Letta initialized"

# Initialize Sugar (run after _install-sugar)
init-sugar:
	@echo "→ Initializing Sugar..."
	sugar init
	@echo "✓ Sugar initialized"

# Initialize Loki (run after _install-loki)
init-loki:
	@echo "→ Initializing Loki..."
	loki init
	@echo "✓ Loki initialized"

# Initialize monorepo structure (run once after setup)
init-monorepo:
	@echo "→ Setting up monorepo structure..."
	mkdir -p packages/{agents,tools,shared}
	mkdir -p apps/{api,cli,web}
	mkdir -p .github/workflows
	mkdir -p docs/{api,guides,specs}
	mkdir -p tests/{integration,e2e,unit}
	@echo "✓ Monorepo structure initialized"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# SECTION 4: PRIVATE HELPERS (prefixed with _)
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Check prerequisites
_check-prereqs:
	@echo "→ Checking prerequisites..."
	@command -v just > /dev/null || (echo "ERROR: just not found — install from https://just.systems" && exit 1)
	@command -v python3 > /dev/null || (echo "ERROR: python3 not found" && exit 1)
	@command -v uv > /dev/null || (echo "ERROR: uv not found — install from https://docs.astral.sh/uv" && exit 1)
	@command -v pdm > /dev/null || (echo "ERROR: pdm not found — install from https://pdm-project.org" && exit 1)
	@command -v pnpm > /dev/null || (echo "ERROR: pnpm not found — run: npm i -g pnpm" && exit 1)
	@command -v claude > /dev/null || (echo "ERROR: claude not found — run: pnpm add -g @anthropic-ai/claude-code" && exit 1)
	@command -v gemini > /dev/null || (echo "ERROR: gemini not found — run: pnpm add -g @google/gemini-cli" && exit 1)
	@echo "✓ Prerequisites satisfied"

# Create Python virtual environment
_create-venv:
	@echo "→ Creating Python virtual environment..."
	uv venv {{PYTHON_VENV}}
	@echo "✓ Virtual environment created"

# Install Ruflo
_install-ruflo:
	@echo "→ Installing Ruflo..."
	pnpm add -g ruflo@latest
	@echo "✓ Ruflo installed"

# Install iFlow CLI
_install-iflow:
	@echo "→ Installing iFlow CLI..."
	pnpm add -g @iflow-ai/iflow-cli
	@echo "✓ iFlow installed"

# Install AgentDB
_install-agentdb:
	@echo "→ Installing AgentDB..."
	pnpm add -g agentdb@latest
	@echo "→ Running AgentDB full setup (SONA + HNSW + RL)..."
	agentdb init --backend auto
	@echo "✓ AgentDB installed"

# Install Loki Mode
_install-loki:
	@echo "→ Installing Loki Mode..."
	pnpm add -g loki-mode
	@echo "✓ Loki installed"

# Install Sugar CLI (pre-built binary – avoids indicatif/console compile errors)
_install-sugar:
	#!/usr/bin/env bash
	set -euo pipefail
	echo "→ Installing Sugar CLI (pre-built binary)..."
	if command -v sugar > /dev/null 2>&1; then
	echo "✓ Sugar already installed: $(sugar --version)"; exit 0
	fi
	OS=$(uname -s | tr '[:upper:]' '[:lower:]')
	ARCH=$(uname -m)
	case "$ARCH" in
	x86_64) ARCH_LABEL="x64" ;;
	arm64|aarch64) ARCH_LABEL="arm64" ;;
	*) echo "✗ Unsupported arch: $ARCH"; exit 1 ;;
	esac
	URL="https://github.com/metaplex-foundation/sugar/releases/latest/download/sugar-cli-macOS-latest-${ARCH_LABEL}.tar.gz"
	echo "  Downloading $URL ..."
	curl -fsSL "$URL" -o /tmp/sugar-cli.tar.gz
	tar -xzf /tmp/sugar-cli.tar.gz -C /tmp
	mkdir -p "$HOME/.cargo/bin"
	mv /tmp/sugar-cli "$HOME/.cargo/bin/sugar" 2>/dev/null || mv /tmp/sugar "$HOME/.cargo/bin/sugar"
	chmod +x "$HOME/.cargo/bin/sugar"
	rm -f /tmp/sugar-cli.tar.gz
	echo "✓ Sugar installed: $("$HOME/.cargo/bin/sugar" --version)"

# Install Letta
_install-letta:
	@echo "→ Installing Letta..."
	uv pip install --python {{PYTHON_VENV}} letta
	@echo "✓ Letta installed"

# Install Kimi CLI
_install-kimi:
	@echo "→ Installing Kimi CLI..."
	uv pip install --python {{PYTHON_VENV}} --no-deps kimi-cli
	@echo "✓ Kimi installed"

# Install SimpleLLMRouter
_install-simplellmrouter:
	@echo "→ Installing SimpleLLMRouter..."
	#!/usr/bin/env zsh
	ROUTER_DIR="{{PROJECT_ROOT}}/../simplellmrouter"
	if [[ -d "$ROUTER_DIR" ]]; then
	uv pip install --python {{PYTHON_VENV}} -e "$ROUTER_DIR"
	echo "✓ SimpleLLMRouter installed from local source"
	else
	echo "⚠ SimpleLLMRouter source not found at $ROUTER_DIR — skipping (clone it to enable)"
	fi

# Create .env file if missing
_set-env:
	@echo "→ Creating .env file..."
	@test -f {{PROJECT_ROOT}}/.env || echo "# Meta Code Squad Environment\nROUTER_PORT={{ROUTER_PORT}}\nLETTA_PORT={{LETTA_PORT}}" > {{PROJECT_ROOT}}/.env
	@echo "✓ .env file ready"

# Start SimpleLLMRouter in background
_start-router:
	@echo "→ Starting SimpleLLMRouter on port {{ROUTER_PORT}}..."
	@lsof -ti:{{ROUTER_PORT}} | xargs kill -9 2>/dev/null || true
	nohup simplellmrouter --port {{ROUTER_PORT}} > /tmp/simplellmrouter.log 2>&1 &
	@sleep 2
	@curl -s http://localhost:{{ROUTER_PORT}}/health > /dev/null && echo "✓ SimpleLLMRouter running" || echo "✗ SimpleLLMRouter failed to start"

# Start Letta server in background
_start-letta:
	@echo "→ Starting Letta server on port {{LETTA_PORT}}..."
	@lsof -ti:{{LETTA_PORT}} | xargs kill -9 2>/dev/null || true
	nohup letta server --port {{LETTA_PORT}} > /tmp/letta.log 2>&1 &
	@sleep 3
	@curl -s http://localhost:{{LETTA_PORT}}/v1/health > /dev/null && echo "✓ Letta server running" || echo "✗ Letta server failed to start"

# Verify critical services are available
_check-services:
	@echo "→ Checking service availability..."
	@command -v simplellmrouter > /dev/null || (echo "ERROR: simplellmrouter not found — run: just _install-simplellmrouter" && exit 1)
	@command -v letta > /dev/null || (echo "ERROR: letta not found — run: just _install-letta" && exit 1)
	@echo "✓ Services available"

# Install git hooks
_install-git-hooks:
	@echo "→ Installing git hooks..."
	mkdir -p {{PROJECT_ROOT}}/.git/hooks
	echo '#!/usr/bin/env bash\njust _hook-pre-commit' > {{PROJECT_ROOT}}/.git/hooks/pre-commit
	chmod +x {{PROJECT_ROOT}}/.git/hooks/pre-commit
	@echo "✓ Git hooks installed"

# Hook: on session start
_hook-session-start:
	@echo "→ Running session start hook..."
	@echo "✓ Session started"

# Hook: on task dispatch
_hook-task-dispatch:
	@echo "→ Running task dispatch hook..."
	@echo "✓ Task dispatched"

# Hook: on edit
_hook-on-edit:
	@echo "→ Running on-edit hook..."
	@echo "✓ Edit recorded"

# Hook: on commit
_hook-on-commit:
	@echo "→ Running on-commit hook..."
	@echo "✓ Commit recorded"

# Hook: pre-commit
_hook-pre-commit:
	@echo "→ Running pre-commit checks..."
	just lint
	just test
	@echo "✓ Pre-commit checks passed"