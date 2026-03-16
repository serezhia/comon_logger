# comon_logger_navigation_flutter

Navigation logging package for Flutter built on top of `comon_logger`.

## Quick Start

```dart
import 'package:comon_logger_navigation_flutter/comon_logger_navigation_flutter.dart';

MaterialApp(
  navigatorObservers: [ComonNavigatorObserver()],
);
```

## What It Logs

| Action | Example |
|--------|---------|
| `PUSH` | `PUSH: /details (from: /home)` |
| `POP` | `POP: /details (from: /home)` |
| `REPLACE` | `REPLACE: /settings (from: /profile)` |
| `REMOVE` | `REMOVE: /temp` |

Each navigation record is emitted with:

- `LogLevel.CONFIG`
- `LogLayer.widgets`
- `LogType.navigation`
- structured `extra` payload for action, route, and previous route

## Custom Logger Name

```dart
ComonNavigatorObserver(loggerName: 'my_app.navigation')
```
