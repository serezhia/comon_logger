# comon_logger_file

File-based log handler for **comon_logger** with automatic log rotation.

## Setup

```dart
import 'package:comon_logger/comon_logger.dart';
import 'package:comon_logger_file/comon_logger_file.dart';

final fileHandler = FileLogHandler(
  directory: '/path/to/logs',
  maxFileSize: 5 * 1024 * 1024, // 5 MB
  maxFiles: 5,
);
await fileHandler.init();
Logger.root.addHandler(fileHandler);
```

## Features

- **Automatic rotation**: When a log file exceeds `maxFileSize`, it rotates
  to `comon_log_1.txt`, `comon_log_2.txt`, etc.
- **File limit**: Old files beyond `maxFiles` are deleted automatically.
- **JSON mode**: Set `writeAsJson: true` to write one JSON object per line
  (compatible with `LogRecord.fromJson()`).
- **Custom formatter**: Pass any `LogFormatter` instance. Defaults to
  `SimpleLogFormatter`.
- **Append on restart**: Re-initializing appends to the existing file.

## Configuration

| Parameter      | Default        | Description                          |
|----------------|----------------|--------------------------------------|
| `directory`    | required       | Directory path for log files         |
| `baseFileName` | `'comon_log'`  | Base name (without extension)        |
| `extension`    | `'.txt'`       | File extension                       |
| `maxFileSize`  | 5 MB           | Max size before rotation             |
| `maxFiles`     | 5              | Max rotated files to keep            |
| `writeAsJson`  | `false`        | Write records as JSON                |
| `filter`       | `AllPassLogFilter` | Filter for this handler          |
| `formatter`    | `SimpleLogFormatter` | Text formatter                 |

## Lifecycle

```dart
await fileHandler.init();     // open file
// ... logging happens ...
await fileHandler.flush();    // ensure writes are on disk
await fileHandler.close();    // release resources
```
