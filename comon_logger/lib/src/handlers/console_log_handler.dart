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
  }) : _formatter = formatter ?? const PrettyLogFormatter();

  final LogFormatter _formatter;

  @override
  void handle(LogRecord record) {
    // ignore: avoid_print
    print(_formatter.format(record));
  }
}
