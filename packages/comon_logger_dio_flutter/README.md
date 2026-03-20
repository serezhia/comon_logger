# comon_logger_dio_flutter

Flutter renderer package for Dio HTTP logs created by `comon_logger_dio`.

## What It Adds

`HttpLogRecordRenderer` turns structured HTTP records into rich log cards with:

- method and status badges
- duration display
- full URL section
- collapsible headers and bodies
- pretty JSON rendering
- copy-friendly formatted output

## Quick Start

```dart
import 'package:comon_logger_dio_flutter/comon_logger_dio_flutter.dart';
import 'package:comon_logger_flutter/comon_logger_flutter.dart';

ComonLoggerScreen(
  handler: historyHandler,
  renderers: const [
    HttpLogRecordRenderer(showRequest: false),
  ],
)
```

## Best With

| Package | Why |
|---------|-----|
| `comon_logger_dio` | Produces the HTTP records rendered here |
| `comon_logger_flutter` | Provides `ComonLoggerScreen` and renderer host |
