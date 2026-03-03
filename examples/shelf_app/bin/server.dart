import 'dart:io';

import 'package:comon_logger/comon_logger.dart';
import 'package:comon_logger_file/comon_logger_file.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'package:shelf_app_example/middleware/logging_middleware.dart';
import 'package:shelf_app_example/routes.dart';

Future<void> main() async {
  // ── Logging setup ───────────────────────────────────────

  // 1) Console handler with pretty formatting
  Logger.root.addHandler(ConsoleLogHandler(formatter: PrettyLogFormatter()));

  // 2) File handler with rotation
  final logDir = '${Directory.systemTemp.path}/comon_logger_shelf_example';
  final fileHandler = FileLogHandler(
    directory: logDir,
    baseFileName: 'shelf_server',
    maxFileSize: 2 * 1024 * 1024, // 2 MB
    maxFiles: 5,
  );
  await fileHandler.init();
  Logger.root.addHandler(fileHandler);

  final log = Logger('shelf.server');

  log.info(
    'File logs → $logDir',
    layer: LogLayer.infra,
    type: LogType.lifecycle,
  );

  // ── Pipeline ────────────────────────────────────────────

  final router = createRouter();

  final handler = const Pipeline()
      .addMiddleware(loggingMiddleware())
      .addHandler(router.call);

  // ── Start server ────────────────────────────────────────

  const port = 8080;
  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  server.autoCompress = true;

  log.info(
    'Server listening on http://localhost:${server.port} 🚀',
    layer: LogLayer.infra,
    type: LogType.lifecycle,
  );

  // ── Graceful shutdown ───────────────────────────────────

  ProcessSignal.sigint.watch().listen((_) async {
    log.info(
      'Shutting down...',
      layer: LogLayer.infra,
      type: LogType.lifecycle,
    );
    await server.close(force: true);
    fileHandler.flush();
    await fileHandler.close();
    log.info('Server stopped.', layer: LogLayer.infra, type: LogType.lifecycle);
    exit(0);
  });
}
