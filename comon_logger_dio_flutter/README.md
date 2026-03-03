# comon_logger_dio_flutter

Flutter UI renderer for Dio HTTP logs from `comon_logger_dio`.

## Usage

```dart
import 'package:comon_logger_dio_flutter/comon_logger_dio_flutter.dart';
import 'package:comon_logger_flutter/comon_logger_flutter.dart';

ComonLoggerScreen(
  handler: historyHandler,
  renderers: [
    HttpLogRecordRenderer(),
  ],
)
```

This package provides `HttpLogRecordRenderer` — a pluggable renderer that gives
Dio HTTP logs a rich, expandable UI with:

- Method / status / duration badges
- Collapsible request & response headers
- Pretty-printed JSON body with syntax highlighting
- One-tap copy with full structured data
