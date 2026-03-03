import 'package:comon_logger/comon_logger.dart';
import 'package:shelf/shelf.dart';

/// Shelf middleware that logs every HTTP request and response using comon_logger.
///
/// - Incoming request → INFO (layer: infra, type: network)
/// - Successful response → FINE with duration
/// - Server error (5xx) → SEVERE with duration
Middleware loggingMiddleware({String loggerName = 'shelf.http'}) {
  final log = Logger(loggerName);

  return (Handler innerHandler) {
    return (Request request) async {
      final stopwatch = Stopwatch()..start();

      log.info(
        '→ ${request.method} ${request.requestedUri.path}',
        layer: LogLayer.infra,
        type: LogType.network,
        extra: {
          'phase': 'request',
          'method': request.method,
          'uri': request.requestedUri.toString(),
          'contentLength': request.contentLength,
        },
      );

      try {
        final response = await innerHandler(request);
        stopwatch.stop();

        final level = response.statusCode >= 500
            ? LogLevel.SEVERE
            : LogLevel.FINE;

        log.log(
          level,
          '← ${response.statusCode} ${request.method} '
          '${request.requestedUri.path} (${stopwatch.elapsedMilliseconds} ms)',
          layer: LogLayer.infra,
          type: LogType.network,
          extra: {
            'phase': 'response',
            'method': request.method,
            'uri': request.requestedUri.toString(),
            'statusCode': response.statusCode,
            'durationMs': stopwatch.elapsedMilliseconds,
          },
        );

        return response;
      } catch (e, st) {
        stopwatch.stop();
        log.severe(
          '✕ ${request.method} ${request.requestedUri.path} '
          '(${stopwatch.elapsedMilliseconds} ms)',
          error: e,
          stackTrace: st,
          layer: LogLayer.infra,
          type: LogType.network,
          extra: {
            'phase': 'error',
            'method': request.method,
            'uri': request.requestedUri.toString(),
            'durationMs': stopwatch.elapsedMilliseconds,
          },
        );
        rethrow;
      }
    };
  };
}
