---
name: solidjs-development
description: >-
  Solid.js reactive framework patterns for building high-performance web applications with
  fine-grained reactivity. Covers signals, effects, memos, stores, control flow
  components, routing, resources, and key differences from React. Use when the task
  involves `Solid.js`, `solid-js`, `SolidStart`, `fine-grained reactivity`, or `Solid
  signals`.
license: MIT
metadata:
  version: "1.0.0"
---
## When to Use

- Building web applications with Solid.js or SolidStart.
- Migrating from React and need to understand Solid's reactivity model.
- Implementing fine-grained reactive state management with signals and stores.
- Working with Solid's control flow components (`Show`, `For`, `Switch`).
- Setting up data fetching with `createResource` or routing with `@solidjs/router`.

## Core Concepts

### Fine-Grained Reactivity (NOT Virtual DOM)

Solid does NOT re-render components. Components run ONCE to set up the reactive graph. Only the specific DOM nodes that depend on changed signals update. This is the fundamental difference from React.

```
React model:    State changes → component re-executes → virtual DOM diff → DOM update
Solid model:    Signal changes → subscribed effect/memo runs → direct DOM update
```

### Signals — Primitive Reactive State

Signals are the foundation. They return a getter function (not a value) and a setter.

```tsx
import { createSignal } from "solid-js";

function Counter() {
  const [count, setCount] = createSignal(0);

  // count is a FUNCTION — you call it to read the value
  return (
    <button onClick={() => setCount(c => c + 1)}>
      Clicks: {count()}
    </button>
  );
}
```

### Effects — Side Effects on Signal Changes

`createEffect` tracks signals read inside it and re-runs when they change.

```tsx
import { createSignal, createEffect } from "solid-js";

function Logger() {
  const [name, setName] = createSignal("World");

  createEffect(() => {
    // Automatically re-runs when name() changes
    console.log(`Hello, ${name()}!`);
  });

  return <input value={name()} onInput={(e) => setName(e.target.value)} />;
}
```

### Memos — Derived/Cached Computations

`createMemo` caches a derived value and only recomputes when dependencies change.

```tsx
import { createSignal, createMemo } from "solid-js";

function FilteredList() {
  const [items, setItems] = createSignal([1, 2, 3, 4, 5]);
  const [min, setMin] = createSignal(3);

  // Only recomputes when items() or min() change
  const filtered = createMemo(() => items().filter(i => i >= min()));

  return <p>Filtered: {filtered().join(", ")}</p>;
}
```

### Stores — Deep Reactive Objects

For complex/nested state, use `createStore` instead of signals.

```tsx
import { createStore } from "solid-js/store";

function TodoApp() {
  const [state, setState] = createStore({
    todos: [
      { id: 1, text: "Learn Solid", done: false },
      { id: 2, text: "Build app", done: false },
    ],
    filter: "all",
  });

  const toggleTodo = (id: number) => {
    setState("todos", (t) => t.id === id, "done", (done) => !done);
  };

  // Path-based setter for nested updates — no spread/copy needed
  const addTodo = (text: string) => {
    setState("todos", (todos) => [...todos, { id: Date.now(), text, done: false }]);
  };

  return (
    <For each={state.todos}>
      {(todo) => (
        <div onClick={() => toggleTodo(todo.id)}>
          {todo.text} {todo.done ? "✓" : ""}
        </div>
      )}
    </For>
  );
}
```

### Control Flow Components

Solid uses dedicated components instead of inline JS for conditional/list rendering. This enables fine-grained DOM updates.

```tsx
import { Show, For, Switch, Match } from "solid-js";

function Dashboard(props) {
  return (
    <div>
      {/* Conditional rendering */}
      <Show when={props.user()} fallback={<p>Please log in</p>}>
        {(user) => <p>Welcome, {user().name}</p>}
      </Show>

      {/* List rendering — keyed by reference by default */}
      <For each={props.items()}>
        {(item, index) => (
          <div>{index()}: {item.name}</div>
        )}
      </For>

      {/* Multi-branch conditional */}
      <Switch fallback={<p>Unknown status</p>}>
        <Match when={props.status() === "loading"}>
          <Spinner />
        </Match>
        <Match when={props.status() === "error"}>
          <ErrorView />
        </Match>
        <Match when={props.status() === "ready"}>
          <Content />
        </Match>
      </Switch>
    </div>
  );
}
```

### Resources — Async Data Fetching

`createResource` wraps async operations with built-in loading/error states.

```tsx
import { createSignal, createResource, Show, Suspense } from "solid-js";

const fetchUser = async (id: string) => {
  const res = await fetch(`/api/users/${id}`);
  return res.json();
};

function UserProfile() {
  const [userId, setUserId] = createSignal("1");
  const [user, { mutate, refetch }] = createResource(userId, fetchUser);

  return (
    <Suspense fallback={<p>Loading...</p>}>
      <Show when={user()} fallback={<p>No user</p>}>
        {(u) => <div>{u().name} — {u().email}</div>}
      </Show>
      <button onClick={refetch}>Refresh</button>
    </Suspense>
  );
}
```

### Context — Dependency Injection

```tsx
import { createContext, useContext, ParentComponent } from "solid-js";
import { createStore } from "solid-js/store";

interface AppState {
  theme: "light" | "dark";
  locale: string;
}

const AppContext = createContext<[AppState, any]>();

export const AppProvider: ParentComponent = (props) => {
  const [state, setState] = createStore<AppState>({
    theme: "light",
    locale: "en",
  });

  return (
    <AppContext.Provider value={[state, setState]}>
      {props.children}
    </AppContext.Provider>
  );
};

export const useApp = () => {
  const ctx = useContext(AppContext);
  if (!ctx) throw new Error("useApp must be used within AppProvider");
  return ctx;
};
```

### Routing with @solidjs/router

```tsx
import { Router, Route, A, useParams } from "@solidjs/router";

function App() {
  return (
    <Router>
      <Route path="/" component={Home} />
      <Route path="/users/:id" component={UserDetail} />
      <Route path="*404" component={NotFound} />
    </Router>
  );
}

function UserDetail() {
  const params = useParams();
  // params.id is reactive
  const [user] = createResource(() => params.id, fetchUser);

  return <Show when={user()}>{(u) => <h1>{u().name}</h1>}</Show>;
}

function Nav() {
  return (
    <nav>
      <A href="/" activeClass="active">Home</A>
      <A href="/users/1">User 1</A>
    </nav>
  );
}
```

## Props and Components

```tsx
import { Component, ParentComponent, splitProps, mergeProps } from "solid-js";

// Props are NOT destructured — it breaks reactivity
interface CardProps {
  title: string;
  subtitle?: string;
  onClick?: () => void;
}

// DO: Access props directly or use splitProps
const Card: ParentComponent<CardProps> = (props) => {
  const merged = mergeProps({ subtitle: "Default subtitle" }, props);
  const [local, others] = splitProps(merged, ["title", "subtitle"]);

  return (
    <div {...others}>
      <h2>{local.title}</h2>
      <p>{local.subtitle}</p>
      {props.children}
    </div>
  );
};
```

## Best Practices

### DO

- **Call signal getters** in JSX or inside tracking scopes (`createEffect`, `createMemo`) — this is how Solid tracks dependencies.
- **Use `<For>`** for list rendering — it efficiently handles keyed updates without reconciliation.
- **Use `<Show>`** for conditionals — it avoids unnecessary DOM creation.
- **Use stores** for complex nested state — path-based setters avoid deep cloning.
- **Use `onCleanup`** inside effects for teardown logic (event listeners, intervals).
- **Use `batch`** to group multiple signal updates into one flush.
- **Wrap lazy-loaded routes** with `<Suspense>` for loading states.
- **Use `createResource`** for any async data — it integrates with `<Suspense>` automatically.

### DON'T

- **DON'T destructure props** — `const { name } = props` breaks reactivity. Access `props.name` directly or use `splitProps`.
- **DON'T call signals outside tracking scopes** and expect reactivity — reading `count()` in the component body but outside JSX/effects won't track.
- **DON'T use `.map()` for lists** — use `<For>` instead; `.map()` recreates all DOM nodes on every change.
- **DON'T think in re-renders** — Solid components run once. If you write code expecting the whole function to re-run, it won't work.
- **DON'T use `createEffect` for derived state** — use `createMemo` instead; effects are for side effects, not computations.
- **DON'T wrap primitives in stores** — use `createSignal` for simple values; stores are for objects/arrays.
- **DON'T forget the `()` on signal getters** — `{count}` passes the function, `{count()}` reads the value.
- **DON'T use React hooks patterns** — there's no rules-of-hooks in Solid; signals can be created anywhere, conditionally, in loops.

## Commands

```bash
# Create new Solid project
npx degit solidjs/templates/ts my-app

# Create SolidStart project
npm init solid@latest my-app

# Development
npm run dev

# Build for production
npm run build
```

## Resources

- [Solid.js Docs](https://docs.solidjs.com/)
- [SolidStart](https://start.solidjs.com/)
- [Solid Playground](https://playground.solidjs.com/)
