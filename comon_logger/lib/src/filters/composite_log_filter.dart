import '../log_filter.dart';
import '../log_record.dart';

/// Combines multiple filters with AND or OR logic.
enum CompositeMode { and, or }

/// Combines multiple [LogFilter]s using [CompositeMode.and] (all must pass)
/// or [CompositeMode.or] (at least one must pass).
class CompositeLogFilter extends LogFilter {
  const CompositeLogFilter(this.filters, {this.mode = CompositeMode.and});

  /// The filters to combine.
  final List<LogFilter> filters;

  /// Whether all filters must pass ([CompositeMode.and]) or at least one
  /// ([CompositeMode.or]).
  final CompositeMode mode;

  @override
  bool shouldLog(LogRecord record) => switch (mode) {
        CompositeMode.and => filters.every((f) => f.shouldLog(record)),
        CompositeMode.or => filters.any((f) => f.shouldLog(record)),
      };
}
