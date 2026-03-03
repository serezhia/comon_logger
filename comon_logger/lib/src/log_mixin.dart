import 'log_layer.dart';
import 'log_level.dart';
import 'log_type.dart';
import 'logger.dart';

/// A mixin that adds logging capabilities to any class.
///
/// It allows setting default context like [logLayer], [logType], and [feature].
///
/// Example:
/// ```dart
/// class MyService with Log {
///   @override
///   LogLayer get logLayer => LogLayer.data;
///
///   @override
///   String get feature => 'Sync';
///
///   void sync() {
///     info('Start sync');
///   }
/// }
/// ```
mixin Log {
  /// The logger for this instance.
  ///
  /// By default, it uses the class name as the logger name.
  Logger get logger => Logger.root;

  /// Override this to provide a default [LogLayer] for all logs in this class.
  LogLayer? get logLayer => null;

  /// Override this to provide a default [LogType] for all logs in this class.
  LogType? get logType => null;

  /// Override this to provide a default feature tag for all logs in this class.
  String? get feature => null;

  /// Override this to provide default extra data for all logs in this class.
  Map<String, dynamic>? get logExtra => null;

  /// Logs a message at [level].
  void _log(
    LogLevel level,
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
    LogLayer? layer,
    LogType? type,
    String? feature,
    Map<String, dynamic>? extra,
  }) {
    final mergedExtra =
        logExtra == null && extra == null ? null : {...?logExtra, ...?extra};

    logger.log(
      level,
      message.toString(),
      error: error,
      stackTrace: stackTrace,
      layer: layer ?? logLayer,
      type: type ?? logType,
      feature: feature ?? this.feature,
      extra: mergedExtra,
    );
  }

  /// Logs a message at [LogLevel.FINEST].
  void finest(
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
    LogLayer? layer,
    LogType? type,
    String? feature,
    Map<String, dynamic>? extra,
  }) =>
      _log(
        LogLevel.FINEST,
        message,
        error: error,
        stackTrace: stackTrace,
        layer: layer,
        type: type,
        feature: feature,
        extra: extra,
      );

  /// Logs a message at [LogLevel.FINER].
  void finer(
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
    LogLayer? layer,
    LogType? type,
    String? feature,
    Map<String, dynamic>? extra,
  }) =>
      _log(
        LogLevel.FINER,
        message,
        error: error,
        stackTrace: stackTrace,
        layer: layer,
        type: type,
        feature: feature,
        extra: extra,
      );

  /// Logs a message at [LogLevel.FINE].
  void fine(
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
    LogLayer? layer,
    LogType? type,
    String? feature,
    Map<String, dynamic>? extra,
  }) =>
      _log(
        LogLevel.FINE,
        message,
        error: error,
        stackTrace: stackTrace,
        layer: layer,
        type: type,
        feature: feature,
        extra: extra,
      );

  /// Logs a message at [LogLevel.CONFIG].
  void config(
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
    LogLayer? layer,
    LogType? type,
    String? feature,
    Map<String, dynamic>? extra,
  }) =>
      _log(
        LogLevel.CONFIG,
        message,
        error: error,
        stackTrace: stackTrace,
        layer: layer,
        type: type,
        feature: feature,
        extra: extra,
      );

  /// Logs a message at [LogLevel.INFO].
  void info(
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
    LogLayer? layer,
    LogType? type,
    String? feature,
    Map<String, dynamic>? extra,
  }) =>
      _log(
        LogLevel.INFO,
        message,
        error: error,
        stackTrace: stackTrace,
        layer: layer,
        type: type,
        feature: feature,
        extra: extra,
      );

  /// Logs a message at [LogLevel.WARNING].
  void warning(
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
    LogLayer? layer,
    LogType? type,
    String? feature,
    Map<String, dynamic>? extra,
  }) =>
      _log(
        LogLevel.WARNING,
        message,
        error: error,
        stackTrace: stackTrace,
        layer: layer,
        type: type,
        feature: feature,
        extra: extra,
      );

  /// Logs a message at [LogLevel.SEVERE].
  void severe(
    Object? message,
    Object? error,
    StackTrace? stackTrace, {
    LogLayer? layer,
    LogType? type,
    String? feature,
    Map<String, dynamic>? extra,
  }) =>
      _log(
        LogLevel.SEVERE,
        message,
        error: error,
        stackTrace: stackTrace,
        layer: layer,
        type: type,
        feature: feature,
        extra: extra,
      );

  /// Logs a message at [LogLevel.SHOUT].
  void shout(
    Object? message,
    Object? error,
    StackTrace? stackTrace, {
    LogLayer? layer,
    LogType? type,
    String? feature,
    Map<String, dynamic>? extra,
  }) =>
      _log(
        LogLevel.SHOUT,
        message,
        error: error,
        stackTrace: stackTrace,
        layer: layer,
        type: type,
        feature: feature,
        extra: extra,
      );
}
