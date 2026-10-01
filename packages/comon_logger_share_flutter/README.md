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
- Share log files from disk (when `logFiles` is set), which also cover earlier
  sessions, such as the one that crashed

## Sharing log files

Pair it with `FileLogHandler` from `comon_logger_file`; flush first so the
latest lines are included:

```dart
ShareLogsAction(
  logFiles: () async {
    fileHandler.flush();
    return [for (final file in fileHandler.getLogFiles()) file.path];
  },
)
```

Files that no longer exist are skipped; with none left the action shows
`ShareLogsStrings.noFiles` instead of an empty share sheet.

## Translating

Pass `strings: ShareLogsStrings(...)` to translate the button and the sheet.
The shared subject and file names stay English.

## Related packages

| Package | Adds |
|---------|------|
| `comon_logger_flutter` | The log viewer screen and action host |
| `comon_logger` | Core logger primitives used by exported records |
