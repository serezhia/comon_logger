import '../log_filter.dart';
import '../log_record.dart';

/// A filter that passes all records. Used as the default filter.
class AllPassLogFilter extends LogFilter {
  const AllPassLogFilter();

  @override
  bool shouldLog(LogRecord record) => true;
}
