import 'dart:io';

import 'package:comon_logger/comon_logger.dart';
import 'package:comon_logger_file/comon_logger_file.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('comon_logger_buffer_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  LogRecord record(String message, [LogLevel level = LogLevel.INFO]) =>
      LogRecord(
        level: level,
        message: message,
        loggerName: 'test',
        time: DateTime(2025, 1, 1, 12),
      );

  String onDisk([String name = 'comon_log.txt']) {
    final file = File('${tempDir.path}/$name');
    return file.existsSync() ? file.readAsStringSync() : '';
  }

  Future<FileLogHandler> open({
    Duration flushInterval = const Duration(milliseconds: 500),
    int maxBufferBytes = 64 * 1024,
    int maxFileSize = 5 * 1024 * 1024,
    int maxFiles = 5,
    String? directory,
  }) async {
    final handler = FileLogHandler(
      directory: directory ?? tempDir.path,
      flushInterval: flushInterval,
      maxBufferBytes: maxBufferBytes,
      maxFileSize: maxFileSize,
      maxFiles: maxFiles,
    );
    await handler.init();
    return handler;
  }

  test('holds records until flushInterval elapses', () async {
    final handler = await open();

    fakeAsync((async) {
      handler.handle(record('first'));
      handler.handle(record('second'));
      async.elapse(const Duration(milliseconds: 499));
      expect(onDisk(), isEmpty);

      async.elapse(const Duration(milliseconds: 1));
      expect(onDisk(), allOf(contains('first'), contains('second')));
    });
    await handler.close();
  });

  test('writes once pending bytes reach maxBufferBytes', () async {
    final handler = await open(maxBufferBytes: 10);

    fakeAsync((async) {
      handler.handle(record('long enough to pass ten bytes'));
      expect(onDisk(), contains('long enough'));
      expect(async.pendingTimers, isEmpty);
    });
    await handler.close();
  });

  test('a record at flushLevel writes it and everything before it', () async {
    final handler = await open();

    fakeAsync((async) {
      handler.handle(record('before'));
      handler.handle(record('boom', LogLevel.SEVERE));

      final lines = onDisk().trim().split('\n');
      expect(lines, hasLength(2));
      expect(lines[0], contains('before'));
      expect(lines[1], contains('boom'));
    });
    await handler.close();
  });

  test('Duration.zero writes every record immediately', () async {
    final handler = await open(flushInterval: Duration.zero);

    fakeAsync((async) {
      handler.handle(record('now'));
      expect(onDisk(), contains('now'));
      expect(async.pendingTimers, isEmpty);
    });
    await handler.close();
  });

  test('close writes pending records', () async {
    final handler = await open(flushInterval: const Duration(hours: 1));

    handler.handle(record('pending'));
    expect(onDisk(), isEmpty);
    await handler.close();

    expect(onDisk(), contains('pending'));
  });

  test('rotates at the same line boundaries as unbuffered writes', () async {
    final bufferedDir = Directory('${tempDir.path}/buffered')..createSync();
    final directDir = Directory('${tempDir.path}/direct')..createSync();
    final buffered = await open(
      directory: bufferedDir.path,
      flushInterval: const Duration(hours: 1),
      maxFileSize: 120,
      maxFiles: 4,
    );
    final direct = await open(
      directory: directDir.path,
      flushInterval: Duration.zero,
      maxFileSize: 120,
      maxFiles: 4,
    );

    for (var i = 0; i < 12; i++) {
      buffered.handle(record('rotation record $i'));
      direct.handle(record('rotation record $i'));
    }
    await buffered.close();
    await direct.close();

    Map<String, String> contents(Directory dir) => {
      for (final file in dir.listSync().whereType<File>())
        file.uri.pathSegments.last: file.readAsStringSync(),
    };
    expect(contents(bufferedDir), hasLength(greaterThan(1)));
    expect(contents(bufferedDir), contents(directDir));
  });
}
