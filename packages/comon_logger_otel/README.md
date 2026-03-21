# comon_logger_otel

`comon_logger_otel` bridges `comon_logger` records into `comon_otel`.

## Usage

```dart
import 'package:comon_logger/comon_logger.dart';
import 'package:comon_logger_otel/comon_logger_otel.dart';
import 'package:comon_otel/comon_otel.dart';

Future<void> main() async {
  await Otel.init(serviceName: 'my-service');

  Logger.root.addHandler(OtelLogHandler());
}
```