---
name: prettier-formatting
description: >-
  Prettier code formatting setup, configuration, editor integration, ESLint coordination,
  and pre-commit hook automation for consistent codebases. Use when the task involves
  `Prettier`, `code formatting`, `.prettierrc`, `Prettier configuration`, or
  `auto-formatting`.
license: MIT
metadata:
  version: "1.0.0"
---
## When to Use

- Setting up Prettier in a new or existing project for consistent formatting.
- Configuring `.prettierrc` options to match team style preferences.
- Integrating Prettier with ESLint without rule conflicts.
- Adding format-on-save in VS Code, JetBrains, or other editors.
- Setting up pre-commit hooks to enforce formatting before code is committed.
- Adding file-type-specific overrides (e.g., different `printWidth` for Markdown vs TypeScript).

## Critical Patterns

- **Prettier Decides, You Don't Argue:** Prettier is intentionally opinionated. Configure only the options it exposes — do NOT fight its AST-based formatting decisions with hacks.
- **ESLint Separation:** Use `eslint-config-prettier` to disable ESLint formatting rules. Do NOT use `eslint-plugin-prettier` — it's slow and mixes concerns. Run Prettier and ESLint as separate steps.
- **Ignore Correctly:** Always create `.prettierignore` to skip generated files, build output, and lock files. Prettier reads `.gitignore` by default, but explicit ignores prevent accidents.
- **Pin the Version:** Lock the Prettier version in `package.json` to avoid formatting churn across developer machines and CI.
- **Format All or Nothing:** When adding Prettier to an existing project, do one full format commit. Never mix formatting changes with logic changes in the same commit.
- **Pre-Commit Enforcement:** Use `lint-staged` + `husky` (or `lefthook`) to format only staged files. Running Prettier on the entire repo per commit is wasteful.

## Code Examples

### Configuration (.prettierrc.json)

```json
{
  "printWidth": 100,
  "tabWidth": 2,
  "useTabs": false,
  "semi": true,
  "singleQuote": true,
  "trailingComma": "all",
  "bracketSpacing": true,
  "arrowParens": "always",
  "endOfLine": "lf",
  "proseWrap": "preserve",
  "htmlWhitespaceSensitivity": "css",
  "singleAttributePerLine": false
}
```

### File-Type Overrides

```json
{
  "printWidth": 100,
  "singleQuote": true,
  "trailingComma": "all",
  "overrides": [
    {
      "files": "*.md",
      "options": {
        "printWidth": 80,
        "proseWrap": "always"
      }
    },
    {
      "files": ["*.json", "*.jsonc"],
      "options": {
        "tabWidth": 2,
        "trailingComma": "none"
      }
    },
    {
      "files": "*.yaml",
      "options": {
        "tabWidth": 2,
        "singleQuote": false
      }
    }
  ]
}
```

### .prettierignore

```gitignore
# Build output
dist/
build/
.next/
out/

# Dependencies
node_modules/

# Lock files (formatting breaks checksums)
pnpm-lock.yaml
package-lock.json
yarn.lock

# Generated
coverage/
*.generated.*
*.min.js
*.min.css

# Assets
*.svg
*.png
*.ico
```

### ESLint Integration (Conflict-Free)

```bash
# Install only the config disabler — NOT the plugin
npm install -D eslint-config-prettier
```

```js
// eslint.config.js
import prettier from "eslint-config-prettier";

export default [
  // ... your other configs
  prettier, // MUST be last — disables ESLint rules that conflict with Prettier
];
```

### Pre-Commit Hook with lint-staged

```json
// package.json
{
  "lint-staged": {
    "*.{js,ts,tsx,jsx,json,css,md,yaml}": "prettier --write"
  }
}
```

```bash
# Setup with Husky
npm install -D husky lint-staged
npx husky init
echo "npx lint-staged" > .husky/pre-commit
```

```yaml
# Or with Lefthook (lefthook.yml)
pre-commit:
  commands:
    prettier:
      glob: "*.{js,ts,tsx,jsx,json,css,md,yaml}"
      run: npx prettier --write {staged_files} && git add {staged_files}
```

### VS Code Settings

```jsonc
// .vscode/settings.json
{
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.formatOnSave": true,
  "[markdown]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[json]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  }
}
```

## Commands

```bash
# Format all files
npx prettier --write .

# Check without writing (for CI)
npx prettier --check .

# Format specific file types
npx prettier --write "src/**/*.{ts,tsx}"

# Show what would change
npx prettier --list-different .

# Debug: show resolved config for a file
npx prettier --find-config-path src/index.ts

# Debug: show which parser Prettier uses
npx prettier --file-info src/index.ts
```

## Best Practices

### DO

- Create a `.prettierrc.json` (or `.prettierrc`) at the project root — explicit config prevents editor-level settings from causing inconsistency.
- Run `prettier --check .` in CI to catch unformatted code before merge.
- Use `overrides` for file types that need different settings (Markdown prose, YAML indentation).
- Add `.vscode/settings.json` with `formatOnSave: true` to the repo so all contributors get it.
- Do one big "format the world" commit when onboarding Prettier, then enforce from that point.

### DON'T

- Don't install `eslint-plugin-prettier` — it runs Prettier inside ESLint, doubling execution time and mixing formatting with linting concerns.
- Don't format lock files (`pnpm-lock.yaml`, `package-lock.json`) — it breaks integrity checksums.
- Don't customize every option — Prettier's defaults are battle-tested. Only change what your team truly needs.
- Don't skip `.prettierignore` — without it, Prettier will try to format generated files, SVGs, and build output, causing noise and errors.
- Don't mix formatting changes with logic changes in pull requests — reviewers can't distinguish what actually changed.
