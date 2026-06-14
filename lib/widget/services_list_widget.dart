import 'package:flutter/material.dart';
import 'package:checkmk_api/checkmk_api.dart' as cmk_api;
import 'package:letscheck/providers/services/services_util.dart';
import 'package:letscheck/widget/services_grouped_card_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServicesListWidget extends StatefulWidget {
  final String alias;
  final List<cmk_api.Service> services;
  final List<cmk_api.Host> hosts;
  final String filter;

  const ServicesListWidget({
    required this.alias,
    required this.services,
    required this.hosts,
    required this.filter,
    super.key,
  });

  @override
  State<ServicesListWidget> createState() => _ServicesListWidgetState();
}

class _ServicesListWidgetState extends State<ServicesListWidget>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final Map<String, bool> _expandedFolders = {};
  final Map<String, bool> _expandedHosts = {};
  static const String _prefKeyOrder = 'hosts_folder_order';
  List<String> _customFolderOrder = [];

  final minimalVisualDensity = VisualDensity(horizontal: -4.0, vertical: -4.0);

  @override
  bool get wantKeepAlive => widget.filter == 'all';

  @override
  void initState() {
    super.initState();
    _loadFolderOrder();
  }

  @override
  void didUpdateWidget(ServicesListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  Future<void> _loadFolderOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final orderState = prefs.getString(_prefKeyOrder);
    if (orderState != null) {
      setState(() {
        _customFolderOrder = orderState.split(',');
      });
    }
  }

  // Get display text for host (with alias if available)
  String _getHostDisplayText(String hostName) {
    // Find the host object
    cmk_api.Host? host;
    for (var h in widget.hosts) {
      if (h.hostName == hostName) {
        host = h;
        break;
      }
    }
    
    if (host == null) {
      return hostName;
    }
    
    // Same logic as in host_card_widget.dart
    if (host.alias != null && host.alias!.isNotEmpty && host.alias != host.hostName) {
      return '${host.alias} - ${host.hostName}';
    }
    if (host.displayName != null && host.displayName!.isNotEmpty && host.displayName != host.hostName) {
      return '${host.displayName} - ${host.hostName}';
    }
    return host.hostName ?? 'Unknown';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin

    // Use simple grouping for critical/warning filters, folder grouping for "all"
    if (widget.filter == 'problems' || widget.filter == 'unhandled' || widget.filter == 'stale') {
      final groupedServices = servicesGroupByHostname(services: widget.services);
      final hostNames = groupedServices.keys.toList()..sort();

      if (widget.services.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text('No alerts found'),
          ),
        );
      }

      return ListView(
        controller: _scrollController,
        children: [
          for (final hostname in hostNames)
            ServicesGroupedCardWidget(
              alias: widget.alias,
              groupName: hostname,
              services: groupedServices[hostname]!,
              showGroupHeader: true,
            ),
        ],
      );
    } else {
      // Use folder grouping for "all" filter
      final groupedServices = servicesGroupByFolderAndHost(
        services: widget.services,
        hosts: widget.hosts,
      );



      // Get folder list - use custom order if available, otherwise use alphabetical with Main first
      List<String> sortedFolders;
      if (_customFolderOrder.isNotEmpty) {
        sortedFolders = _customFolderOrder
            .where((folder) => groupedServices.containsKey(folder))
            .toList();
        
        final existingFolders = sortedFolders.toSet();
        final newFolders = groupedServices.keys
            .where((folder) => !existingFolders.contains(folder))
            .toList()
          ..sort((a, b) {
            if (a == 'Main') return -1;
            if (b == 'Main') return 1;
            return a.compareTo(b);
          });
        
        sortedFolders.addAll(newFolders);
      } else {
        sortedFolders = groupedServices.keys.toList()
          ..sort((a, b) {
            if (a == 'Main') return -1;
            if (b == 'Main') return 1;
            return a.compareTo(b);
          });
      }

      return ListView(
        controller: _scrollController,
        children: [
          for (final folder in sortedFolders)
            Column(
              key: ValueKey(folder),
              children: [
                _buildFolderHeader(folder, groupedServices[folder]!.length),
                if (_expandedFolders[folder] ?? false)
                  ...groupedServices[folder]!.entries.map((entry) {
                    final hostname = entry.key; // This is the actual hostname
                    final hostServices = entry.value;
                    return Column(
                      key: ValueKey(hostname),
                      children: [
                        _buildHostHeader(hostname, hostServices.length),
                        if (_expandedHosts[hostname] ?? false)
                          ...hostServices.map((service) => 
                            ServicesGroupedCardWidget(
                              alias: widget.alias,
                              groupName: hostname, // Use actual hostname for grouping
                              services: [service],
                              showGroupHeader: false,
                            ),
                          ),
                      ],
                    );
                  }),
              ],
            ),
        ],
      );
    }
  }

  Widget _buildFolderHeader(String folderName, int hostCount) {
    return Card(
      child: ListTile(
        leading: Icon(
          _expandedFolders[folderName] ?? false ? Icons.expand_less : Icons.expand_more,
          size: 20,
        ),
        title: Text(
          folderName,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        trailing: Text(
          '($hostCount)',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        onTap: () {
          setState(() {
            _expandedFolders[folderName] = !(_expandedFolders[folderName] ?? false);
          });
        },
      ),
    );
  }

  Widget _buildHostHeader(String hostName, int serviceCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: ListTile(
        leading: Icon(
          _expandedHosts[hostName] ?? false ? Icons.expand_less : Icons.expand_more,
          size: 18,
        ),
        title: Text(
          _getHostDisplayText(hostName),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: Text(
          '($serviceCount)',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        onTap: () {
          setState(() {
            _expandedHosts[hostName] = !(_expandedHosts[hostName] ?? false);
          });
        },
      ),
    );
  }
}
