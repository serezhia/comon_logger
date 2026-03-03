import 'package:comon_logger/comon_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'log_record_renderer.dart';

/// A card widget displaying a single [LogRecord].
///
/// Shows a compact summary (level indicator, time, logger, message).
/// Tap to expand and see full details (error, stack trace, tags, extra).
/// Long-press to copy the record text to clipboard.
///
/// Custom display for specific log types can be provided via [renderers].
/// The first renderer where [LogRecordRenderer.canRender] returns `true`
/// is used. If none match, the default layout is used.
class LogEntryCard extends StatefulWidget {
  const LogEntryCard({
    super.key,
    required this.record,
    this.renderers = const [],
  });

  final LogRecord record;

  /// Custom renderers tried in order for this record.
  final List<LogRecordRenderer> renderers;

  @override
  State<LogEntryCard> createState() => _LogEntryCardState();
}

class _LogEntryCardState extends State<LogEntryCard> {
  bool _expanded = false;

  /// Finds the first renderer that can handle [record], or `null`.
  LogRecordRenderer? _resolveRenderer(LogRecord record) {
    for (final r in widget.renderers) {
      if (r.canRender(record)) return r;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final renderer = _resolveRenderer(record);

    final color = renderer?.indicatorColor(record) ?? _levelColor(record.level);

    // Check if renderer provides a fully custom collapsed layout
    final customCollapsed = renderer?.buildCollapsedContent(context, record);

    final message = renderer?.displayMessage(record) ?? record.message;
    final wrapMessage =
        _expanded || (renderer?.allowMessageWrap(record) ?? false);

    return GestureDetector(
      onLongPress: () => _copyToClipboard(context, record, renderer),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _expanded = !_expanded),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Color indicator strip
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                  ),
                ),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (customCollapsed != null) ...[
                          customCollapsed,
                        ] else ...[
                          _buildHeader(record, color),
                          const SizedBox(height: 4),
                          Text(
                            message,
                            maxLines: wrapMessage ? null : 1,
                            overflow:
                                wrapMessage ? null : TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                        if (_expanded)
                          ..._buildDetails(context, record, renderer),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(LogRecord record, Color color) {
    final time = _formatTime(record.time);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            record.level.name,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          time,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context)
                .textTheme
                .bodySmall
                ?.color
                ?.withValues(alpha: 0.7),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (record.loggerName.isNotEmpty) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              record.loggerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildDetails(
    BuildContext context,
    LogRecord record,
    LogRecordRenderer? renderer,
  ) {
    final widgets = <Widget>[];

    // Tags row
    final showTags = renderer?.showExtraTags(record) ?? true;
    final tags = <String>[
      if (showTags && record.layer != null) 'Layer: ${record.layer}',
      if (showTags && record.type != null) 'Type: ${record.type}',
      if (showTags && record.feature != null) 'Feature: ${record.feature}',
    ];
    if (tags.isNotEmpty) {
      widgets.add(const SizedBox(height: 8));
      widgets.add(Wrap(
        spacing: 6,
        runSpacing: 4,
        children: tags
            .map((tag) => Chip(
                  label: Text(tag, style: const TextStyle(fontSize: 11)),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ))
            .toList(),
      ));
    }

    // Error
    if (record.error != null) {
      widgets.add(const SizedBox(height: 8));
      widgets.add(Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(4),
        ),
        child: SelectableText(
          'Error: ${record.error}',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.red,
            fontFamily: 'monospace',
          ),
        ),
      ));
    }

    // Stack trace
    if (record.stackTrace != null) {
      widgets.add(const SizedBox(height: 4));
      widgets.add(Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: SelectableText(
          record.stackTrace.toString(),
          style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
          maxLines: 10,
        ),
      ));
    }

    // Custom renderer detail (if any)
    final customWidgets = renderer?.buildDetails(context, record);
    if (customWidgets != null && customWidgets.isNotEmpty) {
      widgets.addAll(customWidgets);
    } else if (record.extra != null && record.extra!.isNotEmpty) {
      // Generic extra fallback
      widgets.add(const SizedBox(height: 4));
      widgets.add(Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: SelectableText(
          record.extra.toString(),
          style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
        ),
      ));
    }

    return widgets;
  }

  void _copyToClipboard(
    BuildContext context,
    LogRecord record,
    LogRecordRenderer? renderer,
  ) {
    final text =
        renderer?.formatForCopy(record) ?? _defaultFormatForCopy(record);
    Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Log copied to clipboard'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  /// Default clipboard format when no renderer provides one.
  static String _defaultFormatForCopy(LogRecord record) {
    final buf = StringBuffer();
    buf.writeln(const SimpleLogFormatter().format(record));

    final extra = record.extra;
    if (extra != null && extra.isNotEmpty) {
      buf.writeln('Extra: $extra');
    }
    return buf.toString();
  }

  static Color _levelColor(LogLevel level) {
    if (level >= LogLevel.SHOUT) return Colors.deepPurple;
    if (level >= LogLevel.SEVERE) return Colors.red;
    if (level >= LogLevel.WARNING) return Colors.orange;
    if (level >= LogLevel.INFO) return Colors.cyan;
    if (level >= LogLevel.CONFIG) return Colors.blueGrey;
    return Colors.grey;
  }

  static String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    final ms = time.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }
}
