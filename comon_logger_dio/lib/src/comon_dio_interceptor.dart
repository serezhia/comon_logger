import 'dart:convert';

import 'package:comon_logger/comon_logger.dart';
import 'package:dio/dio.dart';

/// A Dio interceptor that logs HTTP requests, responses, and errors
/// using `comon_logger`.
///
/// **Console vs UI separation:**
/// The `logRequestHeaders`, `logResponseHeaders`, `logRequestBody`, and
/// `logResponseBody` flags control only what appears in the text *message*
/// (printed by console handlers). The log record's `extra` map **always**
/// contains the full structured data (headers, parsed body) so that UI
/// widgets like `HttpLogDetail` can render them regardless of flags.
///
/// ```dart
/// final dio = Dio();
/// dio.interceptors.add(ComonDioInterceptor());
/// ```
class ComonDioInterceptor extends Interceptor {
  ComonDioInterceptor({
    this.requestFilter,
    this.responseFilter,
    this.errorFilter,
    this.logRequestBody = false,
    this.logResponseBody = false,
    this.logRequestHeaders = false,
    this.logResponseHeaders = false,
    this.maxResponseBodyLength,
    String loggerName = 'comon.dio',
  }) : _logger = Logger(loggerName);

  final Logger _logger;

  /// If provided and returns `false`, the request is not logged.
  final bool Function(RequestOptions options)? requestFilter;

  /// If provided and returns `false`, the response is not logged.
  final bool Function(Response<dynamic> response)? responseFilter;

  /// If provided and returns `false`, the error is not logged.
  final bool Function(DioException error)? errorFilter;

  /// Whether to include the request body in the console message.
  /// The body is **always** stored in `extra` for the UI widget.
  final bool logRequestBody;

  /// Whether to include the response body in the console message.
  /// The body is **always** stored in `extra` for the UI widget.
  final bool logResponseBody;

  /// Whether to include request headers in the console message.
  /// Headers are **always** stored in `extra` for the UI widget.
  final bool logRequestHeaders;

  /// Whether to include response headers in the console message.
  /// Headers are **always** stored in `extra` for the UI widget.
  final bool logResponseHeaders;

  /// Maximum length of the response body in the console message.
  ///
  /// When `null`, the console message is not truncated. Does not affect
  /// `extra`, which always keeps the full structured body.
  final int? maxResponseBodyLength;

  /// Tries to parse [data] as a JSON-compatible object.
  ///
  /// If [data] is already a [Map] or [List], returns it directly.
  /// If [data] is a [String], tries `jsonDecode`. Returns `null` on failure.
  static Object? _tryParseBody(Object? data) {
    if (data == null) return null;
    if (data is Map || data is List) return data;
    if (data is String) {
      try {
        return jsonDecode(data);
      } catch (_) {
        return data;
      }
    }
    return data.toString();
  }

  /// Flattens Dio's `Headers.map` (Map<String, List<String>>) into a
  /// simpler map where single-value lists become plain strings.
  static Map<String, dynamic> _flattenHeaders(
      Map<String, List<String>> headers) {
    return {
      for (final entry in headers.entries)
        entry.key: entry.value.length == 1 ? entry.value.first : entry.value,
    };
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (requestFilter != null && !requestFilter!(options)) {
      handler.next(options);
      return;
    }

    // Store start time for duration calculation
    options.extra['_comon_startTime'] = DateTime.now();

    // ── Console message (controlled by flags) ────────────
    final message = StringBuffer()..write('→ ${options.method} ${options.uri}');

    if (logRequestHeaders && options.headers.isNotEmpty) {
      message.write('\nHeaders: ${options.headers}');
    }
    if (logRequestBody && options.data != null) {
      message.write('\nBody: ${options.data}');
    }

    // ── Extra (always full data for UI) ──────────────────
    _logger.fine(
      message.toString(),
      layer: LogLayer.data,
      type: LogType.network,
      extra: {
        'method': options.method,
        'uri': options.uri.toString(),
        'phase': 'request',
        if (options.headers.isNotEmpty)
          'requestHeaders': Map<String, dynamic>.from(options.headers),
        if (options.data != null) 'requestBody': _tryParseBody(options.data),
      },
    );

    handler.next(options);
  }

  @override
  void onResponse(
      Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (responseFilter != null && !responseFilter!(response)) {
      handler.next(response);
      return;
    }

    final startTime =
        response.requestOptions.extra['_comon_startTime'] as DateTime?;
    final duration =
        startTime != null ? DateTime.now().difference(startTime) : null;

    // ── Console message (controlled by flags) ────────────
    final message = StringBuffer()
      ..write(
          '← ${response.statusCode} ${response.requestOptions.method} ${response.realUri}');

    if (duration != null) {
      message.write(' (${duration.inMilliseconds}ms)');
    }

    if (logResponseHeaders && response.headers.map.isNotEmpty) {
      message.write('\nHeaders: ${response.headers.map}');
    }
    if (logResponseBody && response.data != null) {
      var body = response.data.toString();
      final limit = maxResponseBodyLength;
      if (limit != null && limit >= 0 && body.length > limit) {
        body = '${body.substring(0, limit)}... [truncated]';
      }
      message.write('\nBody: $body');
    }

    // ── Extra (always full data for UI) ──────────────────
    _logger.fine(
      message.toString(),
      layer: LogLayer.data,
      type: LogType.network,
      extra: {
        'method': response.requestOptions.method,
        'uri': response.realUri.toString(),
        'statusCode': response.statusCode,
        'phase': 'response',
        if (duration != null) 'durationMs': duration.inMilliseconds,
        if (response.requestOptions.headers.isNotEmpty)
          'requestHeaders':
              Map<String, dynamic>.from(response.requestOptions.headers),
        if (response.requestOptions.data != null)
          'requestBody': _tryParseBody(response.requestOptions.data),
        if (response.headers.map.isNotEmpty)
          'responseHeaders': _flattenHeaders(response.headers.map),
        if (response.data != null) 'responseBody': _tryParseBody(response.data),
      },
    );

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (errorFilter != null && !errorFilter!(err)) {
      handler.next(err);
      return;
    }

    // ── Extra (always full data for UI) ──────────────────
    _logger.severe(
      '✖ ${err.requestOptions.method} ${err.requestOptions.uri} — ${err.message}',
      error: err,
      stackTrace: err.stackTrace,
      layer: LogLayer.data,
      type: LogType.network,
      extra: {
        'method': err.requestOptions.method,
        'uri': err.requestOptions.uri.toString(),
        'statusCode': err.response?.statusCode,
        'phase': 'error',
        'errorType': err.type.name,
        if (err.requestOptions.headers.isNotEmpty)
          'requestHeaders':
              Map<String, dynamic>.from(err.requestOptions.headers),
        if (err.requestOptions.data != null)
          'requestBody': _tryParseBody(err.requestOptions.data),
        if (err.response?.headers.map.isNotEmpty == true)
          'responseHeaders': _flattenHeaders(err.response!.headers.map),
        if (err.response?.data != null)
          'responseBody': _tryParseBody(err.response?.data),
      },
    );

    handler.next(err);
  }
}
