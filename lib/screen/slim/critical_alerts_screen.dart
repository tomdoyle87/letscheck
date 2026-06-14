import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:letscheck/providers/alerts/alerts_provider.dart';
import 'package:letscheck/widget/site_stats_widget.dart';
import 'package:letscheck/screen/slim/slim_layout.dart';

class CriticalAlertsScreen extends ConsumerStatefulWidget {
  final String alias;

  const CriticalAlertsScreen({
    super.key,
    required this.alias,
  });

  @override
  ConsumerState<CriticalAlertsScreen> createState() => _CriticalAlertsScreenState();
}

class _CriticalAlertsScreenState extends ConsumerState<CriticalAlertsScreen> {
  @override
  void initState() {
    super.initState();
    // Clear alerts for this connection when page is navigated to
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(alertsProvider.notifier).clearAlertsForConnection(widget.alias);
    });
  }

  SlimLayoutSettings layoutSettings() {
    return SlimLayoutSettings('Critical Alerts', showSettings: true);
  }

  @override
  Widget build(BuildContext context) {
    final alertsState = ref.watch(alertsProvider);
    final criticalAlerts = alertsState.criticalAlerts;

    return SlimLayout(
      layoutSettings: layoutSettings(),
      child: Column(
        children: [
          SiteStatsWidget(alias: widget.alias),
          Expanded(
            child: criticalAlerts.isEmpty
                ? const Center(
                    child: Text('No critical alerts'),
                  )
                : ListView.builder(
                    itemCount: criticalAlerts.length,
                    itemBuilder: (context, index) {
                      final alert = criticalAlerts[index];
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          leading: const Icon(
                            Icons.error,
                            color: Colors.red,
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
