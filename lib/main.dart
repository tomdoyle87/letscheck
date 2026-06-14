import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, LicenseRegistry, LicenseEntryWithLineBreaks;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// UI Windows & Tray controls
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:tray_manager/src/helpers/sandbox.dart' show runningInSandbox;

// Storage, Platform Specs, Locales, Logging & Debugging
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:talker/talker.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger.dart';

// Timezone imports
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// Internal Project Modules
import 'package:letscheck/platform_interfaces/javascript/javascript.dart';
import 'package:letscheck/providers/providers.dart'; 
import 'package:letscheck/providers/params.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'services/notification_service.dart';
import 'services/monitoring_service.dart';
import 'package:letscheck/widget/alert_handler.dart';

// Blending background definitions while hiding duplicates
import 'providers/app_providers.dart' hide sharedPreferencesProvider, packageInfoProvider;

import 'router.dart';
import 'theme_data.dart';
import 'background_service.dart' as bg_service;

final StreamController<NotificationResponse> selectNotificationStream =
    StreamController<NotificationResponse>.broadcast();

const MethodChannel platform = MethodChannel('jochum.dev/letscheck');
const String portName = 'notification_send_port';

const double ultraWideLayoutThreshold = 1920;
const double wideLayoutThreshold = 1200;

Future<void> _configureLocalTimeZone() async {
  if (kIsWeb || Platform.isLinux) return;

  tz.initializeTimeZones();

  if (Platform.isWindows) return;

  final String timeZoneName = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timeZoneName));
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  LicenseRegistry.addLicense(() async* {
    final fontsLicense = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], fontsLicense);
  });

  if (!kIsWeb) {
    await _configureLocalTimeZone();
  }

  final prefs = await SharedPreferences.getInstance();

  // ---------------- WINDOW MANAGER ----------------
  if (!kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
    await windowManager.ensureInitialized();
    await windowManager.setPreventClose(true);

    WindowOptions windowOptions = const WindowOptions(
      size: Size(800, 1000),
      center: false,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      // START MINIMIZED TO TRAY
      await windowManager.hide();
    });
  }

  // ---------------- TRAY MANAGER ----------------
  if (!kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
    await trayManager.setIcon(
      Platform.isWindows
          ? 'assets/icons/letscheck.ico'
          : Platform.isLinux && runningInSandbox()
              ? 'io.github.jochumdev.letscheck'
              : 'assets/icons/letscheck.png',
    );

    if (!Platform.isWindows) {
      await trayManager.setTitle("LetsCheck");
    }

    Menu menu = Menu(
      items: [
        MenuItem(key: 'show_window', label: 'Show Window'),
        MenuItem.separator(),
        MenuItem(key: 'exit_app', label: 'Exit App'),
      ],
    );

    await trayManager.setContextMenu(menu);
  }

  await initializeDateFormatting(Intl.defaultLocale);

  // ---------------- LOGGING & RUNTIME SETUP ----------------
  final talker = Talker(logger: TalkerLogger(formatter: ColoredLoggerFormatter()));
  
  JavascriptRuntimeWrapper? jsRuntime;
  try {
    jsRuntime = await initJavascriptRuntime();
  } catch (e) {
    print('Failed to initialize JavaScript runtime: $e');
  }
  
  final packageInfo = await PackageInfo.fromPlatform();

  // ---------------- NOTIFICATION & BACKGROUND CHANNELS ----------------
  final notificationService = NotificationService();
  final monitoringService = MonitoringService(notificationService);

  // 1. Hook up the local notifications configuration
  await notificationService.init();

  // 2. STABILIZATION FIX: spin up background communication channels
  await bg_service.initialize(talker);
  
  // SAFETY HANDSHAKE: Ensure the background isolate thread is fully spun up 
  // before we fire the 'start' signal to the notifier logic.
  await Future.delayed(const Duration(seconds: 2));
  bg_service.start();

  // 3. Begin tracking tasks
  monitoringService.start();

  // ---------------- APPLICATION INJECTION ----------------
  final container = ProviderContainer(
    observers: [
      TalkerRiverpodObserver(
        settings: TalkerRiverpodLoggerSettings(
          enabled: true,
          printProviderAdded: true,
          printProviderUpdated: false,
          printProviderDisposed: true,
          printProviderFailed: true,
        ),
        talker: talker,
      ),
    ],
    overrides: [
      talkerProvider.overrideWithValue(talker),
      sharedPreferencesProvider.overrideWithValue(prefs),
      if (jsRuntime != null) javascriptRuntimeProvider.overrideWithValue(jsRuntime),
      packageInfoProvider.overrideWithValue(packageInfo),
      notificationServiceProvider.overrideWithValue(notificationService),
      monitoringServiceProvider.overrideWithValue(monitoringService),
    ],
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const App(),
    ),
  );

  // ---------------- BACKGROUND ENGINE FORCE TRIGGER ----------------
  container.read(monitoringServiceProvider);

  final settings = container.read(settingsProvider);
  if (settings.connections.isNotEmpty) {
    for (final connection in settings.connections) {
      final monitorParams = AliasAndFilterParams(
        alias: connection.alias,
        filter: const [], 
      );

      container.listen(
        hostsProvider(monitorParams), 
        (previous, next) {
          // No-op closure keeps the provider channel alive in the background tray
        },
      );
    }
  }
}

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with TrayListener, WindowListener {

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
      trayManager.addListener(this);
      windowManager.addListener(this);
    }
  }

  @override
  void dispose() {
    if (!kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
      trayManager.removeListener(this);
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onWindowClose() async {
    await windowManager.hide();
  }

  @override
  Future<void> onWindowMinimize() async {
    await windowManager.hide();
  }

  @override
  Future<void> onTrayMenuItemClick(MenuItem menuItem) async {
    if (menuItem.key == 'show_window' || menuItem.key == 'show') {
      await windowManager.show();
      await windowManager.focus();
    } else if (menuItem.key == 'exit_app' || menuItem.key == 'exit') {
      await windowManager.destroy();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLightMode = ref.watch(settingsProvider.select((s) => s.isLightMode));
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      title: 'LetsCheck',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: isLightMode ? ThemeMode.light : ThemeMode.dark,
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            const AlertHandler(),
          ],
        );
      },
    );
  }
}
