# Shelf App Example

A Dart server application demonstrating `comon_logger` for backend/server-side logging.

Uses **shelf** + **shelf_router** as the HTTP framework, with:

- **comon_logger** — core logging (levels, layers, types, filters, formatters)
- **comon_logger_file** — persistent file-based logging with automatic rotation

## Getting Started

```bash
cd examples/shelf_app
dart pub get
dart run bin/server.dart
```

The server starts on `http://localhost:8080`.

## Endpoints

| Method | Path | Description |
|---|---|---|
| GET | `/` | Welcome message |
| GET | `/health` | Health check |
| GET | `/users` | List mock users |
| GET | `/users/<id>` | Get single user (404 if not found) |
| POST | `/users` | Create a new user |
| GET | `/error` | Triggers a deliberate error to demonstrate error logging |

## Logging

All HTTP requests are automatically logged via the logging middleware:

- **Incoming requests** → `INFO` level
- **Successful responses** → `FINE` level with duration
- **Server errors (5xx)** → `SEVERE` level

Logs are written both to **console** (with pretty formatting) and to **file** (with rotation).
