# comon_logger_devtools_extension

DevTools panel for `comon_logger` connected Flutter apps.

## Features

When an app registers `ComonLoggerServiceExtension`, this extension:

1. loads log history from the app
2. subscribes to live log events
3. renders a searchable, filterable log panel inside DevTools

## Features

- live streaming from the connected app
- pause/resume log flow
- level/layer/type/feature/logger filters
- search across log text
- expandable rows with error and extra data
- clear logs locally and remotely

## Installation

This package is an internal DevTools extension package and is not published to
pub.dev. It is consumed from this monorepo workspace.

## App integration

Register the service extension in your Flutter app:

```dart
import 'package:comon_logger_flutter/comon_logger_flutter.dart';

final historyHandler = HistoryLogHandler();

void registerDevToolsBridge() {
	ComonLoggerServiceExtension(historyHandler).register();
}
```

## Build

```bash
cd packages/comon_logger_devtools_extension
flutter build web --release --output=extension/devtools/build
```

## Requirements

- the app must register `ComonLoggerServiceExtension(historyHandler).register()`
- `comon_logger_flutter` must be present in the target app

## Related packages

| Package | Adds |
|---------|------|
| `comon_logger` | Core record model consumed by the extension |
| `comon_logger_flutter` | Service extension bridge and in-app history source |
