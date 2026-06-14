import 'package:flutter/material.dart';
import 'package:checkmk_api/checkmk_api.dart' as cmk_api;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:letscheck/providers/params.dart';
import 'package:letscheck/providers/providers.dart';
import 'package:letscheck/providers/services/services_state.dart';
import 'package:letscheck/providers/hosts/hosts_state.dart';
import 'package:letscheck/widget/services_list_widget.dart';
import 'package:letscheck/widget/site_stats_widget.dart';

import 'package:letscheck/screen/slim/slim_layout.dart';

class ServicesScreen extends ConsumerStatefulWidget {
  final String alias;
  final String filter;

  ServicesScreen({required this.alias, required this.filter});

  @override
  ServicesScreenState createState() => ServicesScreenState(
        alias: alias,
        filter: filter,
      );
}

class ServicesScreenState extends ConsumerState<ServicesScreen> {
  final String alias;
  final String filter;
  late AliasAndFilterParams params;

  ServicesScreenState({required this.alias, required this.filter}) {
    var myFilters = <String>[];
    switch (this.filter) {
      case 'problems':
        myFilters.add(
            '{"op": "=", "left": "state", "right": "${cmk_api.svcStateWarn}"}');
        break;
      case 'unhandled':
        myFilters.add(
            '{"op": "=", "left": "state", "right": "${cmk_api.svcStateCritical}"}');
        break;
      case 'stale':
        myFilters.add(
            '{"op": "=", "left": "state", "right": "${cmk_api.svcStateUnknown}"}');
        break;
      case 'all':
        break;
      default:
        if (this.filter.isNotEmpty) {
          myFilters.add(this.filter);
        }
    }

    params = AliasAndFilterParams(alias: alias, filter: myFilters);
  }

  @override
  void initState() {
    super.initState();
    // Force refresh when page is navigated to
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(servicesProvider(params));
    });
  }

  SlimLayoutSettings settings() {
    var title = 'Services';
    switch (widget.filter) {
      case 'all':
        title = "Services";
        break;
      default:
        title = "Services ${widget.filter}";
    }

    return SlimLayoutSettings(title, showMenu: false);
  }

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(servicesProvider(params));
    final hosts = ref.watch(hostsProvider(AliasAndFilterParams(alias: widget.alias, filter: [])));

    if (services is ServicesLoaded) {
      final hostsList = hosts is HostsLoaded ? hosts.hosts : <cmk_api.Host>[];

      return SlimLayout(
        layoutSettings: settings(),
        child: Column(
          children: [
            SiteStatsWidget(alias: widget.alias),
            Expanded(
              child: ServicesListWidget(
                key: ValueKey('services_${widget.filter}'),
                alias: widget.alias,
                services: services.services,
                hosts: hostsList,
                filter: widget.filter,
              ),
            ),
          ],
        ),
      );
    } else {
      return SlimLayout(
        layoutSettings: settings(),
        child: Column(
          children: [
            SiteStatsWidget(alias: widget.alias),
            const Expanded(child: Center(child: CircularProgressIndicator())),
          ],
        ),
      );
    }
  }
}
