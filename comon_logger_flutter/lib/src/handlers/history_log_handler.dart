import 'dart:async';
import 'dart:convert';

import 'package:comon_logger/comon_logger.dart';

/// An in-memory handler that stores log records for UI display.
///
/// Provides a [history] list and a [onRecord] stream for reactive updates.
/// Use with [ComonLoggerScreen] to display logs in-app.
class HistoryLogHandler extends LogHandler {
  HistoryLogHandler({
    super.filter = const AllPassLogFilter(),
    this.maxHistory = 1000,
  });

  /// Maximum number of records to keep in memory.
  final int maxHistory;

  final List<LogRecord> _history = [];

  final StreamController<LogRecord> _controller =
      StreamController<LogRecord>.broadcast();

  /// All stored records (unmodifiable view).
  List<LogRecord> get history => List.unmodifiable(_history);

  /// Stream of new records (for UI updates).
  Stream<LogRecord> get onRecord => _controller.stream;

  @override
  void handle(LogRecord record) {
    _history.add(record);
    if (_history.length > maxHistory) {
      _history.removeAt(0);
    }
    _controller.add(record);
  }

  /// Remove all stored records.
  void clear() {
    _history.clear();
  }

  /// Export history as formatted text.
  String export({LogFormatter? formatter}) {
    final fmt = formatter ?? const SimpleLogFormatter();
    return _history.map(fmt.format).join('\n');
  }

  /// Export history as a JSON string (for DevTools import).
  String exportJson() {
    return jsonEncode(_history.map((r) => r.toJson()).toList());
  }

  /// Release resources.
  void dispose() {
    _controller.close();
  }
}
