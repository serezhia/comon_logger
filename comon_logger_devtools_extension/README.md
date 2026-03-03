# comon_logger_devtools_extension

DevTools extension for **comon_logger** — a live log viewer with filters,
integrated into Flutter DevTools.

## How it works

When your Flutter app uses `comon_logger_flutter` with
`ComonLoggerServiceExtension.register()`, this DevTools extension:

1. **Loads history** via `ext.comon_logger.getHistory` service extension
2. **Streams live logs** via `comon_logger:log` post events
3. **Displays** a filterable, searchable list of log records

## Features

- **Live streaming** of log records from the connected app
- **Pause/Resume** live log stream
- **Filter** by Level, Layer, Type, Feature, Logger name
- **Search** through log messages
- **Auto-scroll** to latest logs
- **Expandable details** — click a log entry to see error, stack trace, and extra data
- **Clear** logs (locally and remotely)

## UI Layout

```
┌─────────────────────────────────────────────┐
│ [Clear] [Pause] [AutoScroll] [Filter] [Search...] │  ← Toolbar
├─────────────────────────────────────────────┤
│ Level: [FINE] [INFO] [WARNING] ...          │  ← Filter Panel
│ Layer: [data] [domain] [widgets] ...        │     (toggle)
│ Type: [network] [database] ...              │
│ Feature: [____]  Logger: [____]  [Reset]    │
├─────────────────────────────────────────────┤
│ ● Connected  |  Showing 42 of 150           │  ← Status Bar
├─────────────────────────────────────────────┤
│ 12:00:01.234 INFO  dio.request  GET /api... │  ← Log List
│ 12:00:01.567 WARN  app  Something happened  │
│ ...                                         │
└─────────────────────────────────────────────┘
```

## Building

```bash
cd comon_logger_devtools_extension
flutter build web --release --output=extension/devtools/build
```

After building, the `extension/devtools/build/` directory contains the web
assets that DevTools loads automatically when your app has `comon_logger_flutter`
as a dependency.

## Requirements

- The connected app must register service extensions via
  `ComonLoggerServiceExtension(historyHandler).register()`
- `comon_logger_flutter` package must be in the app's dependency tree
