import '../log_formatter.dart';
import '../log_record.dart';

/// A compact, single-line log formatter.
///
/// Output example:
/// ```
/// 12:34:56.789 [INFO] dio.request: GET https://api.example.com/products {network|data|catalog}
/// ```
class SimpleLogFormatter extends LogFormatter {
  const SimpleLogFormatter();

  @override
  String format(LogRecord record) {
    final buf = StringBuffer()
      ..write(_formatTime(record.time))
      ..write(' [${record.level}]')
      ..write(record.loggerName.isNotEmpty ? ' ${record.loggerName}:' : ':')
      ..write(' ${record.message}');

    final tags = <String>[
      if (record.layer != null) record.layer.toString(),
      if (record.type != null) record.type.toString(),
      if (record.feature != null) record.feature!,
    ];
    if (tags.isNotEmpty) {
      buf.write(' {${tags.join('|')}}');
    }

    if (record.error != null) {
      buf.write(' | Error: ${record.error}');
    }
    if (record.stackTrace != null) {
      buf.write('\n${record.stackTrace}');
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
