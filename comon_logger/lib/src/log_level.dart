// ignore_for_file: constant_identifier_names

/// Defines the severity level of a log record.
///
/// Levels are ordered by their [value] from lowest (most verbose)
/// to highest (most critical). Use [LogLevel.OFF] to disable logging.
class LogLevel implements Comparable<LogLevel> {
  const LogLevel(this.name, this.value);

  /// The name of this log level.
  final String name;

  /// The numeric value of this level. Higher means more severe.
  final int value;

  // ── Predefined levels (ascending order) ────────────────

  static const LogLevel FINEST = LogLevel('FINEST', 300);
  static const LogLevel FINER = LogLevel('FINER', 400);
  static const LogLevel FINE = LogLevel('FINE', 500);
  static const LogLevel CONFIG = LogLevel('CONFIG', 700);
  static const LogLevel INFO = LogLevel('INFO', 800);
  static const LogLevel WARNING = LogLevel('WARNING', 900);
  static const LogLevel SEVERE = LogLevel('SEVERE', 1000);
  static const LogLevel SHOUT = LogLevel('SHOUT', 1200);
  static const LogLevel OFF = LogLevel('OFF', 2000);

  /// All predefined levels except [OFF], in ascending order.
  static const List<LogLevel> values = [
    FINEST,
    FINER,
    FINE,
    CONFIG,
    INFO,
    WARNING,
    SEVERE,
    SHOUT,
  ];

  // ── Comparison operators ───────────────────────────────

  bool operator >=(LogLevel other) => value >= other.value;
  bool operator <=(LogLevel other) => value <= other.value;
  bool operator >(LogLevel other) => value > other.value;
  bool operator <(LogLevel other) => value < other.value;

  @override
  int compareTo(LogLevel other) => value.compareTo(other.value);

  // ── Object overrides ──────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LogLevel && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => name;
}
