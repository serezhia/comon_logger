import 'dart:io';

import 'package:comon_logger/comon_logger.dart';
import 'package:comon_logger_dio/comon_logger_dio.dart';
import 'package:comon_logger_dio_flutter/comon_logger_dio_flutter.dart';
import 'package:comon_logger_file/comon_logger_file.dart';
import 'package:comon_logger_flutter/comon_logger_flutter.dart';
import 'package:comon_logger_navigation_flutter/comon_logger_navigation_flutter.dart';
import 'package:comon_logger_share_flutter/comon_logger_share_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// ── Global instances ────────────────────────────────────

/// In-memory history handler — feeds the log viewer screen.
final historyHandler = HistoryLogHandler(maxHistory: 1000);

/// File handler — writes logs to disk (non-web only).
FileLogHandler? fileHandler;

/// Dio instance with comon_logger interceptor.
final dio = Dio()
  ..interceptors.add(
    ComonDioInterceptor(
      logRequestHeaders: true,
      logResponseHeaders: true,
      logRequestBody: true,
      logResponseBody: true,
      maxResponseBodyLength: 500,
    ),
  );

// ── Bootstrap ───────────────────────────────────────────

Future<void> _initLogging() async {
  // 1) Console handler with pretty formatting
  Logger.root.addHandler(ConsoleLogHandler(formatter: PrettyLogFormatter()));

  // 2) History handler for in-app log viewer
  Logger.root.addHandler(historyHandler);

  // 3) File handler (skip on web — no dart:io file system)
  if (!kIsWeb) {
    final dir = '${Directory.systemTemp.path}/comon_logger_flutter_example';
    fileHandler = FileLogHandler(
      directory: dir,
      maxFileSize: 1 * 1024 * 1024, // 1 MB
      maxFiles: 3,
    );
    await fileHandler!.init();
    Logger.root.addHandler(fileHandler!);
  }

  // 4) DevTools service extension (live streaming to DevTools)
  ComonLoggerServiceExtension(historyHandler).register();
}

// ── App ─────────────────────────────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initLogging();

  Logger('app').info('Application started 🚀', layer: LogLayer.app);

  runApp(const FlutterAppExample());
}

class FlutterAppExample extends StatelessWidget {
  const FlutterAppExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'comon_logger Flutter Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      navigatorObservers: [ComonNavigatorObserver()],
      initialRoute: '/',
      routes: {
        '/': (_) => const HomePage(),
        '/logs': (_) => ComonLoggerScreen(
          handler: historyHandler,
          renderers: const [
            NavigationLogRecordRenderer(),
            HttpLogRecordRenderer(),
          ],
          actions: const [ShareLogsAction(), ImportLogsAction()],
        ),
        '/details': (_) => const DetailsPage(),
      },
    );
  }
}

// ── Pages ───────────────────────────────────────────────

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('comon_logger Flutter Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'View logs',
            onPressed: () => Navigator.pushNamed(context, '/logs'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Manual logging ──
          const _SectionHeader('Manual logging'),
          _ActionTile(
            icon: Icons.bug_report,
            title: 'Log at every level',
            subtitle: 'FINEST → SHOUT with layers & types',
            onTap: _logAllLevels,
          ),
          _ActionTile(
            icon: Icons.error_outline,
            title: 'Log an error',
            subtitle: 'SEVERE with error object and stack trace',
            onTap: _logError,
          ),

          const Divider(height: 32),

          // ── Dio (network) ──
          const _SectionHeader('Dio (network)'),
          _ActionTile(
            icon: Icons.cloud_download,
            title: 'GET request (success)',
            subtitle: 'httpbin.org/get',
            onTap: () => _doGet(context),
          ),
          _ActionTile(
            icon: Icons.cloud_upload,
            title: 'POST request',
            subtitle: 'httpbin.org/post',
            onTap: () => _doPost(context),
          ),
          _ActionTile(
            icon: Icons.cloud_off,
            title: 'GET request (404)',
            subtitle: 'httpbin.org/status/404',
            onTap: () => _doError(context),
          ),

          const Divider(height: 32),

          // ── Navigation ──
          const _SectionHeader('Navigation'),
          _ActionTile(
            icon: Icons.navigation,
            title: 'Push /details page',
            subtitle: 'NavigatorObserver logs push & pop',
            onTap: () => Navigator.pushNamed(context, '/details'),
          ),

          const Divider(height: 32),

          // ── Tools ──
          const _SectionHeader('Tools'),
          _ActionTile(
            icon: Icons.list_alt,
            title: 'Open log viewer',
            subtitle: 'ComonLoggerScreen with filters & search',
            onTap: () => Navigator.pushNamed(context, '/logs'),
          ),
          _ActionTile(
            icon: Icons.delete_sweep,
            title: 'Clear all logs',
            subtitle: 'Clears history handler',
            onTap: () {
              historyHandler.clear();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Logs cleared')));
            },
          ),
        ],
      ),
    );
  }
}

class DetailsPage extends StatelessWidget {
  const DetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    Logger(
      'app.details',
    ).fine('DetailsPage built', layer: LogLayer.widgets, type: LogType.ui);

    return Scaffold(
      appBar: AppBar(title: const Text('Details')),
      body: const Center(
        child: Text(
          'This is a detail page.\n'
          'The push & pop are logged by ComonNavigatorObserver.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ── Helpers ─────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

// ── Actions ─────────────────────────────────────────────

void _logAllLevels() {
  final log = Logger('example.manual');

  log.finest('This is FINEST', layer: LogLayer.app, type: LogType.general);
  log.finer('This is FINER', layer: LogLayer.domain, type: LogType.logic);
  log.fine('This is FINE', layer: LogLayer.data, type: LogType.database);
  log.config('This is CONFIG', layer: LogLayer.infra, type: LogType.lifecycle);
  log.info('This is INFO', layer: LogLayer.widgets, type: LogType.ui);
  log.warning('This is WARNING', feature: 'auth');
  log.severe('This is SEVERE', type: LogType.security);
  log.shout('This is SHOUT 🔥');
}

void _logError() {
  final log = Logger('example.errors');

  try {
    throw FormatException('Invalid JSON input', '{"broken: true}', 9);
  } catch (e, st) {
    log.severe(
      'Failed to parse config',
      error: e,
      stackTrace: st,
      layer: LogLayer.data,
      type: LogType.general,
      feature: 'config',
      extra: {'input': '{"broken: true}'},
    );
  }
}

Future<void> _doGet(BuildContext context) async {
  try {
    await dio.get('https://httpbin.org/get');
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('GET succeeded ✓')));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('GET failed: $e')));
    }
  }
}

Future<void> _doPost(BuildContext context) async {
  try {
    await dio.post(
      'https://httpbin.org/post',
      data: {'message': 'Hello from comon_logger!', 'timestamp': 1234567890},
    );
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('POST succeeded ✓')));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('POST failed: $e')));
    }
  }
}

Future<void> _doError(BuildContext context) async {
  try {
    await dio.get('https://httpbin.org/status/404');
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('404 error caught (logged by interceptor)'),
        ),
      );
    }
  }
}
