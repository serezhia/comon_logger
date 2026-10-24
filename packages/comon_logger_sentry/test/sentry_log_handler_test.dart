import 'dart:async';

import 'package:comon_logger/comon_logger.dart';
import 'package:comon_logger_sentry/comon_logger_sentry.dart';
import 'package:sentry/sentry.dart';
import 'package:test/test.dart';

void main() {
  late _RecordingHub hub;

  setUp(() => hub = _RecordingHub());
  tearDown(Logger.reset);

  group('SentryLogHandler', () {
    test('turns a record below the event level into a breadcrumb only', () {
      SentryLogHandler(hub: hub).handle(
        LogRecord(
          level: LogLevel.INFO,
          message: 'history opened',
          loggerName: 'cdlib.history',
          time: DateTime.utc(2026, 10, 24, 12),
          layer: LogLayer.data,
          type: LogType.database,
          feature: 'chats',
          extra: {'chatId': 'c1'},
        ),
      );

      expect(hub.calls, ['breadcrumb']);
      final crumb = hub.breadcrumbs.single;
      expect(crumb.message, 'history opened');
      expect(crumb.category, 'cdlib.history');
      expect(crumb.level, SentryLevel.info);
      expect(crumb.type, 'default');
      expect(crumb.timestamp, DateTime.utc(2026, 10, 24, 12));
      expect(crumb.data, {
        'log.layer': 'data',
        'log.type': 'database',
        'log.feature': 'chats',
        'chatId': 'c1',
      });
    });

    test('reports a severe record as an event before its breadcrumb', () {
      final error = StateError('store closed');
      final stack = StackTrace.current;

      SentryLogHandler(hub: hub).handle(
        LogRecord(
          level: LogLevel.SEVERE,
          message: 'Page failed',
          loggerName: 'cdlib.history',
          time: DateTime.utc(2026, 10, 24, 12),
          error: error,
          stackTrace: stack,
          feature: 'chats',
          extra: {'chatId': 'c1'},
        ),
      );

      expect(hub.calls, ['event', 'breadcrumb']);
      final event = hub.events.single;
      expect(event.throwable, same(error));
      expect(event.message?.formatted, 'Page failed');
      expect(event.logger, 'cdlib.history');
      expect(event.level, SentryLevel.error);
      expect(event.timestamp, DateTime.utc(2026, 10, 24, 12));
      expect(event.tags, {'log.feature': 'chats'});
      expect(event.contexts['log'], {'chatId': 'c1'});
      expect(hub.stackTraces.single, same(stack));
      expect(hub.breadcrumbs.single.type, 'error');
      expect(hub.breadcrumbs.single.data?['error'], 'Bad state: store closed');
    });

    test('reports a record without an error as a message event', () {
      SentryLogHandler(hub: hub).handle(
        LogRecord(
          level: LogLevel.SHOUT,
          message: 'Startup failed',
          loggerName: 'app',
          time: DateTime.utc(2026, 10, 24, 12),
        ),
      );

      final event = hub.events.single;
      expect(event.throwable, isNull);
      expect(event.message?.formatted, 'Startup failed');
      expect(event.level, SentryLevel.fatal);
      expect(event.contexts['log'], isNull);
    });

    test('reports as events only the records its event filter takes', () {
      final handler = SentryLogHandler(
        eventFilter: const _LoggerFilter('cdlib.calls.media'),
        hub: hub,
      );

      handler.handle(
        LogRecord(
          level: LogLevel.WARNING,
          message: 'audio poor',
          loggerName: 'cdlib.calls.media',
          time: DateTime.utc(2026, 10, 24, 12),
        ),
      );
      handler.handle(
        LogRecord(
          level: LogLevel.SEVERE,
          message: 'Uncaught error',
          loggerName: 'app.uncaught',
          time: DateTime.utc(2026, 10, 24, 12),
          error: StateError('caught by Sentry itself'),
        ),
      );

      expect(hub.calls, ['event', 'breadcrumb', 'breadcrumb']);
      expect(hub.events.single.message?.formatted, 'audio poor');
    });

    test('receives records after the root transformers and its filter', () {
      Logger.root
        ..addTransformer(RedactLogTransformer(keys: {'token'}).call)
        ..addHandler(
          SentryLogHandler(filter: LevelLogFilter(LogLevel.INFO), hub: hub),
        );
      final log = Logger('push');

      log.fine('Registering');
      log.info('Registered', extra: {'token': 'secret-value'});

      expect(hub.breadcrumbs.single.message, 'Registered');
      expect(hub.breadcrumbs.single.data, {'token': '<redacted>'});
    });
  });

  group('with Sentry running', () {
    late _RecordingTransport transport;

    setUp(() async {
      transport = _RecordingTransport();
      await Sentry.init(
        (options) => options
          ..dsn = 'https://key@errors.example.org/2'
          ..transport = transport,
      );
    });
    tearDown(Sentry.close);

    test('an event carries the trail up to its record, not after it', () async {
      Logger.root.addHandler(SentryLogHandler());
      final log = Logger('cdlib.history');

      log.info('history opened');
      log.severe('Page failed', error: StateError('store closed'));
      log.info('history closed');
      await transport.sent;

      final event = transport.events.single;
      expect(event.breadcrumbs?.map((crumb) => crumb.message), [
        'history opened',
      ]);
    });
  });

  group('mapLogLevelToSentryLevel', () {
    test('maps predefined levels', () {
      expect(mapLogLevelToSentryLevel(LogLevel.FINEST), SentryLevel.debug);
      expect(mapLogLevelToSentryLevel(LogLevel.CONFIG), SentryLevel.debug);
      expect(mapLogLevelToSentryLevel(LogLevel.INFO), SentryLevel.info);
      expect(mapLogLevelToSentryLevel(LogLevel.WARNING), SentryLevel.warning);
      expect(mapLogLevelToSentryLevel(LogLevel.SEVERE), SentryLevel.error);
      expect(mapLogLevelToSentryLevel(LogLevel.SHOUT), SentryLevel.fatal);
    });

    test('maps a custom level to the predefined level below it', () {
      expect(
        mapLogLevelToSentryLevel(const LogLevel('AUDIT', 950)),
        SentryLevel.warning,
      );
    });
  });
}

class _LoggerFilter extends LogFilter {
  const _LoggerFilter(this.loggerName);
  final String loggerName;

  @override
  bool shouldLog(LogRecord record) => record.loggerName == loggerName;
}

/// Records what the handler hands to Sentry; nothing leaves the test.
class _RecordingHub implements Hub {
  final calls = <String>[];
  final events = <SentryEvent>[];
  final stackTraces = <Object?>[];
  final breadcrumbs = <Breadcrumb>[];

  @override
  Future<SentryId> captureEvent(
    SentryEvent event, {
    dynamic stackTrace,
    Hint? hint,
    ScopeCallback? withScope,
  }) async {
    calls.add('event');
    events.add(event);
    stackTraces.add(stackTrace);
    return event.eventId;
  }

  @override
  Future<void> addBreadcrumb(Breadcrumb crumb, {Hint? hint}) async {
    calls.add('breadcrumb');
    breadcrumbs.add(crumb);
  }

  @override
  Object? noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// Keeps what Sentry would send; nothing leaves the test.
class _RecordingTransport implements Transport {
  final events = <SentryEvent>[];
  final _sent = Completer<void>();

  /// Completes with the first event; Sentry sends after the log call returns.
  Future<void> get sent => _sent.future;

  @override
  Future<SentryId?> send(SentryEnvelope envelope) async {
    for (final item in envelope.items) {
      if (item.originalObject case final SentryEvent event) events.add(event);
    }
    if (!_sent.isCompleted) _sent.complete();
    return envelope.header.eventId;
  }
}
