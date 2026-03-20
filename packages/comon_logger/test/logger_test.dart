import 'dart:async';

import 'package:comon_logger/comon_logger.dart';
import 'package:test/test.dart';

/// A test handler that records all handled records.
class _TestHandler extends LogHandler {
  _TestHandler({super.filter = const AllPassLogFilter()});

  final List<LogRecord> records = [];

  @override
  void handle(LogRecord record) {
    records.add(record);
  }
}

void main() {
  // Reset loggers between tests to avoid shared state.
  // We'll create fresh named loggers using unique names.

  group('Logger', () {
    test('factory constructor returns cached instances', () {
      final a = Logger('test.cached.a');
      final b = Logger('test.cached.a');
      expect(identical(a, b), isTrue);
    });

    test('Logger("") returns root', () {
      expect(identical(Logger(''), Logger.root), isTrue);
    });

    test('different names produce different loggers', () {
      final a = Logger('test.diff.a');
      final b = Logger('test.diff.b');
      expect(identical(a, b), isFalse);
    });

    test('toString includes name', () {
      final log = Logger('test.tostring');
      expect(log.toString(), 'Logger(test.tostring)');
      expect(Logger.root.toString(), 'Logger()');
    });
  });

  group('Logger handlers', () {
    late _TestHandler handler;

    setUp(() {
      handler = _TestHandler();
    });

    test('handler receives records', () {
      final log = Logger('test.handler.receive');
      log.addHandler(handler);

      log.info('hello');

      expect(handler.records, hasLength(1));
      expect(handler.records.first.message, 'hello');
      expect(handler.records.first.level, LogLevel.INFO);
      expect(handler.records.first.loggerName, 'test.handler.receive');

      log.clearHandlers();
    });

    test('removeHandler stops delivery', () {
      final log = Logger('test.handler.remove');
      log.addHandler(handler);
      log.info('one');
      log.removeHandler(handler);
      log.info('two');

      expect(handler.records, hasLength(1));
      expect(handler.records.first.message, 'one');
    });

    test('clearHandlers removes all', () {
      final log = Logger('test.handler.clear');
      log.addHandler(handler);
      log.addHandler(_TestHandler());
      expect(log.handlers, hasLength(2));

      log.clearHandlers();
      expect(log.handlers, isEmpty);
    });

    test('handler filter is respected', () {
      final filteredHandler = _TestHandler(
        filter: const LevelLogFilter(LogLevel.WARNING),
      );
      final log = Logger('test.handler.filter');
      log.addHandler(filteredHandler);

      log.info('should be filtered out');
      log.warning('should pass');
      log.severe('should also pass');

      expect(filteredHandler.records, hasLength(2));
      expect(filteredHandler.records[0].message, 'should pass');
      expect(filteredHandler.records[1].message, 'should also pass');

      log.clearHandlers();
    });
  });

  group('Logger level filtering', () {
    late _TestHandler handler;

    setUp(() {
      handler = _TestHandler();
    });

    test('records below logger level are discarded', () {
      final log = Logger('test.level.filter');
      log.level = LogLevel.WARNING;
      log.addHandler(handler);

      log.info('too low');
      log.warning('just right');
      log.severe('also fine');

      expect(handler.records, hasLength(2));

      log.level = LogLevel.FINEST;
      log.clearHandlers();
    });
  });

  group('Logger hierarchy', () {
    late _TestHandler rootHandler;

    setUp(() {
      rootHandler = _TestHandler();
      Logger.root.addHandler(rootHandler);
    });

    tearDown(() {
      Logger.root.removeHandler(rootHandler);
    });

    test('child records propagate to root', () {
      final child = Logger('test.hierarchy.child');
      child.info('from child');

      expect(rootHandler.records.any((r) => r.message == 'from child'), isTrue);
    });

    test('deeply nested child propagates through parents to root', () {
      final deep = Logger('test.hierarchy.a.b.c');
      deep.info('deep message');

      expect(
        rootHandler.records.any((r) => r.message == 'deep message'),
        isTrue,
      );
    });

    test('parent handler also receives child records', () {
      final parentHandler = _TestHandler();
      final parent = Logger('test.hierarchy.parent');
      parent.addHandler(parentHandler);

      final child = Logger('test.hierarchy.parent.child');
      child.info('child message');

      expect(
        parentHandler.records.any((r) => r.message == 'child message'),
        isTrue,
      );
      expect(
        rootHandler.records.any((r) => r.message == 'child message'),
        isTrue,
      );

      parent.clearHandlers();
    });
  });

  group('Logger stream', () {
    test('onRecord emits log records', () async {
      final log = Logger('test.stream');
      final completer = Completer<LogRecord>();

      final sub = log.onRecord.listen((record) {
        if (!completer.isCompleted) completer.complete(record);
      });

      log.info('streamed');

      final received = await completer.future.timeout(
        const Duration(seconds: 1),
      );
      expect(received.message, 'streamed');

      await sub.cancel();
    });
  });

  group('Logger convenience methods', () {
    late _TestHandler handler;
    late Logger log;

    setUp(() {
      handler = _TestHandler();
      log = Logger('test.convenience');
      log.addHandler(handler);
    });

    tearDown(() {
      log.clearHandlers();
    });

    test('finest logs at FINEST level', () {
      log.finest('msg');
      expect(handler.records.last.level, LogLevel.FINEST);
    });

    test('finer logs at FINER level', () {
      log.finer('msg');
      expect(handler.records.last.level, LogLevel.FINER);
    });

    test('fine logs at FINE level', () {
      log.fine('msg');
      expect(handler.records.last.level, LogLevel.FINE);
    });

    test('config logs at CONFIG level', () {
      log.config('msg');
      expect(handler.records.last.level, LogLevel.CONFIG);
    });

    test('info logs at INFO level', () {
      log.info('msg');
      expect(handler.records.last.level, LogLevel.INFO);
    });

    test('warning logs at WARNING level', () {
      log.warning('msg');
      expect(handler.records.last.level, LogLevel.WARNING);
    });

    test('severe logs at SEVERE level', () {
      log.severe('msg');
      expect(handler.records.last.level, LogLevel.SEVERE);
    });

    test('shout logs at SHOUT level', () {
      log.shout('msg');
      expect(handler.records.last.level, LogLevel.SHOUT);
    });

    test('convenience methods pass all parameters', () {
      log.info(
        'detailed',
        error: Exception('e'),
        layer: LogLayer.data,
        type: LogType.network,
        feature: 'catalog',
        extra: {'k': 'v'},
      );

      final r = handler.records.last;
      expect(r.message, 'detailed');
      expect(r.error, isA<Exception>());
      expect(r.layer, LogLayer.data);
      expect(r.type, LogType.network);
      expect(r.feature, 'catalog');
      expect(r.extra, {'k': 'v'});
    });
  });
}
