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

### Levels

A logger without its own level inherits its parent's, so one line sets the
threshold for the whole app. Guard expensive messages with `isLoggable`.

```dart
Logger.root.level = LogLevel.WARNING; // every logger without its own level
Logger('sync').level = LogLevel.FINE; // except this subtree
Logger('sync').level = null;          // inherit again

if (log.isLoggable(LogLevel.FINE)) log.fine(describe(payload));
```

### Transformers and redaction

Transformers rewrite or drop a record before any handler or `onRecord`
listener sees it. They run from the logger that created the record up to the
root; the first `null` drops it.

```dart
Logger.root.addTransformer(
  RedactLogTransformer(
    keys: {'token', 'password'},
    maxStringLength: 4096,
  ).call,
);

log.info('Signed in', extra: {'token': 'abc'}); // extra: {token: <redacted>}
```

`RedactLogTransformer` only matches `extra` keys; it cannot find a secret
inside the message text.

### Tests

Loggers are global. Call `Logger.reset()` in `tearDown` to remove handlers,
transformers and levels set by a test.

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
