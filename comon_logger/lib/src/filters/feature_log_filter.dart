import '../log_filter.dart';
import '../log_record.dart';

/// Passes records whose [LogRecord.feature] is in the allowed [features] set.
///
/// Records without a feature (`null`) are always passed.
class FeatureLogFilter extends LogFilter {
  const FeatureLogFilter(this.features);

  /// The set of allowed feature names.
  final Set<String> features;

  @override
  bool shouldLog(LogRecord record) =>
      record.feature == null || features.contains(record.feature);
}
