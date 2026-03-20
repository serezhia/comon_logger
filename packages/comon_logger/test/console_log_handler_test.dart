import 'dart:async';

import 'package:comon_logger/comon_logger.dart';
import 'package:test/test.dart';

class _FixedFormatter extends LogFormatter {
  const _FixedFormatter(this.output);

  final String output;

  @override
  String format(LogRecord record) => output;
}

class _SelectiveFormatter extends LogFormatter {
  const _SelectiveFormatter({required this.output, required this.loggerName});

  final String output;
  final String loggerName;

  @override
  bool canFormat(LogRecord record) => record.loggerName == loggerName;

  @override
  String format(LogRecord record) => output;
}

void main() {
  final record = LogRecord(
    level: LogLevel.INFO,
    message: 'ignored',
    loggerName: 'test.console',
    time: DateTime(2026, 3, 16, 20, 18, 6, 183),
  );

  test('splits long console lines into safe chunks', () async {
    final handler = ConsoleLogHandler(
      formatter: const _FixedFormatter('123456789'),
      maxLineLength: 4,
    );

    final printed = <String>[];
    await runZoned(
      () async {
        handler.handle(record);
      },
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) {
          printed.add(line);
        },
      ),
    );

    expect(printed, ['1234', '5678', '9']);
  });

  test('preserves existing line breaks when chunking', () async {
    final handler = ConsoleLogHandler(
      formatter: const _FixedFormatter('abcd\nefghi'),
      maxLineLength: 3,
    );

    final printed = <String>[];
    await runZoned(
      () async {
        handler.handle(record);
      },
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) {
          printed.add(line);
        },
      ),
    );

    expect(printed, ['abc', 'd', 'efg', 'hi']);
  });

  test('uses the first matching formatter add-on before fallback', () async {
    final handler = ConsoleLogHandler(
      formatter: const _FixedFormatter('fallback'),
      formatters: const [
        _SelectiveFormatter(output: 'special', loggerName: 'test.console'),
      ],
    );

    final printed = <String>[];
    await runZoned(
      () async {
        handler.handle(record);
      },
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) {
          printed.add(line);
        },
      ),
    );

    expect(printed, ['special']);
  });

  test('falls back to the default formatter when no add-on matches', () async {
    final handler = ConsoleLogHandler(
      formatter: const _FixedFormatter('fallback'),
      formatters: const [
        _SelectiveFormatter(output: 'special', loggerName: 'another.logger'),
      ],
    );

    final printed = <String>[];
    await runZoned(
      () async {
        handler.handle(record);
      },
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) {
          printed.add(line);
        },
      ),
    );

    expect(printed, ['fallback']);
  });
}
