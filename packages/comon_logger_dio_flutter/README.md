# comon_logger_dio_flutter

Flutter renderer package for Dio HTTP logs created by `comon_logger_dio`.

## Features

`HttpLogRecordRenderer` turns structured HTTP records into rich log cards with:

- method and status badges
- duration display
- full URL section
- collapsible headers and bodies
- pretty JSON rendering
- copy-friendly formatted output

## Installation

```bash
flutter pub add comon_logger_dio_flutter
```

## Quick Start

```dart
import 'package:comon_logger/comon_logger.dart';
import 'package:comon_logger_dio_flutter/comon_logger_dio_flutter.dart';
import 'package:comon_logger_flutter/comon_logger_flutter.dart';

final historyHandler = HistoryLogHandler();

ComonLoggerScreen(
  handler: historyHandler,
  renderers: const [
    HttpLogRecordRenderer(showRequest: false),
  ],
)
```

## Usage notes

- Works best with records produced by `ComonDioInterceptor`
- Automatically matches `LogType.network` records with the expected `extra` payload
- Can be combined with other `LogRecordRenderer`s in the same log screen

## Related packages

| Package | Why |
|---------|-----|
| `comon_logger_dio` | Produces the HTTP records rendered here |
| `comon_logger_flutter` | Provides `ComonLoggerScreen` and renderer host |
| `comon_logger` | Provides `LogRecord`, `LogType`, and logger primitives |
