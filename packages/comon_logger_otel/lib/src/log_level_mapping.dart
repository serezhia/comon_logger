import 'package:comon_logger/comon_logger.dart';
import 'package:comon_otel/comon_otel.dart';

/// Maps comon_logger levels to OpenTelemetry severities.
SeverityNumber mapLogLevelToSeverity(LogLevel level) {
  if (level >= LogLevel.SHOUT) {
    return SeverityNumber.fatal;
  }
  if (level >= LogLevel.SEVERE) {
    return SeverityNumber.error;
  }
  if (level >= LogLevel.WARNING) {
    return SeverityNumber.warn;
  }
  if (level >= LogLevel.INFO) {
    return SeverityNumber.info;
  }
  if (level >= LogLevel.CONFIG) {
    return SeverityNumber.debug2;
  }
  if (level >= LogLevel.FINE) {
    return SeverityNumber.debug;
  }
  if (level >= LogLevel.FINER) {
    return SeverityNumber.trace2;
  }
  return SeverityNumber.trace;
}

/// Returns the exported text label for a mapped severity.
String mapLogLevelToSeverityText(LogLevel level) {
  return switch (mapLogLevelToSeverity(level)) {
    SeverityNumber.trace => 'TRACE',
    SeverityNumber.trace2 => 'TRACE2',
    SeverityNumber.debug => 'DEBUG',
    SeverityNumber.debug2 => 'DEBUG2',
    SeverityNumber.info => 'INFO',
    SeverityNumber.warn => 'WARN',
    SeverityNumber.error => 'ERROR',
    SeverityNumber.fatal => 'FATAL',
    final severity => severity.name.toUpperCase(),
  };
}
