import 'package:flutter/widgets.dart';

/// Every user-visible text of the log viewer, with English defaults.
///
/// Pass a translated instance to `ComonLoggerScreen(strings: ...)`, or put a
/// [ComonLoggerStringsScope] above it. Widgets of the viewer and custom
/// [LogScreenAction]s read the current one with [ComonLoggerStrings.of].
///
/// ```dart
/// ComonLoggerScreen(
///   handler: history,
///   strings: ComonLoggerStrings(
///     title: l10n.logsTitle,
///     recordCount: (shown, total) => l10n.logsCount(shown, total),
///   ),
/// )
/// ```
///
/// Text copied to the clipboard or exported stays in English: it is data for
/// whoever reads the log, not interface text.
@immutable
class ComonLoggerStrings {
  const ComonLoggerStrings({
    this.title = 'Logs',
    this.searchHint = 'Search logs...',
    this.search = 'Search',
    this.closeSearch = 'Close search',
    this.filters = 'Filters',
    this.autoScrollOn = 'Auto-scroll on',
    this.autoScrollOff = 'Auto-scroll off',
    this.clearLogs = 'Clear logs',
    this.noLogsYet = 'No logs yet',
    this.noLogsMatch = 'No logs match filters',
    this.recordCount = _recordCount,
    this.copiedToClipboard = 'Log copied to clipboard',
    this.level = 'Level',
    this.layer = 'Layer',
    this.type = 'Type',
    this.feature = 'Feature',
    this.loggerName = 'Logger name',
    this.resetFilters = 'Reset filters',
    this.error = 'Error',
    this.importTooltip = 'Import logs from JSON',
    this.importTitle = 'Import logs',
    this.importHint = 'Paste JSON from exportJson() or a log file below:',
    this.pasteFromClipboard = 'Paste from clipboard',
    this.cancel = 'Cancel',
    this.import = 'Import',
    this.imported = _imported,
    this.importFailed = _importFailed,
  });

  final String title;
  final String searchHint;
  final String search;
  final String closeSearch;
  final String filters;
  final String autoScrollOn;
  final String autoScrollOff;
  final String clearLogs;
  final String noLogsYet;
  final String noLogsMatch;

  /// Status bar text: records shown after filtering, and all records.
  final String Function(int shown, int total) recordCount;
  final String copiedToClipboard;

  /// Labels of the filter panel and of the tag chips on an expanded record.
  final String level;
  final String layer;
  final String type;
  final String feature;
  final String loggerName;
  final String resetFilters;

  /// Prefix of the error block on an expanded record.
  final String error;

  final String importTooltip;
  final String importTitle;
  final String importHint;
  final String pasteFromClipboard;
  final String cancel;
  final String import;
  final String Function(int count) imported;
  final String Function(Object error) importFailed;

  static String _recordCount(int shown, int total) => '$shown / $total logs';
  static String _imported(int count) => 'Imported $count log records';
  static String _importFailed(Object error) => 'Import failed: $error';

  /// The strings of the nearest [ComonLoggerStringsScope], or the English
  /// defaults.
  static ComonLoggerStrings of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<ComonLoggerStringsScope>()
          ?.strings ??
      const ComonLoggerStrings();
}

/// Provides [ComonLoggerStrings] to the log viewer below it.
class ComonLoggerStringsScope extends InheritedWidget {
  const ComonLoggerStringsScope({
    super.key,
    required this.strings,
    required super.child,
  });

  final ComonLoggerStrings strings;

  @override
  bool updateShouldNotify(ComonLoggerStringsScope oldWidget) =>
      !identical(strings, oldWidget.strings);
}
