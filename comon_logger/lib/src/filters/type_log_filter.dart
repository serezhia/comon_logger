import '../log_filter.dart';
import '../log_record.dart';
import '../log_type.dart';

/// Passes records whose [LogRecord.type] is in the allowed [types] set.
///
/// Records without a type (`null`) are always passed.
class TypeLogFilter extends LogFilter {
  const TypeLogFilter(this.types);

  /// The set of allowed types.
  final Set<LogType> types;

  @override
  bool shouldLog(LogRecord record) =>
      record.type == null || types.contains(record.type);
}
