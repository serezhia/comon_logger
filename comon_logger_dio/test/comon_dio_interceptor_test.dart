import 'dart:async';

import 'package:comon_logger/comon_logger.dart';
import 'package:comon_logger_dio/comon_logger_dio.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

/// A test handler that collects all handled records.
class _TestHandler extends LogHandler {
  _TestHandler({super.filter = const AllPassLogFilter()});

  final List<LogRecord> records = [];

  @override
  void handle(LogRecord record) {
    records.add(record);
  }
}

void main() {
  late _TestHandler handler;
  late Dio dio;

  setUp(() {
    handler = _TestHandler();
    Logger.root.addHandler(handler);

    dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
    dio.interceptors.add(ComonDioInterceptor(
      logRequestBody: true,
      logResponseBody: true,
    ));
  });

  tearDown(() {
    Logger.root.removeHandler(handler);
    dio.close();
  });

  group('ComonDioInterceptor', () {
    test('logger hierarchy propagates to root', () {
      // Verify basic propagation works before testing with Dio
      final childLogger = Logger('comon.dio');
      childLogger.info('direct test');

      expect(handler.records, isNotEmpty,
          reason: 'Logger hierarchy should propagate to root');
      expect(handler.records.first.message, 'direct test');
    });

    test('logs request', () async {
      // Use a mock adapter to avoid real HTTP
      dio.httpClientAdapter = _MockAdapter(
        response: ResponseBody.fromString('{"ok":true}', 200),
      );

      await dio.get<dynamic>('/test');

      final requestLogs =
          handler.records.where((r) => r.extra?['phase'] == 'request').toList();
      expect(requestLogs, isNotEmpty);
      expect(requestLogs.first.message, contains('GET'));
      expect(requestLogs.first.message, contains('/test'));
      expect(requestLogs.first.layer, LogLayer.data);
      expect(requestLogs.first.type, LogType.network);
    });

    test('logs response with status code', () async {
      dio.httpClientAdapter = _MockAdapter(
        response: ResponseBody.fromString('{"ok":true}', 200),
      );

      await dio.get<dynamic>('/test');

      final responseLogs = handler.records
          .where((r) => r.extra?['phase'] == 'response')
          .toList();
      expect(responseLogs, isNotEmpty);
      expect(responseLogs.first.extra?['statusCode'], 200);
    });

    test('does not truncate response body by default', () async {
      final longBody = 'x' * 100;
      dio.httpClientAdapter = _MockAdapter(
        response: ResponseBody.fromString(longBody, 200),
      );

      await dio.get<dynamic>('/full-body');

      final responseLogs = handler.records
          .where((r) => r.extra?['phase'] == 'response')
          .toList();
      expect(responseLogs, isNotEmpty);
      expect(responseLogs.first.message, contains(longBody));
      expect(responseLogs.first.message, isNot(contains('[truncated]')));
    });

    test('logs error', () async {
      dio.httpClientAdapter = _MockAdapter(
        throwError: true,
      );

      try {
        await dio.get<dynamic>('/fail');
      } catch (_) {
        // Expected
      }

      final errorLogs =
          handler.records.where((r) => r.extra?['phase'] == 'error').toList();
      expect(errorLogs, isNotEmpty);
      expect(errorLogs.first.level, LogLevel.SEVERE);
    });

    test('requestFilter suppresses request logging', () async {
      dio.interceptors.clear();
      dio.interceptors.add(ComonDioInterceptor(
        requestFilter: (options) => false,
      ));
      dio.httpClientAdapter = _MockAdapter(
        response: ResponseBody.fromString('ok', 200),
      );

      await dio.get<dynamic>('/filtered');

      final requestLogs =
          handler.records.where((r) => r.extra?['phase'] == 'request').toList();
      expect(requestLogs, isEmpty);
    });

    test('truncates long response body', () async {
      dio.interceptors.clear();
      dio.interceptors.add(ComonDioInterceptor(
        logResponseBody: true,
        maxResponseBodyLength: 20,
      ));

      final longBody = 'x' * 100;
      dio.httpClientAdapter = _MockAdapter(
        response: ResponseBody.fromString(longBody, 200),
      );

      await dio.get<dynamic>('/long');

      final responseLogs = handler.records
          .where((r) => r.extra?['phase'] == 'response')
          .toList();
      expect(responseLogs, isNotEmpty);
      expect(responseLogs.first.message, contains('[truncated]'));
    });
  });
}

/// Simple mock HTTP adapter for testing.
class _MockAdapter implements HttpClientAdapter {
  _MockAdapter({this.response, this.throwError = false});

  final ResponseBody? response;
  final bool throwError;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (throwError) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        message: 'Mock connection error',
      );
    }
    return response ?? ResponseBody.fromString('', 200);
  }

  @override
  void close({bool force = false}) {}
}
