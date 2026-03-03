import 'dart:convert';
import 'dart:io';

import 'package:comon_logger/comon_logger.dart';

/// A [LogHandler] that writes log records to files with automatic rotation.
///
/// ```dart
/// final fileHandler = FileLogHandler(directory: '/path/to/logs');
/// await fileHandler.init();
/// Logger.root.addHandler(fileHandler);
/// ```
///
/// ## Rotation logic
///
/// When the current log file exceeds [maxFileSize], it is rotated:
/// 1. Current file `comon_log.txt` → `comon_log_1.txt`
/// 2. Existing `comon_log_1.txt` → `comon_log_2.txt`, etc.
/// 3. Files beyond [maxFiles] are deleted.
class FileLogHandler extends LogHandler {
  /// Creates a file log handler.
  ///
  /// Call [init] before logging to open the file for writing.
  FileLogHandler({
    required this.directory,
    this.baseFileName = 'comon_log',
    this.extension = '.txt',
    this.maxFileSize = 5 * 1024 * 1024, // 5 MB
    this.maxFiles = 5,
    super.filter = const AllPassLogFilter(),
    LogFormatter? formatter,
    this.writeAsJson = false,
  }) : _formatter = formatter ?? const SimpleLogFormatter();

  /// The directory where log files are stored.
  final String directory;

  /// Base file name (without extension).
  final String baseFileName;

  /// File extension (including the dot).
  final String extension;

  /// Maximum file size in bytes before rotation.
  final int maxFileSize;

  /// Maximum number of rotated files to keep (including the current one).
  final int maxFiles;

  /// The formatter used to convert records to text.
  final LogFormatter _formatter;

  /// When `true`, records are written as JSON (one object per line).
  final bool writeAsJson;

  RandomAccessFile? _raf;
  File? _currentFile;
  int _currentSize = 0;
  bool _initialized = false;

  /// Whether [init] has been called.
  bool get isInitialized => _initialized;

  /// Initializes the handler — creates the directory and opens the log file.
  Future<void> init() async {
    final dir = Directory(directory);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }

    _currentFile = File(_currentFilePath);
    if (_currentFile!.existsSync()) {
      _currentSize = _currentFile!.lengthSync();
    } else {
      _currentSize = 0;
    }

    _raf = _currentFile!.openSync(mode: FileMode.append);
    _initialized = true;
  }

  String get _currentFilePath => '$directory/$baseFileName$extension';

  String _rotatedFilePath(int index) =>
      '$directory/${baseFileName}_$index$extension';

  @override
  void handle(LogRecord record) {
    if (!_initialized || _raf == null) return;

    final line =
        writeAsJson ? jsonEncode(record.toJson()) : _formatter.format(record);

    _writeLine(line);
  }

  void _writeLine(String line) {
    final bytes = utf8.encode('$line\n');
    _raf!.writeFromSync(bytes);
    _currentSize += bytes.length;

    if (_currentSize >= maxFileSize) {
      _rotateSync();
    }
  }

  /// Rotates log files synchronously.
  void _rotateSync() {
    // Close current file handle so it can be renamed
    _raf?.flushSync();
    _raf?.closeSync();
    _raf = null;

    // Shift existing rotated files
    for (var i = maxFiles - 1; i >= 1; i--) {
      final file = File(_rotatedFilePath(i));
      if (file.existsSync()) {
        if (i + 1 >= maxFiles) {
          file.deleteSync();
        } else {
          file.renameSync(_rotatedFilePath(i + 1));
        }
      }
    }

    // Move current file to _1
    if (_currentFile != null && _currentFile!.existsSync()) {
      _currentFile!.renameSync(_rotatedFilePath(1));
    }

    // Open a new current file
    _currentFile = File(_currentFilePath);
    _raf = _currentFile!.openSync(mode: FileMode.append);
    _currentSize = 0;
  }

  /// Flushes the write buffer to disk.
  void flush() => _raf?.flushSync();

  /// Closes the file. Call when the handler is no longer needed.
  Future<void> close() async {
    _raf?.flushSync();
    _raf?.closeSync();
    _raf = null;
    _initialized = false;
  }

  /// Returns all log files in the directory matching [baseFileName].
  List<File> getLogFiles() {
    final dir = Directory(directory);
    if (!dir.existsSync()) return [];

    final prefix = baseFileName;
    return dir.listSync().whereType<File>().where((f) {
      final name = f.uri.pathSegments.last;
      return name.startsWith(prefix) && name.endsWith(extension);
    }).toList()
      ..sort((a, b) => a.path.compareTo(b.path));
  }
}
