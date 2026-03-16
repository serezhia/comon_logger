# comon_logger_file

Rotating file handler for `comon_logger`.

## Quick Start

```dart
import 'package:comon_logger/comon_logger.dart';
import 'package:comon_logger_file/comon_logger_file.dart';

final fileHandler = FileLogHandler(
  directory: '/path/to/logs',
  maxFileSize: 5 * 1024 * 1024,
  maxFiles: 5,
);

await fileHandler.init();
Logger.root.addHandler(fileHandler);
```

## Features

- automatic rotation by file size
- max file retention
- plain text or JSON lines mode
- custom formatter support
- append-on-restart behavior

## Configuration

| Parameter | Default | Description |
|-----------|---------|-------------|
| `directory` | required | Target directory for log files |
| `baseFileName` | `comon_log` | Base file name without extension |
| `extension` | `.txt` | File extension |
| `maxFileSize` | 5 MB | Rotation threshold |
| `maxFiles` | 5 | Max rotated files kept on disk |
| `writeAsJson` | `false` | Write each record as JSON |
| `formatter` | `SimpleLogFormatter` | Formatter used for text mode |

## Lifecycle

```dart
await fileHandler.init();
await fileHandler.flush();
await fileHandler.close();
```
