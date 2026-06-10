import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../services/monitoring_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

// ---------------- SERVICES ----------------

// 1. Initialize the root desktop notification plugin engine
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// 2. Initialize the tracking service and inject the notification engine into it
final monitoringServiceProvider = Provider<MonitoringService>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return MonitoringService(notificationService);
});

// ---------------- PLATFORM ----------------
// Keep these as UnimplementedError because they are overridden inside main.dart 
// with async platform values (await SharedPreferences.getInstance(), etc.)

final sharedPreferencesProvider =
    Provider<SharedPreferences>((ref) => throw UnimplementedError());

final packageInfoProvider =
    Provider<PackageInfo>((ref) => throw UnimplementedError());
