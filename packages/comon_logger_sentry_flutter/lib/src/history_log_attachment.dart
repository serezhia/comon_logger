import 'dart:convert';

import 'package:comon_logger/comon_logger.dart';
import 'package:comon_logger_flutter/comon_logger_flutter.dart';
import 'package:sentry/sentry.dart';

/// A Sentry attachment with the latest [maxRecords] records of [history]
/// that pass [filter], as text, one record per line.
///
/// The text is read when an event is sent, not when the attachment is
/// created, so one attachment added to the scope serves every event:
///
/// ```dart
/// Sentry.configureScope(
///   (scope) => scope.addAttachment(historyLogAttachment(history)),
/// );
/// ```
///
/// Sentry does not scrub attachments: the records are sent as the handler
/// stored them, after the logger's transformers.
SentryAttachment historyLogAttachment(
  HistoryLogHandler history, {
  int maxRecords = 500,
  LogFilter filter = const AllPassLogFilter(),
  LogFormatter formatter = const SimpleLogFormatter(),
  String filename = 'log.txt',
}) {
  assert(maxRecords > 0);
  return SentryAttachment.fromLoader(
    loader: () {
      final records = history.history.where(filter.shouldLog).toList();
      final tail = records.skip(
        records.length > maxRecords ? records.length - maxRecords : 0,
      );
      return utf8.encode(tail.map(formatter.format).join('\n'));
    },
    filename: filename,
    contentType: 'text/plain',
  );
}
