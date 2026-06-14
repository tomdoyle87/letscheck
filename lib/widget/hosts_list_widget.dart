import 'package:flutter/material.dart';
import 'package:checkmk_api/checkmk_api.dart' as cmk_api;
import 'package:letscheck/widget/host_card_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HostsListWidget extends StatefulWidget {
  final String alias;
  final List<cmk_api.Host> hosts;
  final Key? listKey;
  final bool showCollapseButton;
  final String filter;

  const HostsListWidget({
    required this.alias,
    required this.hosts,
    this.listKey,
    this.showCollapseButton = true,
    this.filter = 'all',
  });

  @override
  State<HostsListWidget> createState() => _HostsListWidgetState();
}

class _HostsListWidgetState extends State<HostsListWidget> {
  final Map<String, bool> _expandedFolders = {};
  List<String> _customFolderOrder = [];
  static const String _prefKeyExpansion = 'hosts_folder_expansion';
  static const String _prefKeyOrder = 'hosts_folder_order';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load expanded state
    final expandedState = prefs.getString(_prefKeyExpansion);
    if (expandedState != null) {
      final expandedList = expandedState.split(',');
      setState(() {
        for (var folder in expandedList) {
          _expandedFolders[folder] = true;
        }
      });
    }
    
    // Load custom folder order
    final orderState = prefs.getString(_prefKeyOrder);
    if (orderState != null) {
      setState(() {
        _customFolderOrder = orderState.split(',');
      });
    }
  }

  Future<void> _saveExpandedState() async {
    final prefs = await SharedPreferences.getInstance();
    final expandedList = _expandedFolders.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .join(',');
    await prefs.setString(_prefKeyExpansion, expandedList);
  }

  Future<void> _saveFolderOrder(List<String> newOrder) async {
    final prefs = await SharedPreferences.getInstance();
    final orderString = newOrder.join(',');
    await prefs.setString(_prefKeyOrder, orderString);
    setState(() {
      _customFolderOrder = newOrder;
    });
  }

  Future<void> _resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyExpansion);
    setState(() {
      _expandedFolders.clear();
    });
  }

  void _moveFolder(int oldIndex, int newIndex, List<String> currentFolders) {
    if (newIndex < 0 || newIndex >= currentFolders.length) return;
    
    final newOrder = List<String>.from(currentFolders);
    final item = newOrder.removeAt(oldIndex);
    newOrder.insert(newIndex, item);
    _saveFolderOrder(newOrder);
  }

  // Normalize folder path and extract display name
  String _normalizeFolder(String? folder) {
    if (folder == null || folder.isEmpty) {
      return 'Main';
    }
    
    // Handle filename format like "/wato/hosts/server1.mk" or "/wato/hosts/web/server2.mk"
    // Extract the folder path by removing the filename and /wato/hosts prefix
    String normalized = folder;
    
    // Remove .mk extension if present
    if (normalized.endsWith('.mk')) {
      normalized = normalized.substring(0, normalized.length - 3);
    }
    
    // Extract the directory path by removing the filename
    var lastSlash = normalized.lastIndexOf('/');
    if (lastSlash > 0) {
      normalized = normalized.substring(0, lastSlash);
    }
    
    // Remove /wato/hosts prefix if present
    if (normalized.startsWith('/wato/hosts')) {
      normalized = normalized.substring('/wato/hosts'.length);
    } else if (normalized.startsWith('/wato/')) {
      normalized = normalized.substring('/wato/'.length);
    }
    
    // Remove leading and trailing slashes
    while (normalized.startsWith('/')) {
      normalized = normalized.substring(1);
    }
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    
    // If empty after normalization, it's the main folder
    if (normalized.isEmpty) {
      return 'Main';
    }
    
    // Return the last segment of the path as the folder name
    var parts = normalized.split('/');
    return parts.last;
  }

  @override
  Widget build(BuildContext context) {
    // Use simple list for problems/unhandled filters, folder grouping for others
    if (widget.filter == 'problems' || widget.filter == 'unhandled' || widget.filter == 'stale') {
      if (widget.hosts.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text('No alerts found'),
          ),
        );
      }

      return ListView(
        key: widget.listKey,
        children: widget.hosts.map((host) => HostCardWidget(
          alias: widget.alias,
          host: host,
        )).toList(),
      );
    }

    // Group hosts by their folder for "all" filter
    var groupedHosts = <String, List<cmk_api.Host>>{};

    for (var host in widget.hosts) {
      var folder = _normalizeFolder(host.folder);
      if (!groupedHosts.containsKey(folder)) {
        groupedHosts[folder] = [];
      }
      groupedHosts[folder]!.add(host);
    }

    // Get folder list - use custom order if available, otherwise use alphabetical with Main first
    List<String> sortedFolders;
    if (_customFolderOrder.isNotEmpty) {
      // Filter custom order to only include folders that still exist
      sortedFolders = _customFolderOrder
          .where((folder) => groupedHosts.containsKey(folder))
          .toList();

      // Add any new folders that aren't in the custom order
      final existingFolders = sortedFolders.toSet();
      final newFolders = groupedHosts.keys
          .where((folder) => !existingFolders.contains(folder))
          .toList()
        ..sort((a, b) {
          if (a == 'Main') return -1;
          if (b == 'Main') return 1;
          return a.compareTo(b);
        });

      sortedFolders.addAll(newFolders);
    } else {
      // Default alphabetical sort with Main first
      sortedFolders = groupedHosts.keys.toList()
        ..sort((a, b) {
          if (a == 'Main') return -1;
          if (b == 'Main') return 1;
          return a.compareTo(b);
        });
    }

    return Column(
      children: [
        // Collapse all button - only show when enabled
        if (widget.showCollapseButton)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _resetToDefault,
                  icon: const Icon(Icons.expand_less, size: 16),
                  label: const Text('Collapse all'),
                ),
              ],
            ),
          ),
        // Hosts list
        Expanded(
          child: ListView(
            key: widget.listKey,
            children: [
              // Add grouped hosts by folder
              for (int index = 0; index < sortedFolders.length; index++)
                Column(
                  key: ValueKey(sortedFolders[index]),
                  children: [
                    _buildGroupHeader(
                      sortedFolders[index],
                      _expandedFolders[sortedFolders[index]] ?? false,
                      groupedHosts[sortedFolders[index]]!.length,
                      index,
                      sortedFolders.length,
                      sortedFolders,
                      () {
                        setState(() {
                          _expandedFolders[sortedFolders[index]] = !(_expandedFolders[sortedFolders[index]] ?? false);
                        });
                        _saveExpandedState();
                      },
                    ),
                    if (_expandedFolders[sortedFolders[index]] ?? false)
                      ...groupedHosts[sortedFolders[index]]!.map((host) => HostCardWidget(
                            alias: widget.alias,
                            host: host,
                          )),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGroupHeader(String folderName, bool isExpanded, int hostCount, int index, int totalFolders, List<String> currentFolders, VoidCallback onTap) {
    return Card(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 20,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  folderName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '($hostCount)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 8),
              // Up arrow - separate GestureDetector to prevent bubbling
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (index > 0) {
                    _moveFolder(index, index - 1, currentFolders);
                  }
                },
                onLongPress: () {}, // Consume long press
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.arrow_upward, 
                    size: 18,
                    color: index > 0 ? Theme.of(context).iconTheme.color : Colors.grey,
                  ),
                ),
              ),
              // Down arrow - separate GestureDetector to prevent bubbling
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (index < totalFolders - 1) {
                    _moveFolder(index, index + 1, currentFolders);
                  }
                },
                onLongPress: () {}, // Consume long press
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.arrow_downward, 
                    size: 18,
                    color: index < totalFolders - 1 ? Theme.of(context).iconTheme.color : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
