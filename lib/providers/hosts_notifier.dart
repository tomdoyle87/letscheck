import 'dart:async';

import 'package:checkmk_api/checkmk_api.dart' as cmk_api;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:letscheck/providers/params.dart';
import 'package:letscheck/providers/providers.dart';      // Keeps original hooks working
import 'package:letscheck/providers/hosts_state.dart';
import 'package:letscheck/providers/host_status_provider.dart';
import 'package:letscheck/services/monitoring_service.dart';

class HostsNotifier extends StateNotifier<HostsState> {
  final Ref ref;
  final AliasAndFilterParams params;
  Timer? _refreshTimer;
  late ProviderSubscription<AsyncValue<cmk_api.ConnectionState?>>
      _connectionStateSubscription;

  HostsNotifier(this.ref, this.params) : super(const HostsInitial()) {
    _init();
  }

  Future<void> _init() async {
    _connectionStateSubscription =
        ref.listen(clientStateProvider(params.alias), (previous, next) async {
      if (next.hasValue && next.value == cmk_api.ConnectionState.connected) {
        _startRefreshTimer();
        await _fetchData();
      } else {
        final client = await ref.read(clientProvider(params.alias).future);
        _refreshTimer?.cancel();
        state = HostsError(error: client.error());
      }
    });

    await _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;

    final client = await ref.read(clientProvider(params.alias).future);
    final clientState = ref.read(clientStateProvider(params.alias));

    if (clientState.value != cmk_api.ConnectionState.connected) {
      if (!mounted) return;
      state = HostsError(error: client.error());
      return;
    }

    try {
      final hosts = await client.getApiHosts(filter: params.filter);

      if (!mounted) return;

      // 1. Core UI state assignment
      state = HostsLoaded(hosts: hosts);

      // 2. Map structural values over to your custom background system
      final monitoringService = ref.read(monitoringServiceProvider);

      for (final host in hosts) {
        // Safe mapping fallback checking for extensions properties
        final String currentHostName = host.name ?? 'Unknown Host';
        
        HostState evaluatedEnumState = HostState.unknown;
        final dynamic rawStateValue = host.state;

        if (rawStateValue == 0 || rawStateValue == '0') {
          evaluatedEnumState = HostState.ok;
        } else if (rawStateValue == 1 || rawStateValue == '1') {
          evaluatedEnumState = HostState.critical;
        } else if (rawStateValue == 2 || rawStateValue == '2') {
          evaluatedEnumState = HostState.warning;
        }

        monitoringService.handleStateChange(evaluatedEnumState, currentHostName);
      }

    } on Exception catch (e) {
      if (!mounted) return;
      state = HostsError(error: e);
    }
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    final settings = ref.read(settingsProvider);

    _refreshTimer = Timer.periodic(
      Duration(seconds: settings.refreshSeconds),
      (_) => _fetchData(),
    );
  }

  @override
  void dispose() {
    _connectionStateSubscription.close();
    _refreshTimer?.cancel();
    super.dispose();
  }
}
