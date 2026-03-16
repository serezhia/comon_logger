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

    testWidgets('shows newest logs first by default', (tester) async {
      handler.handle(LogRecord(
        level: LogLevel.INFO,
        message: 'first',
        loggerName: 'test',
        time: DateTime.now(),
      ));
      handler.handle(LogRecord(
        level: LogLevel.INFO,
        message: 'second',
        loggerName: 'test',
        time: DateTime.now(),
      ));

      await tester.pumpWidget(buildApp());
      await tester.pump();

      final firstDy = tester.getTopLeft(find.text('first')).dy;
      final secondDy = tester.getTopLeft(find.text('second')).dy;

      expect(secondDy, lessThan(firstDy));
    });

    testWidgets('starts at the top of the list', (tester) async {
      for (var index = 0; index < 30; index++) {
        handler.handle(LogRecord(
          level: LogLevel.INFO,
          message: 'initial $index',
          loggerName: 'test',
          time: DateTime.now(),
        ));
      }

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final position =
          tester.state<ScrollableState>(find.byType(Scrollable)).position;

      expect(position.pixels, 0.0);
      expect(find.text('initial 29'), findsOneWidget);
    });

    testWidgets('incoming logs do not move the current viewport by default',
        (tester) async {
      for (var index = 0; index < 30; index++) {
        handler.handle(LogRecord(
          level: LogLevel.INFO,
          message: 'log $index',
          loggerName: 'test',
          time: DateTime.now(),
        ));
      }

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final beforeDy = tester.getTopLeft(find.text('log 29')).dy;

      handler.handle(LogRecord(
        level: LogLevel.INFO,
        message: 'log 30',
        loggerName: 'test',
        time: DateTime.now(),
      ));

      await tester.pumpAndSettle();

      final afterDy = tester.getTopLeft(find.text('log 29')).dy;

      expect(afterDy, beforeDy);
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
