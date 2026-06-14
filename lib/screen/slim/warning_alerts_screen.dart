import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:letscheck/providers/alerts/alerts_provider.dart';
import 'package:letscheck/widget/site_stats_widget.dart';
import 'package:letscheck/screen/slim/slim_layout.dart';

class WarningAlertsScreen extends ConsumerWidget {
  final String alias;

  const WarningAlertsScreen({
    super.key,
    required this.alias,
  });

  SlimLayoutSettings layoutSettings() {
    return SlimLayoutSettings('Warning Alerts', showSettings: true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsState = ref.watch(alertsProvider);
    final warningAlerts = alertsState.warningAlerts;

    return SlimLayout(
      layoutSettings: layoutSettings(),
      child: Column(
        children: [
          SiteStatsWidget(alias: alias),
          Expanded(
            child: warningAlerts.isEmpty
                ? const Center(
                    child: Text('No warning alerts'),
                  )
                : ListView.builder(
                    itemCount: warningAlerts.length,
                    itemBuilder: (context, index) {
                      final alert = warningAlerts[index];
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          leading: const Icon(
                            Icons.warning,
                            color: Colors.orange,
                            size: 32,
                          ),
                          title: Text(alert.title),
                          subtitle: Text(alert.body),
                          trailing: Text(
                            '${alert.timestamp.hour}:${alert.timestamp.minute.toString().padLeft(2, '0')}',
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
