import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:checkmk_api/checkmk_api.dart' as cmk_api;

class Alert {
  final String id;
  final String title;
  final String body;
  final String connectionAlias;
  final String hostName;
  final String displayName;
  final int state;
  final DateTime timestamp;

  Alert({
    required this.id,
    required this.title,
    required this.body,
    required this.connectionAlias,
    required this.hostName,
    required this.displayName,
    required this.state,
    required this.timestamp,
  });

  Alert copyWith({
    String? id,
    String? title,
    String? body,
    String? connectionAlias,
    String? hostName,
    String? displayName,
    int? state,
    DateTime? timestamp,
  }) {
    return Alert(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      connectionAlias: connectionAlias ?? this.connectionAlias,
      hostName: hostName ?? this.hostName,
      displayName: displayName ?? this.displayName,
      state: state ?? this.state,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

class AlertsState {
  final List<Alert> criticalAlerts;
  final List<Alert> warningAlerts;

  AlertsState({
    this.criticalAlerts = const [],
    this.warningAlerts = const [],
  });

  AlertsState copyWith({
    List<Alert>? criticalAlerts,
    List<Alert>? warningAlerts,
  }) {
    return AlertsState(
      criticalAlerts: criticalAlerts ?? this.criticalAlerts,
      warningAlerts: warningAlerts ?? this.warningAlerts,
    );
  }
}

class AlertsNotifier extends StateNotifier<AlertsState> {
  AlertsNotifier() : super(AlertsState());

  void addAlert({
    required String title,
    required String body,
    required String connectionAlias,
    required cmk_api.Log log,
  }) {
    final alert = Alert(
      id: '$connectionAlias-${log.hostName}-${log.displayName}',
      title: title,
      body: body,
      connectionAlias: connectionAlias,
      hostName: log.hostName,
      displayName: log.displayName,
      state: log.state,
      timestamp: log.time,
    );

    if (log.state == cmk_api.svcStateCritical) {
      // Remove existing alert with same id
      final criticalAlerts = [...state.criticalAlerts]
          .where((a) => a.id != alert.id)
          .toList();

      state = state.copyWith(
        criticalAlerts: [...criticalAlerts, alert],
      );
    } else if (log.state == cmk_api.svcStateWarn) {
      // Remove existing alert with same id
      final warningAlerts = [...state.warningAlerts]
          .where((a) => a.id != alert.id)
          .toList();

      state = state.copyWith(
        warningAlerts: [...warningAlerts, alert],
      );
    }
  }

  void clearAlert({
    required String connectionAlias,
    required cmk_api.Log log,
  }) {
    final id = '$connectionAlias-${log.hostName}-${log.displayName}';

    // Remove from critical alerts regardless of state
    final criticalAlerts = [...state.criticalAlerts]
        .where((a) => a.id != id)
        .toList();

    // Remove from warning alerts regardless of state
    final warningAlerts = [...state.warningAlerts]
        .where((a) => a.id != id)
        .toList();

    state = state.copyWith(
      criticalAlerts: criticalAlerts,
      warningAlerts: warningAlerts,
    );
  }

  void clearAlertsForConnection(String connectionAlias) {
    final criticalAlerts = [...state.criticalAlerts]
        .where((a) => a.connectionAlias != connectionAlias)
        .toList();

    final warningAlerts = [...state.warningAlerts]
        .where((a) => a.connectionAlias != connectionAlias)
        .toList();

    state = state.copyWith(
      criticalAlerts: criticalAlerts,
      warningAlerts: warningAlerts,
    );
  }

  void clearAll() {
    state = AlertsState();
  }
}

final alertsProvider = StateNotifierProvider<AlertsNotifier, AlertsState>((ref) {
  return AlertsNotifier();
});
