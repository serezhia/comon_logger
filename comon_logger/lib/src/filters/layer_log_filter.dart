import '../log_filter.dart';
import '../log_layer.dart';
import '../log_record.dart';

/// Passes records whose [LogRecord.layer] is in the allowed [layers] set.
///
/// Records without a layer (`null`) are always passed.
class LayerLogFilter extends LogFilter {
  const LayerLogFilter(this.layers);

  /// The set of allowed layers.
  final Set<LogLayer> layers;

  @override
  bool shouldLog(LogRecord record) =>
      record.layer == null || layers.contains(record.layer);
}
