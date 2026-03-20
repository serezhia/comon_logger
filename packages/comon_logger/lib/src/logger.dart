import 'dart:async';

import 'log_handler.dart';
import 'log_layer.dart';
import 'log_level.dart';
import 'log_record.dart';
import 'log_type.dart';

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

  /// The minimum level for this logger. Records below this level are
  /// discarded before reaching any handler.
  LogLevel level = LogLevel.FINEST;

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
    if (level < this.level) return;

    final record = LogRecord(
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

    _publish(record);
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
  }) =>
      log(LogLevel.FINEST, message,
          error: error,
          stackTrace: stackTrace,
          layer: layer,
          type: type,
          feature: feature,
          extra: extra);

  void finer(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    LogLayer? layer,
    LogType? type,
    String? feature,
    Map<String, dynamic>? extra,
  }) =>
      log(LogLevel.FINER, message,
          error: error,
          stackTrace: stackTrace,
          layer: layer,
          type: type,
          feature: feature,
          extra: extra);

  void fine(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    LogLayer? layer,
    LogType? type,
    String? feature,
    Map<String, dynamic>? extra,
  }) =>
      log(LogLevel.FINE, message,
          error: error,
          stackTrace: stackTrace,
          layer: layer,
          type: type,
          feature: feature,
          extra: extra);

  void config(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    LogLayer? layer,
    LogType? type,
    String? feature,
    Map<String, dynamic>? extra,
  }) =>
      log(LogLevel.CONFIG, message,
          error: error,
          stackTrace: stackTrace,
          layer: layer,
          type: type,
          feature: feature,
          extra: extra);

  void info(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    LogLayer? layer,
    LogType? type,
    String? feature,
    Map<String, dynamic>? extra,
  }) =>
      log(LogLevel.INFO, message,
          error: error,
          stackTrace: stackTrace,
          layer: layer,
          type: type,
          feature: feature,
          extra: extra);

  void warning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    LogLayer? layer,
    LogType? type,
    String? feature,
    Map<String, dynamic>? extra,
  }) =>
      log(LogLevel.WARNING, message,
          error: error,
          stackTrace: stackTrace,
          layer: layer,
          type: type,
          feature: feature,
          extra: extra);

  void severe(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    LogLayer? layer,
    LogType? type,
    String? feature,
    Map<String, dynamic>? extra,
  }) =>
      log(LogLevel.SEVERE, message,
          error: error,
          stackTrace: stackTrace,
          layer: layer,
          type: type,
          feature: feature,
          extra: extra);

  void shout(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    LogLayer? layer,
    LogType? type,
    String? feature,
    Map<String, dynamic>? extra,
  }) =>
      log(LogLevel.SHOUT, message,
          error: error,
          stackTrace: stackTrace,
          layer: layer,
          type: type,
          feature: feature,
          extra: extra);

  // ── Object overrides ──────────────────────────────────

  @override
  String toString() => 'Logger($name)';
}
