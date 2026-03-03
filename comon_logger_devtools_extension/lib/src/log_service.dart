import 'dart:async';
import 'dart:convert';

import 'package:comon_logger/comon_logger.dart';
import 'package:devtools_app_shared/service.dart';
import 'package:vm_service/vm_service.dart' hide LogRecord;

/// Connects to a running Flutter app via VM service to receive log records.
///
/// Uses the service extension `ext.comon_logger.getHistory` to load existing
/// logs and listens for live `comon_logger:log` events via `developer.postEvent`.
class DevToolsLogService {
  final StreamController<LogRecord> _controller =
      StreamController<LogRecord>.broadcast();
  final List<LogRecord> _history = [];
  StreamSubscription<Event>? _eventSubscription;
  bool _paused = false;

  /// A broadcast stream of [LogRecord]s received from the connected app.
  Stream<LogRecord> get onRecord => _controller.stream;

  /// All received records (including imported ones).
  List<LogRecord> get history => List.unmodifiable(_history);

  /// Whether live streaming is paused.
  bool get isPaused => _paused;

  /// Connects to the running app and starts receiving log records.
  ///
  /// 1. Calls `ext.comon_logger.getHistory` to load existing records.
  /// 2. Listens on the Extension event stream for live `comon_logger:log` events.
  Future<void> connect(ServiceManager serviceManager) async {
    final service = serviceManager.service;
    if (service == null) return;

    // Load existing history
    await _loadHistory(service, serviceManager);

    // Listen for live events
    _eventSubscription = service.onExtensionEvent.listen(_handleEvent);
  }

  Future<void> _loadHistory(
    VmService service,
    ServiceManager serviceManager,
  ) async {
    try {
      final response = await serviceManager.callServiceExtensionOnMainIsolate(
        'ext.comon_logger.getHistory',
      );
      final data = response.json;
      if (data != null && data['logs'] is List) {
        final logs = data['logs'] as List;
        for (final entry in logs) {
          if (entry is Map<String, dynamic>) {
            final record = LogRecord.fromJson(entry);
            _history.add(record);
            _controller.add(record);
          }
        }
      }
    } catch (_) {
      // Service extension may not be registered yet — that's fine.
    }
  }

  void _handleEvent(Event event) {
    if (_paused) return;
    if (event.extensionKind != 'comon_logger:log') return;

    final data = event.extensionData?.data;
    if (data == null) return;

    try {
      final record = LogRecord.fromJson(data);
      _history.add(record);
      _controller.add(record);
    } catch (_) {
      // Invalid data — skip.
    }
  }

  /// Pauses live log streaming (records are discarded while paused).
  void pause() => _paused = true;

  /// Resumes live log streaming.
  void resume() => _paused = false;

  /// Clears all local history. Optionally clears remote history too.
  Future<void> clear({ServiceManager? serviceManager}) async {
    _history.clear();

    if (serviceManager != null) {
      try {
        await serviceManager.callServiceExtensionOnMainIsolate(
          'ext.comon_logger.clearHistory',
        );
      } catch (_) {
        // Ignore if not available.
      }
    }
  }

  /// Imports records from a JSON string (content of a `.json` log file).
  ///
  /// Expects the format: `{"logs": [<LogRecord.toJson()>, ...]}` or a
  /// plain JSON array `[<LogRecord.toJson()>, ...]`.
  List<LogRecord> importFromJson(String jsonContent) {
    final decoded = jsonDecode(jsonContent);
    final List<dynamic> entries;

    if (decoded is List) {
      entries = decoded;
    } else if (decoded is Map && decoded['logs'] is List) {
      entries = decoded['logs'] as List;
    } else {
      return [];
    }

    final imported = <LogRecord>[];
    for (final entry in entries) {
      if (entry is Map<String, dynamic>) {
        final record = LogRecord.fromJson(entry);
        imported.add(record);
        _history.add(record);
        _controller.add(record);
      }
    }
    return imported;
  }

  /// Releases resources.
  void dispose() {
    _eventSubscription?.cancel();
    _controller.close();
  }
}
