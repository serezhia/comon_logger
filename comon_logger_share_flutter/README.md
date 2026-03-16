# comon_logger_share_flutter

Share/export action package for `comon_logger_flutter`.

## What It Adds

`ShareLogsAction` puts a share button into `ComonLoggerScreen` and exports logs
through the platform share sheet as plain text or JSON.

## Quick Start

```dart
import 'package:comon_logger_flutter/comon_logger_flutter.dart';
import 'package:comon_logger_share_flutter/comon_logger_share_flutter.dart';

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
