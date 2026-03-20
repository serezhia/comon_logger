import 'package:comon_logger/comon_logger.dart';
import 'package:flutter/material.dart';

/// A widget that renders structured navigation log details
/// with a visual route transition display.
class NavigationLogDetail extends StatelessWidget {
  const NavigationLogDetail({super.key, required this.record});

  final LogRecord record;

  @override
  Widget build(BuildContext context) {
    final extra = record.extra ?? {};
    final action = extra['action'] as String? ?? '';
    final route = extra['route'] as String? ?? 'unknown';
    final previousRoute = extra['previousRoute'] as String?;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _actionColor(action).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _actionColor(action).withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Action badge row
            Row(
              children: [
                _ActionBadge(action: action),
                const SizedBox(width: 10),
                Icon(
                  _actionIcon(action),
                  size: 16,
                  color: _actionColor(action),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Route transition visualization
            if (previousRoute != null) ...[
              _RouteTransition(
                action: action,
                fromRoute: _transitionFrom(action, route, previousRoute),
                toRoute: _transitionTo(action, route, previousRoute),
              ),
            ] else ...[
              _SingleRoute(route: route, action: action),
            ],
          ],
        ),
      ),
    );
  }

  /// For POP: from = route being popped, to = previousRoute (destination).
  /// For others: from = previousRoute, to = route.
  static String _transitionFrom(
    String action,
    String route,
    String previousRoute,
  ) {
    return action == 'POP' ? route : previousRoute;
  }

  static String _transitionTo(
    String action,
    String route,
    String previousRoute,
  ) {
    return action == 'POP' ? previousRoute : route;
  }

  static Color _actionColor(String action) {
    return switch (action) {
      'PUSH' => Colors.green,
      'POP' => Colors.orange,
      'REPLACE' => Colors.blue,
      'REMOVE' => Colors.red,
      _ => Colors.grey,
    };
  }

  static IconData _actionIcon(String action) {
    return switch (action) {
      'PUSH' => Icons.arrow_forward_rounded,
      'POP' => Icons.arrow_back_rounded,
      'REPLACE' => Icons.swap_horiz_rounded,
      'REMOVE' => Icons.close_rounded,
      _ => Icons.navigate_next_rounded,
    };
  }
}

// ─────────────────────────────────────────────────────────
//  Action badge
// ─────────────────────────────────────────────────────────

class _ActionBadge extends StatelessWidget {
  const _ActionBadge({required this.action});

  final String action;

  @override
  Widget build(BuildContext context) {
    final color = NavigationLogDetail._actionColor(action);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        action,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Route transition: from → to
// ─────────────────────────────────────────────────────────

class _RouteTransition extends StatelessWidget {
  const _RouteTransition({
    required this.action,
    required this.fromRoute,
    required this.toRoute,
  });

  final String action;
  final String fromRoute;
  final String toRoute;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = NavigationLogDetail._actionColor(action);
    final dimColor =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5) ??
        Colors.grey;

    return Row(
      children: [
        // From route
        Expanded(
          child: _RouteChip(route: fromRoute, color: dimColor, faded: true),
        ),
        // Arrow
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.arrow_forward_rounded, size: 18, color: color),
        ),
        // To route
        Expanded(
          child: _RouteChip(route: toRoute, color: color, faded: false),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Single route (no previous route)
// ─────────────────────────────────────────────────────────

class _SingleRoute extends StatelessWidget {
  const _SingleRoute({required this.route, required this.action});

  final String route;
  final String action;

  @override
  Widget build(BuildContext context) {
    final color = NavigationLogDetail._actionColor(action);
    return _RouteChip(route: route, color: color, faded: false);
  }
}

// ─────────────────────────────────────────────────────────
//  Route chip
// ─────────────────────────────────────────────────────────

class _RouteChip extends StatelessWidget {
  const _RouteChip({
    required this.route,
    required this.color,
    required this.faded,
  });

  final String route;
  final Color color;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: faded ? 0.06 : 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: faded ? 0.15 : 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.route_rounded,
            size: 14,
            color: color.withValues(alpha: faded ? 0.5 : 1.0),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: SelectableText(
              route,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                fontWeight: faded ? FontWeight.w400 : FontWeight.w600,
                color: color.withValues(alpha: faded ? 0.6 : 1.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
