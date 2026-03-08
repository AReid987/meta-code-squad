# forge-quality

QA and linting toolchain for the Meta Code Squad monorepo.

## Overview

Shared quality tooling: Ruff, mypy, ESLint, Prettier configs, and pre-commit hooks.
Applied across all packages in the monorepo.

## Status

Scaffolded. Full implementation spec in docs/prd-aigency-dev-platform.md (Section 3).

## Quick Start

```bash
just lint
just typecheck
just format
```

## Tools

- **Python**: Ruff (lint + format), mypy (types)
- **JavaScript/TypeScript**: ESLint, Prettier
- **Pre-commit**: hooks for both ecosystems (via Lefthook)
- **Coverage**: Codecov integration via CI
- **Security**: gitleaks, detect-secrets, semgrep

## CLI Commands (planned)

| Command | Does |
|---------|------|
| `forge init` | Full 11-step setup |
| `forge commit` | Interactive conventional commit |
| `forge pr` | Generate PR description from commits |
| `forge check` | Run all quality checks without committing |
| `forge audit` | Full security audit |