/// Identifies the type of action or context a log relates to.
///
/// Predefined types cover common categories. Create custom types with
/// `const LogType('myType')` and register them via [LogType.register]
/// so they appear in UI filter chips.
class LogType {
  const LogType(this.name);

  /// The name of this type.
  final String name;

  // ── Predefined types ───────────────────────────────────

  /// HTTP requests/responses, WebSocket, gRPC.
  static const network = LogType('network');

  /// Local DB, shared preferences, secure storage.
  static const database = LogType('database');

  /// Route push/pop/replace.
  static const navigation = LogType('navigation');

  /// State management events (Bloc/Cubit state changes).
  static const logic = LogType('logic');

  /// UI events, gestures, rendering.
  static const ui = LogType('ui');

  /// App lifecycle (init, dispose, pause, resume).
  static const lifecycle = LogType('lifecycle');

  /// Analytics events.
  static const analytics = LogType('analytics');

  /// Performance metrics, timing.
  static const performance = LogType('performance');

  /// Auth, tokens, permissions.
  static const security = LogType('security');

  /// General-purpose / uncategorized.
  static const general = LogType('general');

  // ── Registry ───────────────────────────────────────────

  /// All known types (predefined + registered custom ones).
  /// Custom types can be added via [register].
  static final List<LogType> _values = [
    network,
    database,
    navigation,
    logic,
    ui,
    lifecycle,
    analytics,
    performance,
    security,
    general,
  ];

  /// Returns an unmodifiable view of all registered types.
  static List<LogType> get values => List.unmodifiable(_values);

  /// Register a custom type so it appears in UI filters.
  static void register(LogType type) {
    if (!_values.any((t) => t.name == type.name)) {
      _values.add(type);
    }
  }

  /// Find a type by [name], or return `null`.
  static LogType? tryParse(String name) {
    for (final t in _values) {
      if (t.name == name) return t;
    }
    return null;
  }

  // ── Object overrides ──────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LogType && name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => name;
}
