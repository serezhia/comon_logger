# comon_logger_dio

Dio integration package for `comon_logger` with two pieces:

- `ComonDioInterceptor` for structured request, response, and error logs
- `HttpConsoleLogFormatter` for rich HTTP rendering in the console

## Installation

```bash
dart pub add dio
dart pub add comon_logger_dio
```

## Quick Start

```dart
import 'package:comon_logger/comon_logger.dart';
import 'package:comon_logger_dio/comon_logger_dio.dart';
import 'package:dio/dio.dart';

Logger.root.addHandler(ConsoleLogHandler(
  formatters: const [
    HttpConsoleLogFormatter(),
  ],
  formatter: PrettyLogFormatter(),
));

final dio = Dio();
dio.interceptors.add(ComonDioInterceptor(
  logRequestBody: true,
  logResponseBody: true,
));
```

## Included components

| Component | Purpose |
|-----------|---------|
| `ComonDioInterceptor` | Emits structured network `LogRecord`s from Dio |
| `HttpConsoleLogFormatter` | Pretty console output for HTTP logs |

## Interceptor Options

| Parameter | Default | Description |
|-----------|---------|-------------|
| `logRequestBody` | `false` | Include request body in console message |
| `logResponseBody` | `true` | Include response body in console message |
| `logRequestHeaders` | `false` | Include request headers in console message |
| `logResponseHeaders` | `false` | Include response headers in console message |
| `maxResponseBodyLength` | `null` | Truncate response body; `null` disables truncation |
| `requestFilter` | `null` | Skip request logging when it returns `false` |
| `responseFilter` | `null` | Skip response logging when it returns `false` |
| `errorFilter` | `null` | Skip error logging when it returns `false` |
| `loggerName` | `comon.dio` | Logger name used for emitted records |

## Formatter options

`HttpConsoleLogFormatter` can render:

- short path
- full URL
- query params as a separate section
- request/response headers and bodies
- separate error request/response sections

Example:

```dart
ConsoleLogHandler(
  formatters: const [
    HttpConsoleLogFormatter(
      showFullUrl: true,
      showQueryParams: true,
      showErrorRequestHeaders: false,
      showErrorResponseHeaders: true,
      showErrorRequestBody: false,
      showErrorResponseBody: true,
    ),
  ],
  formatter: PrettyLogFormatter(),
)
```

## Related packages

| Package | Adds |
|---------|------|
| `comon_logger` | Core logger, levels, handlers, and base formatters |
| `comon_logger_dio_flutter` | Rich Flutter rendering for the structured HTTP records |
