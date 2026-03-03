import 'dart:convert';

import '../log_formatter.dart';
import '../log_level.dart';
import '../log_record.dart';

/// A colorful, multi-line formatter with ANSI colors and emoji.
///
/// Output example:
/// ```
/// ┌─────────────────────────────────────────────────
/// │ 🔵 [INFO] 12:34:56.789 | dio.request | network | data | catalog
/// │ GET https://api.example.com/products
/// └─────────────────────────────────────────────────
/// ```
class PrettyLogFormatter extends LogFormatter {
  const PrettyLogFormatter(
      {this.useColors = true, this.maxStackTraceLines = 8});

  /// Whether to use ANSI escape codes for color output.
  final bool useColors;

  /// Maximum number of stack trace lines to include.
  final int maxStackTraceLines;

  static const _topBorder =
      '┌─────────────────────────────────────────────────';
  static const _bottomBorder =
      '└─────────────────────────────────────────────────';
  static const _line = '│ ';

  @override
  String format(LogRecord record) {
    final buf = StringBuffer();
    final color = _ansiColor(record.level);
    final reset = useColors ? '\x1B[0m' : '';

    buf.writeln(_wrap(color, _topBorder));

    // Header line: emoji [LEVEL] HH:MM:SS.mmm | loggerName | tags...
    final header = StringBuffer()
      ..write(_emoji(record.level))
      ..write(' [${record.level}] ')
      ..write(_formatTime(record.time));

    if (record.loggerName.isNotEmpty) {
      header.write(' | ${record.loggerName}');
    }

    final tags = <String>[
      if (record.type != null) record.type.toString(),
      if (record.layer != null) record.layer.toString(),
      if (record.feature != null) record.feature!,
    ];
    if (tags.isNotEmpty) {
      header.write(' | ${tags.join(' | ')}');
    }

    buf.writeln(_wrap(color, '$_line${header.toString()}$reset'));

    // Message (may be multi-line)
    for (final line in record.message.split('\n')) {
      buf.writeln(_wrap(color, '$_line$line$reset'));
    }

    // Error
    if (record.error != null) {
      buf.writeln(
          _wrap(color, '${_line}Error: ${record.error.toString()}$reset'));
    }

    // Stack trace
    if (record.stackTrace != null) {
      final lines = record.stackTrace.toString().split('\n');
      final limit =
          lines.length > maxStackTraceLines ? maxStackTraceLines : lines.length;
      for (var i = 0; i < limit; i++) {
        buf.writeln(_wrap(color, '$_line${lines[i]}$reset'));
      }
      if (lines.length > maxStackTraceLines) {
        buf.writeln(_wrap(
            color,
            '$_line... ${lines.length - maxStackTraceLines} more lines'
            '$reset'));
      }
    }

    // Extra data
    if (record.extra != null && record.extra!.isNotEmpty) {
      final jsonStr = const JsonEncoder.withIndent('  ').convert(record.extra);
      for (final line in jsonStr.split('\n')) {
        buf.writeln(_wrap(color, '$_line$line$reset'));
      }
    }

    buf.write(_wrap(color, _bottomBorder));

    return buf.toString();
  }

  String _wrap(String color, String text) {
    if (!useColors) return text;
    return '$color$text';
  }

  static String _emoji(LogLevel level) {
    if (level == LogLevel.FINEST) return '🔍';
    if (level == LogLevel.FINER) return '📝';
    if (level == LogLevel.FINE) return '📋';
    if (level == LogLevel.CONFIG) return '⚙️';
    if (level == LogLevel.INFO) return '🔵';
    if (level == LogLevel.WARNING) return '🟡';
    if (level == LogLevel.SEVERE) return '🔴';
    if (level == LogLevel.SHOUT) return '💥';
    return '📌';
  }

  String _ansiColor(LogLevel level) {
    if (!useColors) return '';
    if (level == LogLevel.FINEST ||
        level == LogLevel.FINER ||
        level == LogLevel.FINE) {
      return '\x1B[90m'; // grey
    }
    if (level == LogLevel.CONFIG) return '\x1B[36m'; // cyan
    if (level == LogLevel.INFO) return '\x1B[36m'; // cyan
    if (level == LogLevel.WARNING) return '\x1B[33m'; // yellow
    if (level == LogLevel.SEVERE) return '\x1B[31m'; // red
    if (level == LogLevel.SHOUT) return '\x1B[35;1m'; // magenta bold
    return '\x1B[0m';
  }

  static String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    final ms = time.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }
}
