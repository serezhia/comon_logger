import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:comon_logger_flutter/comon_logger_flutter.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// Interface text of [ShareLogsAction], with English defaults.
///
/// The shared payload itself (subject, file names) stays English: it is data
/// for whoever receives the logs.
@immutable
class ShareLogsStrings {
  const ShareLogsStrings({
    this.tooltip = 'Share logs',
    this.asText = 'Share as text',
    this.asTextHint = 'Human-readable, formatted output',
    this.asJson = 'Share as JSON',
    this.asJsonHint = 'For import in log viewer / DevTools',
    this.files = 'Share log files',
    this.filesHint = 'Files saved on this device, including earlier sessions',
    this.noFiles = 'No log files yet',
  });

  final String tooltip;
  final String asText;
  final String asTextHint;
  final String asJson;
  final String asJsonHint;
  final String files;
  final String filesHint;
  final String noFiles;
}

/// A [LogScreenAction] that adds a share button to the log viewer toolbar.
///
/// Opens a bottom sheet with these options:
/// - **Share as text** — human-readable, formatted output of the in-memory
///   history
/// - **Share as JSON** — machine-readable, importable via [ImportLogsAction]
/// - **Share log files** — only when [logFiles] is set: the files on disk,
///   which also cover sessions before the current one (for example the one
///   that crashed)
///
/// ```dart
/// ComonLoggerScreen(
///   handler: historyHandler,
///   actions: [
///     ShareLogsAction(
///       logFiles: () async {
///         fileHandler.flush();
///         return [for (final f in fileHandler.getLogFiles()) f.path];
///       },
///     ),
///   ],
/// )
/// ```
class ShareLogsAction extends LogScreenAction {
  const ShareLogsAction({
    this.logFiles,
    this.strings = const ShareLogsStrings(),
  });

  /// Returns the paths of the log files to share. Missing files are skipped.
  ///
  /// Flush the file handler here so the latest lines are included.
  final Future<List<String>> Function()? logFiles;

  /// Interface text of the button and the bottom sheet.
  final ShareLogsStrings strings;

  @override
  Widget build(BuildContext context, HistoryLogHandler handler) {
    return IconButton(
      icon: const Icon(Icons.share),
      tooltip: strings.tooltip,
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
              title: Text(strings.asText),
              subtitle: Text(strings.asTextHint),
              onTap: () {
                Navigator.pop(ctx);
                SharePlus.instance.share(
                  ShareParams(
                    text: handler.export(),
                    subject: 'Logs from comon_logger',
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.data_object),
              title: Text(strings.asJson),
              subtitle: Text(strings.asJsonHint),
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
            if (logFiles case final logFiles?)
              ListTile(
                leading: const Icon(Icons.folder_zip_outlined),
                title: Text(strings.files),
                subtitle: Text(strings.filesHint),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _shareFiles(context, logFiles);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareFiles(
    BuildContext context,
    Future<List<String>> Function() logFiles,
  ) async {
    final paths = [
      for (final path in await logFiles())
        if (File(path).existsSync()) path,
    ];
    if (paths.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.noFiles)));
      }
      return;
    }
    await SharePlus.instance.share(
      ShareParams(
        files: [for (final path in paths) XFile(path, mimeType: 'text/plain')],
        subject: 'Log files from comon_logger',
      ),
    );
  }
}
