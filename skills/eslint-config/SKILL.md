---
name: eslint-config
description: >-
  ESLint configuration expert for flat config setup, custom rules, TypeScript integration,
  plugin management, and migration from legacy .eslintrc to modern eslint.config.js. Use when
  the task involves `ESLint`, `eslint.config`, `linting JavaScript`, `TypeScript linting`, or
  `ESLint rules`.
license: MIT
metadata:
  version: "1.0.0"
---

## When to Use

- Setting up ESLint from scratch using the modern flat config format (`eslint.config.js`).
- Migrating a project from legacy `.eslintrc.*` to flat config.
- Configuring TypeScript-ESLint for strict type-checked linting.
- Writing custom ESLint rules or shareable config packages.
- Resolving rule conflicts between ESLint, Prettier, and framework-specific plugins.
- Optimizing linting performance for large monorepos.

## Critical Patterns

- **Flat Config Only:** Always use `eslint.config.js` (or `.mjs`/`.mts`). The legacy `.eslintrc.*`
  format is deprecated since ESLint v9. Do NOT create new projects with `.eslintrc`.
- **Explicit Over Implicit:** Flat config has no implicit inheritance. Every config object in the
  array is applied in order — later entries override earlier ones.
- **TypeScript Requires Parser:** Always pair `@typescript-eslint/parser` with
  `@typescript-eslint/eslint-plugin`. Use type-checked rules (`strictTypeChecked`) for maximum
  safety.
- **Severity Consistency:** Use `"error"` for rules that must block CI, `"warn"` for progressive
  adoption, and `"off"` to explicitly disable inherited rules. Never leave rules ambiguous.
- **Ignore via Config:** Use the `ignores` property in flat config instead of `.eslintignore` files.
  Global ignores go in a config object with *only* the `ignores` key.
- **Plugin Namespacing:** In flat config, plugins are objects, not strings. Import the plugin and
  assign it to a namespace key to avoid collisions.
- **Performance:** Use `--cache` in CI and locally. For monorepos, scope linting to changed files
  with `--no-error-on-unmatched-pattern`.

## Code Examples

### Modern Flat Config (eslint.config.js)

```js
import js from "@eslint/js";
import tseslint from "typescript-eslint";
import prettier from "eslint-config-prettier";

export default tseslint.config(
  // Global ignores — standalone object with ONLY ignores key
  {
    ignores: ["dist/", "node_modules/", "coverage/", "**/*.generated.*"],
  },

  // Base JS recommended rules
  js.configs.recommended,

  // TypeScript strict + type-checked rules
  ...tseslint.configs.strictTypeChecked,
  ...tseslint.configs.stylisticTypeChecked,

  // TypeScript parser options — applies to all TS files
  {
    languageOptions: {
      parserOptions: {
        projectService: true,
        tsconfigRootDir: import.meta.dirname,
      },
    },
  },

  // Disable type-checked rules for JS files (config files, scripts)
  {
    files: ["**/*.js", "**/*.mjs"],
    ...tseslint.configs.disableTypeChecked,
  },

  // Project-specific overrides
  {
    files: ["src/**/*.ts"],
    rules: {
      "@typescript-eslint/no-unused-vars": [
        "error",
        { argsIgnorePattern: "^_", varsIgnorePattern: "^_" },
      ],
      "@typescript-eslint/explicit-function-return-type": "error",
      "@typescript-eslint/no-floating-promises": "error",
      "@typescript-eslint/strict-boolean-expressions": "warn",
    },
  },

  // Test file relaxations
  {
    files: ["**/*.test.ts", "**/*.spec.ts"],
    rules: {
      "@typescript-eslint/no-explicit-any": "off",
      "@typescript-eslint/no-non-null-assertion": "off",
      "@typescript-eslint/no-unsafe-assignment": "off",
    },
  },

  // Prettier must be LAST to override formatting rules
  prettier,
);
```

### Custom ESLint Rule

```js
// eslint-rules/no-console-in-services.js
/** @type {import("eslint").Rule.RuleModule} */
export default {
  meta: {
    type: "suggestion",
    docs: {
      description: "Disallow console.* in service files, use a logger instead",
    },
    fixable: null,
    schema: [],
    messages: {
      noConsole: "Use the injected logger instead of console.{{ method }}().",
    },
  },
  create(context) {
    return {
      MemberExpression(node) {
        if (
          node.object.type === "Identifier" &&
          node.object.name === "console" &&
          node.property.type === "Identifier"
        ) {
          context.report({
            node,
            messageId: "noConsole",
            data: { method: node.property.name },
          });
        }
      },
    };
  },
};
```

### Registering a Custom Rule in Flat Config

```js
import noConsoleInServices from "./eslint-rules/no-console-in-services.js";

export default [
  {
    files: ["src/services/**/*.ts"],
    plugins: {
      custom: { rules: { "no-console-in-services": noConsoleInServices } },
    },
    rules: {
      "custom/no-console-in-services": "error",
    },
  },
];
```

### Migration from Legacy .eslintrc to Flat Config

```bash
# Use the official migration tool
npx @eslint/migrate-config .eslintrc.json

# Install the compatibility utility for plugins that lack flat config support
npm install -D @eslint/compat
```

```js
// Using @eslint/compat for legacy plugins
import { fixupPluginRules } from "@eslint/compat";
import legacyPlugin from "eslint-plugin-legacy";

export default [
  {
    plugins: {
      legacy: fixupPluginRules(legacyPlugin),
    },
    rules: {
      "legacy/some-rule": "error",
    },
  },
];
```

## Commands

```bash
# Lint with caching (recommended for CI and local)
npx eslint --cache --cache-location node_modules/.cache/eslint/ .

# Auto-fix safe fixes
npx eslint --fix .

# Lint only staged files (use with lint-staged)
npx eslint --no-error-on-unmatched-pattern

# Debug config resolution for a specific file
npx eslint --print-config src/index.ts

# Inspect which rules are active
npx eslint --inspect-config
```

## Best Practices

### DO

- Use `typescript-eslint.config()` helper — it provides type-safe config composition.
- Place Prettier config (`eslint-config-prettier`) as the **last** entry to disable conflicting
  format rules.
- Enable `projectService: true` instead of manually listing `tsconfig.json` paths.
- Use `--cache` in every environment — it reduces re-lint time by 60-80%.
- Pin plugin versions in `package.json` to avoid surprise rule changes.

### DON'T

- Don't mix `.eslintrc.*` files with `eslint.config.js` — flat config ignores legacy files
  completely.
- Don't use `eslint-plugin-prettier` (runs Prettier inside ESLint) — it's slow. Run Prettier
  separately.
- Don't set `"no-unused-vars": "error"` when using TypeScript — use
  `@typescript-eslint/no-unused-vars` instead to avoid false positives.
- Don't apply type-checked rules to plain `.js` files — they require a `tsconfig.json` and will
  error without one.
- Don't suppress rules with `// eslint-disable` without a justification comment explaining *why*.
- Don't create `.eslintignore` with flat config — use the `ignores` property in the config array.
