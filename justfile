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
	@echo "\n┃┃┃ Meta Code Squad — Starting Dev Environment ┃┃┃\n"
	just doctor
	@echo "↓ Starting core services..."
	just start-router &
	just start-letta &
	@echo "\n✓ Environment live. Happy coding!\n"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# SECTION 3: INDIVIDUAL SERVICES
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Start SimpleLLMRouter on port 8080
start-router:
	@echo "↓ Starting SimpleLLMRouter on :{{ROUTER_PORT}}..."
	cd {{PROJECT_ROOT}}/packages/simplellmrouter && \
	  {{PYTHON_VENV}}/bin/python router.py

# Start Letta server on port 8283
start-letta:
	@echo "↓ Starting Letta on :{{LETTA_PORT}}..."
	{{PYTHON_VENV}}/bin/letta server --port {{LETTA_PORT}}

# Open Rufflo UI in browser
rufflo:
	@echo "↓ Opening Rufflo UI..."
	open http://localhost:3000

# Open iflow UI in browser
iflow:
	@echo "↓ Opening iflow UI..."
	open http://localhost:3001

# Open Sugar UI in browser
sugar:
	@echo "↓ Opening Sugar UI..."
	open http://localhost:3002

# ╔══════════════════════════════════════════════════════════════════════════════╗
# SECTION 4: INITIALIZATION (run after installing packages)
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Initialize Rufflo (run after npm install)
init-rufflo:
	@echo "↓ Initializing Rufflo..."
	cd {{PROJECT_ROOT}}/packages/rufflo && npm install
	@echo "✓ Rufflo ready"

# Initialize Letta (non-interactive)
init-letta:
	@echo "↓ Initializing Letta..."
	{{PYTHON_VENV}}/bin/letta configure --default || true
	@echo "✓ Letta configured"

# Initialize Sugar (run after npm install)
init-sugar:
	@echo "↓ Initializing Sugar..."
	cd {{PROJECT_ROOT}}/packages/sugar && npm install
	@echo "✓ Sugar ready"

# Initialize Loki (run after npm install)
init-loki:
	@echo "↓ Initializing Loki..."
	cd {{PROJECT_ROOT}}/packages/loki && npm install
	@echo "✓ Loki ready"

# Initialize monorepo root
init-monorepo:
	@echo "↓ Initializing monorepo root..."
	cd {{PROJECT_ROOT}} && npm install
	@echo "✓ Monorepo root ready"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# SECTION 5: HEALTH & DIAGNOSTICS
# ╚══════════════════════════════════════════════════════════════════════════════╝

# System health check
doctor:
	@echo "\n┃┃┃ Meta Code Squad — System Doctor ┃┃┃\n"
	@echo "→ Checking Python venv..."
	@test -d {{PYTHON_VENV}} && echo "  ✓ venv exists" || echo "  ✗ venv missing (run: just setup)"
	@echo "→ Checking Python packages..."
	@{{PYTHON_VENV}}/bin/uv pip list 2>/dev/null | grep -qi letta && echo "  ✓ letta installed" || echo "  ✗ letta missing (run: just _install-letta)"
	@echo "→ Checking SimpleLLMRouter..."
	@test -d {{PROJECT_ROOT}}/packages/simplellmrouter && echo "  ✓ simplellmrouter dir exists" || echo "  ✗ simplellmrouter missing — create packages/simplellmrouter"
	@echo "→ Checking Node packages..."
	@test -d {{PROJECT_ROOT}}/packages/rufflo/node_modules && echo "  ✓ rufflo deps installed" || echo "  ✗ rufflo deps missing (run: just init-rufflo)"
	@test -d {{PROJECT_ROOT}}/packages/sugar/node_modules && echo "  ✓ sugar deps installed" || echo "  ✗ sugar deps missing (run: just init-sugar)"
	@test -d {{PROJECT_ROOT}}/packages/loki/node_modules && echo "  ✓ loki deps installed" || echo "  ✗ loki deps missing (run: just init-loki)"
	@echo "→ Checking services..."
	@curl -s http://localhost:{{ROUTER_PORT}}/health > /dev/null && echo "  ✓ SimpleLLMRouter running" || echo "  ✗ SimpleLLMRouter not running (run: just start-router)"
	@curl -s http://localhost:{{LETTA_PORT}}/health > /dev/null && echo "  ✓ Letta running" || echo "  ✗ Letta not running (run: just start-letta)"
	@echo "\n✓ Doctor complete\n"

# Show current environment variables
env:
	@echo "PROJECT_ROOT: {{PROJECT_ROOT}}"
	@echo "PYTHON_VENV:  {{PYTHON_VENV}}"
	@echo "ROUTER_PORT:  {{ROUTER_PORT}}"
	@echo "LETTA_PORT:   {{LETTA_PORT}}"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# SECTION 6: MAINTENANCE & CLEANUP
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Clean all build artifacts and caches
clean:
	@echo "↓ Cleaning build artifacts..."
	find {{PROJECT_ROOT}} -type d -name "node_modules" -prune -exec rm -rf {} \;
	find {{PROJECT_ROOT}} -type d -name "__pycache__" -prune -exec rm -rf {} \;
	find {{PROJECT_ROOT}} -type d -name ".pytest_cache" -prune -exec rm -rf {} \;
	find {{PROJECT_ROOT}} -type d -name ".ruff_cache" -prune -exec rm -rf {} \;
	find {{PROJECT_ROOT}} -type f -name "*.pyc" -delete
	@echo "✓ Clean complete"

# Nuclear option: clean + remove venv
nuke:
	just clean
	@echo "↓ Removing Python venv..."
	rm -rf {{PYTHON_VENV}}
	@echo "✓ Nuked. Run 'just setup' to rebuild."

# ╔══════════════════════════════════════════════════════════════════════════════╗
# SECTION 7: PRIVATE HELPERS (prefixed with _)
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Check for required system tools
_check-prereqs:
	@echo "→ Checking prerequisites..."
	@command -v python3 >/dev/null 2>&1 || { echo "✗ python3 not found"; exit 1; }
	@command -v uv >/dev/null 2>&1 || { echo "✗ uv not found — install with: curl -LsSf https://astral.sh/uv/install.sh | sh"; exit 1; }
	@command -v npm >/dev/null 2>&1 || { echo "✗ npm not found"; exit 1; }
	@command -v git >/dev/null 2>&1 || { echo "✗ git not found"; exit 1; }
	@echo "✓ Prerequisites OK"

# Create Python virtual environment using uv
_create-venv:
	@echo "→ Creating Python venv..."
	@test -d {{PYTHON_VENV}} && echo "  ✓ Virtual environment exists" && exit 0 || true
	uv venv {{PYTHON_VENV}}
	@echo "✓ venv created"

# Install Letta via uv
_install-letta:
	@echo "→ Installing Letta..."
	uv pip install --python {{PYTHON_VENV}}/bin/python letta
	@echo "✓ Letta installed"

# Install SimpleLLMRouter from local package (packages/simplellmrouter must exist)
_install-simplellmrouter:
	@echo "→ Installing SimpleLLMRouter..."
	@test -d {{PROJECT_ROOT}}/packages/simplellmrouter || { echo "✗ packages/simplellmrouter not found — create it first"; exit 1; }
	uv pip install --python {{PYTHON_VENV}}/bin/python -e {{PROJECT_ROOT}}/packages/simplellmrouter
	@echo "✓ SimpleLLMRouter installed"

# Set up .env file
_set-env:
	@echo "→ Setting up .env..."
	test -f {{PROJECT_ROOT}}/.env || cp {{PROJECT_ROOT}}/.env.example {{PROJECT_ROOT}}/.env
	@echo "✓ .env ready"

# Install git hooks
_install-git-hooks:
	@echo "→ Installing git hooks..."
	mkdir -p {{PROJECT_ROOT}}/.git/hooks
	echo '#!/usr/bin/env zsh\njust _hook-pre-commit' > {{PROJECT_ROOT}}/.git/hooks/pre-commit
	chmod +x {{PROJECT_ROOT}}/.git/hooks/pre-commit
	@echo "✓ Git hooks installed"

# Hook: on session start
_hook-session-start:
	@echo "[HOOK] Session started"

# Hook: on task dispatch
_hook-task-dispatch:
	@echo "[HOOK] Task dispatched"

# Hook: on edit
_hook-on-edit:
	@echo "[HOOK] File edited"

# Hook: on commit
_hook-on-commit:
	@echo "[HOOK] Commit triggered"

# Hook: pre-commit
_hook-pre-commit:
	@echo "[HOOK] Running pre-commit checks..."
	{{PYTHON_VENV}}/bin/ruff check {{PROJECT_ROOT}}/packages
	@echo "[HOOK] Pre-commit complete"
