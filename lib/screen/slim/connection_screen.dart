import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:checkmk_api/checkmk_api.dart' as cmk_api;
import 'package:go_router/go_router.dart';

import 'package:letscheck/providers/connection_data/connection_data_state.dart';
import 'package:letscheck/providers/hosts/hosts_state.dart';
import 'package:letscheck/providers/params.dart';
import 'package:letscheck/providers/providers.dart';
import 'package:letscheck/screen/slim/slim_layout.dart';
import 'package:letscheck/widget/site_stats_widget.dart';
import 'package:letscheck/widget/services_list_widget.dart';

class ConnectionScreen extends ConsumerStatefulWidget {
  final String alias;

  const ConnectionScreen({super.key, required this.alias});

  @override
  ConsumerState<ConnectionScreen> createState() => ConnectionScreenState();
}

class ConnectionScreenState extends ConsumerState<ConnectionScreen> {
  SlimLayoutSettings layoutSettings() {
    return SlimLayoutSettings(widget.alias, showSettings: true);
  }

  @override
  Widget build(BuildContext context) {
    final connectionData = ref.watch(connectionDataProvider(widget.alias));
    final hosts = ref.watch(hostsProvider(AliasAndFilterParams(alias: widget.alias, filter: [])));

    return SlimLayout(
      layoutSettings: layoutSettings(),
      child: switch (connectionData) {
        ConnectionDataInitial() => Container(),
        ConnectionDataLoaded(unhServices: final unhServices) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        context.go('/conn/${widget.alias}/critical');
                      },
                      icon: const Icon(Icons.error, color: Colors.red),
                      label: const Text('Critical'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade100,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.go('/conn/${widget.alias}/warning');
                      },
                      icon: const Icon(Icons.warning, color: Colors.orange),
                      label: const Text('Warning'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade100,
                      ),
                    ),
                  ],
                ),
              ),
              SiteStatsWidget(
                alias: widget.alias,
              ),
              Expanded(
                  child: ServicesListWidget(
                alias: widget.alias,
                services: unhServices.toList(),
                hosts: hosts is HostsLoaded ? hosts.hosts : <cmk_api.Host>[],
                filter: 'unhandled',
              )),
            ],
          ),
        ConnectionDataError(error: final error) => Column(
            children: [
              SiteStatsWidget(
                alias: widget.alias,
              ),
              Expanded(child: Center(child: Text('$error!'))),
            ],
          ),
      },
    );
  }
}
