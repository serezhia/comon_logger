# comon_logger_flutter

Flutter UI package for `comon_logger` with an in-app log screen,
`HistoryLogHandler`, filters, search, and expandable details.

## Features

- `HistoryLogHandler` for in-memory log history + live stream
- `ComonLoggerScreen` for viewing logs inside the app
- Search and filter by level, layer, type, feature, and logger name
- Expandable cards with error, stack trace, and extra payload
- Pluggable actions like import and share

## Installation

```bash
flutter pub add comon_logger_flutter
```

## Quick Start

```dart
import 'package:comon_logger/comon_logger.dart';
import 'package:comon_logger_flutter/comon_logger_flutter.dart';
import 'package:flutter/material.dart';

final historyHandler = HistoryLogHandler(maxHistory: 2000);

void initLogging() {
  Logger.root.addHandler(ConsoleLogHandler());
  Logger.root.addHandler(historyHandler);
}

void openLogs(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ComonLoggerScreen(
        handler: historyHandler,
        actions: const [ImportLogsAction()],
      ),
    ),
  );
}
```

## Included components

| Component | Purpose |
|-----------|---------|
| `HistoryLogHandler` | Stores log history for the current app session |
| `ComonLoggerScreen` | Full-screen log browser for Flutter |
| `ImportLogsAction` | Built-in import action for JSON logs |

## Viewer behavior

- Newest-first list by default
- Screen opens at the top of the list
- Incoming logs do not shift the current viewport when auto-scroll is off
- Search across message, logger name, and error text
- Filter chips for `LogLevel`, `LogLayer`, and `LogType`
- Long-press copy support
- Expand/collapse cards for full details

## Composing renderers and actions

```dart
ComonLoggerScreen(
  handler: historyHandler,
  renderers: const [
    HttpLogRecordRenderer(showRequest: false),
  ],
  initialFilter: LogFilterState(
    loggerNameQuery: 'dio',
    types: {LogType.network},
  ),
  actions: const [
    ImportLogsAction(),
    ShareLogsAction(),
  ],
)
```

## Related packages

| Package | Role |
|---------|------|
| `comon_logger_flutter` | Base Flutter log viewer and history storage |
| `comon_logger_dio_flutter` | HTTP-specific log rendering |
| `comon_logger_share_flutter` | Share/export action |
| `comon_logger_navigation_flutter` | Navigation actor + UI integration |
