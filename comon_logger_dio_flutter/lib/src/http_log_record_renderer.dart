import 'dart:convert';

import 'package:comon_logger/comon_logger.dart';
import 'package:comon_logger_flutter/comon_logger_flutter.dart';
import 'package:flutter/material.dart';

import 'http_log_detail.dart';

/// A [LogRecordRenderer] for HTTP network logs produced by `ComonDioInterceptor`.
///
/// Matches records where `type == LogType.network` and `extra` contains
/// a `'phase'` key (the convention used by `ComonDioInterceptor`).
///
/// Any interceptor/logger that follows the same `extra` key convention
/// (`method`, `uri`, `phase`, `statusCode`, `durationMs`,
/// `requestHeaders`, `requestBody`, `responseHeaders`, `responseBody`)
/// will automatically get the same beautiful rendering.
///
/// ```dart
/// ComonLoggerScreen(
///   handler: historyHandler,
///   renderers: [
///     HttpLogRecordRenderer(),
///   ],
/// )
/// ```
class HttpLogRecordRenderer extends LogRecordRenderer {
  /// Creates an HTTP log renderer.
  ///
  /// - [showRequest] — when `false`, request-phase logs are hidden
  ///   (only response / error are rendered).
  /// - [showExtra] — show Layer / Type / Feature tags in expanded view.
  /// - [showRequestHeaders] — show request headers section.
  /// - [showResponseHeaders] — show response headers section.
  /// - [showRequestBody] — show request body section.
  /// - [showResponseBody] — show response body section.
  const HttpLogRecordRenderer({
    this.showRequest = true,
    this.showExtra = false,
    this.showRequestHeaders = true,
    this.showResponseHeaders = true,
    this.showRequestBody = true,
    this.showResponseBody = true,
  });

  /// When `false`, request-phase logs are skipped entirely.
  final bool showRequest;

  /// Whether to show Layer / Type / Feature tag chips.
  final bool showExtra;

  /// Show request headers collapsible section.
  final bool showRequestHeaders;

  /// Show response headers collapsible section.
  final bool showResponseHeaders;

  /// Show request body collapsible section.
  final bool showRequestBody;

  /// Show response body collapsible section.
  final bool showResponseBody;

  @override
  bool canRender(LogRecord record) {
    return record.type == LogType.network &&
        record.extra != null &&
        record.extra!.containsKey('phase');
  }

  @override
  bool shouldHide(LogRecord record) {
    if (!showRequest &&
        canRender(record) &&
        record.extra!['phase'] == 'request') {
      return true;
    }
    return false;
  }

  @override
  bool showExtraTags(LogRecord record) => showExtra;

  // ── Collapsed content ──────────────────────────────────────────────

  @override
  Color? indicatorColor(LogRecord record) {
    final extra = record.extra!;
    final phase = extra['phase'] as String?;
    final statusCode = extra['statusCode'];

    if (phase == 'error') return const Color(0xFFB71C1C);
    if (phase == 'response' && statusCode is int) {
      return _statusColor(statusCode);
    }
    return const Color(0xFF4FC3F7); // light blue for requests
  }

  @override
  Widget? buildCollapsedContent(BuildContext context, LogRecord record) {
    final extra = record.extra!;
    final method = extra['method'] as String? ?? '';
    final uri = extra['uri'] as String? ?? '';
    final statusCode = extra['statusCode'];
    final durationMs = extra['durationMs'];

    // Short path
    String shortUri;
    try {
      final parsed = Uri.parse(uri);
      shortUri =
          parsed.path + (parsed.query.isNotEmpty ? '?${parsed.query}' : '');
      if (shortUri.isEmpty) shortUri = '/';
    } catch (_) {
      shortUri = uri;
    }

    final theme = Theme.of(context);
    final mutedColor = theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top row: badges + duration + time
        Row(
          children: [
            _MethodBadge(method: method),
            const SizedBox(width: 6),
            if (statusCode != null) ...[
              _StatusCodeBadge(statusCode: statusCode as int),
              const SizedBox(width: 6),
            ],
            if (durationMs != null) ...[
              Icon(Icons.timer_outlined, size: 11, color: mutedColor),
              const SizedBox(width: 2),
              Text(
                '${durationMs}ms',
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: mutedColor,
                ),
              ),
              const SizedBox(width: 6),
            ],
            const Spacer(),
            Text(
              _formatTime(record.time),
              style: TextStyle(
                fontSize: 10,
                color: mutedColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Bottom row: URI path
        Text(
          shortUri,
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }

  @override
  bool allowMessageWrap(LogRecord record) => true;

  @override
  List<Widget>? buildDetails(BuildContext context, LogRecord record) {
    return [
      HttpLogDetail(
        record: record,
        showRequestHeaders: showRequestHeaders,
        showResponseHeaders: showResponseHeaders,
        showRequestBody: showRequestBody,
        showResponseBody: showResponseBody,
      ),
    ];
  }

  @override
  String? formatForCopy(LogRecord record) {
    final extra = record.extra!;
    final method = extra['method'] ?? '';
    final uri = extra['uri'] ?? '';
    final statusCode = extra['statusCode'];
    final durationMs = extra['durationMs'];

    final buf = StringBuffer();

    // Base line
    buf.writeln(const SimpleLogFormatter().format(record));

    buf.writeln('─── HTTP Detail ───');
    buf.write('$method $uri');
    if (statusCode != null) buf.write('  Status: $statusCode');
    if (durationMs != null) buf.write('  Duration: ${durationMs}ms');
    buf.writeln();

    _writeHeaders(buf, 'Request Headers', extra['requestHeaders']);
    _writeBody(buf, 'Request Body', extra['requestBody']);
    _writeHeaders(buf, 'Response Headers', extra['responseHeaders']);
    _writeBody(buf, 'Response Body', extra['responseBody']);

    return buf.toString();
  }

  static void _writeHeaders(StringBuffer buf, String label, Object? headers) {
    if (headers is Map && headers.isNotEmpty) {
      buf.writeln('── $label ──');
      for (final entry in headers.entries) {
        final value = entry.value is List
            ? (entry.value as List).join(', ')
            : entry.value;
        buf.writeln('  ${entry.key}: $value');
      }
    }
  }

  static void _writeBody(StringBuffer buf, String label, Object? body) {
    if (body == null) return;
    buf.writeln('── $label ──');
    if (body is Map || body is List) {
      try {
        const encoder = JsonEncoder.withIndent('  ');
        buf.writeln(encoder.convert(body));
      } catch (_) {
        buf.writeln(body);
      }
    } else {
      buf.writeln(body);
    }
  }

  // ── Private helpers ────────────────────────────────────────────────

  static Color _statusColor(int code) {
    if (code < 300) return const Color(0xFF4CAF50); // green
    if (code < 400) return const Color(0xFFFFA726); // orange
    if (code < 500) return const Color(0xFFEF5350); // red
    return const Color(0xFFB71C1C); // dark red
  }

  static Color _methodColor(String method) {
    return switch (method.toUpperCase()) {
      'GET' => const Color(0xFF4CAF50),
      'POST' => const Color(0xFF2196F3),
      'PUT' || 'PATCH' => const Color(0xFFFFA726),
      'DELETE' => const Color(0xFFEF5350),
      _ => const Color(0xFF9E9E9E),
    };
  }

  static String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

// ── Badge widgets ──────────────────────────────────────────────────

class _MethodBadge extends StatelessWidget {
  const _MethodBadge({required this.method});

  final String method;

  @override
  Widget build(BuildContext context) {
    final color = HttpLogRecordRenderer._methodColor(method);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        method.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _StatusCodeBadge extends StatelessWidget {
  const _StatusCodeBadge({required this.statusCode});

  final int statusCode;

  @override
  Widget build(BuildContext context) {
    final color = HttpLogRecordRenderer._statusColor(statusCode);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        statusCode.toString(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
