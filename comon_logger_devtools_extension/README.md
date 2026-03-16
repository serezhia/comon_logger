# comon_logger_devtools_extension

DevTools panel for `comon_logger` connected Flutter apps.

## What It Does

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

## Build

```bash
cd comon_logger_devtools_extension
flutter build web --release --output=extension/devtools/build
```

## Requirements

- the app must register `ComonLoggerServiceExtension(historyHandler).register()`
- `comon_logger_flutter` must be present in the target app
