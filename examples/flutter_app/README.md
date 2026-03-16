# Flutter App Example

A Flutter application demonstrating the full `comon_logger` ecosystem:

- **comon_logger** — core logging (levels, layers, types, filters, formatters)
- **comon_logger_flutter** — in-app log viewer (`ComonLoggerScreen`) with history handler
- **comon_logger_dio** — automatic HTTP request/response logging via Dio interceptor
- **comon_logger_dio_flutter** — rich HTTP log rendering in the log viewer
- **comon_logger_navigation_flutter** — automatic route navigation logging
- **comon_logger_file** — persistent file-based logging with rotation
- **comon_logger_share_flutter** — share/export logs as text or JSON

## Getting Started

```bash
cd examples/flutter_app
flutter pub get
flutter run
```

## Features

| Button | What it does |
|---|---|
| **Log at every level** | Emits FINEST → SHOUT with different layers/types |
| **Log an error** | Catches an exception and logs it at SEVERE with stack trace |
| **GET / POST / 404** | Fires Dio requests — interceptor logs request & response |
| **Push details page** | Navigator observer logs push & pop transitions |
| **Open log viewer** | Full `ComonLoggerScreen` with search, filters, renderers |
| **Clear logs** | Wipes the in-memory history |
