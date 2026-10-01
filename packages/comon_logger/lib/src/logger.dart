import 'dart:async';

import 'log_handler.dart';
import 'log_layer.dart';
import 'log_level.dart';
import 'log_record.dart';
import 'log_type.dart';

/// Rewrites or drops a [LogRecord] before any handler sees it.
///
/// Return the record (or a modified copy) to keep it, or `null` to drop it.
/// Use it to redact secrets or trim payloads in one place for every handler.
typedef LogRecordTransformer = LogRecord? Function(LogRecord record);

/// A hierarchical, cached logger.
///
/// Use the factory constructor to obtain a named logger:
/// ```dart
/// final log = Logger('my_app.catalog');
/// ```
///
/// Logger names follow a dotted hierarchy — `Logger('dio.request')` is a
/// child of `Logger('dio')`, which is a child of [Logger.root].
///
/// Handlers added to [Logger.root] receive records from **all** loggers.
class Logger {
  /// Returns a cached logger for [name].
  ///
  /// `Logger('')` returns the same object as [Logger.root].
  factory Logger(String name) {
    return _loggers.putIfAbsent(name, () => Logger._named(name));
  }

  Logger._named(this.name);

  /// The root logger — a singleton. Handlers attached here receive
  /// every record produced by any logger in the hierarchy.
  static final Logger root = Logger._named('');

  /// Cache of named loggers.
  static final Map<String, Logger> _loggers = {'': root};

  /// The hierarchical name of this logger (e.g. `'dio.request'`).
  final String name;

  /// Handlers registered on this logger.
  final List<LogHandler> _handlers = [];

  final StreamController<LogRecord> _controller =
      StreamController<LogRecord>.broadcast();

  /// A broadcast stream of [LogRecord]s produced by this logger.
  Stream<LogRecord> get onRecord => _controller.stream;

  LogLevel? _level;

  /// The minimum level for this logger. Records below this level are
  /// discarded before reaching any handler.
  ///
  /// A logger without its own level inherits its parent's, up to [root]
  /// (which defaults to [LogLevel.FINEST]). So `Logger.root.level =
  /// LogLevel.WARNING` quiets every logger that was not given its own level.
  /// Assign `null` to go back to inheriting.
  LogLevel get level => _level ?? _getParent()?.level ?? LogLevel.FINEST;

  set level(LogLevel? value) => _level = value;

  /// Whether a record at [level] would be created by this logger.
  ///
  /// Guard expensive messages with it:
  /// ```dart
  /// if (log.isLoggable(LogLevel.FINE)) log.fine(describe(payload));
  /// ```
  bool isLoggable(LogLevel level) => !(level < this.level);

  final List<LogRecordTransformer> _transformers = [];

  /// Adds a transformer applied to every record logged by this logger and
  /// its descendants, before any handler or [onRecord] listener sees it.
  ///
  /// For one record, transformers run from the logger that created it up to
  /// [root], each in the order added. The first `null` drops the record.
  void addTransformer(LogRecordTransformer transformer) =>
      _transformers.add(transformer);

  void removeTransformer(LogRecordTransformer transformer) =>
      _transformers.remove(transformer);

  /// Removes every handler, transformer and explicit level from all loggers
  /// created so far, and sets [root] back to [LogLevel.FINEST].
  ///
  /// Loggers are global, so tests that attach handlers should call this in
  /// `tearDown`. [onRecord] subscriptions are left to their owners.
  static void reset() {
    for (final logger in _loggers.values) {
      logger._handlers.clear();
      logger._transformers.clear();
      logger._level = null;
    }
  }

  // ── Handler management ────────────────────────────────

  void addHandler(LogHandler handler) => _handlers.add(handler);

  void removeHandler(LogHandler handler) => _handlers.remove(handler);

  void clearHandlers() => _handlers.clear();

  /// Returns an unmodifiable view of the currently registered handlers.
  List<LogHandler> get handlers => List.unmodifiable(_handlers);

  // ── Logging ───────────────────────────────────────────

  /// Creates a [LogRecord] and dispatches it to this logger's handlers
  /// and all ancestor handlers up to [root].
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    LogLayer? layer,
    LogType? type,
    String? feature,
    Map<String, dynamic>? extra,
  }) {
    if (!isLoggable(level)) return;

    LogRecord? record = LogRecord(
      level: level,
      message: message,
      loggerName: name,
      time: DateTime.now(),
      error: error,
      stackTrace: stackTrace,
      layer: layer,
      type: type,
      feature: feature,
      extra: extra,
    );

    for (Logger? logger = this; logger != null; logger = logger._getParent()) {
      for (final transform in logger._transformers) {
        record = transform(record!);
        if (record == null) return;
      }
    }

    _publish(record!);
  }

  void _publish(LogRecord record) {
    // Own handlers
    for (final handler in _handlers) {
      if (handler.filter.shouldLog(record)) {
        handler.handle(record);
      }
    }

    // Stream
    _controller.add(record);

    // Propagate to parent
    final parent = _getParent();
    if (parent != null) {
      parent._publish(record);
    }
  }

  /// Returns the parent logger based on name hierarchy.
  ///
  /// `'dio.request'` → parent `'dio'` → parent `''` (root).
  Logger? _getParent() {
    if (name.isEmpty) return null; // root has no parent

    final lastDot = name.lastIndexOf('.');
    final parentName = lastDot == -1 ? '' : name.substring(0, lastDot);
    return Logger(parentName);
  }

  // ── Convenience methods ───────────────────────────────

  void finest(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    LogLayer? layer,
    LogType? type,
    String? feature,
    Map<String, dynamic>? extra,
  }) => log(
    LogLevel.FINEST,
    message,
    error: error,
    stackTrace: stackTrace,
    layer: layer,
    type: type,
    feature: feature,
    extra: extra,
  );

  void finer(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    LogLayer? layer,
    LogType? type,
    String? feature,
    Map<String, dynamic>? extra,
  }) => log(
    LogLevel.FINER,
    message,
    error: error,
    stackTrace: stackTrace,
    layer: layer,
    type: type,
    feature: feature,
    extra: extra,
  );

  void fine(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    LogLayer? layer,
    LogType? type,
    String? feature,
    Map<String, dynamic>? extra,
  }) => log(
    LogLevel.FINE,
    message,
    error: error,
    stackTrace: stackTrace,
    layer: layer,
    type: type,
    feature: feature,
    extra: extra,
  );

  void config(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    LogLayer? layer,
    LogType? type,
    String? feature,
    Map<String, dynamic>? extra,
  }) => log(
    LogLevel.CONFIG,
    message,
    error: error,
    stackTrace: stackTrace,
    layer: layer,
    type: type,
    feature: feature,
    extra: extra,
  );

  void info(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    LogLayer? layer,
    LogType? type,
    String? feature,
    Map<String, dynamic>? extra,
  }) => log(
    LogLevel.INFO,
    message,
    error: error,
    stackTrace: stackTrace,
    layer: layer,
    type: type,
    feature: feature,
    extra: extra,
  );

  void warning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    LogLayer? layer,
    LogType? type,
    String? feature,
    Map<String, dynamic>? extra,
  }) => log(
    LogLevel.WARNING,
    message,
    error: error,
    stackTrace: stackTrace,
    layer: layer,
    type: type,
    feature: feature,
    extra: extra,
  );

  void severe(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    LogLayer? layer,
    LogType? type,
    String? feature,
    Map<String, dynamic>? extra,
  }) => log(
    LogLevel.SEVERE,
    message,
    error: error,
    stackTrace: stackTrace,
    layer: layer,
    type: type,
    feature: feature,
    extra: extra,
  );

  void shout(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    LogLayer? layer,
    LogType? type,
    String? feature,
    Map<String, dynamic>? extra,
  }) => log(
    LogLevel.SHOUT,
    message,
    error: error,
    stackTrace: stackTrace,
    layer: layer,
    type: type,
    feature: feature,
    extra: extra,
  );

  // ── Object overrides ──────────────────────────────────

  @override
  String toString() => 'Logger($name)';
}
