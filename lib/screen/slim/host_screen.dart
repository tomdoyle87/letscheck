import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:letscheck/providers/hosts/hosts_state.dart';
import 'package:letscheck/providers/params.dart';
import 'package:letscheck/providers/providers.dart';
import 'package:letscheck/providers/services/services_state.dart';
import 'package:letscheck/providers/services/services_util.dart';
import 'package:letscheck/widget/site_stats_widget.dart';
import 'package:letscheck/widget/services_grouped_card_widget.dart';
import 'package:letscheck/widget/host_card_widget.dart';

import 'package:letscheck/screen/slim/slim_layout.dart';

class HostScreen extends ConsumerStatefulWidget {
  final String alias;
  final String hostname;

  HostScreen({required this.alias, required this.hostname});

  @override
  HostScreenState createState() => HostScreenState(
        alias: alias,
        hostname: hostname,
      );
}

class HostScreenState extends ConsumerState<HostScreen> {
  final String alias;
  final String hostname;

  late final AliasAndFilterParams hostParams;
  late final AliasAndFilterParams serviceParams;

  HostScreenState({required this.alias, required this.hostname}) {
    hostParams = AliasAndFilterParams(
        alias: alias,
        filter: ['{"op": "=", "left": "name", "right": "$hostname"}']);
    serviceParams = AliasAndFilterParams(
        alias: alias,
        filter: ['{"op": "=", "left": "host_name", "right": "$hostname"}']);
  }

  SlimLayoutSettings settings(WidgetRef ref) {
    var title = 'Host';
    
    // Fetch host information to get alias for title
    final hosts = ref.watch(hostsProvider(hostParams));
    String displayHostname = hostname;
    
    if (hosts is HostsLoaded && hosts.hosts.isNotEmpty) {
      final host = hosts.hosts[0];
      if (host.alias != null && host.alias!.isNotEmpty && host.alias != host.hostName) {
        displayHostname = '${host.alias} - ${host.hostName}';
      } else if (host.displayName != null && host.displayName!.isNotEmpty && host.displayName != host.hostName) {
        displayHostname = '${host.displayName} - ${host.hostName}';
      }
    }
    
    if (displayHostname.length > 25) {
      displayHostname = displayHostname.substring(0, 25);
    }
    title = "Host $displayHostname";

    return SlimLayoutSettings(title, showMenu: false, showSearch: false);
  }

  @override
  Widget build(BuildContext context) {
    final hosts = ref.watch(hostsProvider(hostParams));
    final services = ref.watch(servicesProvider(serviceParams));

    if (hosts is! HostsLoaded || services is! ServicesLoaded) {
      return Container();
    }

    final groupedServices =
        servicesGroupByHostname(services: services.services);

    return SlimLayout(
      layoutSettings: settings(ref),
      child: Column(
        children: [
          SiteStatsWidget(alias: alias),
          Expanded(
              child: Column(children: [
            HostCardWidget(alias: alias, host: hosts.hosts[0]),
            Expanded(
                child: ListView(children: [
              ServicesGroupedCardWidget(
                alias: alias,
                groupName: hostname,
                services: groupedServices[hostname]!,
                showGroupHeader: false,
              )
            ]))
          ])),
        ],
      ),
    );
  }
}
