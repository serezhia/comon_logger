import 'package:comon_logger/comon_logger.dart';
import 'package:comon_logger_flutter/src/handlers/history_log_handler.dart';
import 'package:flutter_test/flutter_test.dart';

LogRecord _makeRecord({
  LogLevel level = LogLevel.INFO,
  String message = 'test',
}) {
  return LogRecord(
    level: level,
    message: message,
    loggerName: 'test',
    time: DateTime.now(),
  );
}

void main() {
  group('HistoryLogHandler', () {
    late HistoryLogHandler handler;

    setUp(() {
      handler = HistoryLogHandler();
    });

    tearDown(() {
      handler.dispose();
    });

    test('stores records', () {
      handler.handle(_makeRecord(message: 'one'));
      handler.handle(_makeRecord(message: 'two'));

      expect(handler.history, hasLength(2));
      expect(handler.history[0].message, 'one');
      expect(handler.history[1].message, 'two');
    });

    test('clear removes all records', () {
      handler.handle(_makeRecord());
      handler.handle(_makeRecord());

      handler.clear();

      expect(handler.history, isEmpty);
    });

    test('respects maxHistory', () {
      final small = HistoryLogHandler(maxHistory: 3);

      for (var i = 0; i < 5; i++) {
        small.handle(_makeRecord(message: 'msg$i'));
      }

      expect(small.history, hasLength(3));
      expect(small.history[0].message, 'msg2');
      expect(small.history[1].message, 'msg3');
      expect(small.history[2].message, 'msg4');

      small.dispose();
    });

    test('onRecord stream emits new records', () async {
      final records = <LogRecord>[];
      final sub = handler.onRecord.listen(records.add);

      handler.handle(_makeRecord(message: 'streamed'));

      // Allow microtask to complete
      await Future<void>.delayed(Duration.zero);

      expect(records, hasLength(1));
      expect(records.first.message, 'streamed');

      await sub.cancel();
    });

    test('export produces text output', () {
      handler.handle(_makeRecord(message: 'line one'));
      handler.handle(_makeRecord(message: 'line two'));

      final output = handler.export();
      expect(output, contains('line one'));
      expect(output, contains('line two'));
    });

    test('exportJson produces valid JSON', () {
      handler.handle(_makeRecord(message: 'json test'));

      final json = handler.exportJson();
      expect(json, startsWith('['));
      expect(json, contains('"json test"'));
    });

    test('history returns unmodifiable list', () {
      handler.handle(_makeRecord());

      expect(
        () => (handler.history as List).add(_makeRecord()),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}
