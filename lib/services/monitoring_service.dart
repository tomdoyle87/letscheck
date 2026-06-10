import 'dart:async';
import '../providers/host_status_provider.dart'; // Ensure correct relative import to your enum
import 'notification_service.dart';

class MonitoringService {
  final NotificationService _notifications;
  
  // Tracks individual statuses indexed strictly by unique Host Names
  final Map<String, HostState> _hostStateCache = {};

  MonitoringService(this._notifications);

  /// Initializes monitoring parameters
  void start() {
  //_notifications.show("System Active", "LetsCheck monitoring engine is listening for state changes.");
  }

  /// Evaluates host update changes using type-safe custom App Enums.
  void handleStateChange(HostState newState, String hostName) async {
    final HostState? previousState = _hostStateCache[hostName];

    // If the specific host state hasn't altered, exit early to prevent GNOME tray flooding
    if (previousState == newState) return;

    // Persist current snapshot to the tracking map cache
    _hostStateCache[hostName] = newState;

    // Trigger alerts conditionally on active shifts (ignoring unknown boots)
    if (previousState != null) {
      switch (newState) {
        case HostState.critical:
          await _notifications.show("CRITICAL", "Host [$hostName] status check failed: Host is DOWN");
          break;
        case HostState.warning:
          await _notifications.show("Warning", "Host [$hostName] services are degraded");
          break;
        case HostState.ok:
          await _notifications.show("OK", "Host [$hostName] has returned to normal operations.");
          break;
        case HostState.unknown:
          // Silent logging fallback or trace metric if needed
          break;
      }
    } else {
      // First check evaluation fallback: trigger immediate alert if starting in a broken state
      if (newState == HostState.critical) {
        await _notifications.show("CRITICAL", "Host [$hostName] detected as DOWN on monitor boot.");
      }
    }
  }
}
