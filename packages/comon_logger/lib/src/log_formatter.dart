import 'log_record.dart';

/// Base class for log formatters.
///
/// A formatter converts a [LogRecord] into a human-readable string
/// for output by a [LogHandler].
abstract class LogFormatter {
  const LogFormatter();

  /// Whether this formatter should handle [record].
  ///
  /// Console handlers can use this to try formatter add-ons in order and fall
  /// back to a default formatter when none match.
  bool canFormat(LogRecord record) => true;

  /// Formats [record] as a string.
  String format(LogRecord record);
}
