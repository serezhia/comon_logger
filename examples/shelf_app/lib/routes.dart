import 'dart:convert';

import 'package:comon_logger/comon_logger.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

final _log = Logger('shelf.api');

// ── Mock data ───────────────────────────────────────────

final _users = <Map<String, dynamic>>[
  {'id': 1, 'name': 'Alice', 'email': 'alice@example.com'},
  {'id': 2, 'name': 'Bob', 'email': 'bob@example.com'},
  {'id': 3, 'name': 'Charlie', 'email': 'charlie@example.com'},
];

int _nextId = 4;

// ── Router ──────────────────────────────────────────────

Router createRouter() {
  final router = Router();

  // GET /
  router.get('/', (Request request) {
    _log.info('Root endpoint hit', layer: LogLayer.app, type: LogType.general);
    return Response.ok(
      jsonEncode({'message': 'Welcome to the comon_logger Shelf example!'}),
      headers: {'Content-Type': 'application/json'},
    );
  });

  // GET /health
  router.get('/health', (Request request) {
    _log.fine('Health check', layer: LogLayer.infra, type: LogType.lifecycle);
    return Response.ok(
      jsonEncode({'status': 'ok', 'uptime': DateTime.now().toIso8601String()}),
      headers: {'Content-Type': 'application/json'},
    );
  });

  // GET /users
  router.get('/users', (Request request) {
    _log.info(
      'Listing all users (${_users.length})',
      layer: LogLayer.data,
      type: LogType.database,
    );
    return Response.ok(
      jsonEncode(_users),
      headers: {'Content-Type': 'application/json'},
    );
  });

  // GET /users/<id>
  router.get('/users/<id>', (Request request, String id) {
    final userId = int.tryParse(id);
    if (userId == null) {
      _log.warning(
        'Invalid user id: $id',
        layer: LogLayer.data,
        type: LogType.general,
      );
      return Response(
        400,
        body: jsonEncode({'error': 'Invalid user id'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final user = _users.cast<Map<String, dynamic>?>().firstWhere(
      (u) => u!['id'] == userId,
      orElse: () => null,
    );

    if (user == null) {
      _log.warning(
        'User $userId not found',
        layer: LogLayer.data,
        type: LogType.database,
        feature: 'users',
      );
      return Response.notFound(
        jsonEncode({'error': 'User not found'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    _log.fine(
      'Found user $userId',
      layer: LogLayer.data,
      type: LogType.database,
      feature: 'users',
    );
    return Response.ok(
      jsonEncode(user),
      headers: {'Content-Type': 'application/json'},
    );
  });

  // POST /users
  router.post('/users', (Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final user = {
        'id': _nextId++,
        'name': data['name'] ?? 'Unknown',
        'email': data['email'] ?? '',
      };

      _users.add(user);

      _log.info(
        'Created user ${user['id']}: ${user['name']}',
        layer: LogLayer.data,
        type: LogType.database,
        feature: 'users',
        extra: {'user': user},
      );

      return Response(
        201,
        body: jsonEncode(user),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, st) {
      _log.severe(
        'Failed to create user',
        error: e,
        stackTrace: st,
        layer: LogLayer.data,
        type: LogType.database,
        feature: 'users',
      );
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to create user'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });

  // GET /error — deliberate error for demo
  router.get('/error', (Request request) {
    _log.warning(
      'About to trigger a deliberate error',
      layer: LogLayer.app,
      type: LogType.general,
    );

    try {
      throw StateError('This is a deliberate error for demonstration');
    } catch (e, st) {
      _log.severe(
        'Deliberate error triggered',
        error: e,
        stackTrace: st,
        layer: LogLayer.app,
        type: LogType.general,
        extra: {'endpoint': '/error', 'deliberate': true},
      );
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });

  return router;
}
