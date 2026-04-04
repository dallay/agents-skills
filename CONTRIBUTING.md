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

Every `SKILL.md` file MUST begin with YAML frontmatter followed by Markdown instructions.

### Minimal Example

```markdown
---
name: docker-expert
description: >
  Advanced Docker containerization guidance for multi-stage builds, image
  hardening, and Compose workflows. Use when working with `Dockerfile`,
  `docker-compose.yml`, containerization, or image optimization.
---

## When to Use

- Creating or reviewing a `Dockerfile`
- Hardening a container image
- Troubleshooting Compose setup
```

### Example With Optional Fields

```markdown
---
name: pdf-processing
description: >
  Extract PDF text, fill forms, and merge files. Use when handling PDFs,
  document extraction, or PDF form workflows.
license: Apache-2.0
metadata:
  author: example-org
  version: "1.0"
---
```

### Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | **Yes** | Kebab-case identifier. Must match the directory name exactly. |
| `description` | **Yes** | What the skill does and when to use it. Put activation cues here. |
| `license` | No | License name or reference to a bundled license file. |
| `compatibility` | No | Environment requirements, if the skill has any. |
| `metadata` | No | Additional string metadata such as author or version. |
| `allowed-tools` | No | Space-delimited list of pre-approved tools. Experimental. |

Do not add non-standard top-level fields such as `version` or `triggers`. If you want version metadata, put it under `metadata`. If you want to describe activation cues, include them directly in `description`.

### Validation Rules

- `name` MUST be kebab-case (lowercase letters, numbers, and hyphens only)
- `name` MUST match the parent directory name exactly
- `name` MUST NOT contain path separators, dots, or special characters
- `name` MUST NOT start or end with a hyphen or contain consecutive hyphens
- `description` MUST be non-empty and describe both the capability and when to use it
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

2. **Strong description** — The `description` should carry the activation cues. Be specific about user intent and nearby phrases, without making the skill so broad that it activates everywhere.

3. **Focused instructions** — Keep `SKILL.md` concise and action-oriented. Prefer the core workflow, defaults, and gotchas over long background material.

4. **Well-structured Markdown** — Use headings, lists, code blocks, and tables to organize content. Make it scannable.

5. **Progressive disclosure** — Keep the main `SKILL.md` under 500 lines when possible. Move detailed reference material to `references/`, `assets/`, or `scripts/`, and tell the agent when to load those files.

6. **No sensitive data** — Do not include API keys, credentials, personal information, or proprietary code in skill content.

7. **Accurate information** — Technical guidance must be correct and up-to-date. Cite sources when referencing specific standards (e.g., WCAG 2.1).

## Testing Locally

Before submitting, test your skill to ensure it works correctly:

### 1. Validate the skill structure

Use the reference validator:

```bash
skills-ref validate skills/your-skill-name
```

If you do not have `skills-ref` installed yet, this repository can bootstrap a pinned local copy for you:

```bash
./scripts/install-skills-ref.sh
```

Verify:
- `name` matches the directory name
- `description` is present and includes activation cues
- Optional fields use official top-level names
- Content after frontmatter is substantive

### 2. Install locally with AgentSync

```bash
# Install from your local clone
agentsync skill install your-skill-name --source /path/to/your/agents-skills/clone

# Or symlink for quick iteration
ln -s /path/to/agents-skills/skills/your-skill-name ~/.config/opencode/skills/your-skill-name
```

### 3. Verify the skill activates

Open your AI coding assistant and test that the skill:
- Activates when prompts match the cues in `description`
- Provides relevant and accurate guidance
- Does not activate in unrelated contexts

### 4. Check CI validation passes

The CI pipeline will run the same validation on your PR. You can run it locally:

```bash
./scripts/validate-skills.sh
```

### 5. Install local hooks

Use Lefthook to catch issues before pushing:

```bash
brew install lefthook
lefthook install
```

## Submitting a Pull Request

### What reviewers look for

1. **Valid manifest** — Frontmatter is well-formed with all required fields
2. **Name consistency** — Directory name matches the `name` field in frontmatter
3. **Content quality** — Instructions are substantive, accurate, and well-organized
4. **Description quality** — `description` clearly communicates both the capability and when the skill should activate
5. **No conflicts** — Skill does not duplicate an existing skill's purpose
6. **Clean PR** — One skill per PR (unless related), clear description

### PR title format

Use conventional commit format:

- `feat: add terraform skill` — for new skills
- `fix: refine docker-expert description` — for skill fixes
- `docs: improve contributing guide` — for documentation changes

## PR Checklist

Before submitting, confirm:

- [ ] Skill directory is under `skills/` with a kebab-case name
- [ ] `SKILL.md` has valid YAML frontmatter with official fields only
- [ ] `name` in frontmatter matches the directory name exactly
- [ ] `description` is a clear summary of what the skill does and when to use it
- [ ] Content after frontmatter is substantive (not placeholder text)
- [ ] Main `SKILL.md` stays concise; detailed material is moved to referenced files when needed
- [ ] `skills-ref validate skills/your-skill-name` passes
- [ ] Tested locally — skill installs and activates correctly
- [ ] No sensitive data (API keys, credentials, personal info)
- [ ] No duplicate of an existing skill's purpose
