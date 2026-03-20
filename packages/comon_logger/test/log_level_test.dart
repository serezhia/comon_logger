import 'package:comon_logger/comon_logger.dart';
import 'package:test/test.dart';

void main() {
  group('LogLevel', () {
    test('has correct values', () {
      expect(LogLevel.FINEST.value, 300);
      expect(LogLevel.FINER.value, 400);
      expect(LogLevel.FINE.value, 500);
      expect(LogLevel.CONFIG.value, 700);
      expect(LogLevel.INFO.value, 800);
      expect(LogLevel.WARNING.value, 900);
      expect(LogLevel.SEVERE.value, 1000);
      expect(LogLevel.SHOUT.value, 1200);
      expect(LogLevel.OFF.value, 2000);
    });

    test('values list contains all levels except OFF in ascending order', () {
      expect(LogLevel.values, [
        LogLevel.FINEST,
        LogLevel.FINER,
        LogLevel.FINE,
        LogLevel.CONFIG,
        LogLevel.INFO,
        LogLevel.WARNING,
        LogLevel.SEVERE,
        LogLevel.SHOUT,
      ]);
      expect(LogLevel.values, isNot(contains(LogLevel.OFF)));
    });

    test('values are in ascending order', () {
      for (var i = 0; i < LogLevel.values.length - 1; i++) {
        expect(
            LogLevel.values[i].value, lessThan(LogLevel.values[i + 1].value));
      }
    });

    test('comparison operators work correctly', () {
      expect(LogLevel.INFO >= LogLevel.FINE, isTrue);
      expect(LogLevel.INFO >= LogLevel.INFO, isTrue);
      expect(LogLevel.FINE >= LogLevel.INFO, isFalse);

      expect(LogLevel.FINE <= LogLevel.INFO, isTrue);
      expect(LogLevel.INFO <= LogLevel.INFO, isTrue);
      expect(LogLevel.INFO <= LogLevel.FINE, isFalse);

      expect(LogLevel.INFO > LogLevel.FINE, isTrue);
      expect(LogLevel.INFO > LogLevel.INFO, isFalse);

      expect(LogLevel.FINE < LogLevel.INFO, isTrue);
      expect(LogLevel.INFO < LogLevel.INFO, isFalse);
    });

    test('compareTo works correctly', () {
      expect(LogLevel.INFO.compareTo(LogLevel.FINE), greaterThan(0));
      expect(LogLevel.INFO.compareTo(LogLevel.INFO), equals(0));
      expect(LogLevel.FINE.compareTo(LogLevel.INFO), lessThan(0));
    });

    test('equality and hashCode', () {
      expect(LogLevel.INFO == LogLevel.INFO, isTrue);
      expect(LogLevel.INFO == LogLevel.WARNING, isFalse);
      expect(LogLevel.INFO.hashCode, LogLevel.INFO.hashCode);

      // Custom level with same value should be equal
      const custom = LogLevel('CUSTOM', 800);
      expect(custom == LogLevel.INFO, isTrue);
    });

    test('toString returns name', () {
      expect(LogLevel.INFO.toString(), 'INFO');
      expect(LogLevel.WARNING.toString(), 'WARNING');
      expect(LogLevel.FINEST.toString(), 'FINEST');
    });

    test('can be sorted', () {
      final levels = [
        LogLevel.SEVERE,
        LogLevel.FINE,
        LogLevel.INFO,
        LogLevel.FINEST,
        LogLevel.WARNING,
      ];
      levels.sort();
      expect(levels, [
        LogLevel.FINEST,
        LogLevel.FINE,
        LogLevel.INFO,
        LogLevel.WARNING,
        LogLevel.SEVERE,
      ]);
    });
  });
}
