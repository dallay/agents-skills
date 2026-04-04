---
name: zig-development
description: >-
  Zig systems programming best practices, patterns, and idioms for safe, performant
  low-level code. Use when the task involves `Zig project`, `build.zig`, `Zig
  programming`, or `systems programming with Zig`.
license: MIT
metadata:
  version: "1.0.0"
---
# Zig Development

Production patterns for Zig systems programming, covering the build system, comptime, error
handling, allocators, testing, and C interop.

## When to Use This Skill

- Starting or structuring a Zig project
- Working with the `build.zig` build system
- Using comptime for compile-time computation
- Handling errors with error unions
- Choosing and using allocators
- Writing tests in Zig
- Interfacing with C libraries

## Core Concepts

### 1. Project Layout

```
myapp/
├── src/
│   ├── main.zig              # Entry point
│   ├── lib.zig               # Library root (public API)
│   ├── parser.zig
│   └── network/
│       ├── client.zig
│       └── protocol.zig
├── build.zig                 # Build configuration
├── build.zig.zon             # Package manifest (dependencies)
└── README.md
```

### 2. Key Principles

| Principle         | Zig Idiom                                          |
|-------------------|----------------------------------------------------|
| No hidden control | No hidden allocations, no operator overloading      |
| Explicit errors   | Error unions force handling at every call site       |
| Comptime          | Generics and metaprogramming via compile-time eval   |
| Manual memory     | Choose allocator per context; no GC                  |
| C interop         | Direct `@cImport` with zero overhead                 |

## Quick Start

```bash
# Initialize a new project
zig init

# Build
zig build

# Build and run
zig build run

# Run tests
zig build test

# Run a single file
zig run src/main.zig

# Format
zig fmt src/
```

## Patterns

### Pattern 1: Build System (build.zig)

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Library
    const lib = b.addStaticLibrary(.{
        .name = "mylib",
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Link C library
    lib.linkSystemLibrary("sqlite3");
    lib.linkLibC();

    b.installArtifact(lib);

    // Executable
    const exe = b.addExecutable(.{
        .name = "myapp",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.linkLibrary(lib);
    b.installArtifact(exe);

    // Run step
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_cmd.step);

    // Tests
    const lib_tests = b.addTest(.{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_lib_tests = b.addRunArtifact(lib_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_tests.step);
}
```

### Pattern 2: Error Handling

```zig
const std = @import("std");

// Define error sets
const ParseError = error{
    InvalidFormat,
    UnexpectedToken,
    EndOfInput,
};

const FileError = error{
    NotFound,
    PermissionDenied,
};

// Error union: return type!value
fn parseNumber(input: []const u8) ParseError!i64 {
    if (input.len == 0) return error.EndOfInput;

    return std.fmt.parseInt(i64, input, 10) catch {
        return error.InvalidFormat;
    };
}

// Propagate errors with try (equivalent to catch |err| return err)
fn loadConfig(path: []const u8) !Config {
    const file = std.fs.cwd().openFile(path, .{}) catch |err| {
        std.log.err("Failed to open {s}: {}", .{ path, err });
        return err;
    };
    defer file.close();

    const content = try file.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(content);

    return try parseConfig(content);
}

// errdefer — cleanup only on error path
fn createResource(allocator: std.mem.Allocator) !*Resource {
    const resource = try allocator.create(Resource);
    errdefer allocator.destroy(resource);

    resource.* = .{
        .data = try allocator.alloc(u8, 1024),
        .state = .initialized,
    };
    errdefer allocator.free(resource.data);

    try resource.validate();
    return resource;
}

// Handle or provide defaults
fn getPort() u16 {
    return parseNumber("8080") catch 3000;
}
```

### Pattern 3: Comptime (Compile-Time Computation)

```zig
const std = @import("std");

// Generic data structure using comptime
fn BoundedArray(comptime T: type, comptime capacity: usize) type {
    return struct {
        const Self = @This();

        items: [capacity]T = undefined,
        len: usize = 0,

        pub fn append(self: *Self, item: T) !void {
            if (self.len >= capacity) return error.Overflow;
            self.items[self.len] = item;
            self.len += 1;
        }

        pub fn slice(self: *const Self) []const T {
            return self.items[0..self.len];
        }

        pub fn pop(self: *Self) ?T {
            if (self.len == 0) return null;
            self.len -= 1;
            return self.items[self.len];
        }
    };
}

// Usage
var buffer = BoundedArray(u8, 256){};
try buffer.append(42);

// Comptime string formatting and validation
fn fieldName(comptime prefix: []const u8, comptime name: []const u8) []const u8 {
    return prefix ++ "_" ++ name;
}

// Comptime type reflection
fn serialize(value: anytype) ![]const u8 {
    const T = @TypeOf(value);
    const info = @typeInfo(T);

    switch (info) {
        .@"struct" => |s| {
            // Iterate struct fields at comptime
            inline for (s.fields) |field| {
                const field_value = @field(value, field.name);
                // Process each field...
                _ = field_value;
            }
        },
        else => @compileError("serialize only supports structs"),
    }

    return "{}";
}
```

### Pattern 4: Allocators

```zig
const std = @import("std");

// Choose allocator based on context
pub fn main() !void {
    // General-purpose allocator (good default)
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Arena allocator — bulk free, great for request-scoped work
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const arena_alloc = arena.allocator();

    // Fixed buffer allocator — no heap, stack-only
    var buf: [4096]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buf);
    const stack_alloc = fba.allocator();

    // Pass allocator to functions that need it
    const result = try processData(allocator, input);
    defer allocator.free(result);
}

// Accept allocator as parameter — Zig convention
fn processData(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    var list = std.ArrayList(u8).init(allocator);
    defer list.deinit();

    try list.appendSlice(input);
    try list.appendSlice(" processed");

    return try list.toOwnedSlice();
}

// Allocator comparison
// | Allocator             | Use Case                        |
// |-----------------------|---------------------------------|
// | GeneralPurpose        | Default, general use            |
// | ArenaAllocator        | Request scope, batch processing |
// | FixedBufferAllocator  | Stack-only, no heap             |
// | page_allocator        | Large allocations               |
// | c_allocator           | C interop                       |
```

### Pattern 5: Optional Types and Slices

```zig
const std = @import("std");

// Optionals — null safety built into the type system
fn findUser(users: []const User, id: u64) ?*const User {
    for (users) |*user| {
        if (user.id == id) return user;
    }
    return null;
}

// Unwrap with orelse for defaults
const user = findUser(users, 42) orelse &default_user;

// Unwrap with if for conditional logic
if (findUser(users, 42)) |user| {
    std.debug.print("Found: {s}\n", .{user.name});
} else {
    std.debug.print("User not found\n", .{});
}

// Slices vs pointers
fn processSlice(data: []const u8) void {
    // Slice = pointer + length (bounds-checked)
    for (data) |byte| {
        _ = byte;
    }
}

fn processMany(data: [*]const u8, len: usize) void {
    // Many-item pointer — no bounds info (for C interop)
    const slice = data[0..len]; // Convert to slice for safety
    processSlice(slice);
}

// Sentinel-terminated slices (for C strings)
fn printCString(s: [*:0]const u8) void {
    const slice = std.mem.span(s);
    std.debug.print("{s}\n", .{slice});
}
```

### Pattern 6: Testing

```zig
const std = @import("std");
const testing = std.testing;

// Tests live alongside the code they test
const Parser = @import("parser.zig");

test "parse valid number" {
    const result = try Parser.parseNumber("42");
    try testing.expectEqual(@as(i64, 42), result);
}

test "parse empty input returns error" {
    const result = Parser.parseNumber("");
    try testing.expectError(error.EndOfInput, result);
}

test "bounded array append and pop" {
    var arr = BoundedArray(u32, 4){};

    try arr.append(10);
    try arr.append(20);
    try arr.append(30);

    try testing.expectEqual(@as(usize, 3), arr.len);
    try testing.expectEqual(@as(?u32, 30), arr.pop());
    try testing.expectEqual(@as(usize, 2), arr.len);
}

test "bounded array overflow" {
    var arr = BoundedArray(u8, 2){};
    try arr.append(1);
    try arr.append(2);

    try testing.expectError(error.Overflow, arr.append(3));
}

test "allocator usage" {
    // Use testing allocator — detects leaks
    const allocator = testing.allocator;

    const data = try allocator.alloc(u8, 100);
    defer allocator.free(data);

    @memset(data, 0);
    try testing.expect(data[0] == 0);
    try testing.expect(data.len == 100);
}

// C interop test
test "call C function" {
    const c = @cImport({
        @cInclude("string.h");
    });

    const result = c.strlen("hello");
    try testing.expectEqual(@as(usize, 5), result);
}
```

## Best Practices

### Do's

- **Use `defer` and `errdefer`** — For deterministic cleanup on every code path
- **Pass allocators explicitly** — Never use a global allocator
- **Use `try` to propagate errors** — Keep error handling explicit
- **Leverage comptime** — For generic types and compile-time validation
- **Use the testing allocator** — Catches memory leaks in tests
- **Use slices over pointers** — Bounds-checked by default
- **Use `std.log`** — For structured diagnostic output

### Don'ts

- **Don't ignore error returns** — Use `_ = foo()` only when truly intentional
- **Don't cast away `const`** — Respect const-correctness
- **Don't use `@intToPtr`/`@ptrToInt` casually** — Unsafe; limit to C interop boundaries
- **Don't allocate in tight loops without arenas** — Heap fragmentation and perf loss
- **Don't use `undefined` without initializing** — Debug builds catch this, release won't
- **Don't `@panic` in library code** — Return errors and let the caller decide

## Resources

- [Zig Language Reference](https://ziglang.org/documentation/master/)
- [Zig Standard Library Docs](https://ziglang.org/documentation/master/std/)
- [Zig Learn](https://ziglearn.org/)
- [Zig Cookbook](https://cookbook.ziglang.cc/)
