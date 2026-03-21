import 'package:comon_logger/comon_logger.dart';
import 'package:comon_otel/comon_otel.dart' as otel;

import 'log_level_mapping.dart';

/// Bridges comon_logger records into the OpenTelemetry logs pipeline.
class OtelLogHandler extends LogHandler {
  OtelLogHandler({
    LogFilter filter = const AllPassLogFilter(),
    otel.LoggerProvider? loggerProvider,
  }) : _loggerProvider = loggerProvider ?? otel.Otel.instance.loggerProvider,
       super(filter: filter);

  final otel.LoggerProvider _loggerProvider;

  @override
  void handle(LogRecord record) {
    _loggerProvider.emit(
      otel.LogRecord.current(
        timestamp: record.time.toUtc(),
        severity: mapLogLevelToSeverity(record.level),
        severityText: mapLogLevelToSeverityText(record.level),
        body: record.message,
        attributes: _buildAttributes(record),
        resource: _loggerProvider.resource,
        loggerName: record.loggerName,
      ),
    );
  }

  Map<String, Object> _buildAttributes(LogRecord record) {
    final attributes = <String, Object>{
      'logger.name': record.loggerName,
      'comon.log.level': record.level.name,
    };

    if (record.layer != null) {
      attributes['comon.log.layer'] = record.layer!.name;
    }
    if (record.type != null) {
      attributes['comon.log.type'] = record.type!.name;
    }
    if (record.feature != null) {
      attributes['comon.log.feature'] = record.feature!;
    }
    if (record.error != null) {
      attributes[otel.SemanticAttributes.exceptionType] = record
          .error
          .runtimeType
          .toString();
      attributes[otel.SemanticAttributes.exceptionMessage] = record.error
          .toString();
    }
    if (record.stackTrace != null) {
      attributes[otel.SemanticAttributes.exceptionStacktrace] = record
          .stackTrace
          .toString();
    }
    if (record.extra != null) {
      _flattenExtra(attributes, 'comon.log.extra', record.extra!);
    }

    return attributes;
  }

  void _flattenExtra(
    Map<String, Object> target,
    String prefix,
    Map<String, dynamic> extra,
  ) {
    for (final entry in extra.entries) {
      final key = '$prefix.${entry.key}';
      final value = entry.value;

      if (value == null) {
        continue;
      }
      if (value is Map<String, dynamic>) {
        _flattenExtra(target, key, value);
        continue;
      }

      target[key] = _sanitizeAttributeValue(value);
    }
  }

  Object _sanitizeAttributeValue(Object value) {
    if (value is String || value is num || value is bool) {
      return value;
    }
    if (value is DateTime) {
      return value.toUtc().toIso8601String();
    }
    return value.toString();
  }
}
