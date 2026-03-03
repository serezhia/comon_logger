import 'package:flutter/widgets.dart';

import '../handlers/history_log_handler.dart';

/// A pluggable action for the [ComonLoggerScreen] toolbar.
///
/// Implement this to add custom buttons to the app bar.
/// Each action receives the [HistoryLogHandler] so it can
/// access log records for export, analysis, etc.
///
/// ```dart
/// ComonLoggerScreen(
///   handler: historyHandler,
///   actions: [
///     ShareLogsAction(),   // from comon_logger_share_flutter
///     ImportLogsAction(),  // built-in
///     MyCustomAction(),    // your own
///   ],
/// )
/// ```
///
/// Actions appear in the toolbar in the order they are provided,
/// after the built-in search / filter / auto-scroll buttons and
/// before the clear button.
abstract class LogScreenAction {
  const LogScreenAction();

  /// Build the action widget (typically an [IconButton]).
  ///
  /// [handler] provides access to log history for export or
  /// manipulation. Use [context] for navigation, dialogs, etc.
  Widget build(BuildContext context, HistoryLogHandler handler);
}
