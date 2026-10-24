# comon_logger_sentry_flutter

Attaches the in-app `comon_logger` history to Sentry events.

## Features

`historyLogAttachment` turns the latest records of a `HistoryLogHandler` into
a text attachment. The text is read when an event is sent, so one attachment
added to the scope serves every event. Pair it with `SentryLogHandler` from
`comon_logger_sentry`, which reports the events.

## Installation

```bash
flutter pub add comon_logger_sentry_flutter
```

## Quick Start

```dart
import 'package:comon_logger/comon_logger.dart';
import 'package:comon_logger_flutter/comon_logger_flutter.dart';
import 'package:comon_logger_sentry/comon_logger_sentry.dart';
import 'package:comon_logger_sentry_flutter/comon_logger_sentry_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

final history = HistoryLogHandler(maxHistory: 2000);

Future<void> main() async {
  Logger.root
    ..addHandler(history)
    ..addHandler(SentryLogHandler());
  await SentryFlutter.init(
    (options) => options.dsn = 'https://key@sentry.example.com/1',
    appRunner: () => runApp(const MyApp()),
  );
  Sentry.configureScope(
    (scope) => scope.addAttachment(historyLogAttachment(history)),
  );
}
```

`maxRecords` (500 by default) bounds the attachment; `formatter` and
`filename` change its text and name.

Sentry does not scrub attachments: records are sent as the history stored
them, after the logger's transformers.

## Related packages

| Package | Adds |
|---------|------|
| `comon_logger_sentry` | Breadcrumbs and events from log records |
| `comon_logger_flutter` | `HistoryLogHandler` and the in-app viewer |
