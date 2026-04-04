---
name: skill-creator
description: >-
  Create or update Agent Skills that follow the official specification and repository
  guidance. Use when creating a new skill, refining an existing skill, or documenting
  reusable AI workflows and instructions.
license: MIT
---
# Skill Creator Guide

This guide covers when to create a skill, how to structure it, and how to keep it aligned with the official Agent Skills specification.

## When to Create a Skill

Create a skill when:

- A pattern is used repeatedly and AI needs guidance
- Project-specific conventions differ from generic best practices
- Complex workflows need step-by-step instructions
- Decision trees help AI choose the right approach

**Don't create a skill when:**

- Documentation already exists (create a reference instead)
- Pattern is trivial or self-explanatory
- It's a one-off task

---

## Skill Structure

```text
skills/{skill-name}/
├── SKILL.md              # Required - main skill file
├── assets/               # Optional - templates, schemas, examples
│   ├── template.py
│   └── schema.json
└── references/           # Optional - links to local docs
    └── docs.md           # Points to docs/developer-guide/*.mdx
```

---

## SKILL.md Template

```markdown
---
name: {skill-name}
description: >
  {What the skill does}. Use when {user intent, nearby cues, or task context}.
license: Apache-2.0
metadata:
  author: generic-author
  version: "1.0"
---

## When to Use

{Bullet points of when to use this skill}

## Critical Patterns

{The most important rules - what AI MUST know}

## Examples

{Minimal, focused examples or workflows}

## Resources

- **Templates**: See [assets/](assets/) for {description}
- **Documentation**: See [references/](references/) for local docs

```

---

## Naming Conventions

| Type | Pattern | Examples |
|------|---------|----------|
| Generic skill | `{technology}` | `pytest`, `playwright`, `typescript` |
| Repo-specific | `{repo}-{component}` | `repo-api`, `repo-ui`, `repo-sdk-check` |
| Testing skill | `test-{component}` | `test-sdk`, `test-api` |
| Workflow skill | `{action}-{target}` | `skill-creator`, `jira-task` |

---

## Decision: assets/ vs references/

```

Need code templates?        → assets/
Need JSON schemas?          → assets/
Need example configs?       → assets/
Link to existing docs?      → references/
Link to external guides?    → references/ (with local path)

```

**Key Rule**: `references/` should point to LOCAL files (`docs/developer-guide/*.mdx`), not web URLs.

---

## Decision: Repo-Specific vs Generic

```

Patterns apply to ANY project?     → Generic skill (e.g., pytest, typescript)
Patterns are repo-specific?        → {repo}-{name} skill
Generic skill needs repo info?     → Add references/ pointing to repo docs

```

---

## Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Skill identifier (lowercase, hyphens) |
| `description` | Yes | What the skill does and when it should activate |
| `license` | No | Recommended when you want to declare reuse terms |
| `compatibility` | No | Environment requirements, only when needed |
| `metadata` | No | Additional string metadata such as author or version |
| `allowed-tools` | No | Experimental pre-approved tool list |

Do not add top-level `version` or `triggers`. Put activation cues in `description`. Put extra metadata, including versions, under `metadata`.

Only include `compatibility`, `metadata`, `license`, or `allowed-tools` when they add real value.

---

## Content Guidelines

### DO

- Start with the most critical patterns
- Keep code examples minimal and focused
- Keep the main `SKILL.md` at 500 lines or fewer
- Use `references/`, `assets/`, or `scripts/` for detail the agent only needs on demand
- Tell the agent when to read an extra file instead of dumping everything into `SKILL.md`

### DON'T

- Add Keywords section (agent searches frontmatter, not body)
- Duplicate content from existing docs (reference instead)
- Include lengthy explanations the agent already knows
- Add non-standard top-level manifest fields
- Use web URLs in references (use local paths)

## Validation

Validate each new skill before opening a PR:

```bash
./scripts/validate-skills.sh
```

Use the shared validator for frontmatter, naming rules, and repo-specific checks. Then do a quick manual check to confirm the description activates in the right situations.

---

## Registering the Skill

After creating the skill, add it to `AGENTS.md`:

```markdown
| `{skill-name}` | {Description} | [SKILL.md](skills/{skill-name}/SKILL.md) |
```

---

## Checklist Before Creating

- [ ] Skill doesn't already exist (check `skills/`)
- [ ] Pattern is reusable (not one-off)
- [ ] Name follows conventions
- [ ] Frontmatter uses official top-level fields only
- [ ] Description explains both capability and activation cues
- [ ] Critical patterns are clear
- [ ] Code examples are minimal
- [ ] Main `SKILL.md` stays concise; detail moves to other files when needed
- [ ] `./scripts/validate-skills.sh` passes
- [ ] Added to AGENTS.md

## Resources - Assets and References

- **Templates**: See [assets/](assets/) for SKILL.md template
