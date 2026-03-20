import 'package:comon_logger/comon_logger.dart';
import 'package:flutter/widgets.dart';

/// A [NavigatorObserver] that logs route changes via [Logger].
///
/// ```dart
/// MaterialApp(
///   navigatorObservers: [ComonNavigatorObserver()],
/// )
/// ```
///
/// All navigation events (push, pop, replace, remove) are logged at
/// [LogLevel.CONFIG] with [LogLayer.widgets] and [LogType.navigation].
class ComonNavigatorObserver extends NavigatorObserver {
  /// Creates a navigator observer that logs via [Logger] with [loggerName].
  ComonNavigatorObserver({String loggerName = 'comon.navigation'})
    : _logger = Logger(loggerName);

  final Logger _logger;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log('PUSH', route, previousRoute: previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log('POP', route, previousRoute: previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _log('REPLACE', newRoute, previousRoute: oldRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log('REMOVE', route, previousRoute: previousRoute);
  }

  void _log(
    String action,
    Route<dynamic>? route, {
    Route<dynamic>? previousRoute,
  }) {
    final routeName = route?.settings.name ?? 'unknown';
    final prevName = previousRoute?.settings.name;

    final message = prevName != null
        ? '$action: $routeName (from: $prevName)'
        : '$action: $routeName';

    final extra = <String, dynamic>{'action': action, 'route': routeName};
    if (prevName != null) {
      extra['previousRoute'] = prevName;
    }

    _logger.config(
      message,
      layer: LogLayer.widgets,
      type: LogType.navigation,
      extra: extra,
    );
  }
}
