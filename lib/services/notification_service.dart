import 'dart:io' show Platform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      linux: initializationSettingsLinux,
    );

    await _plugin.initialize(initializationSettings);
  }

  Future<void> show(String title, String body) async {
    LinuxNotificationUrgency linuxUrgency = LinuxNotificationUrgency.normal;
    
    // Crucial for GNOME: Critical urgency breaks the desktop group/silence rules
    if (title.toUpperCase() == 'CRITICAL' || title.toUpperCase() == 'WARNING') {
      linuxUrgency = LinuxNotificationUrgency.critical;
    }

    final NotificationDetails details = NotificationDetails(
      linux: LinuxNotificationDetails(
        urgency: linuxUrgency,
        resident: true,       // Ensures it sticks in the GNOME calendar banner history tray
        suppressSound: false, // Ensures it pings the desktop environment sound server
      ),
      android: const AndroidNotificationDetails(
        'letscheck_alerts',
        'LetsCheck Alerts',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    // Forces a totally unique system window ID using the current microsecond epoch 
    // to stop the GNOME notification window daemon from overwriting/merging active popups.
    final uniqueId = DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF;

    await _plugin.show(uniqueId, title, body, details);
  }
}
