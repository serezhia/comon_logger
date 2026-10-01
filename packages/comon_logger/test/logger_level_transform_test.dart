import 'package:comon_logger/comon_logger.dart';
import 'package:test/test.dart';

class _TestHandler extends LogHandler {
  _TestHandler() : super(filter: const AllPassLogFilter());

  final List<LogRecord> records = [];

  @override
  void handle(LogRecord record) => records.add(record);
}

void main() {
  late _TestHandler handler;

  setUp(() {
    handler = _TestHandler();
    Logger.root.addHandler(handler);
  });

  tearDown(Logger.reset);

  group('hierarchical level', () {
    test('a logger without its own level inherits from root', () {
      final log = Logger('lt.inherit.child');
      Logger.root.level = LogLevel.WARNING;

      log.info('dropped');
      log.warning('kept');

      expect(log.level, LogLevel.WARNING);
      expect(handler.records.map((r) => r.message), ['kept']);
    });

    test('an intermediate logger level applies to its descendants', () {
      Logger('lt.mid').level = LogLevel.SEVERE;

      Logger('lt.mid.leaf').warning('dropped');
      Logger('lt.other').warning('kept');

      expect(handler.records.map((r) => r.message), ['kept']);
    });

    test('an explicit level overrides the parent', () {
      Logger.root.level = LogLevel.WARNING;
      final log = Logger('lt.explicit')..level = LogLevel.FINE;

      log.fine('kept');

      expect(handler.records.map((r) => r.message), ['kept']);
    });

    test('assigning null goes back to inheriting', () {
      Logger.root.level = LogLevel.SEVERE;
      final log = Logger('lt.nulled')..level = LogLevel.FINEST;

      log.level = null;

      expect(log.level, LogLevel.SEVERE);
    });
  });

  group('isLoggable', () {
    test('matches the effective level', () {
      final log = Logger('lt.loggable')..level = LogLevel.INFO;

      expect(log.isLoggable(LogLevel.FINE), isFalse);
      expect(log.isLoggable(LogLevel.INFO), isTrue);
      expect(log.isLoggable(LogLevel.SHOUT), isTrue);
    });

    test('OFF disables every level', () {
      final log = Logger('lt.off')..level = LogLevel.OFF;

      expect(log.isLoggable(LogLevel.SHOUT), isFalse);
    });
  });

  group('transformers', () {
    test('handlers and onRecord see the transformed record', () async {
      final log = Logger('lt.transform');
      Logger.root.addTransformer((r) => r.copyWith(message: 'x${r.message}'));
      final streamed = log.onRecord.first;

      log.info('a');

      expect(handler.records.single.message, 'xa');
      expect((await streamed).message, 'xa');
    });

    test('a null result drops the record for every handler', () {
      final own = _TestHandler();
      final log = Logger('lt.drop')..addHandler(own);
      Logger.root.addTransformer((r) => r.message == 'secret' ? null : r);

      log.info('secret');
      log.info('public');

      expect(own.records.map((r) => r.message), ['public']);
      expect(handler.records.map((r) => r.message), ['public']);
    });

    test('run from the origin logger up to root, in order added', () {
      final order = <String>[];
      LogRecordTransformer tag(String name) => (r) {
        order.add(name);
        return r;
      };
      Logger.root.addTransformer(tag('root'));
      Logger('lt.order').addTransformer(tag('parent'));
      Logger('lt.order.leaf')
        ..addTransformer(tag('leaf1'))
        ..addTransformer(tag('leaf2'));

      Logger('lt.order.leaf').info('m');

      expect(order, ['leaf1', 'leaf2', 'parent', 'root']);
    });

    test('a sibling transformer does not apply', () {
      Logger('lt.sib.a').addTransformer((_) => null);

      Logger('lt.sib.b').info('kept');

      expect(handler.records, hasLength(1));
    });

    test('do not run for records below the level', () {
      var calls = 0;
      Logger.root
        ..level = LogLevel.INFO
        ..addTransformer((r) {
          calls++;
          return r;
        });

      Logger('lt.cheap').fine('skipped');

      expect(calls, 0);
    });

    test('removeTransformer stops it', () {
      LogRecord? dropAll(LogRecord _) => null;
      Logger.root.addTransformer(dropAll);
      Logger.root.removeTransformer(dropAll);

      Logger('lt.removed').info('kept');

      expect(handler.records, hasLength(1));
    });
  });

  group('reset', () {
    test('clears handlers, transformers and levels', () {
      final own = _TestHandler();
      final log = Logger('lt.reset')
        ..addHandler(own)
        ..addTransformer((_) => null)
        ..level = LogLevel.SHOUT;
      Logger.root.level = LogLevel.SEVERE;

      Logger.reset();
      final after = _TestHandler();
      Logger.root.addHandler(after);
      log.fine('after');

      expect(Logger.root.level, LogLevel.FINEST);
      expect(log.level, LogLevel.FINEST);
      expect(log.handlers, isEmpty);
      expect(own.records, isEmpty);
      expect(after.records.single.message, 'after');
    });
  });
}
