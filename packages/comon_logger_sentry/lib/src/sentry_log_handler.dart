import 'dart:async';

import 'package:comon_logger/comon_logger.dart';
import 'package:sentry/sentry.dart';

import 'log_level_mapping.dart';

/// Sends comon_logger records to Sentry.
///
/// Every record that passes [filter] becomes a breadcrumb, the trail Sentry
/// attaches to the next event. A record at [eventLevel] or above also becomes
/// an event of its own, with its error and stack trace when it has them.
///
/// The handler only reports: the app initializes Sentry (`Sentry.init` or
/// `SentryFlutter.init`) and decides what may leave the device. Transformers
/// on the logger run before handlers, so a `RedactLogTransformer` on
/// [Logger.root] also covers what Sentry receives.
class SentryLogHandler extends LogHandler {
  SentryLogHandler({
    LogFilter filter = const AllPassLogFilter(),
    this.eventLevel = LogLevel.SEVERE,
    Hub? hub,
  }) : _hub = hub ?? HubAdapter(),
       super(filter: filter);

  /// The lowest level reported as an event rather than only a breadcrumb.
  final LogLevel eventLevel;

  final Hub _hub;

  @override
  void handle(LogRecord record) {
    // The event goes first, so its own record is not the last breadcrumb of
    // its trail.
    if (record.level >= eventLevel) {
      unawaited(
        _hub.captureEvent(_event(record), stackTrace: record.stackTrace),
      );
    }
    unawaited(_hub.addBreadcrumb(_breadcrumb(record)));
  }

  SentryEvent _event(LogRecord record) => SentryEvent(
    timestamp: record.time.toUtc(),
    logger: record.loggerName,
    level: mapLogLevelToSentryLevel(record.level),
    message: SentryMessage(record.message),
    throwable: record.error,
    tags: _tags(record),
    contexts: switch (record.extra) {
      final extra? => Contexts()..['log'] = extra,
      null => null,
    },
  );

  Breadcrumb _breadcrumb(LogRecord record) => Breadcrumb(
    timestamp: record.time.toUtc(),
    category: record.loggerName,
    level: mapLogLevelToSentryLevel(record.level),
    type: record.level >= LogLevel.SEVERE ? 'error' : 'default',
    message: record.message,
    data: {
      ..._tags(record),
      if (record.error case final error?) 'error': '$error',
      ...?record.extra,
    },
  );

  Map<String, String> _tags(LogRecord record) => {
    if (record.layer case final layer?) 'log.layer': layer.name,
    if (record.type case final type?) 'log.type': type.name,
    if (record.feature case final feature?) 'log.feature': feature,
  };
}
