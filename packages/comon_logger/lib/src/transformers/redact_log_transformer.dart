import '../log_record.dart';

/// A [LogRecordTransformer]-compatible redactor for secrets and oversized
/// values.
///
/// - Values under any key in [keys] (case-insensitive, at any depth of
///   [LogRecord.extra], including inside lists) become [replacement].
/// - With [maxStringLength], the message, string values in `extra`, and the
///   error's string form are cut to that many characters, followed by
///   `…(+N)` where N is the number of characters removed.
///
/// ```dart
/// Logger.root.addTransformer(
///   RedactLogTransformer(keys: {'token', 'password'}, maxStringLength: 4096)
///       .call,
/// );
/// ```
///
/// Only `extra` keys are recognised. A secret interpolated into the message
/// text cannot be found, so keep secrets in `extra` or out of logs.
class RedactLogTransformer {
  RedactLogTransformer({
    Set<String> keys = const {},
    this.replacement = '<redacted>',
    this.maxStringLength,
  }) : assert(maxStringLength == null || maxStringLength >= 0),
       _keys = {for (final key in keys) key.toLowerCase()};

  final Set<String> _keys;

  /// The value written in place of a redacted one.
  final String replacement;

  /// The longest string kept intact, or `null` for no limit.
  final int? maxStringLength;

  LogRecord call(LogRecord record) {
    final extra = record.extra;
    final error = record.error;
    return LogRecord(
      level: record.level,
      message: _cut(record.message),
      loggerName: record.loggerName,
      time: record.time,
      error: error == null || maxStringLength == null
          ? error
          : _cutError(error),
      stackTrace: record.stackTrace,
      layer: record.layer,
      type: record.type,
      feature: record.feature,
      extra: extra == null ? null : _map(extra),
    );
  }

  Map<String, dynamic> _map(Map<dynamic, dynamic> map) => {
    for (final entry in map.entries)
      '${entry.key}': _keys.contains('${entry.key}'.toLowerCase())
          ? replacement
          : _value(entry.value),
  };

  Object? _value(Object? value) => switch (value) {
    String() => _cut(value),
    Map() => _map(value),
    List() => [for (final item in value) _value(item)],
    _ => value,
  };

  // Errors are kept as objects unless their text has to be cut, so handlers
  // can still inspect the type.
  Object _cutError(Object error) {
    final text = error.toString();
    final cut = _cut(text);
    return identical(cut, text) ? error : cut;
  }

  String _cut(String text) {
    final limit = maxStringLength;
    if (limit == null || text.length <= limit) return text;
    return '${text.substring(0, limit)}…(+${text.length - limit})';
  }
}
