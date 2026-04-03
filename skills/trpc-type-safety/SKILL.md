---
name: trpc-type-safety
version: 1.0.0
description: >
  End-to-end type-safe APIs for TypeScript with tRPC, React Query integration, Zod validation,
  and full-stack type inference without code generation.
triggers:
  - "tRPC router or procedure"
  - "type-safe API"
  - "tRPC with React Query"
  - "tRPC middleware"
  - "tRPC Next.js integration"
  - "end-to-end TypeScript API"
---

# tRPC — End-to-End Type Safety

Build type-safe APIs where TypeScript types flow automatically from server to client with zero code
generation. Define your API once, get automatic type inference everywhere.

## When to Use

- Full-stack TypeScript applications (Next.js, T3 stack, monorepos).
- Projects where client and server share a TypeScript codebase.
- Internal APIs where you control both ends — no external consumers.
- Apps using React Query for data fetching and caching.
- Teams wanting REST-like simplicity with GraphQL-like type safety.

**Avoid when:** public APIs for non-TypeScript clients, polyglot microservices, mobile apps in
Swift/Kotlin, or when you need OpenAPI documentation for external developers.

## Quick Start

```bash
# Server
npm install @trpc/server zod

# React/Next.js client
npm install @trpc/client @trpc/react-query @tanstack/react-query
```

### Server — Define Router

```typescript
// server/trpc.ts
import { initTRPC } from '@trpc/server';
import { z } from 'zod';

const t = initTRPC.create();

export const appRouter = t.router({
  hello: t.procedure
    .input(z.object({ name: z.string() }))
    .query(({ input }) => {
      return { greeting: `Hello ${input.name}` };
    }),

  createPost: t.procedure
    .input(z.object({ title: z.string(), content: z.string() }))
    .mutation(async ({ input }) => {
      return { id: 1, ...input };
    }),
});

export type AppRouter = typeof appRouter;
```

### Client — React Usage

```typescript
// client/trpc.ts
import { createTRPCReact } from '@trpc/react-query';
import type { AppRouter } from '../server/trpc';

export const trpc = createTRPCReact<AppRouter>();

// Component — fully typed, zero codegen
function MyComponent() {
  const { data } = trpc.hello.useQuery({ name: 'World' });
  const createPost = trpc.createPost.useMutation();

  return <div>{data?.greeting}</div>;
}
```

## Router Definition

### Nested Routers (Namespacing)

```typescript
const userRouter = t.router({
  getById: t.procedure
    .input(z.string())
    .query(({ input }) => getUser(input)),

  create: t.procedure
    .input(z.object({ name: z.string(), email: z.string() }))
    .mutation(({ input }) => createUser(input)),
});

const postRouter = t.router({
  list: t.procedure.query(() => getPosts()),
  create: t.procedure
    .input(z.object({ title: z.string() }))
    .mutation(({ input }) => createPost(input)),
});

export const appRouter = t.router({
  user: userRouter,
  post: postRouter,
});

// Client: trpc.user.getById.useQuery('123')
// Client: trpc.post.list.useQuery()
```

### Recommended File Structure

```
server/
├── trpc.ts           # tRPC instance, context, base procedures
├── routers/
│   ├── user.ts       # User procedures
│   ├── post.ts       # Post procedures
│   └── index.ts      # Merge all routers → appRouter
└── schemas/
    ├── user.ts       # Zod schemas (shared validation)
    └── post.ts
```

## Procedures (Query & Mutation)

```typescript
const router = t.router({
  // Query — read data (GET, cached by React Query)
  getUser: t.procedure
    .input(z.string())
    .query(({ input }) => {
      return db.user.findUnique({ where: { id: input } });
    }),

  // Query with complex input
  searchUsers: t.procedure
    .input(z.object({
      query: z.string(),
      limit: z.number().default(10),
    }))
    .query(({ input }) => {
      return db.user.findMany({
        where: { name: { contains: input.query } },
        take: input.limit,
      });
    }),

  // Mutation — write data (POST, not cached)
  createUser: t.procedure
    .input(z.object({
      name: z.string().min(3),
      email: z.string().email(),
    }))
    .mutation(async ({ input }) => {
      return await db.user.create({ data: input });
    }),
});
```

## Context and Middleware

### Creating Context

```typescript
export async function createContext(opts: CreateNextContextOptions) {
  const session = await getSession(opts.req);

  return {
    session,
    db: prisma,
  };
}

export type Context = Awaited<ReturnType<typeof createContext>>;

const t = initTRPC.context<Context>().create();
```

### Authentication Middleware

```typescript
const isAuthed = t.middleware(({ ctx, next }) => {
  if (!ctx.session?.user) {
    throw new TRPCError({ code: 'UNAUTHORIZED' });
  }

  return next({
    ctx: {
      ...ctx,
      user: ctx.session.user, // Narrowed type — guaranteed non-null
    },
  });
});

// Reusable procedure builders
const protectedProcedure = t.procedure.use(isAuthed);

const router = t.router({
  // Public
  getPublicPosts: t.procedure.query(() => getPosts()),

  // Protected — ctx.user is guaranteed
  getMyPosts: protectedProcedure.query(({ ctx }) => {
    return getPostsByUser(ctx.user.id);
  }),
});
```

### Logging Middleware

```typescript
const loggerMiddleware = t.middleware(async ({ path, type, next }) => {
  const start = Date.now();
  const result = await next();
  console.log(`${type} ${path} — ${Date.now() - start}ms`);
  return result;
});
```

## Error Handling

### Throwing Typed Errors

```typescript
import { TRPCError } from '@trpc/server';

const router = t.router({
  getUser: t.procedure
    .input(z.string())
    .query(async ({ input }) => {
      const user = await db.user.findUnique({ where: { id: input } });

      if (!user) {
        throw new TRPCError({
          code: 'NOT_FOUND',
          message: `User ${input} not found`,
        });
      }

      return user;
    }),
});
```

### Error Codes Reference

| Code | HTTP | Use Case |
|------|------|----------|
| `BAD_REQUEST` | 400 | Invalid input |
| `UNAUTHORIZED` | 401 | Not authenticated |
| `FORBIDDEN` | 403 | Not authorized |
| `NOT_FOUND` | 404 | Resource missing |
| `CONFLICT` | 409 | Resource conflict |
| `TOO_MANY_REQUESTS` | 429 | Rate limit exceeded |
| `INTERNAL_SERVER_ERROR` | 500 | Server error |

### Error Formatter (Zod Integration)

```typescript
import { ZodError } from 'zod';

const t = initTRPC.context<Context>().create({
  errorFormatter({ shape, error }) {
    return {
      ...shape,
      data: {
        ...shape.data,
        zodError:
          error.code === 'BAD_REQUEST' && error.cause instanceof ZodError
            ? error.cause.flatten()
            : null,
      },
    };
  },
});
```

## React Integration

### Query with Options

```typescript
function UserProfile({ userId }: { userId: string }) {
  const { data, isLoading, error } = trpc.user.getById.useQuery(userId, {
    staleTime: 5 * 60 * 1000,
    retry: 3,
  });

  if (isLoading) return <div>Loading...</div>;
  if (error) return <div>Error: {error.message}</div>;

  return <div>{data.name}</div>;
}
```

### Mutation with Cache Invalidation

```typescript
function CreatePostForm() {
  const utils = trpc.useContext();

  const createPost = trpc.post.create.useMutation({
    onSuccess: () => {
      utils.post.list.invalidate(); // Refetch post list
    },
  });

  return (
    <button
      onClick={() => createPost.mutate({ title: 'New Post' })}
      disabled={createPost.isLoading}
    >
      {createPost.isLoading ? 'Creating...' : 'Create'}
    </button>
  );
}
```

### Optimistic Updates

```typescript
const createPost = trpc.post.create.useMutation({
  onMutate: async (newPost) => {
    await utils.post.list.cancel();
    const previous = utils.post.list.getData();

    utils.post.list.setData(undefined, (old) => [
      ...(old ?? []),
      { id: 'temp', ...newPost },
    ]);

    return { previous };
  },
  onError: (_err, _newPost, context) => {
    utils.post.list.setData(undefined, context?.previous);
  },
  onSettled: () => {
    utils.post.list.invalidate();
  },
});
```

## Next.js Integration

### API Route (App Router)

```typescript
// app/api/trpc/[trpc]/route.ts
import { fetchRequestHandler } from '@trpc/server/adapters/fetch';
import { appRouter } from '../../../../server/routers';
import { createContext } from '../../../../server/context';

const handler = (req: Request) =>
  fetchRequestHandler({
    endpoint: '/api/trpc',
    req,
    router: appRouter,
    createContext,
  });

export { handler as GET, handler as POST };
```

### Provider Setup

```typescript
// app/providers.tsx
'use client';

import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { httpBatchLink } from '@trpc/client';
import { useState } from 'react';
import { trpc } from './trpc';

export function Providers({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(() => new QueryClient());
  const [trpcClient] = useState(() =>
    trpc.createClient({
      links: [httpBatchLink({ url: '/api/trpc' })],
    })
  );

  return (
    <trpc.Provider client={trpcClient} queryClient={queryClient}>
      <QueryClientProvider client={queryClient}>
        {children}
      </QueryClientProvider>
    </trpc.Provider>
  );
}
```

## Testing

### Unit Testing with Caller

```typescript
import { createCaller } from '../routers';

describe('User Router', () => {
  it('should create user', async () => {
    const caller = createCaller({
      db: mockDb,
      session: null,
    });

    const result = await caller.user.create({
      name: 'Alice',
      email: 'alice@example.com',
    });

    expect(result).toMatchObject({
      name: 'Alice',
      email: 'alice@example.com',
    });
  });
});
```

### Mocking Context for Protected Routes

```typescript
const authedCaller = createCaller({
  db: mockDb,
  session: {
    user: { id: '1', email: 'alice@example.com' },
  },
});

it('should get current user', async () => {
  const user = await authedCaller.user.getMe();
  expect(user.name).toBe('Alice');
});
```

## TypeScript Inference Patterns

```typescript
import type { inferRouterInputs, inferRouterOutputs } from '@trpc/server';
import type { AppRouter } from './server';

// Extract input/output types from any procedure
type RouterInputs = inferRouterInputs<AppRouter>;
type RouterOutputs = inferRouterOutputs<AppRouter>;

type CreateUserInput = RouterInputs['user']['create'];
type User = RouterOutputs['user']['getById'];

// Use in components for prop typing
function UserCard({ user }: { user: User }) {
  return <div>{user.name}</div>;
}
```

## Best Practices

### ✅ DO

- Export `type AppRouter`, never the router implementation, to the client.
- Use Zod schemas for all input validation — they give you runtime safety AND TypeScript types.
- Create reusable procedure builders (`protectedProcedure`, `adminProcedure`) via middleware.
- Organize routers by domain (user, post, admin) in separate files.
- Use `httpBatchLink` to reduce HTTP requests — multiple queries become one round-trip.
- Set `staleTime` on React Query hooks to avoid unnecessary refetches.
- Share Zod schemas between client and server for form validation.
- Use `inferRouterInputs`/`inferRouterOutputs` for component prop types.

### ❌ DON'T

- Import server code into client bundles — only import `type` from the server.
- Skip input validation — even with TypeScript, runtime validation catches bad data.
- Put heavy computation in context creation — keep it lazy.
- Use tRPC for public APIs consumed by non-TypeScript clients.
- Nest routers more than 2 levels deep — it hurts discoverability.
- Forget cache invalidation after mutations — stale data is a common bug.
- Use `.output()` validation on every procedure — it adds runtime overhead. Reserve for critical data.
- Expose internal error details in production — sanitize with `errorFormatter`.
