# comon_logger

A modular, extensible logging ecosystem for Dart & Flutter.  
Zero-dependency core + pluggable add-ons for HTTP, file logging, navigation tracking, sharing, and DevTools integration.

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

---

## Packages

| Package | Description | pub.dev |
|---------|-------------|---------|
| [comon_logger](comon_logger/) | Core logging library for Dart. Hierarchical loggers, typed tags (`LogLevel`, `LogLayer`, `LogType`, `feature`), pluggable handlers, filters, and formatters. **Zero dependencies.** | [![pub](https://img.shields.io/pub/v/comon_logger.svg)](https://pub.dev/packages/comon_logger) |
| [comon_logger_flutter](comon_logger_flutter/) | Flutter UI — full-screen log viewer with multi-select filter chips, text search, tap-to-expand details, copy/clear, auto-scroll. Includes `HistoryLogHandler` and DevTools service extension. | [![pub](https://img.shields.io/pub/v/comon_logger_flutter.svg)](https://pub.dev/packages/comon_logger_flutter) |
| [comon_logger_dio](comon_logger_dio/) | Dio HTTP interceptor — logs requests, responses, and errors through the `Logger` hierarchy. | [![pub](https://img.shields.io/pub/v/comon_logger_dio.svg)](https://pub.dev/packages/comon_logger_dio) |
| [comon_logger_dio_flutter](comon_logger_dio_flutter/) | Flutter UI renderer for Dio HTTP logs — rich expandable cards for request/response details. | [![pub](https://img.shields.io/pub/v/comon_logger_dio_flutter.svg)](https://pub.dev/packages/comon_logger_dio_flutter) |
| [comon_logger_file](comon_logger_file/) | File-based log handler with automatic log rotation (max file size, max files). | [![pub](https://img.shields.io/pub/v/comon_logger_file.svg)](https://pub.dev/packages/comon_logger_file) |
| [comon_logger_share_flutter](comon_logger_share_flutter/) | Share/export action for the log viewer — exports logs as plain text or JSON via the platform share sheet. | [![pub](https://img.shields.io/pub/v/comon_logger_share_flutter.svg)](https://pub.dev/packages/comon_logger_share_flutter) |
| [comon_logger_navigation_flutter](comon_logger_navigation_flutter/) | `NavigatorObserver` — automatically logs all route changes (push, pop, replace, remove) with Flutter UI. | [![pub](https://img.shields.io/pub/v/comon_logger_navigation_flutter.svg)](https://pub.dev/packages/comon_logger_navigation_flutter) |
| [comon_logger_devtools_extension](comon_logger_devtools_extension/) | DevTools extension — live log viewer with filters integrated into Flutter DevTools. | — |

### Dependency graph

```
comon_logger (core, zero deps)
├── comon_logger_flutter (+ flutter)
│   ├── comon_logger_dio_flutter (+ comon_logger_dio)
│   ├── comon_logger_share_flutter (+ share_plus)
│   └── comon_logger_navigation_flutter
├── comon_logger_dio (+ dio)
├── comon_logger_file (pure Dart)
└── comon_logger_devtools_extension (+ devtools_extensions, vm_service)
```

---

## Quick start

### Dart

```dart
import 'package:comon_logger/comon_logger.dart';

void main() {
  Logger.root.addHandler(ConsoleLogHandler(
    filter: LevelLogFilter(LogLevel.FINE),
  ));

  final log = Logger('my_app');
  log.info('Hello from comon_logger!');
}
```

### Flutter

```dart
import 'package:comon_logger/comon_logger.dart';
import 'package:comon_logger_flutter/comon_logger_flutter.dart';

final historyHandler = HistoryLogHandler();

void main() {
  Logger.root.addHandler(ConsoleLogHandler());
  Logger.root.addHandler(historyHandler);
  runApp(MyApp());
}

// Open the log viewer screen anywhere:
Navigator.of(context).push(MaterialPageRoute(
  builder: (_) => ComonLoggerScreen(handler: historyHandler),
));
```

---

## Local development

The repository is managed with [Melos](https://melos.invertase.dev/).

### Prerequisites

- Dart SDK `>=3.0.0 <4.0.0`
- Flutter SDK `>=3.0.0` (for Flutter packages)
- Melos (`dart pub global activate melos`)

### Setup

```bash
# Clone the repository
git clone https://github.com/serezhia/comon_logger.git
cd comon_logger

# Bootstrap — installs dependencies and creates pubspec_overrides.yaml
# for each package so they use local path dependencies
melos bootstrap
```

### How it works

Each package's `pubspec.yaml` declares dependencies on other `comon_logger_*` packages using **exact pub.dev versions** (e.g. `comon_logger: 0.1.0`). This is what gets published.

When you run `melos bootstrap`, it generates a `pubspec_overrides.yaml` in each package that **overrides** those version dependencies with local **path** dependencies. This file is gitignored and never published.

```
# Example: comon_logger_flutter/pubspec_overrides.yaml (auto-generated)
dependency_overrides:
  comon_logger:
    path: ../comon_logger
```

This means:
- **Locally** — all packages resolve to your local source code (live changes, no need to publish first)
- **On pub.dev** — clean version dependencies, no path references

### Available commands

```bash
# Run all tests (Dart + Flutter)
melos run test

# Run only Dart tests
melos run test:dart

# Run only Flutter tests
melos run test:flutter

# Static analysis
melos run analyze

# Format code
melos run format

# Dry-run publish (check all packages pass pub.dev validation)
melos run publish:dry
```

---

## Publishing to pub.dev

Packages must be published **in dependency order** — core first, dependents after.

### 1. Bump versions

Update `version:` in each package's `pubspec.yaml` and the corresponding version constraints in dependent packages.

### 2. Dry-run

```bash
melos run publish:dry
```

Fix any warnings before proceeding.

### 3. Publish (in order)

```bash
# 1) Core (no dependencies)
cd comon_logger && dart pub publish

# 2) Packages depending only on core
cd ../comon_logger_flutter && dart pub publish
cd ../comon_logger_dio && dart pub publish
cd ../comon_logger_file && dart pub publish

# 3) Packages depending on other comon_logger_* packages
cd ../comon_logger_dio_flutter && dart pub publish
cd ../comon_logger_share_flutter && dart pub publish
cd ../comon_logger_navigation_flutter && dart pub publish
```

> **Note:** `comon_logger_devtools_extension` has `publish_to: "none"` — it is bundled with `comon_logger_flutter` and not published separately.

### Version constraints

When bumping versions, update the `^x.y.z` constraints in all dependent packages:

| If you change... | Update constraints in... |
|-----------------|------------------------|
| `comon_logger` | all other packages |
| `comon_logger_flutter` | `comon_logger_dio_flutter`, `comon_logger_share_flutter`, `comon_logger_navigation_flutter` |
| `comon_logger_dio` | `comon_logger_dio_flutter` |

After updating versions, run `melos bootstrap` again to refresh overrides.

---

## Examples

| Example | Description |
|---------|-------------|
| [examples/flutter_app](examples/flutter_app/) | Full Flutter app with all packages — log viewer, Dio interceptor, navigation observer, file logging, share |
| [examples/shelf_app](examples/shelf_app/) | Dart backend app with Shelf — console + file logging |

---

## License

MIT — see [LICENSE](LICENSE) for details.
