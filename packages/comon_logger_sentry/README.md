# comon_logger_sentry

Sends `comon_logger` records to [Sentry](https://sentry.io) or a self-hosted Sentry.

## Features

`SentryLogHandler` is a normal `LogHandler`:

- every record that passes its filter becomes a breadcrumb, the trail Sentry
  attaches to the next event;
- a record at `eventLevel` (SEVERE by default) or above also becomes an event,
  with its error and stack trace;
- `layer`, `type` and `feature` become `log.layer`, `log.type` and
  `log.feature` tags; `extra` becomes the event's `log` context and the
  breadcrumb's data.

The handler only reports. The app initializes Sentry and decides what may
leave the device.

## Installation

```bash
dart pub add comon_logger_sentry
```

## Quick Start

```dart
import 'package:comon_logger/comon_logger.dart';
import 'package:comon_logger_sentry/comon_logger_sentry.dart';
import 'package:sentry/sentry.dart';

Future<void> main() async {
  await Sentry.init((options) => options.dsn = 'https://key@sentry.example.com/1');

  Logger.root
    ..addTransformer(RedactLogTransformer(keys: {'token', 'password'}).call)
    ..addHandler(SentryLogHandler(filter: LevelLogFilter(LogLevel.INFO)));
}
```

Transformers on the logger run before handlers, so the redaction above also
covers what Sentry receives. In Flutter use `SentryFlutter.init` from
`sentry_flutter`; the handler is the same.

## Level mapping

| comon_logger | Sentry |
|---|---|
| SHOUT and above | fatal |
| SEVERE | error |
| WARNING | warning |
| INFO | info |
| below INFO | debug |

Custom levels map by value to the predefined level below them.

## Related packages

| Package | Adds |
|---------|------|
| `comon_logger_sentry_flutter` | The in-app history attached to each event |
| `comon_logger` | Core logger primitives |
