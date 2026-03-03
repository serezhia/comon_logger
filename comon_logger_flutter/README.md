# comon_logger_flutter

Flutter UI for `comon_logger` — log viewer screen with filters.

## Features

- **HistoryLogHandler** — in-memory log storage with stream
- **ComonLoggerScreen** — full-screen log viewer with:
  - Multi-select filter chips for Level, Layer, Type
  - Text search across message, logger name, and error
  - Feature and logger name text filters
  - Tap to expand log details (error, stack trace, tags)
  - Long-press to copy to clipboard
  - Share and clear buttons
  - Auto-scroll to latest logs
- **DevTools service extension** — live log streaming to DevTools

## Setup

```dart
import 'package:comon_logger/comon_logger.dart';
import 'package:comon_logger_flutter/comon_logger_flutter.dart';

// During app initialization:
final historyHandler = HistoryLogHandler(maxHistory: 2000);
Logger.root.addHandler(historyHandler);
Logger.root.addHandler(ConsoleLogHandler());

// For DevTools streaming:
ComonLoggerServiceExtension(historyHandler).register();

// To open the log viewer:
Navigator.push(context, MaterialPageRoute(
  builder: (_) => ComonLoggerScreen(handler: historyHandler),
));
```
