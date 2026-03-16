import '../filters/all_pass_log_filter.dart';
import '../formatters/pretty_log_formatter.dart';
import '../log_formatter.dart';
import '../log_handler.dart';
import '../log_record.dart';

/// A handler that prints formatted log records to the console.
class ConsoleLogHandler extends LogHandler {
  ConsoleLogHandler({
    super.filter = const AllPassLogFilter(),
    LogFormatter? formatter,
    List<LogFormatter> formatters = const [],
    this.maxLineLength = 800,
  })  : _formatter = formatter ?? const PrettyLogFormatter(),
        _formatters = List.unmodifiable(formatters);

  final LogFormatter _formatter;
  final List<LogFormatter> _formatters;

  /// Formatter add-ons tried before the fallback [formatter].
  ///
  /// The first formatter whose [LogFormatter.canFormat] returns `true` wins.
  List<LogFormatter> get formatters => _formatters;

  /// Maximum length of a single printed console line.
  ///
  /// Flutter/logcat can truncate long lines, so formatted output is split into
  /// smaller chunks before printing.
  final int maxLineLength;

  @override
  void handle(LogRecord record) {
    final formatter = _resolveFormatter(record);
    final formatted = formatter.format(record);
    for (final line in formatted.split('\n')) {
      for (final chunk in _splitLine(line)) {
        // ignore: avoid_print
        print(chunk);
      }
    }
  }

  LogFormatter _resolveFormatter(LogRecord record) {
    for (final formatter in _formatters) {
      if (formatter.canFormat(record)) {
        return formatter;
      }
    }
    return _formatter;
  }

  Iterable<String> _splitLine(String line) sync* {
    if (maxLineLength <= 0 || line.length <= maxLineLength) {
      yield line;
      return;
    }

    for (var start = 0; start < line.length; start += maxLineLength) {
      final end = start + maxLineLength;
      yield line.substring(start, end > line.length ? line.length : end);
    }
  }
}
