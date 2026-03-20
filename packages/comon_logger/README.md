# comon_logger

Zero-dependency logging core for Dart with hierarchical loggers, typed tags,
filters, handlers, and extensible formatter add-ons.

## Features

- Hierarchical `Logger` instances with propagation to `Logger.root`
- Structured tags with `LogLevel`, `LogLayer`, `LogType`, and `feature`
- Per-handler filtering via `LogFilter`
- Console, file, and custom handler support
- `PrettyLogFormatter` and `SimpleLogFormatter` out of the box
- Formatter add-ons via `ConsoleLogHandler(formatters: [...])`

## Installation

```bash
dart pub add comon_logger
```

## Quick Start

```dart
import 'package:comon_logger/comon_logger.dart';

void main() {
  Logger.root.addHandler(ConsoleLogHandler(
    filter: const LevelLogFilter(LogLevel.INFO),
  ));

  final log = Logger('my_app.catalog');

  log.info(
    'Products loaded: 42 items',
    layer: LogLayer.data,
    type: LogType.network,
    feature: 'catalog',
  );

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

## Configuration

### Logger hierarchy

```text
Logger('dio.request') -> Logger('dio') -> Logger.root
```

Handlers on `Logger.root` receive records from all child loggers.

### Tags

| Tag | Purpose | Examples |
|-----|---------|----------|
| `LogLevel` | Severity | `INFO`, `WARNING`, `SEVERE` |
| `LogLayer` | Architectural origin | `data`, `domain`, `widgets`, `app`, `infra` |
| `LogType` | Action category | `network`, `navigation`, `database`, `ui` |
| `feature` | Free-form feature marker | `catalog`, `auth`, `checkout` |

### Filters

```dart
const filter = CompositeLogFilter([
  LevelLogFilter(LogLevel.INFO),
  TypeLogFilter({LogType.network}),
], mode: CompositeMode.and);
```

### Formatter add-ons

`ConsoleLogHandler` can try specialized formatters first and fall back to a
default formatter for all other records.

```dart
Logger.root.addHandler(ConsoleLogHandler(
  formatters: const [
    MySpecialFormatter(),
  ],
  formatter: PrettyLogFormatter(),
));
```

The first formatter whose `canFormat(record)` returns `true` wins.

## Included formatters

| Formatter | Purpose |
|-----------|---------|
| `PrettyLogFormatter` | Multi-line console output with ANSI colors and emoji |
| `SimpleLogFormatter` | Compact single-line text format |

## Related packages

| Package | Adds |
|---------|------|
| `comon_logger_flutter` | In-app log viewer and `HistoryLogHandler` |
| `comon_logger_dio` | Dio interceptor and HTTP console formatter |
| `comon_logger_dio_flutter` | Rich HTTP UI renderer for Flutter logs |
| `comon_logger_navigation_flutter` | Navigation observer with structured route logs |
| `comon_logger_share_flutter` | Share/export action for the viewer |
| `comon_logger_file` | Rotating file log handler |
