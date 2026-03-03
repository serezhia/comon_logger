import 'package:comon_logger/comon_logger.dart';
import 'package:comon_logger_flutter/comon_logger_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late HistoryLogHandler handler;

  setUp(() {
    handler = HistoryLogHandler();
  });

  tearDown(() {
    handler.dispose();
  });

  Widget buildApp() {
    return MaterialApp(
      home: ComonLoggerScreen(handler: handler),
    );
  }

  group('ComonLoggerScreen', () {
    testWidgets('shows "No logs yet" when empty', (tester) async {
      await tester.pumpWidget(buildApp());
      expect(find.text('No logs yet'), findsOneWidget);
    });

    testWidgets('shows log message', (tester) async {
      handler.handle(LogRecord(
        level: LogLevel.INFO,
        message: 'Hello World',
        loggerName: 'test',
        time: DateTime.now(),
      ));

      await tester.pumpWidget(buildApp());
      await tester.pump();

      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('shows log count in status bar', (tester) async {
      handler.handle(LogRecord(
        level: LogLevel.INFO,
        message: 'msg1',
        loggerName: 'test',
        time: DateTime.now(),
      ));
      handler.handle(LogRecord(
        level: LogLevel.WARNING,
        message: 'msg2',
        loggerName: 'test',
        time: DateTime.now(),
      ));

      await tester.pumpWidget(buildApp());
      await tester.pump();

      expect(find.text('2 / 2 logs'), findsOneWidget);
    });

    testWidgets('clear button removes all logs', (tester) async {
      handler.handle(LogRecord(
        level: LogLevel.INFO,
        message: 'to be cleared',
        loggerName: 'test',
        time: DateTime.now(),
      ));

      await tester.pumpWidget(buildApp());
      await tester.pump();

      // Tap the clear button
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();

      expect(find.text('No logs yet'), findsOneWidget);
    });

    testWidgets('filter panel toggles on/off', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ComonLoggerScreen(
          handler: handler,
          showFilterButton: true,
        ),
      ));

      // Filters should be hidden initially
      expect(find.text('Level'), findsNothing);

      // Tap filter toggle
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pump();

      // Filters should now be visible
      expect(find.text('Level'), findsOneWidget);
      expect(find.text('Layer'), findsOneWidget);
      expect(find.text('Type'), findsOneWidget);
    });

    testWidgets('search toggle shows text field', (tester) async {
      await tester.pumpWidget(buildApp());

      // Tap search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('tapping log entry expands it', (tester) async {
      handler.handle(LogRecord(
        level: LogLevel.SEVERE,
        message: 'Error occurred',
        loggerName: 'test',
        time: DateTime.now(),
        error: Exception('test error'),
        layer: LogLayer.data,
        type: LogType.network,
        feature: 'catalog',
      ));

      await tester.pumpWidget(buildApp());
      await tester.pump();

      // Tap the card to expand
      await tester.tap(find.text('Error occurred'));
      await tester.pump();

      // Should show tags now
      expect(find.text('Layer: data'), findsOneWidget);
      expect(find.text('Type: network'), findsOneWidget);
      expect(find.text('Feature: catalog'), findsOneWidget);
    });
  });
}
