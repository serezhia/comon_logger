import 'dart:convert';

import 'package:comon_logger/comon_logger.dart';
import 'package:flutter/material.dart';
import '../l10n/comon_logger_strings.dart';
import 'package:flutter/services.dart';

import '../handlers/history_log_handler.dart';
import 'log_screen_action.dart';

/// Built-in [LogScreenAction] that imports log records from JSON.
///
/// Shows a dialog where the user can paste JSON exported by
/// [HistoryLogHandler.exportJson] and appends the parsed records
/// to the current session.
///
/// ```dart
/// ComonLoggerScreen(
///   handler: historyHandler,
///   actions: [
///     ImportLogsAction(),
///   ],
/// )
/// ```
class ImportLogsAction extends LogScreenAction {
  const ImportLogsAction();

  @override
  Widget build(BuildContext context, HistoryLogHandler handler) {
    return IconButton(
      icon: const Icon(Icons.file_open_outlined),
      tooltip: ComonLoggerStrings.of(context).importTooltip,
      onPressed: () => _importLogs(context, handler),
    );
  }

  Future<void> _importLogs(
    BuildContext context,
    HistoryLogHandler handler,
  ) async {
    // The dialog is a separate route, outside the screen's strings scope.
    final strings = ComonLoggerStrings.of(context);
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.importTitle),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(strings.importHint, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.content_paste, size: 16),
                    label: Text(strings.pasteFromClipboard),
                    onPressed: () async {
                      final data = await Clipboard.getData('text/plain');
                      if (data?.text != null) {
                        controller.text = data!.text!;
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  decoration: const InputDecoration(
                    hintText: '[{"level":"INFO",...}, ...]',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(strings.import),
          ),
        ],
      ),
    );

    if (result == null || result.trim().isEmpty) return;

    try {
      final decoded = jsonDecode(result.trim());
      final List<dynamic> entries;
      if (decoded is List) {
        entries = decoded;
      } else if (decoded is Map && decoded['logs'] is List) {
        entries = decoded['logs'] as List;
      } else {
        throw const FormatException('Expected a JSON array or {"logs": [...]}');
      }

      var count = 0;
      for (final entry in entries) {
        if (entry is Map<String, dynamic>) {
          final record = LogRecord.fromJson(entry);
          handler.handle(record);
          count++;
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.imported(count))));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.importFailed(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
