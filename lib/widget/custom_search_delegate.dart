import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:letscheck/providers/providers.dart';
import 'package:letscheck/providers/search/search_state.dart';
import 'package:letscheck/providers/services/services_util.dart';
import 'package:letscheck/widget/host_card_widget.dart';
import 'package:letscheck/widget/services_grouped_card_widget.dart';

class CustomSearchDelegate extends SearchDelegate {
  CustomSearchDelegate()
      : super(
          searchFieldLabel: 'Search...',
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.search,
        );

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    if (theme.colorScheme.brightness == Brightness.dark) {
      return theme.copyWith(
        primaryColor: theme.colorScheme.primary,
        secondaryHeaderColor: Colors.black,
        primaryIconTheme: theme.primaryIconTheme.copyWith(color: Colors.black),
      );
    } else {
      return theme;
    }
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.search_off),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Check if query contains filters or has sufficient length
    final hasFilters = query.contains(':');
    final hasSearchTerm = query.length >= 3;

    if (!hasFilters && !hasSearchTerm) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (query.isEmpty)
                Text(
                  'Search Instructions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              if (query.isEmpty) SizedBox(height: 16),
              if (query.isEmpty)
                Text(
                  'Use filters to narrow your search:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              if (query.isEmpty) SizedBox(height: 8),
              if (query.isEmpty)
                Text('• connection: <name> - Filter by connection name'),
              if (query.isEmpty)
                Text('• host: - Search only hosts'),
              if (query.isEmpty)
                Text('• service: - Search only services'),
              if (query.isEmpty)
                Text('• state: <0|1|2|3> - Filter by state'),
              if (query.isEmpty)
                Text('• acked: <true|false> - Filter by acknowledged status'),
              if (query.isEmpty) SizedBox(height: 16),
              if (query.isEmpty)
                Text(
                  'Search includes names, aliases, IP addresses, and descriptions',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              if (query.isEmpty) SizedBox(height: 16),
              if (query.isEmpty)
                Text(
                  'Examples:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              if (query.isEmpty) SizedBox(height: 8),
              if (query.isEmpty) Text('• server - Basic text search'),
              if (query.isEmpty) Text('• webserver - Searches host aliases too'),
              if (query.isEmpty) Text('• cpu|memory - Multiple terms'),
              if (query.isEmpty) Text('• host: server - Hosts only'),
              if (query.isEmpty) Text('• service: cpu - Services only'),
              if (query.isEmpty) Text('• state: 2 - Critical items'),
              if (query.isEmpty) Text('• Combine filters: host: state: 1'),
              if (!query.isEmpty)
                Center(
                  child: Text(
                    'Search term must be longer than two letters or use filters.',
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Create a RiverPod ConsumerWidget
    return SearchResultView(query: query);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // Show instructions when the search bar is empty
    if (query.isEmpty) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Search Instructions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'Use filters to narrow your search:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• connection: <name> - Filter by connection name'),
              Text('• host: - Search only hosts'),
              Text('• service: - Search only services'),
              Text('• state: <0|1|2|3> - Filter by state'),
              Text('• acked: <true|false> - Filter by acknowledged status'),
              SizedBox(height: 16),
              Text(
                'Search includes names, aliases, IP addresses, and descriptions',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
              SizedBox(height: 16),
              Text(
                'Examples:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• server - Basic text search'),
              Text('• webserver - Searches host aliases too'),
              Text('• cpu|memory - Multiple terms'),
              Text('• host: server - Hosts only'),
              Text('• service: cpu - Services only'),
              Text('• state: 2 - Critical items'),
              Text('• Combine filters: host: state: 1'),
            ],
          ),
        ),
      );
    }
    return Column();
  }
}

class SearchResultView extends ConsumerStatefulWidget {
  final String query;

  const SearchResultView({super.key, required this.query});

  @override
  ConsumerState<SearchResultView> createState() => _SearchResultViewState();
}

class _SearchResultViewState extends ConsumerState<SearchResultView> {
  @override
  void initState() {
    super.initState();
    Future(() {
      if (mounted) {
        ref.read(searchProvider.notifier).search(widget.query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final search = ref.watch(searchProvider);

    if (search is! SearchLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    var groupItems = <dynamic>[];
    search.hosts.forEach((alias, hosts) {
      for (var host in hosts) {
        groupItems
            .add({'group': '$alias: Hosts', 'alias': alias, 'host': host});
      }
    });
    search.services.forEach((alias, services) {
      final groupedServices =
          servicesGroupByHostname(services: services.toList());

      groupedServices.forEach((_, hServices) {
        groupItems.add({
          'group': '$alias: Services',
          'alias': alias,
          'services': hServices
        });
      });
    });

    if (groupItems.isEmpty) {
      return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Center(
                child: Column(
              children: <Widget>[
                Text(
                  'No Results Found.',
                ),
              ],
            ))
          ]);
    } else {
      return GroupedListView<dynamic, String>(
        elements: groupItems,
        groupBy: (element) => element['group'],
        groupComparator: (value1, value2) => value2.compareTo(value1),
        useStickyGroupSeparators: false,
        groupSeparatorBuilder: (String value) => Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        itemBuilder: (context, element) {
          if (element.containsKey('host')) {
            return HostCardWidget(
                alias: element['alias'], host: element['host']);
          }
          // Service
          return ServicesGroupedCardWidget(
              alias: element['alias'],
              groupName: element['services'][0].hostName,
              services: element['services']);
        },
      );
    }
  }
}
