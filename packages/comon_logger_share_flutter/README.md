# comon_logger_share_flutter

Share/export action package for `comon_logger_flutter`.

## Features

`ShareLogsAction` puts a share button into `ComonLoggerScreen` and exports logs
through the platform share sheet as plain text or JSON.

## Installation

```bash
flutter pub add comon_logger_share_flutter
```

## Quick Start

```dart
import 'package:comon_logger_flutter/comon_logger_flutter.dart';
import 'package:comon_logger_share_flutter/comon_logger_share_flutter.dart';

final historyHandler = HistoryLogHandler();

ComonLoggerScreen(
  handler: historyHandler,
  actions: const [
    ShareLogsAction(),
    ImportLogsAction(),
  ],
)
```

This keeps `comon_logger_flutter` free from the `share_plus` plugin unless you
explicitly opt into sharing.

## Export modes

- Share as formatted plain text for quick debugging
- Share as JSON for import back into `ComonLoggerScreen` or DevTools workflows

## Related packages

| Package | Adds |
|---------|------|
| `comon_logger_flutter` | The log viewer screen and action host |
| `comon_logger` | Core logger primitives used by exported records |
