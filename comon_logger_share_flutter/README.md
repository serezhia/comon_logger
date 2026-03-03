# comon_logger_share_flutter

Share / export action for the `comon_logger_flutter` log viewer screen.

Adds a **Share** button to the toolbar that lets users export logs as
plain text or as a JSON file via the platform share sheet.

## Usage

```dart
import 'package:comon_logger_flutter/comon_logger_flutter.dart';
import 'package:comon_logger_share_flutter/comon_logger_share_flutter.dart';

ComonLoggerScreen(
  handler: historyHandler,
  actions: [
    ShareLogsAction(),
    ImportLogsAction(), // built-in, no extra deps
  ],
)
```

This keeps the core `comon_logger_flutter` package free from the
`share_plus` native plugin dependency.
