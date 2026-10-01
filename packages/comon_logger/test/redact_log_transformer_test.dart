import 'package:comon_logger/comon_logger.dart';
import 'package:test/test.dart';

LogRecord _record({
  String message = 'm',
  Object? error,
  Map<String, dynamic>? extra,
}) => LogRecord(
  level: LogLevel.INFO,
  message: message,
  loggerName: 'redact',
  time: DateTime(2026),
  error: error,
  extra: extra,
  feature: 'auth',
);

void main() {
  group('RedactLogTransformer', () {
    test('replaces listed keys at any depth, case-insensitively', () {
      final redact = RedactLogTransformer(keys: {'token', 'Password'});

      final out = redact(
        _record(
          extra: {
            'Token': 'abc',
            'user': {'password': 'p', 'name': 'n'},
            'items': [
              {'token': 't'},
              'plain',
            ],
            'count': 3,
          },
        ),
      );

      expect(out.extra, {
        'Token': '<redacted>',
        'user': {'password': '<redacted>', 'name': 'n'},
        'items': [
          {'token': '<redacted>'},
          'plain',
        ],
        'count': 3,
      });
    });

    test('cuts long strings and says how much was removed', () {
      final redact = RedactLogTransformer(maxStringLength: 3);

      final out = redact(
        _record(
          message: 'abcdef',
          error: StateError('long error'),
          extra: {'body': 'xyz12', 'short': 'ab'},
        ),
      );

      expect(out.message, 'abc…(+3)');
      expect(out.extra, {'body': 'xyz…(+2)', 'short': 'ab'});
      expect(out.error, isA<String>());
      expect((out.error as String).startsWith('Bad'), isTrue);
    });

    test('keeps short errors as objects and other fields unchanged', () {
      final error = ArgumentError();
      final redact = RedactLogTransformer(maxStringLength: 1000);

      final out = redact(_record(error: error));

      expect(identical(out.error, error), isTrue);
      expect(out.feature, 'auth');
      expect(out.loggerName, 'redact');
      expect(out.extra, isNull);
    });

    test('plugs into Logger.addTransformer', () {
      final seen = <LogRecord>[];
      final log = Logger('redact.wired')
        ..addTransformer(RedactLogTransformer(keys: {'token'}).call);
      log.onRecord.listen(seen.add);

      log.info('signed in', extra: {'token': 'secret'});

      return Future<void>.delayed(Duration.zero, () {
        expect(seen.single.extra, {'token': '<redacted>'});
      });
    });
  });
}
