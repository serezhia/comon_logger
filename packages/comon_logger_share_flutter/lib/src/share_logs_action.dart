import 'dart:convert';
import 'dart:typed_data';

import 'package:comon_logger_flutter/comon_logger_flutter.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// A [LogScreenAction] that adds a share button to the log viewer toolbar.
///
/// Opens a bottom sheet with two options:
/// - **Share as text** — human-readable, formatted output
/// - **Share as JSON** — machine-readable, importable via [ImportLogsAction]
///
/// ```dart
/// ComonLoggerScreen(
///   handler: historyHandler,
///   actions: [
///     ShareLogsAction(),
///   ],
/// )
/// ```
class ShareLogsAction extends LogScreenAction {
  const ShareLogsAction();

  @override
  Widget build(BuildContext context, HistoryLogHandler handler) {
    return IconButton(
      icon: const Icon(Icons.share),
      tooltip: 'Share logs',
      onPressed: () => _shareLogs(context, handler),
    );
  }

  void _shareLogs(BuildContext context, HistoryLogHandler handler) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.text_snippet),
              title: const Text('Share as text'),
              subtitle: const Text('Human-readable, formatted output'),
              onTap: () {
                Navigator.pop(ctx);
                SharePlus.instance.share(ShareParams(
                  text: handler.export(),
                  subject: 'Logs from comon_logger',
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.data_object),
              title: const Text('Share as JSON'),
              subtitle: const Text('For import in log viewer / DevTools'),
              onTap: () async {
                Navigator.pop(ctx);
                final jsonString = handler.exportJson();
                final bytes = utf8.encode(jsonString);
                final name =
                    'logs_${DateTime.now().toIso8601String().replaceAll(':', '-')}.json';
                final file = XFile.fromData(
                  Uint8List.fromList(bytes),
                  mimeType: 'application/json',
                  name: name,
                );
                await SharePlus.instance.share(
                  ShareParams(
                    files: [file],
                    text: 'Logs provided by comon_logger',
                    subject: 'Log Export',
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
