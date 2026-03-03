# comon_logger_dio

Dio HTTP interceptor for `comon_logger` — logs requests, responses, and errors.

## Usage

```dart
import 'package:comon_logger_dio/comon_logger_dio.dart';

final dio = Dio();
dio.interceptors.add(ComonDioInterceptor(
  logRequestBody: true,
  logResponseBody: true,
  logRequestHeaders: false,
  logResponseHeaders: false,
  maxResponseBodyLength: 1000,
));
```

## Options

| Parameter | Default | Description |
|-----------|---------|-------------|
| `logRequestBody` | `false` | Include request body |
| `logResponseBody` | `true` | Include response body |
| `logRequestHeaders` | `false` | Include request headers |
| `logResponseHeaders` | `false` | Include response headers |
| `maxResponseBodyLength` | `1000` | Truncate body beyond this |
| `requestFilter` | `null` | Skip logging if returns false |
| `responseFilter` | `null` | Skip logging if returns false |
| `errorFilter` | `null` | Skip logging if returns false |
| `loggerName` | `'comon.dio'` | Logger name for hierarchy |
