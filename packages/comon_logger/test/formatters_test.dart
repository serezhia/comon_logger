import 'package:comon_logger/comon_logger.dart';
import 'package:test/test.dart';

void main() {
  final time = DateTime(2026, 2, 27, 12, 34, 56, 789);

  LogRecord makeRecord({
    LogLevel level = LogLevel.INFO,
    String message = 'Test message',
    String loggerName = 'test.logger',
    Object? error,
    StackTrace? stackTrace,
    LogLayer? layer,
    LogType? type,
    String? feature,
    Map<String, dynamic>? extra,
  }) {
    return LogRecord(
      level: level,
      message: message,
      loggerName: loggerName,
      time: time,
      error: error,
      stackTrace: stackTrace,
      layer: layer,
      type: type,
      feature: feature,
      extra: extra,
    );
  }

  group('SimpleLogFormatter', () {
    const formatter = SimpleLogFormatter();

    test('formats basic record', () {
      final output = formatter.format(makeRecord());
      expect(output, contains('12:34:56.789'));
      expect(output, contains('[INFO]'));
      expect(output, contains('test.logger:'));
      expect(output, contains('Test message'));
    });

    test('includes tags when present', () {
      final output = formatter.format(
        makeRecord(
          layer: LogLayer.data,
          type: LogType.network,
          feature: 'catalog',
        ),
      );
      expect(output, contains('{data|network|catalog}'));
    });

    test('omits tags when absent', () {
      final output = formatter.format(makeRecord());
      expect(output, isNot(contains('{')));
    });

    test('includes error when present', () {
      final output = formatter.format(makeRecord(error: Exception('boom')));
      expect(output, contains('Error:'));
      expect(output, contains('boom'));
    });

    test('handles empty loggerName', () {
      final output = formatter.format(makeRecord(loggerName: ''));
      expect(output, contains(':'));
      expect(output, contains('Test message'));
    });
  });

  group('PrettyLogFormatter', () {
    const formatter = PrettyLogFormatter(useColors: false);

    test('starts with top border and ends with bottom border', () {
      final output = formatter.format(makeRecord());
      final lines = output.split('\n');
      expect(lines.first, startsWith('┌'));
      expect(lines.last, startsWith('└'));
    });

    test('includes emoji for level', () {
      final output = formatter.format(makeRecord(level: LogLevel.INFO));
      expect(output, contains('🔵'));

      final warnOutput = formatter.format(makeRecord(level: LogLevel.WARNING));
      expect(warnOutput, contains('🟡'));

      final severeOutput = formatter.format(makeRecord(level: LogLevel.SEVERE));
      expect(severeOutput, contains('🔴'));
    });

    test('includes message', () {
      final output = formatter.format(makeRecord(message: 'Hello world'));
      expect(output, contains('Hello world'));
    });

    test('includes tags in header', () {
      final output = formatter.format(
        makeRecord(
          layer: LogLayer.data,
          type: LogType.network,
          feature: 'catalog',
        ),
      );
      expect(output, contains('data'));
      expect(output, contains('network'));
      expect(output, contains('catalog'));
    });

    test('includes error', () {
      final output = formatter.format(
        makeRecord(error: Exception('test error')),
      );
      expect(output, contains('Error:'));
      expect(output, contains('test error'));
    });

    test('includes stack trace with limit', () {
      final stack = StackTrace.current;
      final output = formatter.format(makeRecord(stackTrace: stack));
      // Should contain stack trace lines
      expect(output, contains('│'));
    });

    test('includes extra as JSON', () {
      final output = formatter.format(
        makeRecord(extra: {'key': 'value', 'count': 42}),
      );
      expect(output, contains('"key"'));
      expect(output, contains('"value"'));
      expect(output, contains('42'));
    });

    test('handles multi-line messages', () {
      final output = formatter.format(
        makeRecord(message: 'Line 1\nLine 2\nLine 3'),
      );
      expect(output, contains('Line 1'));
      expect(output, contains('Line 2'));
      expect(output, contains('Line 3'));
    });
  });
}
