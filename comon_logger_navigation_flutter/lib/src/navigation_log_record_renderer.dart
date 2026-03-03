import 'package:comon_logger/comon_logger.dart';
import 'package:comon_logger_flutter/comon_logger_flutter.dart';
import 'package:flutter/widgets.dart';

import 'navigation_log_detail.dart';

/// A [LogRecordRenderer] for navigation logs produced by [ComonNavigatorObserver].
///
/// Matches records where `type == LogType.navigation` and `extra` contains
/// an `'action'` key.
///
/// Renders a visual route transition (from → to) with color-coded action
/// badges for PUSH, POP, REPLACE, and REMOVE.
///
/// ```dart
/// ComonLoggerScreen(
///   handler: historyHandler,
///   renderers: [
///     NavigationLogRecordRenderer(),
///     HttpLogRecordRenderer(), // from comon_logger_dio_flutter
///   ],
/// )
/// ```
class NavigationLogRecordRenderer extends LogRecordRenderer {
  const NavigationLogRecordRenderer();

  @override
  bool canRender(LogRecord record) {
    return record.type == LogType.navigation &&
        record.extra != null &&
        record.extra!.containsKey('action');
  }

  @override
  String? displayMessage(LogRecord record) {
    final extra = record.extra!;
    final action = extra['action'] as String? ?? '';
    final route = extra['route'] as String? ?? 'unknown';
    final previousRoute = extra['previousRoute'] as String?;

    final icon = switch (action) {
      'PUSH' => '→',
      'POP' => '←',
      'REPLACE' => '⇄',
      'REMOVE' => '✖',
      _ => '•',
    };

    if (previousRoute != null) {
      return switch (action) {
        'POP' => '$icon $route → $previousRoute',
        _ => '$icon $previousRoute → $route',
      };
    }
    return '$icon $route';
  }

  @override
  bool allowMessageWrap(LogRecord record) => false;

  @override
  List<Widget>? buildDetails(BuildContext context, LogRecord record) {
    return [NavigationLogDetail(record: record)];
  }

  @override
  String? formatForCopy(LogRecord record) {
    final extra = record.extra!;
    final action = extra['action'] ?? '';
    final route = extra['route'] ?? 'unknown';
    final previousRoute = extra['previousRoute'];

    final buf = StringBuffer();
    buf.writeln(const SimpleLogFormatter().format(record));
    buf.writeln('─── Navigation Detail ───');
    buf.write('Action: $action');
    buf.writeln();
    buf.write('Route: $route');
    if (previousRoute != null) {
      buf.writeln();
      buf.write('Previous Route: $previousRoute');
    }
    buf.writeln();
    return buf.toString();
  }
}
