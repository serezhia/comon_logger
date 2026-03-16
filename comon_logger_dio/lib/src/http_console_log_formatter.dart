import 'dart:convert';

import 'package:comon_logger/comon_logger.dart';

/// Rich console formatter for HTTP logs produced by [ComonDioInterceptor].
class HttpConsoleLogFormatter extends LogFormatter {
  const HttpConsoleLogFormatter({
    this.useColors = true,
    this.showFullUrl = false,
    this.showQueryParams = true,
    this.showRequestHeaders = false,
    this.showResponseHeaders = false,
    this.showRequestBody = true,
    this.showResponseBody = true,
    this.showErrorRequestHeaders = true,
    this.showErrorResponseHeaders = true,
    this.showErrorRequestBody = true,
    this.showErrorResponseBody = true,
    this.maxStackTraceLines = 8,
  });

  final bool useColors;
  final bool showFullUrl;
  final bool showQueryParams;
  final bool showRequestHeaders;
  final bool showResponseHeaders;
  final bool showRequestBody;
  final bool showResponseBody;
  final bool showErrorRequestHeaders;
  final bool showErrorResponseHeaders;
  final bool showErrorRequestBody;
  final bool showErrorResponseBody;
  final int maxStackTraceLines;

  static const _topBorder =
      '┌─────────────────────────────────────────────────';
  static const _bottomBorder =
      '└─────────────────────────────────────────────────';
  static const _line = '│ ';

  @override
  bool canFormat(LogRecord record) {
    return record.type == LogType.network &&
        record.extra != null &&
        record.extra!.containsKey('phase');
  }

  @override
  String format(LogRecord record) {
    final extra = record.extra ?? const <String, dynamic>{};
    final phase = extra['phase'] as String? ?? 'network';
    final method = extra['method'] as String? ?? '';
    final uri = extra['uri'] as String? ?? '';
    final statusCode = extra['statusCode'];
    final durationMs = extra['durationMs'];
    final parsedUri = _tryParseUri(uri);
    final isError = phase == 'error';

    final color = _ansiColor(phase, statusCode, record.level);
    final reset = useColors ? '\x1B[0m' : '';
    final buf = StringBuffer();

    buf.writeln(_wrap(color, _topBorder));

    final header = StringBuffer()
      ..write(_phaseIcon(phase))
      ..write(' ${phase.toUpperCase()}')
      ..write(method.isNotEmpty ? ' $method' : '')
      ..write(statusCode is int ? ' $statusCode' : '')
      ..write(durationMs is int ? ' ${durationMs}ms' : '')
      ..write(' | ${_formatTime(record.time)}');

    if (record.loggerName.isNotEmpty) {
      header.write(' | ${record.loggerName}');
    }

    buf.writeln(_wrap(color, '$_line${header.toString()}$reset'));

    final shortUri = _shortUri(uri, parsedUri);
    if (shortUri.isNotEmpty) {
      buf.writeln(_wrap(color, '$_line$shortUri$reset'));
    }
    if (showFullUrl && uri.isNotEmpty && uri != shortUri) {
      buf.writeln(_wrap(color, '$_line$uri$reset'));
    }
    _writeQueryParams(buf, color, reset, parsedUri);

    _writeHeaders(
      buf,
      color,
      reset,
      'Request Headers',
      _showRequestHeaders(isError) ? extra['requestHeaders'] : null,
    );
    _writeBody(
      buf,
      color,
      reset,
      'Request Body',
      _showRequestBody(isError) ? extra['requestBody'] : null,
    );
    _writeHeaders(
      buf,
      color,
      reset,
      'Response Headers',
      _showResponseHeaders(isError) ? extra['responseHeaders'] : null,
    );
    _writeBody(
      buf,
      color,
      reset,
      'Response Body',
      _showResponseBody(isError) ? extra['responseBody'] : null,
    );

    if (record.error != null) {
      buf.writeln(_wrap(color, '${_line}Error: ${record.error}$reset'));
    }

    if (record.stackTrace != null) {
      final lines = record.stackTrace.toString().split('\n');
      final limit =
          lines.length > maxStackTraceLines ? maxStackTraceLines : lines.length;
      for (var index = 0; index < limit; index++) {
        buf.writeln(_wrap(color, '$_line${lines[index]}$reset'));
      }
      if (lines.length > maxStackTraceLines) {
        buf.writeln(_wrap(
          color,
          '$_line... ${lines.length - maxStackTraceLines} more lines$reset',
        ));
      }
    }

    buf.write(_wrap(color, _bottomBorder));
    return buf.toString();
  }

  bool _showRequestHeaders(bool isError) =>
      isError ? showErrorRequestHeaders : showRequestHeaders;

  bool _showResponseHeaders(bool isError) =>
      isError ? showErrorResponseHeaders : showResponseHeaders;

  bool _showRequestBody(bool isError) =>
      isError ? showErrorRequestBody : showRequestBody;

  bool _showResponseBody(bool isError) =>
      isError ? showErrorResponseBody : showResponseBody;

  static Uri? _tryParseUri(String uri) {
    if (uri.isEmpty) return null;
    try {
      return Uri.parse(uri);
    } catch (_) {
      return null;
    }
  }

  static String _shortUri(String uri, Uri? parsedUri) {
    if (uri.isEmpty) return '';
    if (parsedUri == null) return uri;
    return parsedUri.path.isEmpty ? '/' : parsedUri.path;
  }

  void _writeQueryParams(
    StringBuffer buf,
    String color,
    String reset,
    Uri? parsedUri,
  ) {
    if (!showQueryParams ||
        parsedUri == null ||
        parsedUri.queryParameters.isEmpty) {
      return;
    }

    buf.writeln(_wrap(color, '$_line── Query Params ──$reset'));
    final entries = parsedUri.queryParameters.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final entry in entries) {
      buf.writeln(_wrap(color, '$_line${entry.key}: ${entry.value}$reset'));
    }
  }

  static void _writeHeaders(
    StringBuffer buf,
    String color,
    String reset,
    String label,
    Object? headers,
  ) {
    if (headers is! Map || headers.isEmpty) return;

    buf.writeln(_wrap(color, '$_line── $label ──$reset'));
    final entries = headers.entries.toList()
      ..sort((a, b) => '${a.key}'.compareTo('${b.key}'));
    for (final entry in entries) {
      final value =
          entry.value is List ? (entry.value as List).join(', ') : entry.value;
      buf.writeln(_wrap(color, '$_line${entry.key}: $value$reset'));
    }
  }

  static void _writeBody(
    StringBuffer buf,
    String color,
    String reset,
    String label,
    Object? body,
  ) {
    if (body == null) return;

    buf.writeln(_wrap(color, '$_line── $label ──$reset'));
    final text = _formatBody(body);
    for (final line in text.split('\n')) {
      buf.writeln(_wrap(color, '$_line$line$reset'));
    }
  }

  static String _formatBody(Object body) {
    if (body is Map || body is List) {
      try {
        return const JsonEncoder.withIndent('  ').convert(body);
      } catch (_) {
        return body.toString();
      }
    }
    return body.toString();
  }

  static String _phaseIcon(String phase) {
    return switch (phase) {
      'request' => '⇢',
      'response' => '⇠',
      'error' => '✖',
      _ => '•',
    };
  }

  String _ansiColor(String phase, Object? statusCode, LogLevel level) {
    if (!useColors) return '';
    if (phase == 'error' || level >= LogLevel.SEVERE) return '\x1B[31m';
    if (statusCode is int) {
      if (statusCode < 300) return '\x1B[32m';
      if (statusCode < 400) return '\x1B[33m';
      if (statusCode < 500) return '\x1B[31m';
      return '\x1B[35;1m';
    }
    return '\x1B[36m';
  }

  static String _wrap(String color, String text) =>
      color.isEmpty ? text : '$color$text';

  static String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    final ms = time.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }
}
