import 'package:comon_logger/comon_logger.dart';
import 'package:comon_logger_otel/comon_logger_otel.dart';
import 'package:comon_otel/comon_otel.dart' as otel;
import 'package:test/test.dart';

void main() {
  group('OtelLogHandler', () {
    test('maps severity and preserves structured attributes', () {
      final processor = _RecordingLogProcessor();
      final handler = OtelLogHandler(
        loggerProvider: otel.LoggerProvider(
          resource: otel.Resource(serviceName: 'logger-test'),
          logProcessors: <otel.LogProcessor>[processor],
        ),
      );

      handler.handle(
        LogRecord(
          level: LogLevel.WARNING,
          message: 'disk almost full',
          loggerName: 'storage.monitor',
          time: DateTime.utc(2026, 3, 21, 10, 0, 0),
          feature: 'storage',
          extra: <String, dynamic>{
            'freeBytes': 1024,
            'nested': <String, dynamic>{'mount': '/tmp'},
          },
        ),
      );

      final record = processor.records.single;
      expect(record.severity, otel.SeverityNumber.warn);
      expect(record.severityText, 'WARN');
      expect(record.body, 'disk almost full');
      expect(record.loggerName, 'storage.monitor');
      expect(record.attributes['comon.log.feature'], 'storage');
      expect(record.attributes['comon.log.extra.freeBytes'], 1024);
      expect(record.attributes['comon.log.extra.nested.mount'], '/tmp');
    });

    test('captures the active span context when emitting logs', () async {
      final logProcessor = _RecordingLogProcessor();
      final loggerProvider = otel.LoggerProvider(
        resource: otel.Resource(serviceName: 'logger-test'),
        logProcessors: <otel.LogProcessor>[logProcessor],
      );
      final tracerProvider = otel.TracerProvider(
        resource: otel.Resource(serviceName: 'logger-test'),
        spanProcessors: <otel.SpanProcessor>[],
        sampler: const otel.AlwaysOnSampler(),
      );
      final handler = OtelLogHandler(loggerProvider: loggerProvider);
      final tracer = tracerProvider.getTracer('logger-test');
      final span = tracer.startSpan('active-operation');

      otel.OtelContext.withSpan(span, () {
        handler.handle(
          LogRecord(
            level: LogLevel.INFO,
            message: 'inside span',
            loggerName: 'test.logger',
            time: DateTime.utc(2026, 3, 21, 10, 30, 0),
          ),
        );
      });

      final record = logProcessor.records.single;
      expect(record.traceId, span.traceId);
      expect(record.spanId, span.spanId);

      await span.end();
    });
  });

  group('mapLogLevelToSeverity', () {
    test('maps built-in levels to OpenTelemetry severities', () {
      expect(mapLogLevelToSeverity(LogLevel.FINEST), otel.SeverityNumber.trace);
      expect(mapLogLevelToSeverity(LogLevel.FINER), otel.SeverityNumber.trace2);
      expect(mapLogLevelToSeverity(LogLevel.FINE), otel.SeverityNumber.debug);
      expect(
        mapLogLevelToSeverity(LogLevel.CONFIG),
        otel.SeverityNumber.debug2,
      );
      expect(mapLogLevelToSeverity(LogLevel.INFO), otel.SeverityNumber.info);
      expect(mapLogLevelToSeverity(LogLevel.WARNING), otel.SeverityNumber.warn);
      expect(mapLogLevelToSeverity(LogLevel.SEVERE), otel.SeverityNumber.error);
      expect(mapLogLevelToSeverity(LogLevel.SHOUT), otel.SeverityNumber.fatal);
    });
  });
}

class _RecordingLogProcessor implements otel.LogProcessor {
  final List<otel.LogRecord> records = <otel.LogRecord>[];

  @override
  void onEmit(otel.LogRecord record) {
    records.add(record);
  }

  @override
  Future<void> forceFlush() async {}

  @override
  Future<void> shutdown() async {}
}
