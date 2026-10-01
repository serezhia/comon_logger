import 'dart:io';

import 'package:comon_logger_flutter/comon_logger_flutter.dart';
import 'package:comon_logger_share_flutter/comon_logger_share_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

class _FakeSharePlatform extends SharePlatform with MockPlatformInterfaceMixin {
  final List<ShareParams> shared = [];

  @override
  Future<ShareResult> share(ShareParams params) async {
    shared.add(params);
    return ShareResult.unavailable;
  }
}

void main() {
  late _FakeSharePlatform platform;
  late HistoryLogHandler handler;
  late Directory dir;

  setUp(() async {
    platform = _FakeSharePlatform();
    SharePlatform.instance = platform;
    handler = HistoryLogHandler();
    dir = await Directory.systemTemp.createTemp('share_logs_test_');
  });

  tearDown(() async {
    handler.dispose();
    await dir.delete(recursive: true);
  });

  Future<void> openSheet(WidgetTester tester, ShareLogsAction action) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ComonLoggerScreen(handler: handler, actions: [action]),
      ),
    );
    await tester.tap(find.byTooltip(action.strings.tooltip));
    await tester.pumpAndSettle();
  }

  testWidgets('file option is hidden without logFiles', (tester) async {
    await openSheet(tester, const ShareLogsAction());

    expect(find.text('Share as text'), findsOneWidget);
    expect(find.text('Share log files'), findsNothing);
  });

  testWidgets('shares the existing log files', (tester) async {
    final current = File('${dir.path}/comon_log.txt')..writeAsStringSync('a');
    final rotated = File('${dir.path}/comon_log_1.txt')..writeAsStringSync('b');
    var asked = 0;

    await openSheet(
      tester,
      ShareLogsAction(
        logFiles: () async {
          asked++;
          return [current.path, rotated.path, '${dir.path}/missing.txt'];
        },
      ),
    );
    await tester.runAsync(() async {
      await tester.tap(find.text('Share log files'));
      await tester.pumpAndSettle();
    });
    await tester.pumpAndSettle();

    expect(asked, 1);
    expect(platform.shared, hasLength(1));
    expect(platform.shared.single.files!.map((f) => f.path), [
      current.path,
      rotated.path,
    ]);
  });

  testWidgets('says so when there are no log files', (tester) async {
    await openSheet(
      tester,
      ShareLogsAction(
        logFiles: () async => ['${dir.path}/missing.txt'],
        strings: const ShareLogsStrings(
          tooltip: 'Поделиться',
          files: 'Файлы логов',
          noFiles: 'Файлов нет',
        ),
      ),
    );
    await tester.runAsync(() async {
      await tester.tap(find.text('Файлы логов'));
      await tester.pumpAndSettle();
    });
    await tester.pumpAndSettle();

    expect(platform.shared, isEmpty);
    expect(find.text('Файлов нет'), findsOneWidget);
  });
}
