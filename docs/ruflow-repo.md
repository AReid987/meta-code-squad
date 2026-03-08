Title: GitHub - ruvnet/ruflo: 🌊 The leading agent orchestration platform for Claude. Deploy intelligent multi-agent swarms, coordinate autonomous workflows, and build conversational AI systems. Features    enterprise-grade architecture, distributed swarm intelligence, RAG integration, and native Claude Code / Codex Integration

URL Source: https://github.com/ruvnet/ruflo

Markdown Content:
Skip to content
Navigation Menu
Platform
Solutions
Resources
Open Source
Enterprise
Pricing
Sign in
Sign up
ruvnet
/
ruflo
Public
Notifications
Fork 2.2k
 Star 19.3k
Code
Issues
419
Pull requests
13
Discussions
Actions
Projects
Wiki
Security
Insights
ruvnet/ruflo
 main
169 Branches
1453 Tags
Code
Folders and files
Name	Last commit message	Last commit date

Latest commit
ruvnet
fix: v3.5.5-v3.5.7 platform parity, branding, stdin timeout (#1301)
15664e0
 · 
History
5,956 Commits


.agents
	
Checkpoint: File edits
	


.claude-plugin
	
[release] v2.5.0-alpha.141 - SDK integration and settings updates
	


.claude
	
fix: v3.5.5-v3.5.7 platform parity, branding, stdin timeout (#1301)
	


.githooks
	
[feat] Complete agentic-flow integration with execution layer fixes
	


.github
	
Checkpoint: File edits
	


agents
	
Checkpoint: File edits
	


bin
	
feat: Ruflo v3.5.0 — first major stable release with full agentic-flo…
	


plugin
	
Fix init hook bugs: TOOL_INPUT_prompt overflow and description field (#…
	


ruflo
	
fix: v3.5.5-v3.5.7 platform parity, branding, stdin timeout (#1301)
	


scripts
	
feat(ADR-058): self-contained ruflo.rvf appliance with ruvLLM + verif…
	


tests
	
feat(ADR-057): RVF native storage with security hardening (#1244)
	


v2
	
Checkpoint: File edits
	


v3
	
fix: v3.5.5-v3.5.7 platform parity, branding, stdin timeout (#1301)
	


.gitignore
	
Checkpoint: File edits
	


.npmignore
	
Checkpoint: File edits
	


AGENTS.md
	
Checkpoint: File edits
	


CHANGELOG.md
	
feat: Ruflo v3.5.0 — first major stable release with full agentic-flo…
	


CLAUDE.local.md
	
Checkpoint: File edits
	


CLAUDE.md
	
feat: Ruflo v3.5.0 — first major stable release with full agentic-flo…
	


LICENSE
	
fix(memory): support namespace in delete command (#981)
	


README.md
	
release: v3.5.3 — publish fixes, branding, cleanup
	


package-lock.json
	
fix: v3.5.5-v3.5.7 platform parity, branding, stdin timeout (#1301)
	


package.json
	
fix: v3.5.5-v3.5.7 platform parity, branding, stdin timeout (#1301)
	


tsconfig.json
	
checkpoint: File edit:
	
Repository files navigation
README
MIT license
🌊 RuFlo v3.5: Enterprise AI Orchestration Platform

      

  

Production-ready multi-agent AI orchestration for Claude Code

Deploy 60+ specialized agents in coordinated swarms with self-learning capabilities, fault-tolerant consensus, and enterprise-grade security.

Why Ruflo? Claude Flow is now Ruflo — named by Ruv, who loves Rust, flow states, and building things that feel inevitable. The "Ru" is the Ruv. The "flo" is the flow. Underneath, WASM kernels written in Rust power the policy engine, embeddings, and proof system. 5,800 commits later, the alpha is over. This is v3.5.

Getting into the Flow

Ruflo is a comprehensive AI agent orchestration framework that transforms Claude Code into a powerful multi-agent development platform. It enables teams to deploy, coordinate, and optimize specialized AI agents working together on complex software engineering tasks.

Self-Learning/Self-Optimizing Agent Architecture
User → Ruflo (CLI/MCP) → Router → Swarm → Agents → Memory → LLM Providers
                       ↑                          ↓
                       └──── Learning Loop ←──────┘

📐 Expanded Architecture — Full system diagram with RuVector intelligence
Get Started Fast
# One-line install (recommended)
curl -fsSL https://cdn.jsdelivr.net/gh/ruvnet/claude-flow@main/scripts/install.sh | bash

# Or full setup with MCP + diagnostics
curl -fsSL https://cdn.jsdelivr.net/gh/ruvnet/claude-flow@main/scripts/install.sh | bash -s -- --full

# Or via npx
npx ruflo@latest init --wizard
Key Capabilities

🤖 60+ Specialized Agents - Ready-to-use AI agents for coding, code review, testing, security audits, documentation, and DevOps. Each agent is optimized for its specific role.

🐝 Coordinated Agent Teams - Run unlimited agents simultaneously in organized swarms. Agents spawn sub-workers, communicate, share context, and divide work automatically using hierarchical (queen/workers) or mesh (peer-to-peer) patterns.

🧠 Learns From Your Workflow - The system remembers what works. Successful patterns are stored and reused, routing similar tasks to the best-performing agents. Gets smarter over time.

🔌 Works With Any LLM - Switch between Claude, GPT, Gemini, Cohere, or local models like Llama. Automatic failover if one provider is unavailable. Smart routing picks the cheapest option that meets quality requirements.

⚡ Plugs Into Claude Code - Native integration via MCP (Model Context Protocol). Use ruflo commands directly in your Claude Code sessions with full tool access.

🔒 Production-Ready Security - Built-in protection against prompt injection, input validation, path traversal prevention, command injection blocking, and safe credential handling.

🧩 Extensible Plugin System - Add custom capabilities with the plugin SDK. Create workers, hooks, providers, and security modules. Share plugins via the decentralized IPFS marketplace.

A multi-purpose Agent Tool Kit
🔄 Core Flow — How requests move through the system
🐝 Swarm Coordination — How agents work together
🧠 Intelligence & Memory — How the system learns and remembers
⚡ Optimization — How to reduce cost and latency
🔧 Operations — Background services and integrations
🎯 Task Routing — Extend your Claude Code subscription by 250%
⚡ Agent Booster (WASM) — Skip LLM for simple code transforms
💰 Token Optimizer — 30-50% token reduction
🛡️ Anti-Drift Swarm Configuration — Prevent goal drift in multi-agent work
Claude Code: With vs Without Ruflo
Capability	Claude Code Alone	Claude Code + Ruflo
Agent Collaboration	Agents work in isolation, no shared context	Agents collaborate via swarms with shared memory and consensus
Coordination	Manual orchestration between tasks	Queen-led hierarchy with 5 consensus algorithms (Raft, Byzantine, Gossip)
Hive Mind	⛔ Not available	🐝 Queen-led swarms with collective intelligence, 3 queen types, 8 worker types
Consensus	⛔ No multi-agent decisions	Byzantine fault-tolerant voting (f < n/3), weighted, majority
Memory	Session-only, no persistence	HNSW vector memory with sub-ms retrieval + knowledge graph
Vector Database	⛔ No native support	🐘 RuVector PostgreSQL with 77+ SQL functions, ~61µs search, 16,400 QPS
Knowledge Graph	⛔ Flat insight lists	PageRank + community detection identifies influential insights (ADR-049)
Collective Memory	⛔ No shared knowledge	Shared knowledge base with LRU cache, SQLite persistence, 8 memory types
Learning	Static behavior, no adaptation	SONA self-learning with <0.05ms adaptation, LearningBridge for insights
Agent Scoping	Single project scope	3-scope agent memory (project/local/user) with cross-agent transfer
Task Routing	You decide which agent to use	Intelligent routing based on learned patterns (89% accuracy)
Complex Tasks	Manual breakdown required	Automatic decomposition across 5 domains (Security, Core, Integration, Support)
Background Workers	Nothing runs automatically	12 context-triggered workers auto-dispatch on file changes, patterns, sessions
LLM Provider	Anthropic only	6 providers with automatic failover and cost-based routing (85% savings)
Security	Standard protections	CVE-hardened with bcrypt, input validation, path traversal prevention
Performance	Baseline	Faster tasks via parallel swarm spawning and intelligent routing
Quick Start
Prerequisites
Node.js 20+ (required)
npm 9+ / pnpm / bun package manager

IMPORTANT: Claude Code must be installed first:

# 1. Install Claude Code globally
npm install -g @anthropic-ai/claude-code

# 2. (Optional) Skip permissions check for faster setup
claude --dangerously-skip-permissions
Installation
One-Line Install (Recommended)
# curl-style installer with progress display
curl -fsSL https://cdn.jsdelivr.net/gh/ruvnet/claude-flow@main/scripts/install.sh | bash

# Full setup (global + MCP + diagnostics)
curl -fsSL https://cdn.jsdelivr.net/gh/ruvnet/claude-flow@main/scripts/install.sh | bash -s -- --full
Install Options
npm/npx Install
# Quick start (no install needed)
npx ruflo@latest init

# Or install globally
npm install -g ruflo@latest
ruflo init

# With Bun (faster)
bunx ruflo@latest init
Install Profiles
Profile	Size	Use Case
--omit=optional	~45MB	Core CLI only (fastest)
Default	~340MB	Full install with ML/embeddings
# Minimal install (skip ML/embeddings)
npm install -g ruflo@latest --omit=optional
🤖 OpenAI Codex CLI Support — Full Codex integration with self-learning
Basic Usage
# Initialize project
npx ruflo@latest init

# Start MCP server for Claude Code integration
npx ruflo@latest mcp start

# Run a task with agents
npx ruflo@latest --agent coder --task "Implement user authentication"

# List available agents
npx ruflo@latest --list
Upgrading
# Update helpers and statusline (preserves your data)
npx ruflo@v3alpha init upgrade

# Update AND add any missing skills/agents/commands
npx ruflo@v3alpha init upgrade --add-missing

The --add-missing flag automatically detects and installs new skills, agents, and commands that were added in newer versions, without overwriting your existing customizations.

Claude Code MCP Integration

Add ruflo as an MCP server for seamless integration:

# Add ruflo MCP server to Claude Code
claude mcp add ruflo -- npx -y ruflo@latest mcp start

# Verify installation
claude mcp list

Once added, Claude Code can use all 175+ ruflo MCP tools directly:

swarm_init - Initialize agent swarms
agent_spawn - Spawn specialized agents
memory_search - Search patterns with HNSW vector search
hooks_route - Intelligent task routing
And 170+ more tools...
What is it exactly? Agents that learn, build and work perpetually.
🆚 Why Ruflo v3?
🚀 Key Differentiators — Self-learning, memory optimization, fault tolerance
💰 Intelligent 3-Tier Model Routing — Save 75% on API costs, extend Claude Max 2.5x
📋 Spec-Driven Development — Build complete specs, implement without drift
🏗️ Architecture Diagrams
📊 System Overview — High-level architecture
🔄 Request Flow — How tasks are processed
🧠 Memory Architecture — How knowledge is stored, learned, and retrieved
🧠 AgentDB v3 Controllers — 20+ intelligent memory controllers
🐝 Swarm Topology — Multi-agent coordination patterns
🔒 Security Layer — Threat detection and prevention
🔌 Setup & Configuration

Connect Ruflo to your development environment.

🔌 MCP Setup — Connect Ruflo to Any AI Environment
🛡️ @claude-flow/guidance — Long-horizon governance control plane for Claude Code agents
📦 Core Features

Comprehensive capabilities for enterprise-grade AI agent orchestration.

📦 Features — 60+ Agents, Swarm Topologies, MCP Tools & Security
🎯 Use Cases & Workflows

Real-world scenarios and pre-built workflows for common tasks.

🎯 Use Cases — Real-world scenarios and how to solve them
🧠 Infinite Context & Memory Optimization

Ruflo eliminates Claude Code's context window ceiling with a real-time memory management system that archives, optimizes, and restores conversation context automatically.

♾️ Context Autopilot — Never lose context to compaction again
💾 Storage: RVF (RuVector Format)

Ruflo uses RVF — a compact binary storage format that replaces the 18MB sql.js WASM dependency with pure TypeScript. No native compilation, no WASM downloads, works everywhere Node.js runs.

💾 RVF Storage — Binary format, vector search, migration, and auto-selection
🧠 Intelligence & Learning

Self-learning hooks, pattern recognition, and intelligent task routing.

🪝 Hooks, Event Hooks, Workers & Pattern Intelligence
📦 Pattern Store & Export — Share Patterns, Import Config
🛠️ Development Tools

Scripts, coordination systems, and collaborative development features.

🛠️ Helper Scripts — 30+ Development Automation Tools
🎓 Skills System — 42 Pre-Built Workflows for Any Task
🎫 Claims & Work Coordination — Human-Agent Task Management
🧭 Intelligent Routing — Q-Learning Task Assignment
💻 Programmatic Usage

Use Ruflo packages directly in your applications.

💻 Programmatic SDK — Use Ruflo in Your Code
🔗 Ecosystem & Integrations

Core infrastructure packages powering Ruflo's intelligence layer.

⚡ Agentic-Flow Integration — Core AI Infrastructure
🥋 Agentic-Jujutsu — Self-Learning AI Version Control
🦀 RuVector — High-Performance Rust/WASM Intelligence
☁️ Cloud & Deployment

Cloud platform integration and deployment tools.

☁️ Flow Nexus — Cloud Platform Integration
🔗 Stream-Chain — Multi-Agent Pipelines
👥 Pair Programming — Collaborative AI Development
🛡️ Security

AI manipulation defense, threat detection, and input validation.

🛡️ AIDefence Security — Threat Detection, PII Scanning
🏗️ Architecture & Modules

Domain-driven design, performance benchmarks, and testing framework.

🏗️ Architecture — DDD Modules, Topology Benchmarks & Metrics
🌐 Browser Automation — @claude-flow/browser
📦 Release Management — @claude-flow/deployment
📊 Performance Benchmarking — @claude-flow/performance
🧪 Testing Framework — @claude-flow/testing
⚙️ Configuration & Reference

Environment setup, configuration options, and platform support.

💻 Cross-Platform Support
⚙️ Environment Variables
📄 Configuration Reference
📖 Help & Resources

Troubleshooting, migration guides, and documentation links.

🔧 Troubleshooting
🔄 Migration Guide (V2 → V3)
📚 Documentation
Support
Resource	Link
📚 Documentation	github.com/ruvnet/claude-flow
🐛 Issues & Bugs	github.com/ruvnet/claude-flow/issues
💼 Professional Implementation	ruv.io — Enterprise consulting, custom integrations, and production deployment
💬 Discord Community	Agentics Foundation
License

MIT - RuvNet

  

About

🌊 The leading agent orchestration platform for Claude. Deploy intelligent multi-agent swarms, coordinate autonomous workflows, and build conversational AI systems. Features enterprise-grade architecture, distributed swarm intelligence, RAG integration, and native Claude Code / Codex Integration

Cognitum.One
Topics
multi-agent swarm agents codex multi-agent-systems autonomous-agents swarm-intelligence huggingface ai-assistant ai-tools anthropic-claude agentic-framework agentic-workflow agentic-rag agentic-ai model-context-protocol mcp-server claude-code agentic-engineering claude-code-skills
Resources
 Readme
License
 MIT license
 Activity
Stars
 19.3k stars
Watchers
 204 watching
Forks
 2.2k forks
Report repository


Releases 1,460
v3.5.14 — Security Fixes + Cross-Platform Windows Hooks
Latest
+ 1,459 releases


Packages
No packages published



Contributors
12


Languages
TypeScript
63.8%
 
JavaScript
22.8%
 
Python
8.5%
 
Shell
3.0%
 
Svelte
1.0%
 
Rust
0.4%
 
Other
0.5%
Footer
© 2026 GitHub, Inc.
Footer navigation
Terms
Privacy
Security
Status
Community
Docs
Contact
Manage cookies
Do not share my personal information
