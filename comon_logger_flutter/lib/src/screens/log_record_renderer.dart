import 'package:comon_logger/comon_logger.dart';
import 'package:flutter/widgets.dart';

/// Extension point for customizing how specific [LogRecord]s are
/// displayed in the log viewer.
///
/// Implement this interface to control the collapsed message, expanded
/// detail widgets, clipboard text, and collapsed-text wrapping behavior
/// for records that match [canRender].
///
/// Register renderers when creating [ComonLoggerScreen]:
/// ```dart
/// ComonLoggerScreen(
///   handler: historyHandler,
///   renderers: [
///     HttpLogRecordRenderer(), // from comon_logger_dio_flutter
///     MyGrpcRenderer(),           // your custom renderer
///   ],
/// )
/// ```
///
/// Renderers are tried in order; the first one where [canRender] returns
/// `true` wins. If none match, the default card layout is used.
abstract class LogRecordRenderer {
  const LogRecordRenderer();

  /// Whether this renderer should handle [record].
  bool canRender(LogRecord record);

  /// Whether this record should be hidden from the log list entirely.
  ///
  /// Checked even before [canRender]. When `true` the record is
  /// filtered out from the visible list.
  /// Defaults to `false` (show everything).
  bool shouldHide(LogRecord record) => false;

  /// A custom widget for the *collapsed* card content.
  ///
  /// When non-null, replaces the **entire** default collapsed layout
  /// (level badge, time, logger name, and message text).
  /// The card shell (color strip, tap-to-expand, long-press-to-copy)
  /// is still provided by [LogEntryCard].
  ///
  /// Return `null` to fall back to the default header + [displayMessage].
  Widget? buildCollapsedContent(BuildContext context, LogRecord record) => null;

  /// Overrides the color of the left indicator strip.
  ///
  /// Return `null` to fall back to the default [LogLevel]-based color.
  Color? indicatorColor(LogRecord record) => null;

  /// Short text shown in the *collapsed* card.
  ///
  /// Return `null` to fall back to [LogRecord.message].
  String? displayMessage(LogRecord record) => null;

  /// Whether the collapsed message should wrap (no `maxLines: 1`).
  ///
  /// Useful for URL-heavy logs where truncation hides important info.
  /// Defaults to `false` (single line with ellipsis).
  bool allowMessageWrap(LogRecord record) => false;

  /// Whether the default tags row (Layer, Type, Feature) should be shown.
  ///
  /// Return `false` to hide the tags when this renderer handles the record.
  /// Defaults to `true`.
  bool showExtraTags(LogRecord record) => true;

  /// Builds extra widgets shown when the card is *expanded*.
  ///
  /// Return `null` or an empty list to add nothing beyond the
  /// default tags / error / stack-trace sections.
  List<Widget>? buildDetails(BuildContext context, LogRecord record) => null;

  /// Formatted text for the clipboard (long-press to copy).
  ///
  /// Return `null` to fall back to [SimpleLogFormatter] output +
  /// generic `extra` dump.
  String? formatForCopy(LogRecord record) => null;
}
