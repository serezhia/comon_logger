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
          // JSON body — single SelectableText for proper text selection
          SelectableText.rich(
            TextSpan(
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                height: 1.4,
              ),
              children: [
                if (data is Map || data is List)
                  _buildJsonSpan(data, 0, theme)
                else
                  TextSpan(text: prettyText),
              ],
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

  /// Recursively builds a color-highlighted JSON [TextSpan] tree.
  static TextSpan _buildJsonSpan(Object? data, int depth, ThemeData theme) {
    final indent = '  ' * depth;
    final childIndent = '  ' * (depth + 1);
    final punctuationStyle = TextStyle(
      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
    );

    if (data is Map) {
      if (data.isEmpty) {
        return TextSpan(
          text: '{}',
          style: TextStyle(color: theme.textTheme.bodyMedium?.color),
        );
      }

      final entries = data.entries.toList();
      final children = <InlineSpan>[
        TextSpan(text: '{\n', style: punctuationStyle),
      ];

      for (var i = 0; i < entries.length; i++) {
        final entry = entries[i];
        final comma = i < entries.length - 1 ? ',' : '';

        children.add(TextSpan(text: childIndent));
        children.add(TextSpan(
          text: '"${entry.key}"',
          style: TextStyle(color: theme.colorScheme.primary),
        ));
        children.add(TextSpan(text: ': ', style: punctuationStyle));

        if (entry.value is Map || entry.value is List) {
          children.add(_buildJsonSpan(entry.value, depth + 1, theme));
        } else {
          children.add(_valueSpan(entry.value, theme));
        }

        children.add(TextSpan(text: '$comma\n', style: punctuationStyle));
      }

      children.add(TextSpan(text: '$indent}', style: punctuationStyle));
      return TextSpan(children: children);
    }

    if (data is List) {
      if (data.isEmpty) {
        return TextSpan(
          text: '[]',
          style: TextStyle(color: theme.textTheme.bodyMedium?.color),
        );
      }

      final children = <InlineSpan>[
        TextSpan(text: '[\n', style: punctuationStyle),
      ];

      for (var i = 0; i < data.length; i++) {
        final comma = i < data.length - 1 ? ',' : '';

        children.add(TextSpan(text: childIndent));

        if (data[i] is Map || data[i] is List) {
          children.add(_buildJsonSpan(data[i], depth + 1, theme));
        } else {
          children.add(_valueSpan(data[i], theme));
        }

        children.add(TextSpan(text: '$comma\n', style: punctuationStyle));
      }

      children.add(TextSpan(text: '$indent]', style: punctuationStyle));
      return TextSpan(children: children);
    }

    // Primitive
    return _valueSpan(data, theme);
  }

  /// Returns a styled [TextSpan] for a JSON primitive value.
  static TextSpan _valueSpan(Object? value, ThemeData theme) {
    if (value == null) {
      return TextSpan(
        text: 'null',
        style: TextStyle(
          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
          fontStyle: FontStyle.italic,
        ),
      );
    }
    if (value is bool) {
      return TextSpan(
        text: '$value',
        style: TextStyle(color: Colors.deepPurple.shade300),
      );
    }
    if (value is num) {
      return TextSpan(
        text: '$value',
        style: TextStyle(color: Colors.teal.shade400),
      );
    }
    if (value is String) {
      return TextSpan(
        text: '"$value"',
        style: TextStyle(color: Colors.orange.shade400),
      );
    }
    return TextSpan(text: value.toString());
  }
}
