# comon_logger_navigation_flutter

Navigation logging package for Flutter built on top of `comon_logger`.

## Features

- `NavigatorObserver` for push, pop, replace, and remove events
- Structured navigation records with action, route, and previous route
- `LogLevel.CONFIG`, `LogLayer.widgets`, and `LogType.navigation` out of the box
- Ready to combine with the `comon_logger_flutter` viewer stack

## Installation

```bash
flutter pub add comon_logger_navigation_flutter
```

## Quick Start

```dart
import 'package:flutter/material.dart';
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

## Configuration

```dart
ComonNavigatorObserver(loggerName: 'my_app.navigation')
```

## Related packages

| Package | Adds |
|---------|------|
| `comon_logger` | Core logger, tags, and filtering primitives |
| `comon_logger_flutter` | In-app log viewer for navigation records |
