import 'dart:convert';

import 'package:comon_logger/comon_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A widget that renders structured HTTP log details (headers, JSON body)
/// in a beautiful, expandable format.
class HttpLogDetail extends StatelessWidget {
  const HttpLogDetail({
    super.key,
    required this.record,
    this.showRequestHeaders = true,
    this.showResponseHeaders = true,
    this.showRequestBody = true,
    this.showResponseBody = true,
  });

  final LogRecord record;

  /// Show request headers collapsible section.
  final bool showRequestHeaders;

  /// Show response headers collapsible section.
  final bool showResponseHeaders;

  /// Show request body collapsible section.
  final bool showRequestBody;

  /// Show response body collapsible section.
  final bool showResponseBody;

  @override
  Widget build(BuildContext context) {
    final extra = record.extra ?? {};
    final uri = extra['uri'] as String? ?? '';

    final requestHeaders = extra['requestHeaders'] as Map<String, dynamic>?;
    final responseHeaders = extra['responseHeaders'] as Map<String, dynamic>?;
    final requestBody = extra['requestBody'];
    final responseBody = extra['responseBody'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Full URL ────────────────────────────────────
        _CollapsibleSection(
          title: 'Full URL',
          icon: Icons.link_rounded,
          iconColor: Colors.blueGrey,
          child: SelectableText(
            uri,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ),

        // ── Request headers ─────────────────────────────
        if (showRequestHeaders &&
            requestHeaders != null &&
            requestHeaders.isNotEmpty)
          _CollapsibleSection(
            title: 'Request Headers',
            icon: Icons.arrow_upward_rounded,
            iconColor: Colors.blue,
            child: _HeadersTable(headers: requestHeaders),
          ),

        // ── Request body ────────────────────────────────
        if (showRequestBody && requestBody != null)
          _CollapsibleSection(
            title: 'Request Body',
            icon: Icons.arrow_upward_rounded,
            iconColor: Colors.blue,
            child: _JsonViewer(data: requestBody),
          ),

        // ── Response headers ────────────────────────────
        if (showResponseHeaders &&
            responseHeaders != null &&
            responseHeaders.isNotEmpty)
          _CollapsibleSection(
            title: 'Response Headers',
            icon: Icons.arrow_downward_rounded,
            iconColor: Colors.green,
            child: _HeadersTable(headers: responseHeaders),
          ),

        // ── Response body ───────────────────────────────
        if (showResponseBody && responseBody != null)
          _CollapsibleSection(
            title: 'Response Body',
            icon: Icons.arrow_downward_rounded,
            iconColor: Colors.green,
            child: _JsonViewer(data: responseBody),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Collapsible section wrapper
// ─────────────────────────────────────────────────────────

class _CollapsibleSection extends StatefulWidget {
  const _CollapsibleSection({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  @override
  State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<_CollapsibleSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              children: [
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  size: 18,
                  color:
                      theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Icon(widget.icon, size: 14, color: widget.iconColor),
                const SizedBox(width: 6),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodySmall?.color
                        ?.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 2),
            child: widget.child,
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Headers table
// ─────────────────────────────────────────────────────────

class _HeadersTable extends StatelessWidget {
  const _HeadersTable({required this.headers});

  final Map<String, dynamic> headers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = headers.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: entries.map((entry) {
          final value = entry.value is List
              ? (entry.value as List).join(', ')
              : entry.value.toString();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  '${entry.key}: ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                    color: theme.colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: SelectableText(
                    value,
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  JSON viewer with pretty formatting & copy
// ─────────────────────────────────────────────────────────

class _JsonViewer extends StatelessWidget {
  const _JsonViewer({required this.data});

  final Object data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prettyText = _prettyPrint(data);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Copy button
          Align(
            alignment: Alignment.topRight,
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () {
                Clipboard.setData(ClipboardData(text: prettyText));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied to clipboard'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.copy_rounded,
                  size: 14,
                  color:
                      theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          // JSON body
          if (data is Map || data is List)
            _buildJsonTree(context, data, 0)
          else
            SelectableText(
              prettyText,
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
        ],
      ),
    );
  }

  static String _prettyPrint(Object data) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(data);
    } catch (_) {
      return data.toString();
    }
  }

  /// Recursively builds a color-highlighted JSON tree widget.
  static Widget _buildJsonTree(BuildContext context, Object? data, int depth) {
    final theme = Theme.of(context);
    final indent = '  ' * depth;

    if (data is Map) {
      if (data.isEmpty) {
        return Text('{}',
            style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: theme.textTheme.bodyMedium?.color));
      }

      final entries = data.entries.toList();
      final lines = <Widget>[];
      lines.add(Text('$indent{',
          style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color:
                  theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))));

      for (var i = 0; i < entries.length; i++) {
        final entry = entries[i];
        final comma = i < entries.length - 1 ? ',' : '';
        final key = entry.key;
        final value = entry.value;

        if (value is Map || value is List) {
          lines.add(Padding(
            padding: EdgeInsets.only(left: (depth + 1) * 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        fontSize: 11, fontFamily: 'monospace', height: 1.4),
                    children: [
                      TextSpan(
                        text: '"$key"',
                        style: TextStyle(color: theme.colorScheme.primary),
                      ),
                      TextSpan(
                        text: ': ',
                        style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),
                _buildJsonTree(context, value, depth + 1),
                if (comma.isNotEmpty)
                  Text(comma,
                      style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: theme.textTheme.bodyMedium?.color
                              ?.withValues(alpha: 0.5))),
              ],
            ),
          ));
        } else {
          lines.add(Padding(
            padding: EdgeInsets.only(left: (depth + 1) * 12.0),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                    fontSize: 11, fontFamily: 'monospace', height: 1.4),
                children: [
                  TextSpan(
                    text: '"$key"',
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                  TextSpan(
                    text: ': ',
                    style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color
                            ?.withValues(alpha: 0.5)),
                  ),
                  _valueSpan(value, theme),
                  TextSpan(
                    text: comma,
                    style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color
                            ?.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
          ));
        }
      }

      lines.add(Text('$indent}',
          style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color:
                  theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))));

      return SelectionArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: lines,
        ),
      );
    }

    if (data is List) {
      if (data.isEmpty) {
        return Text('[]',
            style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: theme.textTheme.bodyMedium?.color));
      }

      final lines = <Widget>[];
      lines.add(Text('$indent[',
          style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color:
                  theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))));

      for (var i = 0; i < data.length; i++) {
        final value = data[i];
        final comma = i < data.length - 1 ? ',' : '';

        if (value is Map || value is List) {
          lines.add(Padding(
            padding: EdgeInsets.only(left: (depth + 1) * 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildJsonTree(context, value, depth + 1),
                if (comma.isNotEmpty)
                  Text(comma,
                      style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: theme.textTheme.bodyMedium?.color
                              ?.withValues(alpha: 0.5))),
              ],
            ),
          ));
        } else {
          lines.add(Padding(
            padding: EdgeInsets.only(left: (depth + 1) * 12.0),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                    fontSize: 11, fontFamily: 'monospace', height: 1.4),
                children: [
                  _valueSpan(value, theme),
                  TextSpan(
                    text: comma,
                    style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color
                            ?.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
          ));
        }
      }

      lines.add(Text('$indent]',
          style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color:
                  theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))));

      return SelectionArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: lines,
        ),
      );
    }

    // Primitive
    return RichText(
      text: TextSpan(
        style:
            const TextStyle(fontSize: 11, fontFamily: 'monospace', height: 1.4),
        children: [_valueSpan(data, theme)],
      ),
    );
  }

  /// Returns a styled [TextSpan] for a JSON primitive value.
  static TextSpan _valueSpan(Object? value, ThemeData theme) {
    if (value == null) {
      return TextSpan(
        text: 'null',
        style: TextStyle(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
            fontStyle: FontStyle.italic),
      );
    }
    if (value is bool) {
      return TextSpan(
        text: '$value',
        style: TextSpan(
                text: '', style: TextStyle(color: Colors.deepPurple.shade300))
            .style,
      );
    }
    if (value is num) {
      return TextSpan(
        text: '$value',
        style: TextSpan(text: '', style: TextStyle(color: Colors.teal.shade400))
            .style,
      );
    }
    if (value is String) {
      return TextSpan(
        text: '"$value"',
        style:
            TextSpan(text: '', style: TextStyle(color: Colors.orange.shade400))
                .style,
      );
    }
    return TextSpan(text: value.toString());
  }
}
