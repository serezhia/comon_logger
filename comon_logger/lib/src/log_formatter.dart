import 'log_record.dart';

/// Base class for log formatters.
///
/// A formatter converts a [LogRecord] into a human-readable string
/// for output by a [LogHandler].
abstract class LogFormatter {
  const LogFormatter();

  /// Formats [record] as a string.
  String format(LogRecord record);
}
