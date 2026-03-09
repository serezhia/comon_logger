import 'package:comon_logger/comon_logger.dart';
import 'package:fixnum/fixnum.dart';

import 'log_exporter.dart';
import 'proto/common.pb.dart' as otel_common;
import 'severity.dart';

/// A [LogHandler] that exports log records to an OTLP gRPC endpoint.
///
/// Logs are buffered and sent asynchronously. If the gRPC endpoint is
/// unreachable, logs are silently dropped.
///
/// ```dart
/// Logger.root.addHandler(OtlpLogHandler(
///   endpoint: 'netdata:4317',
///   serviceName: 'my-server',
/// ));
/// ```
class OtlpLogHandler extends LogHandler {
  OtlpLogHandler({
    required String endpoint,
    String serviceName = 'dart-server',
    String? serviceVersion,
    bool insecure = true,
    super.filter = const AllPassLogFilter(),
  }) : _exporter = LogExporter(
          endpoint: endpoint,
          serviceName: serviceName,
          serviceVersion: serviceVersion,
          insecure: insecure,
        );

  final LogExporter _exporter;

  @override
  void handle(LogRecord record) {
    final (severityNumber, severityText) = mapSeverity(record.level);

    final timeNanos = Int64(record.time.microsecondsSinceEpoch) * 1000;

    final attributes = <otel_common.KeyValue>[];

    if (record.feature != null) {
      attributes.add(otel_common.KeyValue(
        key: 'LOG_FEATURE',
        value: otel_common.AnyValue(stringValue: record.feature),
      ));
    }

    if (record.error != null) {
      attributes.add(otel_common.KeyValue(
        key: 'LOG_ERROR',
        value: otel_common.AnyValue(stringValue: record.error.toString()),
      ));
    }

    if (record.stackTrace != null) {
      attributes.add(otel_common.KeyValue(
        key: 'LOG_STACK_TRACE',
        value:
            otel_common.AnyValue(stringValue: record.stackTrace.toString()),
      ));
    }

    if (record.layer != null) {
      attributes.add(otel_common.KeyValue(
        key: 'LOG_LAYER',
        value: otel_common.AnyValue(stringValue: record.layer.toString()),
      ));
    }

    if (record.type != null) {
      attributes.add(otel_common.KeyValue(
        key: 'LOG_TYPE',
        value: otel_common.AnyValue(stringValue: record.type.toString()),
      ));
    }

    if (record.extra != null) {
      for (final entry in record.extra!.entries) {
        attributes.add(otel_common.KeyValue(
          key: entry.key,
          value: _toAnyValue(entry.value),
        ));
      }
    }

    _exporter.add(
      timeUnixNano: timeNanos,
      severityNumber: severityNumber,
      severityText: severityText,
      body: record.message,
      scopeName: record.loggerName,
      attributes: attributes,
    );
  }

  /// Flushes remaining buffered logs and closes the gRPC channel.
  Future<void> shutdown() => _exporter.shutdown();
}

otel_common.AnyValue _toAnyValue(Object? value) {
  return switch (value) {
    final String s => otel_common.AnyValue(stringValue: s),
    final int i => otel_common.AnyValue(intValue: Int64(i)),
    final double d => otel_common.AnyValue(doubleValue: d),
    final bool b => otel_common.AnyValue(boolValue: b),
    _ => otel_common.AnyValue(stringValue: value.toString()),
  };
}
