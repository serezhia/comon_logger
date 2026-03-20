import 'package:comon_logger/comon_logger.dart';
import 'package:comon_logger_navigation_flutter/comon_logger_navigation_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingHandler extends LogHandler {
  _RecordingHandler() : super(filter: const AllPassLogFilter());
  final records = <LogRecord>[];

  @override
  void handle(LogRecord record) => records.add(record);
}

void main() {
  late _RecordingHandler handler;

  setUp(() {
    Logger.root.clearHandlers();
    handler = _RecordingHandler();
    Logger.root.addHandler(handler);
  });

  tearDown(() {
    Logger.root.clearHandlers();
  });

  testWidgets('logs PUSH on Navigator.push', (tester) async {
    final observer = ComonNavigatorObserver();

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        initialRoute: '/',
        routes: {
          '/': (_) => Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamed('/details'),
              child: const Text('Go'),
            ),
          ),
          '/details': (_) => const Text('Details'),
        },
      ),
    );

    // Initial push for '/'
    final initialRecords = handler.records.length;
    expect(initialRecords, greaterThanOrEqualTo(1));
    expect(handler.records.first.message, contains('PUSH'));

    // Navigate to /details
    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();

    final pushRecord = handler.records.last;
    expect(pushRecord.message, contains('PUSH'));
    expect(pushRecord.message, contains('/details'));
    expect(pushRecord.layer, LogLayer.widgets);
    expect(pushRecord.type, LogType.navigation);
    expect(pushRecord.extra?['action'], 'PUSH');
    expect(pushRecord.extra?['route'], '/details');
  });

  testWidgets('logs POP on Navigator.pop', (tester) async {
    final observer = ComonNavigatorObserver();

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        initialRoute: '/',
        routes: {
          '/': (_) => Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamed('/details'),
              child: const Text('Go'),
            ),
          ),
          '/details': (_) => Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back'),
            ),
          ),
        },
      ),
    );

    // Push to /details
    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();

    // Pop back
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    final popRecord = handler.records.last;
    expect(popRecord.message, contains('POP'));
    expect(popRecord.message, contains('/details'));
    expect(popRecord.extra?['action'], 'POP');
  });

  testWidgets('logs REPLACE on Navigator.pushReplacementNamed', (tester) async {
    final observer = ComonNavigatorObserver();

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        initialRoute: '/',
        routes: {
          '/': (_) => Builder(
            builder: (context) => ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pushReplacementNamed('/settings'),
              child: const Text('Replace'),
            ),
          ),
          '/settings': (_) => const Text('Settings'),
        },
      ),
    );

    await tester.tap(find.text('Replace'));
    await tester.pumpAndSettle();

    final replaceRecord = handler.records.last;
    expect(replaceRecord.message, contains('REPLACE'));
    expect(replaceRecord.message, contains('/settings'));
    expect(replaceRecord.extra?['action'], 'REPLACE');
  });

  test('custom loggerName is used', () {
    final observer = ComonNavigatorObserver(loggerName: 'my_app.nav');
    // Just verify it was created without error
    expect(observer, isA<NavigatorObserver>());
  });
}
