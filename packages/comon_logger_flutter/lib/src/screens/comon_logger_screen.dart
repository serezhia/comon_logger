import 'dart:async';

import 'package:comon_logger/comon_logger.dart';
import 'package:flutter/material.dart';

import '../handlers/history_log_handler.dart';
import 'log_entry_card.dart';
import 'log_filter_panel.dart';
import 'log_record_renderer.dart';
import 'log_screen_action.dart';

/// A full-screen log viewer with filtering, search, and pluggable actions.
///
/// Use [renderers] to plug in custom display for specific log types.
/// Use [actions] to add toolbar buttons (share, import, etc.):
/// ```dart
/// Navigator.push(context, MaterialPageRoute(
///   builder: (_) => ComonLoggerScreen(
///     handler: historyHandler,
///     renderers: [
///       HttpLogRecordRenderer(), // from comon_logger_dio_flutter
///     ],
///     actions: [
///       ShareLogsAction(),   // from comon_logger_share_flutter
///       ImportLogsAction(),  // built-in
///     ],
///     initialAutoScroll: false,
///     initialSearchQuery: 'error',
///     initialFilter: LogFilterState(levels: {LogLevel.SEVERE}),
///     showFilterButton: true,
///   ),
/// ));
/// ```
///
/// Built-in toolbar buttons (search, auto-scroll, clear) are always present
/// by default. The **filter** button is hidden unless [showFilterButton]
/// is `true`. Custom [actions] appear between auto-scroll and clear.
class ComonLoggerScreen extends StatefulWidget {
  const ComonLoggerScreen({
    super.key,
    required this.handler,
    this.renderers = const [],
    this.actions = const [],
    this.initialAutoScroll = false,
    this.initialSearchQuery = '',
    this.initialFilter,
    this.showSearchButton = true,
    this.showFilterButton = false,
    this.showClearButton = true,
    this.reverseOrder = true,
  });

  /// The [HistoryLogHandler] providing log records.
  final HistoryLogHandler handler;

  /// Custom renderers for specific log types.
  ///
  /// Tried in order — the first one where [LogRecordRenderer.canRender]
  /// returns `true` wins. If none match, the default card layout is used.
  final List<LogRecordRenderer> renderers;

  /// Pluggable toolbar actions (share, import, custom).
  ///
  /// Shown in the app bar between the built-in buttons and the
  /// clear button. See [LogScreenAction] for the interface.
  final List<LogScreenAction> actions;

  /// Initial auto-scroll state. Defaults to `false`.
  final bool initialAutoScroll;

  /// Initial search query. When non-empty, the search bar is shown
  /// with this text pre-filled.
  final String initialSearchQuery;

  /// Initial filter state. When non-null, filters are applied immediately.
  final LogFilterState? initialFilter;

  /// Whether to show the search button in the toolbar.
  final bool showSearchButton;

  /// Whether to show the filter button in the toolbar.
  ///
  /// Defaults to `false` — opt-in to keep the toolbar minimal.
  final bool showFilterButton;

  /// Whether to show the clear button in the toolbar.
  final bool showClearButton;

  /// Show newest logs at the top.
  ///
  /// When `true`, records are rendered in reverse chronological order while
  /// the screen still opens at the top of the list.
  /// Defaults to `true`.
  final bool reverseOrder;

  @override
  State<ComonLoggerScreen> createState() => _ComonLoggerScreenState();
}

class _ComonLoggerScreenState extends State<ComonLoggerScreen> {
  late StreamSubscription<LogRecord> _subscription;
  final List<LogRecord> _records = [];
  List<LogRecord> _filteredRecords = [];
  LogFilterState _filterState = LogFilterState();
  bool _showFilters = false;
  bool _showSearch = false;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController(keepScrollOffset: false);
  bool _autoScroll = true;
  final Set<LogRecord> _expandedRecords = {};

  @override
  void initState() {
    super.initState();
    _autoScroll = widget.initialAutoScroll;
    _filterState = widget.initialFilter ?? LogFilterState();

    if (widget.initialSearchQuery.isNotEmpty) {
      _showSearch = true;
      _searchController.text = widget.initialSearchQuery;
      _filterState = _filterState.copyWith(
        searchQuery: widget.initialSearchQuery,
      );
    }

    _records.addAll(widget.handler.history);
    _applyFilters();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0.0);
      }
    });

    _subscription = widget.handler.onRecord.listen((record) {
      final preserveViewport = !_autoScroll && widget.reverseOrder;
      final previousOffset = _scrollController.hasClients
          ? _scrollController.offset
          : null;
      final previousMaxExtent = _scrollController.hasClients
          ? _scrollController.position.maxScrollExtent
          : null;

      setState(() {
        _records.add(record);
        _applyFilters();
      });

      if (_autoScroll) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            final target = widget.reverseOrder
                ? 0.0
                : _scrollController.position.maxScrollExtent;
            _scrollController.animateTo(
              target,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      } else if (preserveViewport &&
          previousOffset != null &&
          previousMaxExtent != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            final delta =
                _scrollController.position.maxScrollExtent - previousMaxExtent;
            if (delta > 0) {
              final target = (previousOffset + delta).clamp(
                0.0,
                _scrollController.position.maxScrollExtent,
              );
              _scrollController.jumpTo(target);
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    _filteredRecords = _records.where((r) => _filterState.matches(r)).toList();
  }

  void _clearLogs() {
    setState(() {
      widget.handler.clear();
      _records.clear();
      _filteredRecords.clear();
      _expandedRecords.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search logs...',
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() {
                    _filterState = _filterState.copyWith(searchQuery: val);
                    _applyFilters();
                  });
                },
              )
            : const Text('Logs'),
        actions: [
          // Search toggle
          if (widget.showSearchButton)
            IconButton(
              icon: Icon(_showSearch ? Icons.close : Icons.search),
              tooltip: _showSearch ? 'Close search' : 'Search',
              onPressed: () {
                setState(() {
                  _showSearch = !_showSearch;
                  if (!_showSearch) {
                    _searchController.clear();
                    _filterState = _filterState.copyWith(searchQuery: '');
                    _applyFilters();
                  }
                });
              },
            ),
          // Filter toggle
          if (widget.showFilterButton)
            IconButton(
              icon: Icon(
                _showFilters ? Icons.filter_list_off : Icons.filter_list,
                color: _filterState.hasActiveFilters
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              tooltip: 'Filters',
              onPressed: () => setState(() => _showFilters = !_showFilters),
            ),
          // Auto-scroll toggle
          IconButton(
            icon: Icon(
              _autoScroll
                  ? Icons.vertical_align_bottom
                  : Icons.vertical_align_center,
            ),
            tooltip: _autoScroll ? 'Auto-scroll on' : 'Auto-scroll off',
            onPressed: () => setState(() => _autoScroll = !_autoScroll),
          ),
          // Pluggable actions
          for (final action in widget.actions)
            action.build(context, widget.handler),
          // Clear
          if (widget.showClearButton)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear logs',
              onPressed: _clearLogs,
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter panel
          if (_showFilters)
            LogFilterPanel(
              filterState: _filterState,
              onFilterChanged: (newState) {
                setState(() {
                  _filterState = newState;
                  _applyFilters();
                });
              },
            ),

          // Status bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '${_filteredRecords.length} / ${_records.length} logs',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),

          // Log list
          Expanded(
            child: _filteredRecords.isEmpty
                ? Center(
                    child: Text(
                      _records.isEmpty
                          ? 'No logs yet'
                          : 'No logs match filters',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(
                          context,
                        ).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _filteredRecords.length,
                    padding: EdgeInsets.only(
                      top: 4,
                      bottom: 4 + MediaQuery.of(context).padding.bottom,
                    ),
                    itemBuilder: (context, index) {
                      final actualIndex = widget.reverseOrder
                          ? _filteredRecords.length - 1 - index
                          : index;
                      final rec = _filteredRecords[actualIndex];
                      // Let renderers hide records entirely
                      for (final r in widget.renderers) {
                        if (r.shouldHide(rec)) {
                          return const SizedBox.shrink();
                        }
                      }
                      return LogEntryCard(
                        key: ObjectKey(rec),
                        record: rec,
                        renderers: widget.renderers,
                        expanded: _expandedRecords.contains(rec),
                        onToggleExpanded: () {
                          setState(() {
                            if (!_expandedRecords.remove(rec)) {
                              _expandedRecords.add(rec);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
