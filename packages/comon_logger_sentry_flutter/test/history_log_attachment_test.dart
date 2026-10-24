import 'dart:convert';

import 'package:comon_logger/comon_logger.dart';
import 'package:comon_logger_flutter/comon_logger_flutter.dart';
import 'package:comon_logger_sentry_flutter/comon_logger_sentry_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late HistoryLogHandler history;

  setUp(() => history = HistoryLogHandler());
  tearDown(() => history.dispose());

  LogRecord record(String message) => LogRecord(
    level: LogLevel.INFO,
    message: message,
    loggerName: 'app',
    time: DateTime.utc(2026, 10, 24, 12),
  );

  test('carries the latest records as text', () async {
    for (final message in ['one', 'two', 'three']) {
      history.handle(record(message));
    }

    final attachment = historyLogAttachment(history, maxRecords: 2);

    expect(attachment.filename, 'log.txt');
    expect(attachment.contentType, 'text/plain');
    final text = utf8.decode(await attachment.bytes);
    expect(text.split('\n'), hasLength(2));
    expect(text, isNot(contains('one')));
    expect(text, contains('two'));
    expect(text, contains('three'));
  });

  test('reads the history when the event is sent', () async {
    final attachment = historyLogAttachment(history);

    history.handle(record('after the attachment'));

    expect(
      utf8.decode(await attachment.bytes),
      contains('after the attachment'),
    );
  });

  test('formats each record with the given formatter', () async {
    history.handle(record('json line'));

    final attachment = historyLogAttachment(
      history,
      formatter: const _MessageFormatter(),
      filename: 'comon-log.txt',
    );

    expect(attachment.filename, 'comon-log.txt');
    expect(utf8.decode(await attachment.bytes), 'json line');
  });
}

class _MessageFormatter extends LogFormatter {
  const _MessageFormatter();

  @override
  String format(LogRecord record) => record.message;
}
