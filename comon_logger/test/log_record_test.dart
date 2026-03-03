import 'package:comon_logger/comon_logger.dart';
import 'package:test/test.dart';

void main() {
  group('LogRecord', () {
    late LogRecord record;
    late DateTime time;

    setUp(() {
      time = DateTime(2026, 2, 27, 12, 34, 56, 789);
      record = LogRecord(
        level: LogLevel.INFO,
        message: 'Test message',
        loggerName: 'test.logger',
        time: time,
        layer: LogLayer.data,
        type: LogType.network,
        feature: 'catalog',
        extra: {'key': 'value'},
      );
    });

    test('stores all fields correctly', () {
      expect(record.level, LogLevel.INFO);
      expect(record.message, 'Test message');
      expect(record.loggerName, 'test.logger');
      expect(record.time, time);
      expect(record.layer, LogLayer.data);
      expect(record.type, LogType.network);
      expect(record.feature, 'catalog');
      expect(record.extra, {'key': 'value'});
      expect(record.error, isNull);
      expect(record.stackTrace, isNull);
    });

    test('stores error and stackTrace', () {
      final error = Exception('Test error');
      final stack = StackTrace.current;
      final r = LogRecord(
        level: LogLevel.SEVERE,
        message: 'Error occurred',
        loggerName: 'test',
        time: time,
        error: error,
        stackTrace: stack,
      );

      expect(r.error, error);
      expect(r.stackTrace, stack);
    });

    test('nullable fields default to null', () {
      final r = LogRecord(
        level: LogLevel.INFO,
        message: 'Simple',
        loggerName: '',
        time: time,
      );

      expect(r.error, isNull);
      expect(r.stackTrace, isNull);
      expect(r.layer, isNull);
      expect(r.type, isNull);
      expect(r.feature, isNull);
      expect(r.extra, isNull);
    });

    group('copyWith', () {
      test('copies with new message', () {
        final copy = record.copyWith(message: 'New message');
        expect(copy.message, 'New message');
        expect(copy.level, record.level);
        expect(copy.loggerName, record.loggerName);
        expect(copy.time, record.time);
        expect(copy.layer, record.layer);
      });

      test('copies with new level', () {
        final copy = record.copyWith(level: LogLevel.WARNING);
        expect(copy.level, LogLevel.WARNING);
        expect(copy.message, record.message);
      });

      test('preserves all fields when no arguments given', () {
        final copy = record.copyWith();
        expect(copy.level, record.level);
        expect(copy.message, record.message);
        expect(copy.loggerName, record.loggerName);
        expect(copy.time, record.time);
        expect(copy.layer, record.layer);
        expect(copy.type, record.type);
        expect(copy.feature, record.feature);
        expect(copy.extra, record.extra);
      });
    });

    group('toJson / fromJson', () {
      test('round-trips correctly', () {
        final json = record.toJson();
        final restored = LogRecord.fromJson(json);

        expect(restored.level, record.level);
        expect(restored.message, record.message);
        expect(restored.loggerName, record.loggerName);
        expect(restored.time, record.time);
        expect(restored.layer, record.layer);
        expect(restored.type, record.type);
        expect(restored.feature, record.feature);
        expect(restored.extra, record.extra);
      });

      test('toJson includes correct fields', () {
        final json = record.toJson();
        expect(json['level'], 'INFO');
        expect(json['levelValue'], 800);
        expect(json['message'], 'Test message');
        expect(json['loggerName'], 'test.logger');
        expect(json['time'], time.toIso8601String());
        expect(json['layer'], 'data');
        expect(json['type'], 'network');
        expect(json['feature'], 'catalog');
        expect(json['extra'], {'key': 'value'});
      });

      test('toJson omits null fields', () {
        final simple = LogRecord(
          level: LogLevel.INFO,
          message: 'Simple',
          loggerName: 'test',
          time: time,
        );
        final json = simple.toJson();
        expect(json.containsKey('error'), isFalse);
        expect(json.containsKey('stackTrace'), isFalse);
        expect(json.containsKey('layer'), isFalse);
        expect(json.containsKey('type'), isFalse);
        expect(json.containsKey('feature'), isFalse);
        expect(json.containsKey('extra'), isFalse);
      });

      test('round-trips with error', () {
        final r = LogRecord(
          level: LogLevel.SEVERE,
          message: 'Error',
          loggerName: 'test',
          time: time,
          error: Exception('fail'),
        );
        final json = r.toJson();
        expect(json['error'], contains('fail'));

        final restored = LogRecord.fromJson(json);
        expect(restored.error, isA<String>());
        expect(restored.error.toString(), contains('fail'));
      });

      test('fromJson handles unknown level', () {
        final json = {
          'level': 'CUSTOM_LEVEL',
          'levelValue': 950,
          'message': 'test',
          'loggerName': 'test',
          'time': time.toIso8601String(),
        };
        final r = LogRecord.fromJson(json);
        expect(r.level.name, 'CUSTOM_LEVEL');
        expect(r.level.value, 950);
      });

      test('fromJson handles unknown layer/type', () {
        final json = {
          'level': 'INFO',
          'levelValue': 800,
          'message': 'test',
          'loggerName': 'test',
          'time': time.toIso8601String(),
          'layer': 'unknown_layer',
          'type': 'unknown_type',
        };
        final r = LogRecord.fromJson(json);
        expect(r.layer?.name, 'unknown_layer');
        expect(r.type?.name, 'unknown_type');
      });
    });

    test('toString produces readable output', () {
      final str = record.toString();
      expect(str, contains('[INFO]'));
      expect(str, contains('test.logger'));
      expect(str, contains('Test message'));
      expect(str, contains('data'));
      expect(str, contains('network'));
      expect(str, contains('catalog'));
    });

    test('toString with error/stack', () {
      final r = LogRecord(
        level: LogLevel.SEVERE,
        message: 'Crash',
        loggerName: 'test',
        time: time,
        error: Exception('boom'),
        stackTrace: StackTrace.current,
      );
      final str = r.toString();
      expect(str, contains('Error:'));
      expect(str, contains('boom'));
      expect(str, contains('StackTrace:'));
    });
  });
}
