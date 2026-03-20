import 'package:comon_logger/comon_logger.dart';
import 'package:flutter/material.dart';

/// Filter state for the log viewer.
class LogFilterState {
  LogFilterState({
    Set<LogLevel>? levels,
    Set<LogLayer>? layers,
    Set<LogType>? types,
    this.featureQuery = '',
    this.loggerNameQuery = '',
    this.searchQuery = '',
  })  : levels = levels ?? {},
        layers = layers ?? {},
        types = types ?? {};

  final Set<LogLevel> levels;
  final Set<LogLayer> layers;
  final Set<LogType> types;
  final String featureQuery;
  final String loggerNameQuery;
  final String searchQuery;

  bool get hasActiveFilters =>
      levels.isNotEmpty ||
      layers.isNotEmpty ||
      types.isNotEmpty ||
      featureQuery.isNotEmpty ||
      loggerNameQuery.isNotEmpty ||
      searchQuery.isNotEmpty;

  /// Returns true if [record] passes all active filters.
  bool matches(LogRecord record) {
    if (levels.isNotEmpty && !levels.contains(record.level)) {
      return false;
    }
    if (layers.isNotEmpty &&
        record.layer != null &&
        !layers.contains(record.layer)) {
      return false;
    }
    if (types.isNotEmpty &&
        record.type != null &&
        !types.contains(record.type)) {
      return false;
    }
    if (featureQuery.isNotEmpty &&
        (record.feature == null ||
            !record.feature!
                .toLowerCase()
                .contains(featureQuery.toLowerCase()))) {
      return false;
    }
    if (loggerNameQuery.isNotEmpty &&
        !record.loggerName
            .toLowerCase()
            .contains(loggerNameQuery.toLowerCase())) {
      return false;
    }
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      final inMessage = record.message.toLowerCase().contains(q);
      final inLogger = record.loggerName.toLowerCase().contains(q);
      final inError =
          record.error?.toString().toLowerCase().contains(q) ?? false;
      if (!inMessage && !inLogger && !inError) return false;
    }
    return true;
  }

  LogFilterState copyWith({
    Set<LogLevel>? levels,
    Set<LogLayer>? layers,
    Set<LogType>? types,
    String? featureQuery,
    String? loggerNameQuery,
    String? searchQuery,
  }) {
    return LogFilterState(
      levels: levels ?? this.levels,
      layers: layers ?? this.layers,
      types: types ?? this.types,
      featureQuery: featureQuery ?? this.featureQuery,
      loggerNameQuery: loggerNameQuery ?? this.loggerNameQuery,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// A collapsible filter panel for the log viewer.
class LogFilterPanel extends StatelessWidget {
  const LogFilterPanel({
    super.key,
    required this.filterState,
    required this.onFilterChanged,
  });

  final LogFilterState filterState;
  final ValueChanged<LogFilterState> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Level chips
          _buildSection(
            context,
            label: 'Level',
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: LogLevel.values.map((level) {
                final selected = filterState.levels.contains(level);
                return FilterChip(
                  label: Text(level.name, style: const TextStyle(fontSize: 11)),
                  selected: selected,
                  visualDensity: VisualDensity.compact,
                  onSelected: (val) {
                    final newLevels = Set<LogLevel>.from(filterState.levels);
                    val ? newLevels.add(level) : newLevels.remove(level);
                    onFilterChanged(filterState.copyWith(levels: newLevels));
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),

          // Layer chips
          _buildSection(
            context,
            label: 'Layer',
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: LogLayer.values.map((layer) {
                final selected = filterState.layers.contains(layer);
                return FilterChip(
                  label: Text(layer.name, style: const TextStyle(fontSize: 11)),
                  selected: selected,
                  visualDensity: VisualDensity.compact,
                  onSelected: (val) {
                    final newLayers = Set<LogLayer>.from(filterState.layers);
                    val ? newLayers.add(layer) : newLayers.remove(layer);
                    onFilterChanged(filterState.copyWith(layers: newLayers));
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),

          // Type chips
          _buildSection(
            context,
            label: 'Type',
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: LogType.values.map((type) {
                final selected = filterState.types.contains(type);
                return FilterChip(
                  label: Text(type.name, style: const TextStyle(fontSize: 11)),
                  selected: selected,
                  visualDensity: VisualDensity.compact,
                  onSelected: (val) {
                    final newTypes = Set<LogType>.from(filterState.types);
                    val ? newTypes.add(type) : newTypes.remove(type);
                    onFilterChanged(filterState.copyWith(types: newTypes));
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),

          // Text filters
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Feature',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 13),
                  onChanged: (val) =>
                      onFilterChanged(filterState.copyWith(featureQuery: val)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Logger name',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 13),
                  onChanged: (val) => onFilterChanged(
                      filterState.copyWith(loggerNameQuery: val)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Reset button
          if (filterState.hasActiveFilters)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => onFilterChanged(LogFilterState()),
                icon: const Icon(Icons.clear_all, size: 18),
                label:
                    const Text('Reset filters', style: TextStyle(fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Theme.of(context)
                .textTheme
                .bodySmall
                ?.color
                ?.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 2),
        child,
      ],
    );
  }
}
