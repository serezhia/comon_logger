import 'package:comon_logger/comon_logger.dart';
import 'package:comon_logger_flutter/comon_logger_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

LogRecord _record(String message) => LogRecord(
  level: LogLevel.INFO,
  message: message,
  loggerName: 'test',
  time: DateTime(2026),
  layer: LogLayer.data,
  error: 'broken',
);

const _ru = ComonLoggerStrings(
  title: 'Журнал',
  noLogsYet: 'Пока пусто',
  clearLogs: 'Очистить',
  search: 'Поиск',
  layer: 'Слой',
  error: 'Ошибка',
  importTooltip: 'Импорт',
  importTitle: 'Импорт журнала',
  cancel: 'Отмена',
  recordCount: _count,
);

String _count(int shown, int total) => 'показано $shown из $total';

void main() {
  late HistoryLogHandler handler;

  setUp(() => handler = HistoryLogHandler(maxHistory: 3));
  tearDown(() => handler.dispose());

  testWidgets('screen uses the strings passed to it', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ComonLoggerScreen(handler: handler, strings: _ru),
      ),
    );

    expect(find.text('Журнал'), findsOneWidget);
    expect(find.text('Пока пусто'), findsOneWidget);
    expect(find.text('показано 0 из 0'), findsOneWidget);
    expect(find.byTooltip('Очистить'), findsOneWidget);
    expect(find.byTooltip('Поиск'), findsOneWidget);
    expect(find.text('Logs'), findsNothing);
  });

  testWidgets('screen picks strings from an enclosing scope', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ComonLoggerStringsScope(
          strings: _ru,
          child: ComonLoggerScreen(handler: handler),
        ),
      ),
    );

    expect(find.text('Журнал'), findsOneWidget);
  });

  testWidgets('expanded record labels use the strings', (tester) async {
    handler.handle(_record('tap me'));
    await tester.pumpWidget(
      MaterialApp(
        home: ComonLoggerScreen(handler: handler, strings: _ru),
      ),
    );

    await tester.tap(find.text('tap me'));
    await tester.pump();

    expect(find.text('Слой: data'), findsOneWidget);
    expect(find.text('Ошибка: broken'), findsOneWidget);
  });

  testWidgets('import dialog keeps the screen strings', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ComonLoggerScreen(
          handler: handler,
          strings: _ru,
          actions: const [ImportLogsAction()],
        ),
      ),
    );

    await tester.tap(find.byTooltip('Импорт'));
    await tester.pumpAndSettle();

    expect(find.text('Импорт журнала'), findsOneWidget);
    expect(find.text('Отмена'), findsOneWidget);
  });

  testWidgets('open screen keeps no more records than maxHistory', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ComonLoggerScreen(handler: handler, strings: _ru),
      ),
    );

    for (var i = 0; i < 5; i++) {
      handler.handle(_record('m$i'));
      await tester.pump();
    }
    await tester.pump();

    expect(find.text('показано 3 из 3'), findsOneWidget);
    expect(find.text('m0'), findsNothing);
    expect(find.text('m4'), findsOneWidget);
  });
}
