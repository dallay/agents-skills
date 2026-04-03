# Contributing to Agent Skills

Thank you for your interest in contributing! This guide explains how to create, test, and submit AI agent skills to this repository.

## Table of Contents

- [Creating a New Skill](#creating-a-new-skill)
- [SKILL.md Manifest Format](#skillmd-manifest-format)
- [Naming Conventions](#naming-conventions)
- [Quality Expectations](#quality-expectations)
- [Testing Locally](#testing-locally)
- [Submitting a Pull Request](#submitting-a-pull-request)
- [PR Checklist](#pr-checklist)

## Creating a New Skill

Each skill is a directory under `skills/` containing at minimum a `SKILL.md` file:

```
skills/
└── your-skill-name/
    ├── SKILL.md              # Required: manifest + instructions
    └── ... (optional files)  # Templates, scripts, reference materials
```

### Steps

1. Fork this repository
2. Create a new directory: `skills/your-skill-name/`
3. Add a `SKILL.md` file with valid frontmatter and instructions
4. Test the skill locally (see [Testing Locally](#testing-locally))
5. Open a pull request

## SKILL.md Manifest Format

Every `SKILL.md` file MUST begin with YAML frontmatter followed by the skill instructions in Markdown.

### Full Example

```markdown
---
name: docker-expert
version: 1.0.0
description: >
  Advanced Docker containerization expert for multi-stage builds, image
  optimization, security hardening, and Compose orchestration.
triggers:
  - "When working with Dockerfile"
  - "When working with docker-compose.yml"
  - "containerization"
  - "multi-stage builds"
  - "optimizing Docker images"
---

# Docker Expert

## Purpose

You are an advanced Docker containerization expert...

## Guidelines

1. Always use multi-stage builds for production images
2. Pin base image versions with SHA digests
3. ...

## Examples

### Multi-stage Build

\`\`\`dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --production
...
\`\`\`
```

### Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | **Yes** | Kebab-case identifier. **Must match the directory name exactly.** |
| `version` | No | Semver format (e.g., `1.0.0`). Defaults to `1.0.0` if omitted. |
| `description` | **Yes** | Short description of what the skill does. One or two sentences. |
| `triggers` | **Yes** | List of phrases that indicate when this skill should be activated. Must be a non-empty array. |

### Validation Rules

- `name` MUST be kebab-case (lowercase letters, numbers, and hyphens only)
- `name` MUST match the parent directory name exactly
- `name` MUST NOT contain path separators, dots, or special characters
- `version`, if present, MUST be valid semver
- `description` MUST be non-empty
- `triggers` MUST be a non-empty array of strings
- Content after frontmatter MUST be non-empty and substantive

## Naming Conventions

Skill names follow these conventions:

- **Format:** `kebab-case` — lowercase letters, numbers, and hyphens only
- **Descriptive:** The name should clearly indicate what the skill covers
- **Technology-specific:** Include the technology or domain name when applicable

### Good Examples

| Name | Why It Works |
|------|-------------|
| `docker-expert` | Technology + expertise level |
| `github-actions` | Specific technology |
| `rust-async-patterns` | Language + specific topic |
| `sql-optimization-patterns` | Domain + specific focus |
| `core-web-vitals` | Well-known industry term |

### Avoid

| Name | Issue |
|------|-------|
| `docker` | Too generic |
| `my-awesome-skill` | Not descriptive |
| `Docker_Expert` | Wrong case (use kebab-case) |
| `skill.docker` | No dots allowed |

## Quality Expectations

Every skill submitted to this repository must meet these standards:

1. **Useful content** — The skill must provide actionable instructions that genuinely help an AI agent perform a specific task better. No placeholder text or vague guidance.

2. **Proper triggers** — Trigger phrases must be specific enough to activate the skill in the right context, without being so broad they activate inappropriately.

3. **Complete instructions** — The skill should cover the topic thoroughly. Include guidelines, best practices, examples, and common pitfalls.

4. **Well-structured Markdown** — Use headings, lists, code blocks, and tables to organize content. Make it scannable.

5. **No sensitive data** — Do not include API keys, credentials, personal information, or proprietary code in skill content.

6. **Accurate information** — Technical guidance must be correct and up-to-date. Cite sources when referencing specific standards (e.g., WCAG 2.1).

## Testing Locally

Before submitting, test your skill to ensure it works correctly:

### 1. Validate the manifest structure

Check that your `SKILL.md` starts with valid YAML frontmatter:

```bash
# Quick check: frontmatter exists and parses
head -20 skills/your-skill-name/SKILL.md
```

Verify:
- First line is `---`
- Frontmatter closes with another `---`
- `name` matches directory name
- `description` and `triggers` are present and non-empty

### 2. Install locally with AgentSync

```bash
# Install from your local clone
agentsync skill install your-skill-name --source /path/to/your/agents-skills/clone

# Or symlink for quick iteration
ln -s /path/to/agents-skills/skills/your-skill-name ~/.config/opencode/skills/your-skill-name
```

### 3. Verify the skill activates

Open your AI coding assistant and test that the skill:
- Activates when you use one of the trigger phrases
- Provides relevant and accurate guidance
- Does not activate in unrelated contexts

### 4. Check CI validation passes

The CI pipeline will run the same validation on your PR. You can run it locally:

```bash
# Check frontmatter exists
head -1 skills/your-skill-name/SKILL.md | grep -q '^---$'

# Check name matches directory
grep '^name:' skills/your-skill-name/SKILL.md
```

## Submitting a Pull Request

### What reviewers look for

1. **Valid manifest** — Frontmatter is well-formed with all required fields
2. **Name consistency** — Directory name matches the `name` field in frontmatter
3. **Content quality** — Instructions are substantive, accurate, and well-organized
4. **Trigger relevance** — Triggers are specific and appropriate for the skill's domain
5. **No conflicts** — Skill does not duplicate an existing skill's purpose
6. **Clean PR** — One skill per PR (unless related), clear description

### PR title format

Use conventional commit format:

- `feat: add terraform skill` — for new skills
- `fix: update docker-expert triggers` — for skill fixes
- `docs: improve contributing guide` — for documentation changes

## PR Checklist

Before submitting, confirm:

- [ ] Skill directory is under `skills/` with a kebab-case name
- [ ] `SKILL.md` has valid YAML frontmatter (name, description, triggers)
- [ ] `name` in frontmatter matches the directory name exactly
- [ ] `description` is a clear, non-empty summary
- [ ] `triggers` is a non-empty array with specific activation phrases
- [ ] Content after frontmatter is substantive (not placeholder text)
- [ ] Tested locally — skill installs and activates correctly
- [ ] No sensitive data (API keys, credentials, personal info)
- [ ] No duplicate of an existing skill's purpose
