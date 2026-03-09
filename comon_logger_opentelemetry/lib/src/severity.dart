import 'package:comon_logger/comon_logger.dart';

import 'proto/logs.pbenum.dart';

/// Maps [LogLevel] to OTLP [SeverityNumber] and severity text.

(SeverityNumber, String) mapSeverity(LogLevel level) {
  if (level >= LogLevel.SHOUT) {
    return (SeverityNumber.SEVERITY_NUMBER_FATAL, 'FATAL');
  }
  if (level >= LogLevel.SEVERE) {
    return (SeverityNumber.SEVERITY_NUMBER_ERROR, 'ERROR');
  }
  if (level >= LogLevel.WARNING) {
    return (SeverityNumber.SEVERITY_NUMBER_WARN, 'WARN');
  }
  if (level >= LogLevel.INFO) {
    return (SeverityNumber.SEVERITY_NUMBER_INFO, 'INFO');
  }
  if (level >= LogLevel.FINE) {
    return (SeverityNumber.SEVERITY_NUMBER_DEBUG, 'DEBUG');
  }
  return (SeverityNumber.SEVERITY_NUMBER_TRACE, 'TRACE');
}
