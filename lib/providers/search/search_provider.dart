import 'package:checkmk_api/checkmk_api.dart' as cmk_api;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:letscheck/providers/providers.dart';
import 'search_state.dart';

class SearchNotifier extends StateNotifier<SearchState> {
  final Ref ref;

  SearchNotifier(this.ref) : super(const SearchInitial());

  Map<String, String> _parseFilters(String query) {
    final filters = <String, String>{};
    final parts = query.trim().split('|');
    var searchTerm = '';

    // Type filters that don't consume the search term
    final typeFilters = ['host', 'service', 'connection'];

    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.contains(':')) {
        final filterParts = trimmed.split(':');
        if (filterParts.length >= 2) {
          final key = filterParts[0].trim().toLowerCase();
          final value = filterParts.sublist(1).join(':').trim();
          
          // Type filters don't consume the search term
          if (typeFilters.contains(key)) {
            filters[key] = ''; // Type filters have no value
            // Add the value as a search term
            if (searchTerm.isNotEmpty) searchTerm += '|';
            searchTerm += value;
          } else {
            // Value filters consume the value
            filters[key] = value;
          }
        }
      } else {
        if (searchTerm.isNotEmpty) searchTerm += '|';
        searchTerm += trimmed;
      }
    }

    if (searchTerm.isNotEmpty) {
      filters['term'] = searchTerm;
    }

    return filters;
  }

  Future<void> search(String query) async {
    if (!mounted) return;

    if (query.isEmpty) {
      state = const SearchInitial();
      return;
    }

    if (state is SearchLoading) return;

    state = SearchLoading(query: query);

    final settings = ref.read(settingsProvider);
    final filters = _parseFilters(query);

    var hosts = <String, Set<cmk_api.Host>>{};
    var services = <String, Set<cmk_api.Service>>{};

    // Filter by connection if specified
    var aliasesToSearch = settings.connections.map((c) => c.alias).toList();
    if (filters.containsKey('connection')) {
      final connectionFilter = filters['connection']!.toLowerCase();
      aliasesToSearch = aliasesToSearch
          .where((alias) => alias.toLowerCase().contains(connectionFilter))
          .toList();
    }

    // Determine what to search
    final searchHosts = !filters.containsKey('service');
    final searchServices = !filters.containsKey('host');

    // Get search term
    final searchTerm = filters['term'] ?? '';

    for (final alias in aliasesToSearch) {
      final client = await ref.read(clientProvider(alias).future);
      final clientState = ref.read(clientStateProvider(alias));

      if (!mounted) return;

      if (clientState.value != cmk_api.ConnectionState.connected) {
        continue;
      }

      try {
        // Build host filters
        var hostFilters = <String>[];
        if (searchTerm.isNotEmpty) {
          // Use OR for multiple search fields when searching by term
          final searchOr = [
            '{"op": "~~", "left": "name", "right": "$searchTerm"}',
            '{"op": "~~", "left": "alias", "right": "$searchTerm"}',
            '{"op": "~~", "left": "address", "right": "$searchTerm"}',
          ];
          hostFilters.add('{"op": "or", "expr": [${searchOr.join(',')}]}');
        }
        if (filters.containsKey('alias')) {
          final aliasTerm = filters['alias'];
          hostFilters.add('{"op": "~~", "left": "alias", "right": "$aliasTerm"}');
        }
        if (filters.containsKey('state')) {
          final stateValue = filters['state'];
          hostFilters.add('{"op": "=", "left": "state", "right": "$stateValue"}');
        }
        if (filters.containsKey('acked')) {
          final acked = filters['acked']?.toLowerCase() == 'true';
          hostFilters.add('{"op": "=", "left": "acknowledged", "right": $acked}');
        }

        // Build service filters
        var serviceFilters = <String>[];
        if (searchTerm.isNotEmpty) {
          // Use OR for multiple search fields when searching by term
          final searchOr = [
            '{"op": "~~", "left": "description", "right": "$searchTerm"}',
            '{"op": "~~", "left": "host_name", "right": "$searchTerm"}',
          ];
          serviceFilters.add('{"op": "or", "expr": [${searchOr.join(',')}]}');
        }
        if (filters.containsKey('alias')) {
          final aliasTerm = filters['alias'];
          serviceFilters.add('{"op": "~~", "left": "host_name", "right": "$aliasTerm"}');
        }
        if (filters.containsKey('state')) {
          final stateValue = filters['state'];
          serviceFilters.add('{"op": "=", "left": "state", "right": "$stateValue"}');
        }
        if (filters.containsKey('acked')) {
          final acked = filters['acked']?.toLowerCase() == 'true';
          serviceFilters.add('{"op": "=", "left": "acknowledged", "right": $acked}');
        }

        // Fetch hosts
        if (searchHosts) {
          final hostsFilter = hostFilters.isNotEmpty
              ? <String>['{"op": "and", "expr": [${hostFilters.join(',')}]}']
              : <String>[];
          final hostsResult = await client.getApiHosts(filter: hostsFilter);

          if (hosts.containsKey(alias)) {
            hosts[alias]!.addAll(hostsResult);
          } else {
            hosts[alias] = hostsResult.toSet();
          }
        }

        // Fetch services
        if (searchServices) {
          final servicesFilter = serviceFilters.isNotEmpty
              ? <String>['{"op": "and", "expr": [${serviceFilters.join(',')}]}']
              : <String>[];
          final servicesResult = await client.getApiServices(filter: servicesFilter);

          if (services.containsKey(alias)) {
            services[alias]!.addAll(servicesResult);
          } else {
            services[alias] = servicesResult.toSet();
          }
        }
      } on cmk_api.NetworkException {
        // Ignore.
      }
    }

    if (!mounted) return;

    state = SearchLoaded(
      query: query,
      hosts: hosts,
      services: services,
    );
  }
}
