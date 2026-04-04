---
name: {skill-name}
description: >
  {Brief description of what this skill enables}. Use when {user intent,
  nearby phrases, or task context that should activate the skill}.
license: Apache-2.0
metadata:
  author: {author}
  version: "1.0"
---

> **REPLACE PLACEHOLDERS:** Replace every `{...}` token in this template before submission. PRs containing unreplaced placeholders will be rejected.

# {Skill Name}

## When to Use

Use this skill when:

- {Condition 1}
- {Condition 2}
- {Condition 3}

---

## Critical Patterns

{The MOST important rules - what AI MUST follow}

### Pattern 1: {Name}

```{language}
{code example}
```

### Pattern 2: {Name}

```{language}
{code example}
```

## Code Examples

> **REPLACE PLACEHOLDERS:** Update every remaining `{...}` token in headings, examples, and resource text before you submit the skill.

### Example 1: {Description}

```{language}
{minimal, focused example}
```

### Example 2: {Description}

```{language}
{minimal, focused example}
```

## Resources

- **Templates**: See [assets/](assets/) for {description of templates}
- **Documentation**: See [references/](references/) for local developer guide links

<!--
Notes:
- Use only official top-level fields in frontmatter.
- Put activation cues in `description`; do not add a separate `triggers` field.
- Remove optional fields you do not need, such as `license` or `metadata`.
- `SKILL.md` must be 500 lines or fewer; move detailed material to referenced files.
- Validate with: ./scripts/validate-skills.sh
-->
