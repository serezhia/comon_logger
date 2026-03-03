import 'log_filter.dart';
import 'log_record.dart';

/// Base class for log handlers.
///
/// A handler receives [LogRecord]s that pass its [filter] and processes
/// them (e.g. prints to console, writes to file, sends to analytics).
abstract class LogHandler {
  const LogHandler({required this.filter});

  /// The filter that determines whether a record should be handled.
  final LogFilter filter;

  /// Process a [record]. Only called when [filter.shouldLog] returns `true`.
  void handle(LogRecord record);
}
