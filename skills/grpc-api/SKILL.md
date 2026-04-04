---
name: grpc-api
description: >-
  Build high-performance gRPC services with Protocol Buffers, streaming patterns, and
  microservice communication in Node.js and polyglot environments. Use when the task
  involves `gRPC server or client`, `Protocol Buffers`, `protobuf service definition`,
  `gRPC streaming`, `microservice communication`, or `inter-service APIs`.
license: MIT
metadata:
  version: "1.0.0"
---
# gRPC API Development

Build efficient gRPC services using Protocol Buffers for contract-first API design, with support for
unary calls, server streaming, client streaming, and bidirectional streaming.

## When to Use

- Building microservices that require high-performance binary communication.
- Defining strict service contracts with Protocol Buffers (`.proto` files).
- Implementing real-time bidirectional or server-push streaming.
- Creating internal service-to-service APIs in polyglot architectures.
- Optimizing bandwidth in constrained or high-throughput environments.

## Critical Patterns

- **Contract First:** Always define your `.proto` file before writing any server or client code. The proto IS your API contract.
- **Use Proper Status Codes:** Map domain errors to gRPC status codes (`NOT_FOUND`, `ALREADY_EXISTS`, `INVALID_ARGUMENT`, etc.). Never return raw exceptions.
- **Field Numbering is Forever:** Once a proto field number is assigned and released, NEVER reuse it. Add new fields with new numbers; deprecate old ones.
- **Streaming for Large Data:** Use server streaming for large result sets and client streaming for bulk uploads. Avoid sending massive unary payloads.
- **Deadlines Over Timeouts:** Always set deadlines on client calls. A missing deadline can hang forever in production.
- **TLS in Production:** Never use `createInsecure()` credentials outside of local development.
- **Keep Messages Flat:** Avoid deeply nested message types. Flatten where possible for better wire efficiency and readability.

## Proto Definition Patterns

### Complete Service Definition

```protobuf
syntax = "proto3";

package user.service;

message User {
  string id = 1;
  string email = 2;
  string first_name = 3;
  string last_name = 4;
  string role = 5;
  int64 created_at = 6;
  int64 updated_at = 7;
}

message CreateUserRequest {
  string email = 1;
  string first_name = 2;
  string last_name = 3;
  string role = 4;
}

message UpdateUserRequest {
  string id = 1;
  string email = 2;
  string first_name = 3;
  string last_name = 4;
}

message GetUserRequest {
  string id = 1;
}

message ListUsersRequest {
  int32 page = 1;
  int32 limit = 2;
}

message ListUsersResponse {
  repeated User users = 1;
  int32 total = 2;
  int32 page = 3;
}

message DeleteUserRequest {
  string id = 1;
}

message Empty {}

// Four RPC patterns: unary, server streaming, client streaming, bidirectional
service UserService {
  rpc GetUser(GetUserRequest) returns (User);              // Unary
  rpc ListUsers(ListUsersRequest) returns (ListUsersResponse); // Unary
  rpc CreateUser(CreateUserRequest) returns (User);        // Unary
  rpc UpdateUser(UpdateUserRequest) returns (User);        // Unary
  rpc DeleteUser(DeleteUserRequest) returns (Empty);       // Unary
  rpc StreamUsers(Empty) returns (stream User);            // Server streaming
  rpc BulkCreateUsers(stream CreateUserRequest) returns (ListUsersResponse); // Client streaming
}
```

### Event Streaming Service

```protobuf
message Event {
  string type = 1;
  string user_id = 2;
  string data = 3;
  int64 timestamp = 4;
}

service EventService {
  rpc Subscribe(Empty) returns (stream Event);   // Server streaming
  rpc PublishEvent(Event) returns (Empty);        // Unary
}
```

## Node.js Server Implementation

### Loading Proto and Implementing Handlers

```javascript
const grpc = require("@grpc/grpc-js");
const protoLoader = require("@grpc/proto-loader");
const path = require("path");

const packageDef = protoLoader.loadSync(path.join(__dirname, "user.proto"), {
  keepCase: true,
  longs: String,
  enums: String,
  defaults: true,
  oneofs: true,
});

const userProto = grpc.loadPackageDefinition(packageDef).user.service;

const users = new Map();
let userIdCounter = 1;

const userServiceImpl = {
  // Unary RPC — single request, single response
  getUser: (call, callback) => {
    const user = users.get(call.request.id);
    if (!user) {
      return callback({
        code: grpc.status.NOT_FOUND,
        details: "User not found",
      });
    }
    callback(null, user);
  },

  // Unary with pagination
  listUsers: (call, callback) => {
    const page = call.request.page || 1;
    const limit = call.request.limit || 20;
    const offset = (page - 1) * limit;

    const userArray = Array.from(users.values());
    const paginatedUsers = userArray.slice(offset, offset + limit);

    callback(null, {
      users: paginatedUsers,
      total: userArray.length,
      page: page,
    });
  },

  // Unary — create with auto ID
  createUser: (call, callback) => {
    const id = String(userIdCounter++);
    const user = {
      id,
      email: call.request.email,
      first_name: call.request.first_name,
      last_name: call.request.last_name,
      role: call.request.role,
      created_at: Date.now(),
      updated_at: Date.now(),
    };
    users.set(id, user);
    callback(null, user);
  },

  // Server streaming — push all users to client
  streamUsers: (call) => {
    Array.from(users.values()).forEach((user) => {
      call.write(user);
    });
    call.end();
  },

  // Client streaming — receive bulk data, respond once
  bulkCreateUsers: (call, callback) => {
    const createdUsers = [];

    call.on("data", (request) => {
      const id = String(userIdCounter++);
      const user = {
        id,
        email: request.email,
        first_name: request.first_name,
        last_name: request.last_name,
        role: request.role,
        created_at: Date.now(),
        updated_at: Date.now(),
      };
      users.set(id, user);
      createdUsers.push(user);
    });

    call.on("end", () => {
      callback(null, {
        users: createdUsers,
        total: createdUsers.length,
        page: 1,
      });
    });

    call.on("error", (err) => {
      callback(err);
    });
  },
};

// Start the server
const server = new grpc.Server();
server.addService(userProto.UserService.service, userServiceImpl);

server.bindAsync(
  "0.0.0.0:50051",
  grpc.ServerCredentials.createInsecure(),
  () => {
    console.log("gRPC server running on port 50051");
  },
);
```

## Client Implementation

### Unary, Server Streaming, and Client Streaming Calls

```javascript
const grpc = require("@grpc/grpc-js");
const protoLoader = require("@grpc/proto-loader");
const path = require("path");

const packageDef = protoLoader.loadSync(path.join(__dirname, "user.proto"));
const userProto = grpc.loadPackageDefinition(packageDef).user.service;

const client = new userProto.UserService(
  "localhost:50051",
  grpc.credentials.createInsecure(),
);

// Unary call
client.getUser({ id: "123" }, (err, user) => {
  if (err) console.error(err);
  console.log("User:", user);
});

// Server streaming — receive multiple messages
const stream = client.streamUsers({});
stream.on("data", (user) => {
  console.log("Received user:", user);
});
stream.on("end", () => {
  console.log("Stream ended");
});

// Client streaming — send multiple messages, receive one response
const writeStream = client.bulkCreateUsers((err, response) => {
  if (err) console.error(err);
  console.log("Created users:", response.users.length);
});

writeStream.write({
  email: "user1@example.com",
  first_name: "John",
  last_name: "Doe",
});
writeStream.write({
  email: "user2@example.com",
  first_name: "Jane",
  last_name: "Smith",
});
writeStream.end();
```

### Client with Deadlines and Metadata

```javascript
// Always set deadlines in production
const deadline = new Date();
deadline.setSeconds(deadline.getSeconds() + 5); // 5-second deadline

const metadata = new grpc.Metadata();
metadata.add("x-request-id", "abc-123");
metadata.add("authorization", "Bearer token-here");

client.getUser({ id: "123" }, metadata, { deadline }, (err, user) => {
  if (err) {
    if (err.code === grpc.status.DEADLINE_EXCEEDED) {
      console.error("Request timed out");
    }
    return;
  }
  console.log("User:", user);
});
```

## gRPC Status Codes Reference

| Code | Name | When to Use |
|------|------|-------------|
| 0 | `OK` | Success |
| 3 | `INVALID_ARGUMENT` | Bad input from client |
| 5 | `NOT_FOUND` | Resource does not exist |
| 6 | `ALREADY_EXISTS` | Duplicate creation attempt |
| 7 | `PERMISSION_DENIED` | Authenticated but not authorized |
| 13 | `INTERNAL` | Unexpected server error |
| 14 | `UNAVAILABLE` | Transient failure, client should retry |
| 16 | `UNAUTHENTICATED` | Missing or invalid credentials |

## Best Practices

### ✅ DO

- Define `.proto` files first — they are your single source of truth.
- Use clear, descriptive message and service naming (`CreateUserRequest`, not `Req1`).
- Implement proper error handling with gRPC status codes on every handler.
- Add metadata for request tracing (request ID, correlation ID).
- Version your protobuf definitions — never break backwards compatibility.
- Use server streaming for large datasets instead of massive unary responses.
- Set deadlines on every client call.
- Use TLS credentials in production (`grpc.ServerCredentials.createSsl()`).
- Monitor gRPC metrics (latency, error rates, stream counts).

### ❌ DON'T

- Use gRPC directly from browsers — use gRPC-Web or a REST gateway instead.
- Reuse or reassign proto field numbers after they have been published.
- Create deeply nested message types — keep messages flat and composable.
- Ignore error status codes or return generic `INTERNAL` for all failures.
- Send uncompressed large payloads — enable gzip with `grpc.compression`.
- Skip TLS in production — always encrypt service-to-service traffic.
- Use `createInsecure()` credentials outside of local development.
- Expose internal implementation details in proto definitions.
