# comon_logger_navigation

`NavigatorObserver` actor for **comon_logger** — automatically logs all route
changes (push, pop, replace, remove) via the Logger hierarchy.

## Setup

```dart
import 'package:comon_logger_navigation/comon_logger_navigation.dart';

MaterialApp(
  navigatorObservers: [ComonNavigatorObserver()],
);
```

## What is logged

| Action    | Example message                            |
|-----------|--------------------------------------------|
| `PUSH`    | `PUSH: /details (from: /home)`             |
| `POP`     | `POP: /details (from: /home)`              |
| `REPLACE` | `REPLACE: /settings (from: /profile)`      |
| `REMOVE`  | `REMOVE: /temp`                            |

All events are tagged with:
- **Level**: `CONFIG`
- **Layer**: `LogLayer.widgets`
- **Type**: `LogType.navigation`
- **Extra**: `{'action': 'PUSH', 'route': '/details', 'previousRoute': '/home'}`

## Custom logger name

```dart
ComonNavigatorObserver(loggerName: 'my_app.navigation')
```
