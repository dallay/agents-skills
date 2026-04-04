---
name: express-api
description: >-
  Express.js server-side development patterns for building robust REST APIs with proper
  middleware chains, error handling, request validation, security hardening, and scalable
  project structure. Use when the task involves `Express.js`, `Express server`, `Express
  middleware`, `Node.js REST API`, or `Express routing`.
license: MIT
metadata:
  version: "1.0.0"
---
## When to Use

- Building or refactoring a REST API with Express.js.
- Setting up middleware chains for authentication, logging, or validation.
- Structuring an Express project for maintainability and testability.
- Adding security headers, rate limiting, or CORS configuration.
- Implementing centralized error handling across routes.

## Critical Patterns

- **Layered Architecture:** Separate routes → controllers → services → repositories. Routes define endpoints, controllers handle HTTP concerns, services contain business logic, repositories handle data access.
- **Centralized Error Handling:** NEVER scatter `try/catch` in every route. Use an async wrapper and a single error-handling middleware at the end of the middleware chain.
- **Validate at the Edge:** Validate ALL incoming data (body, params, query) at the route level using Zod or Joi BEFORE it reaches the controller.
- **Security by Default:** Always use `helmet`, configure `cors` explicitly (never `*` in production), and apply rate limiting to public endpoints.
- **Environment Config:** Use a validated config module. NEVER access `process.env` directly throughout the codebase.
- **Consistent Response Shape:** Every API response should follow the same envelope: `{ data, error, meta }`.

## Project Structure

```
src/
├── config/
│   └── env.ts              # Validated environment config
├── middleware/
│   ├── errorHandler.ts      # Centralized error handler
│   ├── validate.ts          # Request validation middleware
│   ├── auth.ts              # Authentication middleware
│   └── rateLimiter.ts       # Rate limiting config
├── routes/
│   ├── index.ts             # Route aggregator
│   └── users.routes.ts      # /users route definitions
├── controllers/
│   └── users.controller.ts  # HTTP concern handling
├── services/
│   └── users.service.ts     # Business logic
├── repositories/
│   └── users.repository.ts  # Data access
├── errors/
│   └── AppError.ts          # Custom error classes
├── utils/
│   └── asyncHandler.ts      # Async error wrapper
└── app.ts                   # Express app setup
```

## Code Examples

### App Setup with Security Middleware

```typescript
import express from "express";
import helmet from "helmet";
import cors from "cors";
import { rateLimit } from "express-rate-limit";
import { errorHandler } from "./middleware/errorHandler";
import { routes } from "./routes";

const app = express();

// Security middleware — order matters
app.use(helmet());
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(",") ?? [],
  credentials: true,
}));
app.use(rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
}));

// Body parsing
app.use(express.json({ limit: "10kb" }));
app.use(express.urlencoded({ extended: true }));

// Routes
app.use("/api/v1", routes);

// Health check — outside versioned routes
app.get("/health", (_req, res) => {
  res.json({ status: "ok" });
});

// Centralized error handler — MUST be last
app.use(errorHandler);

export { app };
```

### Async Error Wrapper

```typescript
import { Request, Response, NextFunction, RequestHandler } from "express";

// Wraps async route handlers so thrown errors reach the error middleware
export const asyncHandler = (
  fn: (req: Request, res: Response, next: NextFunction) => Promise<void>
): RequestHandler => {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};
```

### Custom Error Classes

```typescript
export class AppError extends Error {
  constructor(
    public readonly statusCode: number,
    public readonly message: string,
    public readonly isOperational = true,
  ) {
    super(message);
    Object.setPrototypeOf(this, new.target.prototype);
    Error.captureStackTrace(this);
  }
}

export class NotFoundError extends AppError {
  constructor(resource: string) {
    super(404, `${resource} not found`);
  }
}

export class ValidationError extends AppError {
  constructor(message: string) {
    super(400, message);
  }
}
```

### Centralized Error Handler

```typescript
import { Request, Response, NextFunction } from "express";
import { AppError } from "../errors/AppError";
import { ZodError } from "zod";

export function errorHandler(
  err: Error,
  _req: Request,
  res: Response,
  _next: NextFunction,
): void {
  // Zod validation errors
  if (err instanceof ZodError) {
    res.status(400).json({
      error: "Validation failed",
      details: err.errors.map((e) => ({
        path: e.path.join("."),
        message: e.message,
      })),
    });
    return;
  }

  // Known operational errors
  if (err instanceof AppError) {
    res.status(err.statusCode).json({ error: err.message });
    return;
  }

  // Unknown errors — don't leak internals
  console.error("Unhandled error:", err);
  res.status(500).json({ error: "Internal server error" });
}
```

### Request Validation with Zod

```typescript
import { Request, Response, NextFunction } from "express";
import { AnyZodObject, ZodError } from "zod";

export const validate = (schema: AnyZodObject) => {
  return (req: Request, _res: Response, next: NextFunction) => {
    try {
      schema.parse({
        body: req.body,
        query: req.query,
        params: req.params,
      });
      next();
    } catch (err) {
      next(err); // Caught by errorHandler
    }
  };
};

// Usage — define schemas per route
import { z } from "zod";

export const createUserSchema = z.object({
  body: z.object({
    email: z.string().email(),
    name: z.string().min(2).max(100),
    role: z.enum(["user", "admin"]).default("user"),
  }),
});
```

### Routes → Controller → Service Pattern

```typescript
// routes/users.routes.ts
import { Router } from "express";
import { asyncHandler } from "../utils/asyncHandler";
import { validate } from "../middleware/validate";
import { createUserSchema } from "../schemas/user.schema";
import * as controller from "../controllers/users.controller";

const router = Router();

router.get("/", asyncHandler(controller.list));
router.get("/:id", asyncHandler(controller.getById));
router.post("/", validate(createUserSchema), asyncHandler(controller.create));

export { router as usersRouter };
```

```typescript
// controllers/users.controller.ts
import { Request, Response } from "express";
import * as userService from "../services/users.service";

export async function list(_req: Request, res: Response): Promise<void> {
  const users = await userService.findAll();
  res.json({ data: users });
}

export async function getById(req: Request, res: Response): Promise<void> {
  const user = await userService.findById(req.params.id);
  res.json({ data: user });
}

export async function create(req: Request, res: Response): Promise<void> {
  const user = await userService.create(req.body);
  res.status(201).json({ data: user });
}
```

### Environment Config with Validation

```typescript
import { z } from "zod";

const envSchema = z.object({
  NODE_ENV: z.enum(["development", "production", "test"]).default("development"),
  PORT: z.coerce.number().default(3000),
  DATABASE_URL: z.string().url(),
  JWT_SECRET: z.string().min(32),
  ALLOWED_ORIGINS: z.string().default("http://localhost:3000"),
});

// Validate once at startup — fail fast
export const env = envSchema.parse(process.env);
```

## Best Practices

### DO

- Use `express.Router()` to modularize routes by domain.
- Return appropriate HTTP status codes: `201` for created, `204` for no-content, `404` for not found.
- Use API versioning in the URL path (`/api/v1/...`).
- Set `trust proxy` if behind a reverse proxy (for rate limiting and IP detection).
- Add request ID middleware for tracing across logs.
- Gracefully shut down: listen for `SIGTERM`/`SIGINT`, stop accepting new connections, drain existing ones.

### DON'T

- DON'T use `app.use(cors())` with no options — it allows all origins.
- DON'T put business logic in route handlers or controllers — keep it in services.
- DON'T return stack traces or internal error details in production responses.
- DON'T use `express.static` for user-uploaded files without path sanitization.
- DON'T use synchronous file operations (`fs.readFileSync`) in request handlers.
- DON'T call `res.json()` or `res.send()` more than once per request — it causes "headers already sent" errors.
- DON'T forget to call `next()` in non-terminal middleware — the request will hang.
