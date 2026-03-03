import 'log_record.dart';

/// Base class for log filters.
///
/// Each [LogHandler] has a filter that determines whether a given
/// [LogRecord] should be processed by that handler.
abstract class LogFilter {
  const LogFilter();

  /// Returns `true` if [record] should be logged.
  bool shouldLog(LogRecord record);
}
