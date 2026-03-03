# Examples

Example applications demonstrating the `comon_logger` ecosystem.

## flutter_app

A Flutter application showcasing the full suite of comon_logger packages — in-app log viewer, Dio HTTP logging, navigation observer, file logging, DevTools integration, and more.

```bash
cd examples/flutter_app
flutter pub get
flutter run
```

## shelf_app

A Dart server application using **shelf** + **shelf_router** with comon_logger for structured request logging, error tracking, and rotating file logs.

```bash
cd examples/shelf_app
dart pub get
dart run bin/server.dart
# Server starts on http://localhost:8080
```
