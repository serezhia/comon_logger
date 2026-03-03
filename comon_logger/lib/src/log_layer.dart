/// Identifies the architectural layer a log originates from.
///
/// Predefined layers cover common app architecture patterns.
/// Create custom layers with `const LogLayer('myLayer')` and register
/// them via [LogLayer.register] so they appear in UI filter chips.
class LogLayer {
  const LogLayer(this.name);

  /// The name of this layer.
  final String name;

  // ── Predefined layers ──────────────────────────────────

  /// Data layer (repositories, DTOs, network, local storage).
  static const data = LogLayer('data');

  /// Domain layer (blocs, cubits, use cases, business logic).
  static const domain = LogLayer('domain');

  /// Presentation layer (screens, views, components, UI).
  static const widgets = LogLayer('widgets');

  /// App-level (initialization, lifecycle, configuration).
  static const app = LogLayer('app');

  /// Infrastructure (DI, routing, platform channels).
  static const infra = LogLayer('infra');

  // ── Registry ───────────────────────────────────────────

  /// All known layers (predefined + registered custom ones).
  /// Custom layers can be added via [register].
  static final List<LogLayer> _values = [
    data,
    domain,
    widgets,
    app,
    infra,
  ];

  /// Returns an unmodifiable view of all registered layers.
  static List<LogLayer> get values => List.unmodifiable(_values);

  /// Register a custom layer so it appears in UI filters.
  static void register(LogLayer layer) {
    if (!_values.any((l) => l.name == layer.name)) {
      _values.add(layer);
    }
  }

  /// Find a layer by [name], or return `null`.
  static LogLayer? tryParse(String name) {
    for (final l in _values) {
      if (l.name == name) return l;
    }
    return null;
  }

  // ── Object overrides ──────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LogLayer && name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => name;
}
