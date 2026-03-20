import 'dart:convert';
import 'dart:io';

import 'package:comon_logger/comon_logger.dart';
import 'package:comon_logger_file/comon_logger_file.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late FileLogHandler handler;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('comon_logger_file_test_');
  });

  tearDown(() async {
    if (handler.isInitialized) {
      await handler.close();
    }
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  LogRecord makeRecord(String message) => LogRecord(
    level: LogLevel.INFO,
    message: message,
    loggerName: 'test',
    time: DateTime(2025, 1, 1, 12, 0, 0),
  );

  test('init creates directory if not exists', () async {
    final subDir = '${tempDir.path}/sub/logs';
    handler = FileLogHandler(directory: subDir);
    await handler.init();

    expect(Directory(subDir).existsSync(), isTrue);
    expect(handler.isInitialized, isTrue);
  });

  test('writes log record to file', () async {
    handler = FileLogHandler(directory: tempDir.path);
    await handler.init();

    handler.handle(makeRecord('Hello, file!'));
    handler.flush();

    final logFile = File('${tempDir.path}/comon_log.txt');
    expect(logFile.existsSync(), isTrue);

    final content = await logFile.readAsString();
    expect(content, contains('Hello, file!'));
  });

  test('writes multiple records', () async {
    handler = FileLogHandler(directory: tempDir.path);
    await handler.init();

    handler.handle(makeRecord('First'));
    handler.handle(makeRecord('Second'));
    handler.handle(makeRecord('Third'));
    handler.flush();

    final content = await File('${tempDir.path}/comon_log.txt').readAsString();
    final lines = content.trim().split('\n');
    expect(lines.length, 3);
    expect(lines[0], contains('First'));
    expect(lines[1], contains('Second'));
    expect(lines[2], contains('Third'));
  });

  test('writes JSON when writeAsJson is true', () async {
    handler = FileLogHandler(directory: tempDir.path, writeAsJson: true);
    await handler.init();

    handler.handle(makeRecord('JSON test'));
    handler.flush();

    final content = await File('${tempDir.path}/comon_log.txt').readAsString();
    final json = jsonDecode(content.trim()) as Map<String, dynamic>;
    expect(json['message'], 'JSON test');
    expect(json['level'], 'INFO');
  });

  test('rotates file when maxFileSize is exceeded', () async {
    handler = FileLogHandler(
      directory: tempDir.path,
      maxFileSize: 50, // very small for testing
      maxFiles: 3,
    );
    await handler.init();

    // Write enough to trigger rotation
    for (var i = 0; i < 10; i++) {
      handler.handle(makeRecord('Record number $i with some padding'));
    }
    handler.flush();

    final files = handler.getLogFiles();
    expect(files.length, greaterThan(1));
    expect(files.length, lessThanOrEqualTo(3));

    // Current file should exist
    expect(File('${tempDir.path}/comon_log.txt').existsSync(), isTrue);
  });

  test('respects maxFiles limit during rotation', () async {
    handler = FileLogHandler(
      directory: tempDir.path,
      maxFileSize: 30, // tiny
      maxFiles: 2,
    );
    await handler.init();

    for (var i = 0; i < 20; i++) {
      handler.handle(makeRecord('Overflow record $i padding text'));
    }
    handler.flush();

    final files = handler.getLogFiles();
    // Should never exceed maxFiles
    expect(files.length, lessThanOrEqualTo(2));
  });

  test('getLogFiles returns matching files', () async {
    handler = FileLogHandler(directory: tempDir.path);
    await handler.init();

    handler.handle(makeRecord('test'));
    handler.flush();

    // Create a non-matching file
    await File('${tempDir.path}/other.log').writeAsString('other');

    final files = handler.getLogFiles();
    expect(files.every((f) => f.path.contains('comon_log')), isTrue);
  });

  test('appends to existing file on reinit', () async {
    handler = FileLogHandler(directory: tempDir.path);
    await handler.init();

    handler.handle(makeRecord('First session'));
    await handler.close();

    // Re-init
    handler = FileLogHandler(directory: tempDir.path);
    await handler.init();

    handler.handle(makeRecord('Second session'));
    handler.flush();

    final content = await File('${tempDir.path}/comon_log.txt').readAsString();
    expect(content, contains('First session'));
    expect(content, contains('Second session'));
  });

  test('does nothing when not initialized', () async {
    handler = FileLogHandler(directory: tempDir.path);
    // Don't call init
    handler.handle(makeRecord('Should be ignored'));

    final logFile = File('${tempDir.path}/comon_log.txt');
    expect(logFile.existsSync(), isFalse);
  });

  test('custom baseFileName and extension', () async {
    handler = FileLogHandler(
      directory: tempDir.path,
      baseFileName: 'app_log',
      extension: '.log',
    );
    await handler.init();

    handler.handle(makeRecord('Custom name'));
    handler.flush();

    expect(File('${tempDir.path}/app_log.log').existsSync(), isTrue);
  });

  test('close sets isInitialized to false', () async {
    handler = FileLogHandler(directory: tempDir.path);
    await handler.init();
    expect(handler.isInitialized, isTrue);

    await handler.close();
    expect(handler.isInitialized, isFalse);
  });
}
