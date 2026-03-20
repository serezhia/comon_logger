import 'log_layer.dart';
import 'log_level.dart';
import 'log_type.dart';

/// An immutable record of a single log event.
class LogRecord {
  const LogRecord({
    required this.level,
    required this.message,
    required this.loggerName,
    required this.time,
    this.error,
    this.stackTrace,
    this.layer,
    this.type,
    this.feature,
    this.extra,
  });

  /// The severity level.
  final LogLevel level;

  /// The log message.
  final String message;

  /// The name of the logger that produced this record.
  final String loggerName;

  /// When this record was created.
  final DateTime time;

  /// An optional error object associated with this log.
  final Object? error;

  /// An optional stack trace associated with this log.
  final StackTrace? stackTrace;

  /// The architectural layer this log originates from.
  final LogLayer? layer;

  /// The type of action or context this log relates to.
  final LogType? type;

  /// An optional feature tag for filtering (e.g. 'catalog', 'auth').
  final String? feature;

  /// Arbitrary extra data for handlers/formatters.
  final Map<String, dynamic>? extra;

  // ── copyWith ──────────────────────────────────────────

  LogRecord copyWith({
    LogLevel? level,
    String? message,
    String? loggerName,
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
    LogLayer? layer,
    LogType? type,
    String? feature,
    Map<String, dynamic>? extra,
  }) {
    return LogRecord(
      level: level ?? this.level,
      message: message ?? this.message,
      loggerName: loggerName ?? this.loggerName,
      time: time ?? this.time,
      error: error ?? this.error,
      stackTrace: stackTrace ?? this.stackTrace,
      layer: layer ?? this.layer,
      type: type ?? this.type,
      feature: feature ?? this.feature,
      extra: extra ?? this.extra,
    );
  }

  // ── Serialization ─────────────────────────────────────

  /// Converts this record to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'level': level.name,
      'levelValue': level.value,
      'message': message,
      'loggerName': loggerName,
      'time': time.toIso8601String(),
      if (error != null) 'error': error.toString(),
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
      if (layer != null) 'layer': layer!.name,
      if (type != null) 'type': type!.name,
      if (feature != null) 'feature': feature,
      if (extra != null) 'extra': extra,
    };
  }

  /// Creates a [LogRecord] from a JSON map produced by [toJson].
  factory LogRecord.fromJson(Map<String, dynamic> json) {
    final levelName = json['level'] as String;
    final levelValue = json['levelValue'] as int?;

    // Try to match a predefined level, otherwise create a custom one.
    final level =
        LogLevel.values.cast<LogLevel?>().firstWhere(
          (l) => l!.name == levelName,
          orElse: () => null,
        ) ??
        LogLevel(levelName, levelValue ?? 0);

    return LogRecord(
      level: level,
      message: json['message'] as String,
      loggerName: json['loggerName'] as String,
      time: DateTime.parse(json['time'] as String),
      error: json['error'] as String?,
      stackTrace: json['stackTrace'] != null
          ? StackTrace.fromString(json['stackTrace'] as String)
          : null,
      layer: json['layer'] != null
          ? LogLayer.tryParse(json['layer'] as String) ??
                LogLayer(json['layer'] as String)
          : null,
      type: json['type'] != null
          ? LogType.tryParse(json['type'] as String) ??
                LogType(json['type'] as String)
          : null,
      feature: json['feature'] as String?,
      extra: json['extra'] != null
          ? Map<String, dynamic>.from(json['extra'] as Map)
          : null,
    );
  }

  // ── toString ──────────────────────────────────────────

  @override
  String toString() {
    final buf = StringBuffer()
      ..write(_formatTime(time))
      ..write(' [')
      ..write(level)
      ..write('] ')
      ..write(loggerName.isNotEmpty ? '$loggerName: ' : '')
      ..write(message);

    final tags = <String>[
      if (layer != null) layer.toString(),
      if (type != null) type.toString(),
    ];
    if (feature != null) {
      tags.add(feature!);
    }
    if (tags.isNotEmpty) {
      buf.write(' {${tags.join('|')}}');
    }

    if (error != null) {
      buf.write('\n  Error: $error');
    }
    if (stackTrace != null) {
      buf.write('\n  StackTrace: $stackTrace');
    }

    return buf.toString();
  }

  static String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    final ms = time.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }
}
