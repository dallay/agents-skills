# Agent Skills

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

> Curated AI agent skills for [AgentSync](https://github.com/dallay/agentsync) — install, contribute, and manage reusable skills for your AI coding assistants.

## What Is This?

This repository is the canonical home for all dallay-maintained AI agent skills. Each skill is a self-contained set of instructions that enhances your AI coding assistant (Claude, Copilot, Cursor, Gemini, and more) with specialized knowledge for specific tasks.

Skills are installed and managed via the [AgentSync CLI](https://github.com/dallay/agentsync).

## Quick Install

```bash
# Install a skill using AgentSync
agentsync skill install <skill-name>

# Example: install the Docker expert skill
agentsync skill install docker-expert

# See available skills for your project
agentsync skill suggest
```

## Available Skills

| Skill | Description |
|-------|-------------|
| [accessibility](skills/accessibility/) | WCAG 2.1 audit and improvement guidelines |
| [best-practices](skills/best-practices/) | Modern web development best practices |
| [brainstorming](skills/brainstorming/) | Explore intent, requirements and design before implementation |
| [core-web-vitals](skills/core-web-vitals/) | Optimize LCP, INP, CLS for better page experience |
| [docker-expert](skills/docker-expert/) | Multi-stage builds, image optimization, security hardening |
| [frontend-design](skills/frontend-design/) | Production-grade frontend interfaces with high design quality |
| [github-actions](skills/github-actions/) | Robust CI/CD pipelines with GitHub Actions |
| [grafana-dashboards](skills/grafana-dashboards/) | Production Grafana dashboards for system metrics |
| [makefile](skills/makefile/) | Clean, maintainable GNU Make Makefiles |
| [markdown-a11y](skills/markdown-a11y/) | Markdown accessibility review guidelines |
| [performance](skills/performance/) | Web performance optimization |
| [pinned-tag](skills/pinned-tag/) | Pin GitHub Actions to commit SHAs for security |
| [pr-creator](skills/pr-creator/) | Create PRs following repo templates and standards |
| [rust-async-patterns](skills/rust-async-patterns/) | Async Rust with Tokio, error handling, concurrency |
| [seo](skills/seo/) | Search engine visibility and ranking optimization |
| [skill-creator](skills/skill-creator/) | Create new AI agent skills |
| [sql-optimization-patterns](skills/sql-optimization-patterns/) | SQL query optimization and indexing strategies |
| [web-quality-audit](skills/web-quality-audit/) | Comprehensive web quality audit |
| [webapp-testing](skills/webapp-testing/) | Test web applications using Playwright |

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to submit new skills.

## How It Works

Each skill lives in its own directory under `skills/`:

```
skills/
└── docker-expert/
    └── SKILL.md          # Manifest (frontmatter) + instructions
```

When you run `agentsync skill install docker-expert`, the CLI downloads and installs the skill directly from this repository — no search API needed.

## Contributing

We welcome community contributions! Whether you want to improve an existing skill or create a new one, check out our [Contributing Guide](CONTRIBUTING.md) for:

- How to create a new skill
- SKILL.md manifest format
- Naming conventions and quality expectations
- How to test locally before submitting

## Related

- [AgentSync CLI](https://github.com/dallay/agentsync) — the CLI that installs and manages skills
- [AgentSync Documentation](https://agentsync.dev) — full documentation

## License

[MIT](LICENSE) © 2026 dallay
