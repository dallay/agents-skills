---
name: cypress-e2e
version: 1.0.0
description: >
  Cypress end-to-end testing patterns for reliable browser-based testing, covering selectors,
  custom commands, API mocking with cy.intercept, CI configuration, and best practices for
  deterministic, maintainable E2E test suites.
triggers:
  - "Cypress"
  - "E2E testing"
  - "cypress.config"
  - "end-to-end testing"
  - "browser testing"
---

## When to Use

- Writing end-to-end tests for web applications with Cypress.
- Setting up API mocking with `cy.intercept` for deterministic tests.
- Creating reusable custom commands for common workflows.
- Configuring Cypress for CI/CD pipelines.
- Debugging flaky E2E tests or improving test reliability.

## Critical Patterns

- **Use `data-cy` Attributes:** NEVER select elements by class name, tag, or content that changes with design or i18n. Use dedicated `data-cy` attributes that exist solely for testing.
- **No Arbitrary Waits:** NEVER use `cy.wait(5000)`. Always wait for specific conditions: route aliases, DOM elements, or assertions that Cypress retries automatically.
- **Test User Flows, Not Units:** E2E tests validate complete workflows (login → navigate → perform action → verify result). For isolated logic, use unit tests.
- **API-First Setup:** Use `cy.request()` or API calls to set up test state (create users, seed data) instead of navigating through the UI. Reserve UI interactions for what you're actually testing.
- **Each Test Stands Alone:** Tests must not depend on previous tests or shared state. Use `beforeEach` to set up and clean state for each test.

## Code Examples

### Test Structure with Selectors

```typescript
// cypress/e2e/dashboard.cy.ts
describe("Dashboard", () => {
  beforeEach(() => {
    // Set up state via API — fast and reliable
    cy.request("POST", "/api/test/seed", { fixture: "dashboard" });
    cy.loginByApi("admin@test.com", "password123");
    cy.visit("/dashboard");
  });

  it("displays project list with correct count", () => {
    cy.get("[data-cy=project-list]").should("be.visible");
    cy.get("[data-cy=project-card]").should("have.length", 3);
  });

  it("creates a new project", () => {
    cy.get("[data-cy=create-project-btn]").click();
    cy.get("[data-cy=project-name-input]").type("New Project");
    cy.get("[data-cy=project-form-submit]").click();

    // Assert on visible result, not internal state
    cy.get("[data-cy=project-card]").should("have.length", 4);
    cy.contains("[data-cy=project-card]", "New Project").should("exist");
  });

  it("filters projects by status", () => {
    cy.get("[data-cy=filter-dropdown]").click();
    cy.get("[data-cy=filter-option-active]").click();

    cy.get("[data-cy=project-card]").should("have.length", 2);
    cy.get("[data-cy=active-filter-badge]").should("be.visible");
  });
});
```

### Custom Commands

```typescript
// cypress/support/commands.ts
declare global {
  namespace Cypress {
    interface Chainable {
      loginByApi(email: string, password: string): Chainable<void>;
      getByDataCy(selector: string): Chainable<JQuery<HTMLElement>>;
    }
  }
}

// Login via API — skip the UI for non-login tests
Cypress.Commands.add("loginByApi", (email: string, password: string) => {
  cy.request("POST", "/api/auth/login", { email, password }).then((resp) => {
    window.localStorage.setItem("auth_token", resp.body.token);
  });
});

// Shorthand for data-cy selectors
Cypress.Commands.add("getByDataCy", (selector: string) => {
  return cy.get(`[data-cy=${selector}]`);
});
```

### API Mocking with cy.intercept

```typescript
describe("User Profile", () => {
  it("displays user data from API", () => {
    // Intercept and mock the API response
    cy.intercept("GET", "/api/users/me", {
      statusCode: 200,
      body: {
        id: "1",
        name: "Alice",
        email: "alice@test.com",
        role: "admin",
      },
    }).as("getProfile");

    cy.visit("/profile");
    cy.wait("@getProfile"); // Wait for the specific request

    cy.getByDataCy("user-name").should("contain", "Alice");
    cy.getByDataCy("user-role").should("contain", "admin");
  });

  it("handles API errors gracefully", () => {
    cy.intercept("GET", "/api/users/me", {
      statusCode: 500,
      body: { error: "Internal server error" },
    }).as("getProfileError");

    cy.visit("/profile");
    cy.wait("@getProfileError");

    cy.getByDataCy("error-message").should("contain", "Something went wrong");
    cy.getByDataCy("retry-button").should("be.visible");
  });

  it("shows loading state while fetching", () => {
    cy.intercept("GET", "/api/users/me", (req) => {
      req.reply({
        delay: 1000,
        body: { id: "1", name: "Alice" },
      });
    }).as("getProfileSlow");

    cy.visit("/profile");
    cy.getByDataCy("loading-spinner").should("be.visible");
    cy.wait("@getProfileSlow");
    cy.getByDataCy("loading-spinner").should("not.exist");
  });
});
```

### Using Fixtures

```typescript
// cypress/fixtures/users.json
[
  { "id": "1", "name": "Alice", "role": "admin" },
  { "id": "2", "name": "Bob", "role": "user" }
]

// In test
cy.intercept("GET", "/api/users", { fixture: "users.json" }).as("getUsers");
```

### Cypress Configuration

```typescript
// cypress.config.ts
import { defineConfig } from "cypress";

export default defineConfig({
  e2e: {
    baseUrl: "http://localhost:3000",
    specPattern: "cypress/e2e/**/*.cy.{ts,tsx}",
    supportFile: "cypress/support/e2e.ts",
    viewportWidth: 1280,
    viewportHeight: 720,
    video: false,           // Enable in CI only
    screenshotOnRunFailure: true,
    defaultCommandTimeout: 10000,
    retries: {
      runMode: 2,           // Retry in CI
      openMode: 0,          // No retry in interactive
    },
    setupNodeEvents(on, config) {
      // Plugins, code coverage, etc.
    },
  },
});
```

### CI Configuration (GitHub Actions)

```yaml
cypress-e2e:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: cypress-io/github-action@v6
      with:
        build: npm run build
        start: npm start
        wait-on: "http://localhost:3000"
        wait-on-timeout: 120
        browser: chrome
      env:
        CYPRESS_BASE_URL: http://localhost:3000
    - uses: actions/upload-artifact@v4
      if: failure()
      with:
        name: cypress-screenshots
        path: cypress/screenshots
```

### Viewport Testing

```typescript
describe("Responsive Navigation", () => {
  const viewports: Cypress.ViewportPreset[] = ["iphone-6", "ipad-2", "macbook-15"];

  viewports.forEach((viewport) => {
    it(`renders correctly on ${viewport}`, () => {
      cy.viewport(viewport);
      cy.visit("/");

      if (viewport === "iphone-6") {
        cy.getByDataCy("mobile-menu-btn").should("be.visible");
        cy.getByDataCy("desktop-nav").should("not.be.visible");
      } else {
        cy.getByDataCy("desktop-nav").should("be.visible");
      }
    });
  });
});
```

## Best Practices

### DO

- Add `data-cy` attributes to interactive and assertable elements in your component code.
- Use `cy.intercept()` to mock APIs for deterministic, fast tests.
- Use `cy.request()` for test setup (seeding data, authentication) to keep tests fast.
- Wait on aliased routes (`cy.wait("@alias")`) instead of arbitrary timeouts.
- Run tests in CI with `--browser chrome --headless` and upload screenshots on failure.
- Group related tests by feature in separate spec files.

### DON'T

- DON'T use `cy.wait(3000)` — it makes tests slow and flaky. Wait for assertions or route aliases instead.
- DON'T select elements by CSS class (`.btn-primary`) or tag (`button`) — they change with redesigns.
- DON'T write tests that depend on execution order or data from previous tests.
- DON'T test third-party UI (OAuth login pages, payment forms) — mock them at the API boundary.
- DON'T use `cy.get().then()` for simple assertions — Cypress commands retry automatically. Use `.should()` instead.
- DON'T navigate through the UI to set up test state — use API calls. Test the flow you're verifying, not the setup.
