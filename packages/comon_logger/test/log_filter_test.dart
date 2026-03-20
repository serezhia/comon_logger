import 'package:comon_logger/comon_logger.dart';
import 'package:test/test.dart';

LogRecord _makeRecord({
  LogLevel level = LogLevel.INFO,
  LogLayer? layer,
  LogType? type,
  String? feature,
}) {
  return LogRecord(
    level: level,
    message: 'test',
    loggerName: 'test',
    time: DateTime.now(),
    layer: layer,
    type: type,
    feature: feature,
  );
}

void main() {
  group('AllPassLogFilter', () {
    test('passes everything', () {
      const filter = AllPassLogFilter();
      expect(filter.shouldLog(_makeRecord(level: LogLevel.FINEST)), isTrue);
      expect(filter.shouldLog(_makeRecord(level: LogLevel.SHOUT)), isTrue);
    });
  });

  group('LevelLogFilter', () {
    test('passes records at or above minLevel', () {
      const filter = LevelLogFilter(LogLevel.WARNING);
      expect(filter.shouldLog(_makeRecord(level: LogLevel.WARNING)), isTrue);
      expect(filter.shouldLog(_makeRecord(level: LogLevel.SEVERE)), isTrue);
      expect(filter.shouldLog(_makeRecord(level: LogLevel.SHOUT)), isTrue);
    });

    test('rejects records below minLevel', () {
      const filter = LevelLogFilter(LogLevel.WARNING);
      expect(filter.shouldLog(_makeRecord(level: LogLevel.INFO)), isFalse);
      expect(filter.shouldLog(_makeRecord(level: LogLevel.FINE)), isFalse);
      expect(filter.shouldLog(_makeRecord(level: LogLevel.FINEST)), isFalse);
    });
  });

  group('TypeLogFilter', () {
    test('passes records with matching type', () {
      final filter = TypeLogFilter({LogType.network, LogType.database});
      expect(filter.shouldLog(_makeRecord(type: LogType.network)), isTrue);
      expect(filter.shouldLog(_makeRecord(type: LogType.database)), isTrue);
    });

    test('rejects records with non-matching type', () {
      final filter = TypeLogFilter({LogType.network});
      expect(filter.shouldLog(_makeRecord(type: LogType.navigation)), isFalse);
    });

    test('passes records with null type', () {
      final filter = TypeLogFilter({LogType.network});
      expect(filter.shouldLog(_makeRecord()), isTrue);
    });
  });

  group('LayerLogFilter', () {
    test('passes records with matching layer', () {
      final filter = LayerLogFilter({LogLayer.data, LogLayer.domain});
      expect(filter.shouldLog(_makeRecord(layer: LogLayer.data)), isTrue);
      expect(filter.shouldLog(_makeRecord(layer: LogLayer.domain)), isTrue);
    });

    test('rejects records with non-matching layer', () {
      final filter = LayerLogFilter({LogLayer.data});
      expect(filter.shouldLog(_makeRecord(layer: LogLayer.widgets)), isFalse);
    });

    test('passes records with null layer', () {
      final filter = LayerLogFilter({LogLayer.data});
      expect(filter.shouldLog(_makeRecord()), isTrue);
    });
  });

  group('FeatureLogFilter', () {
    test('passes records with matching feature', () {
      const filter = FeatureLogFilter({'catalog', 'auth'});
      expect(filter.shouldLog(_makeRecord(feature: 'catalog')), isTrue);
      expect(filter.shouldLog(_makeRecord(feature: 'auth')), isTrue);
    });

    test('rejects records with non-matching feature', () {
      const filter = FeatureLogFilter({'catalog'});
      expect(filter.shouldLog(_makeRecord(feature: 'settings')), isFalse);
    });

    test('passes records with null feature', () {
      const filter = FeatureLogFilter({'catalog'});
      expect(filter.shouldLog(_makeRecord()), isTrue);
    });
  });

  group('CompositeLogFilter', () {
    test('AND mode: all must pass', () {
      final filter = CompositeLogFilter([
        const LevelLogFilter(LogLevel.INFO),
        TypeLogFilter({LogType.network}),
      ]);

      // Both pass
      expect(
        filter.shouldLog(
            _makeRecord(level: LogLevel.INFO, type: LogType.network)),
        isTrue,
      );

      // Level fails
      expect(
        filter.shouldLog(
            _makeRecord(level: LogLevel.FINE, type: LogType.network)),
        isFalse,
      );

      // Type fails
      expect(
        filter.shouldLog(
            _makeRecord(level: LogLevel.INFO, type: LogType.navigation)),
        isFalse,
      );
    });

    test('OR mode: at least one must pass', () {
      final filter = CompositeLogFilter(
        [
          const LevelLogFilter(LogLevel.SEVERE),
          TypeLogFilter({LogType.network}),
        ],
        mode: CompositeMode.or,
      );

      // Level passes
      expect(
        filter.shouldLog(
            _makeRecord(level: LogLevel.SEVERE, type: LogType.navigation)),
        isTrue,
      );

      // Type passes
      expect(
        filter.shouldLog(
            _makeRecord(level: LogLevel.FINE, type: LogType.network)),
        isTrue,
      );

      // Neither passes
      expect(
        filter.shouldLog(
            _makeRecord(level: LogLevel.FINE, type: LogType.navigation)),
        isFalse,
      );
    });

    test('empty filters list: AND passes, OR fails', () {
      const andFilter = CompositeLogFilter([]);
      const orFilter = CompositeLogFilter([], mode: CompositeMode.or);

      expect(andFilter.shouldLog(_makeRecord()), isTrue);
      expect(orFilter.shouldLog(_makeRecord()), isFalse);
    });
  });
}
