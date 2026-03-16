# comon_logger

A composable logging ecosystem for Dart and Flutter with a zero-dependency core,
an in-app Flutter log viewer, Dio HTTP integrations, file logging, sharing,
and navigation tracking.

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## Why comon_logger

- One `Logger` model for Dart and Flutter
- Typed metadata: `LogLevel`, `LogLayer`, `LogType`, `feature`
- Pluggable handlers, filters, and formatter add-ons
- Rich Flutter viewer for live logs inside the app
- Dedicated packages for Dio, file logging, share, and navigation

## Package Matrix

| Package | Use it for | pub.dev |
|---------|------------|---------|
| [comon_logger](comon_logger/) | Core logging primitives, handlers, filters, formatters, logger hierarchy | [![pub](https://img.shields.io/pub/v/comon_logger.svg)](https://pub.dev/packages/comon_logger) |
| [comon_logger_flutter](comon_logger_flutter/) | In-app Flutter log screen, `HistoryLogHandler`, DevTools service extension | [![pub](https://img.shields.io/pub/v/comon_logger_flutter.svg)](https://pub.dev/packages/comon_logger_flutter) |
| [comon_logger_dio](comon_logger_dio/) | Dio interceptor plus rich HTTP console formatter | [![pub](https://img.shields.io/pub/v/comon_logger_dio.svg)](https://pub.dev/packages/comon_logger_dio) |
| [comon_logger_dio_flutter](comon_logger_dio_flutter/) | HTTP renderer for `ComonLoggerScreen` | [![pub](https://img.shields.io/pub/v/comon_logger_dio_flutter.svg)](https://pub.dev/packages/comon_logger_dio_flutter) |
| [comon_logger_file](comon_logger_file/) | Rotating file logs for Dart and Flutter | [![pub](https://img.shields.io/pub/v/comon_logger_file.svg)](https://pub.dev/packages/comon_logger_file) |
| [comon_logger_share_flutter](comon_logger_share_flutter/) | Share/export action for the Flutter log viewer | [![pub](https://img.shields.io/pub/v/comon_logger_share_flutter.svg)](https://pub.dev/packages/comon_logger_share_flutter) |
| [comon_logger_navigation_flutter](comon_logger_navigation_flutter/) | `NavigatorObserver` with structured navigation logs | [![pub](https://img.shields.io/pub/v/comon_logger_navigation_flutter.svg)](https://pub.dev/packages/comon_logger_navigation_flutter) |

## Ecosystem Layout

| Layer | Packages |
|------|----------|
| Core | `comon_logger` |
| Flutter viewer | `comon_logger_flutter` |
| Console HTTP | `comon_logger_dio` |
| Flutter HTTP UI | `comon_logger_dio_flutter` |
| Export and sharing | `comon_logger_share_flutter` |
| Routing | `comon_logger_navigation_flutter` |
| Persistence | `comon_logger_file` |

## Quick Start

### Dart

```dart
import 'package:comon_logger/comon_logger.dart';

void main() {
  Logger.root.addHandler(ConsoleLogHandler(
    filter: LevelLogFilter(LogLevel.FINE),
  ));

  final log = Logger('my_app.catalog');
  log.info('Products loaded', type: LogType.network, layer: LogLayer.data);
}
```

### Flutter

```dart
import 'package:comon_logger/comon_logger.dart';
import 'package:comon_logger_flutter/comon_logger_flutter.dart';

final historyHandler = HistoryLogHandler(maxHistory: 2000);

void main() {
  Logger.root.addHandler(ConsoleLogHandler());
  Logger.root.addHandler(historyHandler);
  runApp(const MyApp());
}

Navigator.of(context).push(MaterialPageRoute(
  builder: (_) => ComonLoggerScreen(handler: historyHandler),
));
```

### Dio + Console Add-on

```dart
import 'package:comon_logger/comon_logger.dart';
import 'package:comon_logger_dio/comon_logger_dio.dart';

Logger.root.addHandler(ConsoleLogHandler(
  formatters: const [
    HttpConsoleLogFormatter(),
  ],
  formatter: PrettyLogFormatter(),
));
```

## Examples

| Example | What it demonstrates |
|---------|----------------------|
| [examples/flutter_app](examples/flutter_app/) | Full Flutter setup with console, file, Dio, navigation, share, and viewer screen |
| [examples/shelf_app](examples/shelf_app/) | Dart backend logging with console and rotating files |

## Development

This mono-repo is managed with [Melos](https://melos.invertase.dev/).

```bash
git clone https://github.com/serezhia/comon_logger.git
cd comon_logger
melos bootstrap
melos run test
```

Useful commands:

```bash
melos run test
melos run test:dart
melos run test:flutter
melos run analyze
melos run format
melos run publish:dry
```

## Publishing Notes

Publish packages in dependency order:

1. `comon_logger`
2. `comon_logger_flutter`, `comon_logger_dio`, `comon_logger_file`
3. `comon_logger_dio_flutter`, `comon_logger_share_flutter`, `comon_logger_navigation_flutter`

## License

MIT. See [LICENSE](LICENSE).
