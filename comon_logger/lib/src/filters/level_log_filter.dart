import '../log_filter.dart';
import '../log_level.dart';
import '../log_record.dart';

/// Passes records with level >= [minLevel].
class LevelLogFilter extends LogFilter {
  const LevelLogFilter(this.minLevel);

  /// The minimum level a record must have to pass.
  final LogLevel minLevel;

  @override
  bool shouldLog(LogRecord record) => record.level >= minLevel;
}
