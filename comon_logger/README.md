# comon_logger

A modular, extensible logging library for Dart. Core package with zero dependencies.

## Features

- **Hierarchical loggers** — `Logger('dio.request')` is a child of `Logger('dio')`, which is a child of `Logger.root`
- **Typed tags** — `LogLevel`, `LogLayer`, `LogType`, `feature` for granular filtering
- **Pluggable handlers** — attach any number of handlers to any logger
- **Pluggable filters** — each handler has its own filter chain
- **Pluggable formatters** — pretty (ANSI + emoji) or simple (single-line) output
- **Extensible** — create custom layers, types, filters, formatters, and handlers
- **Zero dependencies** — pure Dart, works everywhere

## Quick Start

```dart
import 'package:comon_logger/comon_logger.dart';

void main() {
  // Add a handler to root — it receives ALL logs from every logger
  Logger.root.addHandler(ConsoleLogHandler(
    filter: LevelLogFilter(LogLevel.FINE),
  ));

  // Create a named logger
  final log = Logger('my_app.catalog');

  // Log with tags
  log.info(
    'Products loaded: 42 items',
    layer: LogLayer.data,
    type: LogType.network,
    feature: 'catalog',
  );

  // Log an error
  log.severe(
    'Failed to load products',
    error: Exception('Network timeout'),
    stackTrace: StackTrace.current,
    layer: LogLayer.data,
    type: LogType.network,
    feature: 'catalog',
  );
}
```

## Architecture

```
Actors (produce logs)                    Handlers (consume logs)
┌─────────────────────┐                  ┌──────────────────────────────────┐
│ DioInterceptor      │──log──┐          │ LogFilter → ConsoleLogHandler   │
│ NavigatorObserver    │──log──┤          │ LogFilter → FileLogHandler      │
│ BlocObserver        │──log──┼──► Logger.root ──► handlers ──┤            │
│ Any code            │──log──┘          │ LogFilter → HistoryLogHandler   │
└─────────────────────┘                  │ LogFilter → AnalyticsLogHandler │
                                         └──────────────────────────────────┘
```

## Logger Hierarchy

Loggers form a dotted-name hierarchy. Records propagate up from child to parent:

```
Logger('dio.request')  →  Logger('dio')  →  Logger.root ('')
```

Handlers on `Logger.root` receive records from **all** loggers. Handlers on
`Logger('dio')` receive records from `Logger('dio')` and `Logger('dio.request')`.

## Log Levels

| Level   | Value | Description         |
|---------|-------|---------------------|
| FINEST  | 300   | Most verbose        |
| FINER   | 400   | Verbose             |
| FINE    | 500   | Fine-grained        |
| CONFIG  | 700   | Configuration info  |
| INFO    | 800   | Informational       |
| WARNING | 900   | Potential problem   |
| SEVERE  | 1000  | Serious failure     |
| SHOUT   | 1200  | Critical / fatal    |
| OFF     | 2000  | Disables logging    |

## Tags

Each `LogRecord` can carry typed tags for filtering:

- **`LogLayer`** — architectural layer: `data`, `domain`, `widgets`, `app`, `infra`
- **`LogType`** — action type: `network`, `database`, `navigation`, `logic`, `ui`, `lifecycle`, `analytics`, `performance`, `security`, `general`
- **`feature`** — free-form string (e.g. `'catalog'`, `'auth'`)

### Custom Tags

```dart
// Simple constants
const kPaymentsLayer = LogLayer('payments');
const kDeeplinkType = LogType('deeplink');

// Register for UI filter visibility
LogLayer.register(kPaymentsLayer);
LogType.register(kDeeplinkType);
```

## Filters

```dart
// By level
const filter = LevelLogFilter(LogLevel.WARNING);

// By type
const filter = TypeLogFilter({LogType.network, LogType.database});

// By layer
const filter = LayerLogFilter({LogLayer.data});

// By feature
const filter = FeatureLogFilter({'catalog', 'auth'});

// Combine with AND/OR
const filter = CompositeLogFilter([
  LevelLogFilter(LogLevel.INFO),
  TypeLogFilter({LogType.network}),
], mode: CompositeMode.and);
```

## Formatters

- **`PrettyLogFormatter`** — multi-line with ANSI colors and emoji
- **`SimpleLogFormatter`** — compact single-line format

## Related Packages

| Package | Description |
|---------|-------------|
| `comon_logger_flutter` | Flutter UI log viewer + HistoryLogHandler |
| `comon_logger_dio` | Dio HTTP interceptor |
| `comon_logger_dio_flutter` | Beautiful HTTP log renderer for Dio |
| `comon_logger_navigation_flutter` | NavigatorObserver + navigation log renderer |
| `comon_logger_share_flutter` | Share/export toolbar action |
| `comon_logger_file` | File-based log handler with rotation |
| `comon_logger_devtools_extension` | DevTools browser extension |
