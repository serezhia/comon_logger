import 'dart:convert';
import 'dart:developer' as developer;

import '../handlers/history_log_handler.dart';

/// Registers service extensions for DevTools communication.
///
/// Enables live log streaming to DevTools via `postEvent` and provides
/// service extensions for querying/clearing log history.
class ComonLoggerServiceExtension {
  ComonLoggerServiceExtension(this._historyHandler);

  final HistoryLogHandler _historyHandler;
  bool _registered = false;

  /// Register the service extensions. Safe to call multiple times.
  void register() {
    if (_registered) return;
    _registered = true;

    // Stream each new log as a postEvent
    _historyHandler.onRecord.listen((record) {
      developer.postEvent('comon_logger:log', record.toJson());
    });

    // Service extension: get current history
    developer.registerExtension('ext.comon_logger.getHistory', (
      method,
      params,
    ) async {
      final records = _historyHandler.history.map((r) => r.toJson()).toList();
      return developer.ServiceExtensionResponse.result(
        jsonEncode({'logs': records}),
      );
    });

    // Service extension: clear history
    developer.registerExtension('ext.comon_logger.clearHistory', (
      method,
      params,
    ) async {
      _historyHandler.clear();
      return developer.ServiceExtensionResponse.result(
        jsonEncode({'success': true}),
      );
    });
  }
}
