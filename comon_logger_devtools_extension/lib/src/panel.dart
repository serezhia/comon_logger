import 'package:comon_logger/comon_logger.dart';
import 'package:devtools_app_shared/service.dart' hide ConnectedApp;
import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'log_service.dart';

/// Color mapping for log levels.
Color _levelColor(LogLevel level) {
  if (level >= LogLevel.SHOUT) return Colors.red.shade900;
  if (level >= LogLevel.SEVERE) return Colors.red;
  if (level >= LogLevel.WARNING) return Colors.orange;
  if (level >= LogLevel.INFO) return Colors.blue;
  if (level >= LogLevel.CONFIG) return Colors.teal;
  if (level >= LogLevel.FINE) return Colors.green;
  return Colors.grey;
}

/// The main panel of the comon_logger DevTools extension.
///
/// Displays a filterable list of log records streamed from the connected
/// Flutter application.
class ComonLoggerDevToolsPanel extends StatefulWidget {
  const ComonLoggerDevToolsPanel({super.key});

  @override
  State<ComonLoggerDevToolsPanel> createState() =>
      _ComonLoggerDevToolsPanelState();
}

class _ComonLoggerDevToolsPanelState extends State<ComonLoggerDevToolsPanel> {
  final DevToolsLogService _logService = DevToolsLogService();
  final List<LogRecord> _records = [];
  List<LogRecord> _filteredRecords = [];
  final ScrollController _scrollController = ScrollController();

  // Filters
  final Set<LogLevel> _selectedLevels = {};
  final Set<LogLayer> _selectedLayers = {};
  final Set<LogType> _selectedTypes = {};
  String _featureFilter = '';
  String _loggerNameFilter = '';
  String _searchText = '';

  bool _autoScroll = true;
  bool _showFilters = false;
  int? _expandedIndex;
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    _connectToService();
  }

  Future<void> _connectToService() async {
    try {
      // In standalone mode (no connected app), serviceManager may not have
      // a VM service available — that's fine, the UI still works for imports.
      serviceManager.registerLifecycleCallback(
        ServiceManagerLifecycle.afterOpenVmService,
        (_) async {
          await _logService.connect(serviceManager);

          _logService.onRecord.listen((record) {
            if (!mounted) return;
            setState(() {
              _records.add(record);
              _applyFilters();
            });
            _maybeScrollToBottom();
          });

          if (mounted) {
            setState(() {
              _connected = true;
              _records.addAll(_logService.history);
              _applyFilters();
            });
          }
        },
      );
    } catch (_) {
      // Standalone mode or connection failure — extension works without
      // a connected app (import, filters, etc. are fully functional).
    }
  }

  void _applyFilters() {
    _filteredRecords = _records.where((r) {
      if (_selectedLevels.isNotEmpty && !_selectedLevels.contains(r.level)) {
        return false;
      }
      if (_selectedLayers.isNotEmpty &&
          (r.layer == null || !_selectedLayers.contains(r.layer))) {
        return false;
      }
      if (_selectedTypes.isNotEmpty &&
          (r.type == null || !_selectedTypes.contains(r.type))) {
        return false;
      }
      if (_featureFilter.isNotEmpty &&
          (r.feature == null ||
              !r.feature!
                  .toLowerCase()
                  .contains(_featureFilter.toLowerCase()))) {
        return false;
      }
      if (_loggerNameFilter.isNotEmpty &&
          !r.loggerName
              .toLowerCase()
              .contains(_loggerNameFilter.toLowerCase())) {
        return false;
      }
      if (_searchText.isNotEmpty &&
          !r.message.toLowerCase().contains(_searchText.toLowerCase()) &&
          !(r.error?.toString().toLowerCase().contains(
                    _searchText.toLowerCase(),
                  ) ??
              false)) {
        return false;
      }
      return true;
    }).toList();
  }

  void _maybeScrollToBottom() {
    if (!_autoScroll) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearLogs() {
    setState(() {
      _records.clear();
      _filteredRecords.clear();
      _expandedIndex = null;
    });
    _logService.clear(serviceManager: _connected ? serviceManager : null);
  }

  void _resetFilters() {
    setState(() {
      _selectedLevels.clear();
      _selectedLayers.clear();
      _selectedTypes.clear();
      _featureFilter = '';
      _loggerNameFilter = '';
      _searchText = '';
      _applyFilters();
    });
  }

  void _togglePause() {
    setState(() {
      if (_logService.isPaused) {
        _logService.resume();
      } else {
        _logService.pause();
      }
    });
  }

  Future<void> _importLogs() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import logs from JSON'),
        content: SizedBox(
          width: 600,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Paste JSON exported via exportJson() or from a log file. '
                'Accepts a JSON array [...] or {"logs": [...]}.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.content_paste, size: 16),
                    label: const Text('Paste from clipboard'),
                    onPressed: () async {
                      final data = await Clipboard.getData('text/plain');
                      if (data?.text != null) {
                        controller.text = data!.text!;
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                  decoration: const InputDecoration(
                    hintText: '[{"level":"INFO","message":"...", ...}]',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (result == null || result.trim().isEmpty) return;

    try {
      final imported = _logService.importFromJson(result.trim());
      setState(() {
        // Service already added to its internal history;
        // sync our local list too (only new records)
        _records.addAll(imported);
        _applyFilters();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported ${imported.length} log records')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _logService.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(),
        if (_showFilters) _buildFilterPanel(),
        _buildStatusBar(),
        Expanded(child: _buildLogList()),
      ],
    );
  }

  Widget _buildToolbar() {
    return Material(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear logs',
              onPressed: _clearLogs,
            ),
            IconButton(
              icon: Icon(_logService.isPaused ? Icons.play_arrow : Icons.pause),
              tooltip: _logService.isPaused ? 'Resume' : 'Pause',
              onPressed: _togglePause,
            ),
            IconButton(
              icon: Icon(
                _autoScroll
                    ? Icons.vertical_align_bottom
                    : Icons.vertical_align_center,
              ),
              tooltip: _autoScroll ? 'Auto-scroll ON' : 'Auto-scroll OFF',
              onPressed: () => setState(() => _autoScroll = !_autoScroll),
            ),
            IconButton(
              icon: Icon(
                _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
              ),
              tooltip: 'Toggle filters',
              onPressed: () => setState(() => _showFilters = !_showFilters),
            ),
            IconButton(
              icon: const Icon(Icons.file_open_outlined),
              tooltip: 'Import logs from JSON',
              onPressed: _importLogs,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 36,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search logs...',
                    prefixIcon: Icon(Icons.search, size: 18),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchText = value;
                      _applyFilters();
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Levels
          Wrap(
            spacing: 4,
            children: [
              const Text('Level: ',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              for (final level in [
                LogLevel.FINEST,
                LogLevel.FINER,
                LogLevel.FINE,
                LogLevel.CONFIG,
                LogLevel.INFO,
                LogLevel.WARNING,
                LogLevel.SEVERE,
                LogLevel.SHOUT,
              ])
                FilterChip(
                  label: Text(level.name, style: const TextStyle(fontSize: 11)),
                  selected: _selectedLevels.contains(level),
                  onSelected: (selected) {
                    setState(() {
                      selected
                          ? _selectedLevels.add(level)
                          : _selectedLevels.remove(level);
                      _applyFilters();
                    });
                  },
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 4),
          // Layers
          Wrap(
            spacing: 4,
            children: [
              const Text('Layer: ',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              for (final layer in [
                LogLayer.data,
                LogLayer.domain,
                LogLayer.widgets,
                LogLayer.app,
                LogLayer.infra,
              ])
                FilterChip(
                  label: Text(layer.name, style: const TextStyle(fontSize: 11)),
                  selected: _selectedLayers.contains(layer),
                  onSelected: (selected) {
                    setState(() {
                      selected
                          ? _selectedLayers.add(layer)
                          : _selectedLayers.remove(layer);
                      _applyFilters();
                    });
                  },
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 4),
          // Types
          Wrap(
            spacing: 4,
            children: [
              const Text('Type: ',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              for (final type in [
                LogType.network,
                LogType.database,
                LogType.navigation,
                LogType.logic,
                LogType.ui,
                LogType.lifecycle,
                LogType.analytics,
                LogType.performance,
                LogType.security,
                LogType.general,
              ])
                FilterChip(
                  label: Text(type.name, style: const TextStyle(fontSize: 11)),
                  selected: _selectedTypes.contains(type),
                  onSelected: (selected) {
                    setState(() {
                      selected
                          ? _selectedTypes.add(type)
                          : _selectedTypes.remove(type);
                      _applyFilters();
                    });
                  },
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 4),
          // Text filters
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Feature filter',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      isDense: true,
                    ),
                    onChanged: (v) {
                      setState(() {
                        _featureFilter = v;
                        _applyFilters();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Logger name filter',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      isDense: true,
                    ),
                    onChanged: (v) {
                      setState(() {
                        _loggerNameFilter = v;
                        _applyFilters();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Reset'),
                onPressed: _resetFilters,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Row(
        children: [
          Icon(
            _connected ? Icons.circle : Icons.circle_outlined,
            size: 10,
            color: _connected ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            _connected ? 'Connected' : 'Disconnected',
            style: const TextStyle(fontSize: 12),
          ),
          const Spacer(),
          Text(
            'Showing ${_filteredRecords.length} of ${_records.length}',
            style: const TextStyle(fontSize: 12),
          ),
          if (_logService.isPaused) ...[
            const SizedBox(width: 8),
            const Text(
              'PAUSED',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogList() {
    if (_filteredRecords.isEmpty) {
      return const Center(
        child: Text(
          'No log records',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _filteredRecords.length,
      itemBuilder: (context, index) {
        final record = _filteredRecords[index];
        final isExpanded = _expandedIndex == index;
        final time = '${record.time.hour.toString().padLeft(2, '0')}:'
            '${record.time.minute.toString().padLeft(2, '0')}:'
            '${record.time.second.toString().padLeft(2, '0')}.'
            '${record.time.millisecond.toString().padLeft(3, '0')}';

        return InkWell(
          onTap: () {
            setState(() {
              _expandedIndex = isExpanded ? null : index;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: _levelColor(record.level),
                  width: 3,
                ),
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        time,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color:
                            _levelColor(record.level).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        record.level.name,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _levelColor(record.level),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (record.loggerName.isNotEmpty)
                      Text(
                        record.loggerName,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        record.message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    if (record.layer != null)
                      _tag(record.layer!.name, Colors.purple),
                    if (record.type != null)
                      _tag(record.type!.name, Colors.indigo),
                    if (record.feature != null)
                      _tag(record.feature!, Colors.brown),
                  ],
                ),
                // Expanded details
                if (isExpanded) ...[
                  const Divider(height: 8),
                  Text(
                    record.message,
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (record.error != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Error: ${record.error}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                  if (record.stackTrace != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(4),
                      color: Colors.grey.shade100,
                      child: Text(
                        record.stackTrace.toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                  if (record.extra != null && record.extra!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Extra: ${record.extra}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tag(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 9, color: color),
        ),
      ),
    );
  }
}
