---
name: qwik-development
version: 1.0.0
description: >
  Qwik framework patterns for building instantly-interactive web applications using resumability,
  lazy loading, and fine-grained serialization. Covers components, signals, tasks, QwikCity routing,
  and the optimizer.
triggers:
  - "Qwik"
  - "@builder.io/qwik"
  - "QwikCity"
  - "resumability"
  - "Qwik framework"
---

## When to Use

- Building web applications with Qwik or QwikCity.
- Implementing resumable applications that skip hydration.
- Working with Qwik's optimizer and the `$` suffix convention.
- Setting up server-side data loading with `routeLoader$` or form handling with `routeAction$`.
- Optimizing time-to-interactive for content-heavy sites.

## Core Concepts

### Resumability vs Hydration

Qwik does NOT hydrate. The server serializes the application state and event handlers into HTML. The browser resumes where the server left off — no re-execution of component code needed.

```
Traditional SPA:  Server renders HTML → Client downloads JS → Hydration replays all components
Qwik:             Server renders HTML → Client resumes → JS loaded ONLY when user interacts
```

### The `$` Suffix — Lazy Loading Boundaries

The `$` marks a lazy-loading boundary. Any function with `$` can be independently loaded by the optimizer. This is Qwik's key mechanism for splitting code.

```tsx
import { component$, useSignal, $ } from "@builder.io/qwik";

export const Counter = component$(() => {
  const count = useSignal(0);

  // onClick$ — handler is lazy-loaded only when user clicks
  const increment = $(() => {
    count.value++;
  });

  return (
    <button onClick$={increment}>
      Count: {count.value}
    </button>
  );
});
```

### Components with `component$`

Every Qwik component is wrapped in `component$` to enable resumability and lazy loading.

```tsx
import { component$ } from "@builder.io/qwik";

interface UserCardProps {
  name: string;
  email: string;
  role?: string;
}

export const UserCard = component$<UserCardProps>((props) => {
  return (
    <div class="user-card">
      <h3>{props.name}</h3>
      <p>{props.email}</p>
      {props.role && <span class="badge">{props.role}</span>}
    </div>
  );
});
```

### Reactive State — `useSignal` and `useStore`

```tsx
import { component$, useSignal, useStore } from "@builder.io/qwik";

export const FormExample = component$(() => {
  // useSignal for primitive values
  const isSubmitting = useSignal(false);
  const count = useSignal(0);

  // useStore for objects/arrays
  const form = useStore({
    name: "",
    email: "",
    errors: [] as string[],
  });

  return (
    <form
      preventdefault:submit
      onSubmit$={async () => {
        isSubmitting.value = true;
        form.errors = [];
        // Signals/stores read via .value (signals) or direct access (stores)
        await submitForm({ name: form.name, email: form.email });
        isSubmitting.value = false;
      }}
    >
      <input
        value={form.name}
        onInput$={(_, el) => (form.name = el.value)}
      />
      <input
        value={form.email}
        onInput$={(_, el) => (form.email = el.value)}
      />
      <button type="submit" disabled={isSubmitting.value}>
        {isSubmitting.value ? "Submitting..." : "Submit"}
      </button>
    </form>
  );
});
```

### Tasks — Side Effects and Lifecycle

```tsx
import { component$, useSignal, useTask$, useVisibleTask$ } from "@builder.io/qwik";

export const DataDisplay = component$(() => {
  const query = useSignal("");
  const results = useSignal<string[]>([]);

  // useTask$ — runs on server AND client, tracks signal dependencies
  useTask$(({ track, cleanup }) => {
    track(() => query.value);

    const controller = new AbortController();
    cleanup(() => controller.abort());

    if (query.value.length > 2) {
      fetch(`/api/search?q=${query.value}`, { signal: controller.signal })
        .then((r) => r.json())
        .then((data) => (results.value = data));
    }
  });

  // useVisibleTask$ — runs ONLY on client, when element becomes visible
  useVisibleTask$(() => {
    // Browser-only code: DOM APIs, analytics, etc.
    console.log("Component is visible in the browser");

    // Optional: run eagerly instead of waiting for visibility
    // useVisibleTask$(() => { ... }, { strategy: "document-ready" });
  });

  return (
    <div>
      <input bind:value={query} placeholder="Search..." />
      <ul>
        {results.value.map((r) => (
          <li key={r}>{r}</li>
        ))}
      </ul>
    </div>
  );
});
```

### QwikCity Routing

QwikCity uses file-based routing with `layout.tsx` and `index.tsx` conventions.

```
src/routes/
├── layout.tsx          # Root layout (wraps all pages)
├── index.tsx           # Home page (/)
├── about/
│   └── index.tsx       # About page (/about)
├── users/
│   ├── layout.tsx      # Users layout (wraps all /users/* pages)
│   ├── index.tsx       # Users list (/users)
│   └── [userId]/
│       └── index.tsx   # User detail (/users/:userId)
```

### Data Loading with `routeLoader$`

```tsx
import { component$ } from "@builder.io/qwik";
import { routeLoader$ } from "@builder.io/qwik-city";

// Runs on the server BEFORE the component renders
export const useUserData = routeLoader$(async (requestEvent) => {
  const userId = requestEvent.params.userId;
  const res = await fetch(`https://api.example.com/users/${userId}`);

  if (!res.ok) {
    throw requestEvent.redirect(302, "/users");
  }

  return (await res.json()) as { name: string; email: string };
});

export default component$(() => {
  const user = useUserData();

  return (
    <div>
      <h1>{user.value.name}</h1>
      <p>{user.value.email}</p>
    </div>
  );
});
```

### Form Actions with `routeAction$`

```tsx
import { component$ } from "@builder.io/qwik";
import { routeAction$, Form, zod$, z } from "@builder.io/qwik-city";

export const useCreateUser = routeAction$(
  async (data, requestEvent) => {
    const res = await fetch("https://api.example.com/users", {
      method: "POST",
      body: JSON.stringify(data),
      headers: { "Content-Type": "application/json" },
    });

    if (!res.ok) {
      return requestEvent.fail(400, { message: "Failed to create user" });
    }

    return { success: true };
  },
  // Built-in Zod validation
  zod$({
    name: z.string().min(2),
    email: z.string().email(),
  })
);

export default component$(() => {
  const action = useCreateUser();

  return (
    <Form action={action}>
      <input name="name" />
      <input name="email" type="email" />
      {action.value?.failed && <p class="error">{action.value.message}</p>}
      <button type="submit" disabled={action.isRunning}>Create</button>
    </Form>
  );
});
```

### Serialization Rules

Qwik serializes state into HTML. Not everything is serializable.

```tsx
// Serializable (safe to use in signals/stores)
const count = useSignal(42);               // primitives
const items = useSignal(["a", "b"]);       // arrays
const user = useStore({ name: "Ada" });    // plain objects
const handler = $(() => console.log("hi")); // QRL functions ($ suffix)

// NOT serializable (will cause errors if captured in closures)
// - Class instances (new MyClass())
// - DOM nodes (document.getElementById)
// - Closures that capture non-serializable values
// - Functions without $ suffix
```

## Best Practices

### DO

- **Use `component$`** for all components — it enables lazy loading and resumability.
- **Use `$` suffix** on event handlers and callbacks — `onClick$`, `onInput$`, `$(() => ...)`.
- **Use `routeLoader$`** for server-side data fetching — data is available before component renders.
- **Use `routeAction$`** with `Form` for mutations — works without JavaScript for progressive enhancement.
- **Use `useTask$`** for reactive side effects — it tracks dependencies automatically.
- **Use `bind:value`** for two-way binding on inputs — cleaner than manual `onInput$` + value.
- **Use `preventdefault:submit`** on forms — Qwik's declarative way to prevent default behavior.
- **Keep serialization in mind** — only use serializable values in component state.

### DON'T

- **DON'T forget the `$`** on event handlers — `onClick` won't work, must be `onClick$`.
- **DON'T use `useVisibleTask$` for data fetching** — use `routeLoader$` instead; `useVisibleTask$` runs client-only and hurts performance.
- **DON'T capture non-serializable values** in `$()` closures — the optimizer needs to serialize them.
- **DON'T use `useEffect`/`useState`** — those are React; Qwik uses `useTask$`/`useSignal`.
- **DON'T import heavy libraries at the top level** — use dynamic `import()` inside `$()` functions to keep bundles lean.
- **DON'T use `useVisibleTask$` when `useTask$` works** — `useTask$` runs on both server and client and is more efficient.
- **DON'T mutate signal values directly** — use `.value = newValue` for signals; for stores, mutate properties directly.

## Commands

```bash
# Create a new Qwik project
npm create qwik@latest

# Development
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview

# Add integrations (adapters, etc.)
npm run qwik add
```

## Resources

- [Qwik Docs](https://qwik.dev/)
- [QwikCity Docs](https://qwik.dev/docs/qwikcity/)
- [Qwik Playground](https://qwik.dev/playground/)
