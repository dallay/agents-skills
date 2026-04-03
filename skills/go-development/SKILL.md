---
name: go-development
version: 1.0.0
description: >
  Go (Golang) best practices, patterns, and idioms for building reliable, performant applications.
triggers:
  - "Go project"
  - "Golang"
  - "go.mod"
  - "goroutines"
  - "Go error handling"
---

# Go Development

Production patterns and idioms for Go programming, covering project structure, error handling,
concurrency, interfaces, testing, and module management.

## When to Use This Skill

- Starting or structuring a Go project
- Writing idiomatic Go error handling
- Working with goroutines and channels
- Designing interfaces and composable packages
- Writing tests with `go test`
- Managing dependencies with Go modules
- Using context for cancellation and propagation

## Core Concepts

### 1. Project Layout

```
myapp/
├── cmd/
│   └── myapp/
│       └── main.go          # Entry point
├── internal/                 # Private packages (not importable externally)
│   ├── handler/
│   │   └── handler.go
│   ├── service/
│   │   └── service.go
│   └── repository/
│       └── repository.go
├── pkg/                      # Public reusable packages
│   └── httputil/
│       └── response.go
├── go.mod
├── go.sum
├── Makefile
└── README.md
```

### 2. Key Principles

| Principle              | Go Idiom                                           |
|------------------------|----------------------------------------------------|
| Error handling         | Return `error` as last value, check immediately    |
| Composition            | Embed interfaces, not structs                      |
| Concurrency            | Share memory by communicating (channels)            |
| Simplicity             | Fewer abstractions, explicit over implicit          |
| Zero values            | Design types so zero value is useful                |

## Quick Start

```bash
# Initialize a new module
go mod init github.com/user/myapp

# Add dependencies
go get github.com/gin-gonic/gin@latest

# Tidy dependencies
go mod tidy

# Build and run
go build -o myapp ./cmd/myapp
go run ./cmd/myapp

# Run tests
go test ./...
go test -v -race -count=1 ./...
```

## Patterns

### Pattern 1: Error Handling

```go
package service

import (
    "errors"
    "fmt"
)

// Define sentinel errors for comparison
var (
    ErrNotFound     = errors.New("not found")
    ErrUnauthorized = errors.New("unauthorized")
)

// Custom error type with context
type ValidationError struct {
    Field   string
    Message string
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation failed on %s: %s", e.Field, e.Message)
}

// Wrap errors with context using %w
func GetUser(id string) (*User, error) {
    user, err := db.Find(id)
    if err != nil {
        return nil, fmt.Errorf("GetUser(%s): %w", id, err)
    }
    if user == nil {
        return nil, fmt.Errorf("GetUser(%s): %w", id, ErrNotFound)
    }
    return user, nil
}

// Check wrapped errors with errors.Is and errors.As
func HandleRequest(id string) error {
    user, err := GetUser(id)
    if err != nil {
        if errors.Is(err, ErrNotFound) {
            return writeNotFound()
        }
        var validErr *ValidationError
        if errors.As(err, &validErr) {
            return writeBadRequest(validErr.Field, validErr.Message)
        }
        return fmt.Errorf("handling request: %w", err)
    }
    return writeJSON(user)
}
```

### Pattern 2: Goroutines and Channels

```go
package worker

import (
    "context"
    "fmt"
    "sync"
)

// Fan-out/fan-in with worker pool
func ProcessItems(ctx context.Context, items []string, workers int) []Result {
    jobs := make(chan string, len(items))
    results := make(chan Result, len(items))

    // Start workers
    var wg sync.WaitGroup
    for i := 0; i < workers; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            for item := range jobs {
                select {
                case <-ctx.Done():
                    return
                default:
                    results <- process(item)
                }
            }
        }()
    }

    // Send jobs
    for _, item := range items {
        jobs <- item
    }
    close(jobs)

    // Wait and close results
    go func() {
        wg.Wait()
        close(results)
    }()

    // Collect results
    var out []Result
    for r := range results {
        out = append(out, r)
    }
    return out
}

// Select for timeout and cancellation
func FetchWithTimeout(ctx context.Context, url string) (string, error) {
    ch := make(chan string, 1)
    errCh := make(chan error, 1)

    go func() {
        data, err := httpGet(url)
        if err != nil {
            errCh <- err
            return
        }
        ch <- data
    }()

    select {
    case data := <-ch:
        return data, nil
    case err := <-errCh:
        return "", err
    case <-ctx.Done():
        return "", fmt.Errorf("fetch %s: %w", url, ctx.Err())
    }
}
```

### Pattern 3: Interfaces and Composition

```go
package service

import "context"

// Small, focused interfaces (accept interfaces, return structs)
type UserReader interface {
    GetUser(ctx context.Context, id string) (*User, error)
}

type UserWriter interface {
    SaveUser(ctx context.Context, user *User) error
    DeleteUser(ctx context.Context, id string) error
}

// Compose interfaces
type UserRepository interface {
    UserReader
    UserWriter
}

// Depend on the smallest interface needed
type UserService struct {
    reader UserReader  // Only needs read access
}

func NewUserService(reader UserReader) *UserService {
    return &UserService{reader: reader}
}

func (s *UserService) GetProfile(ctx context.Context, id string) (*Profile, error) {
    user, err := s.reader.GetUser(ctx, id)
    if err != nil {
        return nil, fmt.Errorf("getting profile: %w", err)
    }
    return toProfile(user), nil
}
```

### Pattern 4: Context Propagation

```go
package middleware

import (
    "context"
    "net/http"
)

type contextKey string

const userIDKey contextKey = "userID"

// Store values in context
func AuthMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        userID, err := validateToken(r.Header.Get("Authorization"))
        if err != nil {
            http.Error(w, "unauthorized", http.StatusUnauthorized)
            return
        }
        ctx := context.WithValue(r.Context(), userIDKey, userID)
        next.ServeHTTP(w, r.WithContext(ctx))
    })
}

// Retrieve values from context
func UserIDFromContext(ctx context.Context) (string, bool) {
    id, ok := ctx.Value(userIDKey).(string)
    return id, ok
}

// Pass context through the call chain — always first parameter
func (s *Service) DoWork(ctx context.Context, input Input) error {
    ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
    defer cancel()

    return s.repo.Save(ctx, input)
}
```

### Pattern 5: Testing

```go
package service_test

import (
    "context"
    "errors"
    "testing"

    "github.com/user/myapp/internal/service"
)

// Table-driven tests
func TestGetProfile(t *testing.T) {
    tests := []struct {
        name    string
        userID  string
        mock    *mockReader
        want    *service.Profile
        wantErr error
    }{
        {
            name:   "success",
            userID: "123",
            mock:   &mockReader{user: &service.User{ID: "123", Name: "Alice"}},
            want:   &service.Profile{ID: "123", DisplayName: "Alice"},
        },
        {
            name:    "not found",
            userID:  "999",
            mock:    &mockReader{err: service.ErrNotFound},
            wantErr: service.ErrNotFound,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            svc := service.NewUserService(tt.mock)
            got, err := svc.GetProfile(context.Background(), tt.userID)

            if tt.wantErr != nil {
                if !errors.Is(err, tt.wantErr) {
                    t.Errorf("want error %v, got %v", tt.wantErr, err)
                }
                return
            }
            if err != nil {
                t.Fatalf("unexpected error: %v", err)
            }
            if got.ID != tt.want.ID {
                t.Errorf("want ID %s, got %s", tt.want.ID, got.ID)
            }
        })
    }
}

// Mock by implementing the interface
type mockReader struct {
    user *service.User
    err  error
}

func (m *mockReader) GetUser(_ context.Context, _ string) (*service.User, error) {
    return m.user, m.err
}

// Test helpers
func TestMain(m *testing.M) {
    // Setup/teardown for entire package
    os.Exit(m.Run())
}
```

### Pattern 6: Defer, Panic, Recover

```go
package resource

import (
    "fmt"
    "io"
    "os"
)

// Defer for cleanup — executes LIFO on function exit
func ReadFile(path string) ([]byte, error) {
    f, err := os.Open(path)
    if err != nil {
        return nil, fmt.Errorf("opening %s: %w", path, err)
    }
    defer f.Close()

    return io.ReadAll(f)
}

// Capture close errors with named returns
func WriteFile(path string, data []byte) (err error) {
    f, err := os.Create(path)
    if err != nil {
        return fmt.Errorf("creating %s: %w", path, err)
    }
    defer func() {
        if cerr := f.Close(); cerr != nil && err == nil {
            err = fmt.Errorf("closing %s: %w", path, cerr)
        }
    }()

    _, err = f.Write(data)
    return err
}

// Recover from panics at API boundaries only
func SafeHandler(fn func()) {
    defer func() {
        if r := recover(); r != nil {
            fmt.Printf("recovered from panic: %v\n", r)
        }
    }()
    fn()
}
```

## Best Practices

### Do's

- **Return errors** — Check every error immediately after the call
- **Use `fmt.Errorf` with `%w`** — For wrapping errors with context
- **Accept interfaces, return structs** — Keeps APIs flexible
- **Use `context.Context`** — As first parameter for cancellation and deadlines
- **Write table-driven tests** — Cover edge cases systematically
- **Use `sync.WaitGroup`** — To coordinate goroutine completion
- **Prefer `make` and `len`** — Over manual capacity management
- **Run `go vet` and `staticcheck`** — Catch bugs before runtime

### Don'ts

- **Don't ignore errors** — `_ = doSomething()` hides bugs
- **Don't use `panic` for control flow** — Reserve for truly unrecoverable states
- **Don't overuse `interface{}`/`any`** — Use generics (Go 1.18+) or typed interfaces
- **Don't leak goroutines** — Always provide a way to stop (context, done channel)
- **Don't use `init()` heavily** — Makes testing and reasoning harder
- **Don't embed mutexes in exported structs** — Keep synchronization internal

## Resources

- [Effective Go](https://go.dev/doc/effective_go)
- [Go Code Review Comments](https://github.com/golang/go/wiki/CodeReviewComments)
- [Standard Project Layout](https://github.com/golang-standards/project-layout)
- [Go Proverbs](https://go-proverbs.github.io/)
