import 'package:comon_logger/comon_logger.dart';
import 'package:comon_logger_dio/comon_logger_dio.dart';
import 'package:test/test.dart';

void main() {
  const formatter = HttpConsoleLogFormatter(useColors: false);

  LogRecord makeHttpRecord({
    required String phase,
    int? statusCode,
    Object? requestBody,
    Object? responseBody,
    Map<String, dynamic>? requestHeaders,
    Map<String, dynamic>? responseHeaders,
  }) {
    return LogRecord(
      level: phase == 'error' ? LogLevel.SEVERE : LogLevel.FINE,
      message: 'ignored',
      loggerName: 'comon.dio',
      time: DateTime(2026, 3, 16, 12, 30, 0, 123),
      error: phase == 'error' ? Exception('boom') : null,
      type: LogType.network,
      layer: LogLayer.data,
      extra: {
        'phase': phase,
        'method': 'GET',
        'uri': 'https://example.com/items?page=2',
        if (statusCode != null) 'statusCode': statusCode,
        'durationMs': 210,
        'requestHeaders': requestHeaders ?? {'Authorization': 'Bearer token'},
        if (requestBody != null) 'requestBody': requestBody,
        if (responseHeaders != null) 'responseHeaders': responseHeaders,
        if (responseBody != null) 'responseBody': responseBody,
      },
    );
  }

  test('matches Dio HTTP records', () {
    final record = makeHttpRecord(phase: 'response', statusCode: 200);
    expect(formatter.canFormat(record), isTrue);
  });

  test('does not match non-network records', () {
    final record = LogRecord(
      level: LogLevel.INFO,
      message: 'plain',
      loggerName: 'app',
      time: DateTime.now(),
    );

    expect(formatter.canFormat(record), isFalse);
  });

  test('formats response logs with HTTP details', () {
    final output = formatter.format(
      makeHttpRecord(
        phase: 'response',
        statusCode: 200,
        responseBody: {'ok': true},
      ),
    );

    expect(output, contains('RESPONSE GET 200 210ms'));
    expect(output, contains('/items'));
    expect(output, contains('https://example.com/items?page=2'));
    expect(output, contains('Query Params'));
    expect(output, contains('page: 2'));
    expect(output, contains('Request Headers'));
    expect(output, contains('Response Body'));
    expect(output, contains('"ok": true'));
  });

  test('formats error logs with error details', () {
    final output = formatter.format(makeHttpRecord(phase: 'error'));

    expect(output, contains('ERROR GET 210ms'));
    expect(output, contains('Error: Exception: boom'));
  });

  test('can hide full url and query params', () {
    const formatter = HttpConsoleLogFormatter(
      useColors: false,
      showFullUrl: false,
      showQueryParams: false,
    );

    final output = formatter.format(
      makeHttpRecord(phase: 'response', statusCode: 200),
    );

    expect(output, contains('/items'));
    expect(output, isNot(contains('https://example.com/items?page=2')));
    expect(output, isNot(contains('Query Params')));
  });

  test('can hide error request and response details separately', () {
    const formatter = HttpConsoleLogFormatter(
      useColors: false,
      showErrorRequestHeaders: false,
      showErrorResponseHeaders: false,
      showErrorRequestBody: false,
      showErrorResponseBody: false,
    );

    final output = formatter.format(
      makeHttpRecord(
        phase: 'error',
        requestBody: {'request': true},
        responseBody: {'response': true},
        responseHeaders: {'content-type': 'application/json'},
      ),
    );

    expect(output, contains('Error: Exception: boom'));
    expect(output, isNot(contains('Request Headers')));
    expect(output, isNot(contains('Response Headers')));
    expect(output, isNot(contains('Request Body')));
    expect(output, isNot(contains('Response Body')));
  });
}
