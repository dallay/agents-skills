---
name: jest-testing
description: >-
  Jest testing framework patterns for JavaScript and TypeScript projects, covering test
  structure, mocking strategies, async testing, snapshot testing, React component testing
  with Testing Library, and practical test organization. Use when the task involves
  `Jest`, `JavaScript testing`, `React testing`, `jest.config`, or `unit testing JS`.
license: MIT
metadata:
  version: "1.0.0"
---
## When to Use

- Writing or refactoring unit and integration tests with Jest.
- Setting up mocking strategies for modules, functions, or APIs.
- Testing async code (Promises, async/await, timers).
- Testing React components alongside `@testing-library/react`.
- Configuring Jest for TypeScript, coverage, or CI environments.
- Debugging flaky or slow tests.

## Critical Patterns

- **Arrange-Act-Assert:** Every test follows three clear phases — set up state, perform the action, verify the outcome. No mixing.
- **Test Behavior, Not Implementation:** Assert on observable outcomes (return values, DOM changes, thrown errors), not internal function calls.
- **Isolate with Mocking:** Mock external dependencies (APIs, databases, file system) but NOT the unit under test. Over-mocking hides real bugs.
- **One Assertion Focus Per Test:** Each `it` block should test one logical behavior. Multiple assertions are fine if they verify the same behavior.
- **Deterministic Tests:** No reliance on real time, network, or random values. Use fake timers, mocked fetch, and seeded data.
- **Clean Up After Yourself:** Reset mocks in `afterEach`. Avoid shared mutable state between tests.

## Code Examples

### Basic Test Structure

```typescript
describe("UserService", () => {
  let service: UserService;

  beforeEach(() => {
    service = new UserService();
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe("findById", () => {
    it("returns user when found", async () => {
      // Arrange
      const mockUser = { id: "1", name: "Alice" };
      jest.spyOn(db, "query").mockResolvedValue(mockUser);

      // Act
      const result = await service.findById("1");

      // Assert
      expect(result).toEqual(mockUser);
    });

    it("throws NotFoundError when user does not exist", async () => {
      jest.spyOn(db, "query").mockResolvedValue(null);

      await expect(service.findById("999")).rejects.toThrow(NotFoundError);
    });
  });
});
```

### Common Matchers

```typescript
// Equality
expect(value).toBe(primitive);           // strict equality (===)
expect(value).toEqual(object);           // deep equality
expect(value).toStrictEqual(object);     // deep equality + type checking

// Truthiness
expect(value).toBeTruthy();
expect(value).toBeFalsy();
expect(value).toBeNull();
expect(value).toBeUndefined();
expect(value).toBeDefined();

// Numbers
expect(value).toBeGreaterThan(3);
expect(value).toBeCloseTo(0.3, 5);       // floating point

// Strings
expect(value).toMatch(/regex/);
expect(value).toContain("substring");

// Arrays / Iterables
expect(array).toContain(item);
expect(array).toHaveLength(3);
expect(array).toEqual(expect.arrayContaining([1, 2]));

// Objects
expect(obj).toHaveProperty("key", "value");
expect(obj).toMatchObject({ name: "Alice" }); // partial match

// Exceptions
expect(() => fn()).toThrow(ErrorType);
expect(() => fn()).toThrow("message");
```

### Mocking Strategies

```typescript
// 1. jest.fn() — create a standalone mock function
const mockCallback = jest.fn();
mockCallback.mockReturnValue(42);
mockCallback.mockResolvedValue({ data: "ok" }); // async

expect(mockCallback).toHaveBeenCalledTimes(1);
expect(mockCallback).toHaveBeenCalledWith("arg1", "arg2");

// 2. jest.spyOn() — spy on existing methods (preserves original unless mocked)
const spy = jest.spyOn(Math, "random").mockReturnValue(0.5);
// ... test code ...
spy.mockRestore(); // restore original

// 3. jest.mock() — mock entire modules
jest.mock("../services/emailService", () => ({
  sendEmail: jest.fn().mockResolvedValue({ sent: true }),
}));

// 4. Manual mocks — __mocks__ directory
// __mocks__/axios.ts
export default {
  get: jest.fn().mockResolvedValue({ data: {} }),
  post: jest.fn().mockResolvedValue({ data: {} }),
};
```

### Async Testing

```typescript
// async/await — preferred
it("fetches user data", async () => {
  const data = await fetchUser("1");
  expect(data.name).toBe("Alice");
});

// Rejections
it("rejects with an error", async () => {
  await expect(fetchUser("bad")).rejects.toThrow("Not found");
});

// Fake timers
it("debounces the search", () => {
  jest.useFakeTimers();

  const callback = jest.fn();
  const debounced = debounce(callback, 300);

  debounced("query");
  expect(callback).not.toHaveBeenCalled();

  jest.advanceTimersByTime(300);
  expect(callback).toHaveBeenCalledWith("query");

  jest.useRealTimers();
});
```

### Testing React Components

```typescript
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { LoginForm } from "./LoginForm";

describe("LoginForm", () => {
  it("submits valid credentials", async () => {
    const user = userEvent.setup();
    const onSubmit = jest.fn();
    render(<LoginForm onSubmit={onSubmit} />);

    await user.type(screen.getByLabelText(/email/i), "alice@example.com");
    await user.type(screen.getByLabelText(/password/i), "secret123");
    await user.click(screen.getByRole("button", { name: /sign in/i }));

    expect(onSubmit).toHaveBeenCalledWith({
      email: "alice@example.com",
      password: "secret123",
    });
  });

  it("shows validation error for empty email", async () => {
    const user = userEvent.setup();
    render(<LoginForm onSubmit={jest.fn()} />);

    await user.click(screen.getByRole("button", { name: /sign in/i }));

    expect(screen.getByText(/email is required/i)).toBeInTheDocument();
  });
});
```

### Snapshot Testing

```typescript
// Use sparingly — only for stable, serializable output
it("renders correctly", () => {
  const { container } = render(<Badge variant="success">Active</Badge>);
  expect(container.firstChild).toMatchSnapshot();
});

// Inline snapshots — better for small outputs
it("formats the date", () => {
  expect(formatDate("2024-01-15")).toMatchInlineSnapshot(`"January 15, 2024"`);
});
```

### Jest Configuration

```typescript
// jest.config.ts
import type { Config } from "jest";

const config: Config = {
  preset: "ts-jest",
  testEnvironment: "jsdom", // "node" for backend
  roots: ["<rootDir>/src"],
  testMatch: ["**/__tests__/**/*.test.ts(x)?", "**/*.spec.ts(x)?"],
  moduleNameMapper: {
    "^@/(.*)$": "<rootDir>/src/$1",
  },
  setupFilesAfterSetup: ["<rootDir>/jest.setup.ts"],
  collectCoverageFrom: [
    "src/**/*.{ts,tsx}",
    "!src/**/*.d.ts",
    "!src/**/index.ts", // barrel exports
  ],
  coverageThresholds: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80,
    },
  },
};

export default config;
```

## Best Practices

### DO

- Use `describe` blocks to group related tests by function or feature.
- Name tests as complete sentences: `it("returns null when user is not found")`.
- Use `beforeEach` for setup that every test in a `describe` needs — never rely on test execution order.
- Run tests in watch mode during development: `jest --watch`.
- Use `jest.requireActual()` when partially mocking a module to preserve unmocked exports.
- Run `--detectOpenHandles` to debug tests that won't exit.

### DON'T

- DON'T use `toBeTruthy()` when you can be specific — use `toBe(true)`, `toEqual(value)`, or `toBeNull()`.
- DON'T mock the module under test — only mock its dependencies.
- DON'T write tests that depend on execution order or shared mutable state.
- DON'T snapshot large component trees — snapshots become noise that nobody reviews.
- DON'T use `test.only` or `describe.only` in committed code — they silently skip other tests.
- DON'T suppress errors with `try/catch` inside tests — let Jest catch and report them with `rejects.toThrow`.
- DON'T use arbitrary `setTimeout` or `sleep` for async tests — use `waitFor`, fake timers, or resolved promises.
