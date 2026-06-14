import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:checkmk_api/checkmk_api.dart' as cmk_api;
import 'package:letscheck/providers/alerts/alerts_provider.dart';
import 'package:letscheck/background_service.dart' as bg_service;

class AlertHandler extends ConsumerStatefulWidget {
  const AlertHandler({super.key});

  @override
  ConsumerState<AlertHandler> createState() => _AlertHandlerState();
}

class _AlertHandlerState extends ConsumerState<AlertHandler> {
  @override
  void initState() {
    super.initState();
    _setupAlertListener();
  }

  void _setupAlertListener() {
    if (kIsWeb) return;

    if (Platform.isAndroid || Platform.isIOS) {
      // Mobile platforms use FlutterBackgroundService
      // Note: Need to import FlutterBackgroundService separately for mobile
      // For now, focusing on desktop since that's the primary platform
    } else {
      // Desktop platforms use IsolateBackgroundService
      bg_service.IsolateBackgroundService.instance.on('alert').listen((event) {
        if (event == null) return;
        _handleAlertMessage(event);
      });
    }
  }

  void _handleAlertMessage(Map<String, dynamic> event) {
    final type = event['type'] as String?;
    final title = event['title'] as String?;
    final body = event['body'] as String?;
    final connectionAlias = event['connectionAlias'] as String?;
    final hostName = event['hostName'] as String?;
    final displayName = event['displayName'] as String?;
    final stateValue = event['state'] as int?;
    final timestampStr = event['timestamp'] as String?;

    if (type == null || title == null || body == null ||
        connectionAlias == null || hostName == null ||
        displayName == null || stateValue == null || timestampStr == null) {
      return;
    }

    final timestamp = DateTime.parse(timestampStr);

    // Create a mock Log object for the provider
    final log = cmk_api.Log(
      time: timestamp,
      hostName: hostName,
      displayName: displayName,
      state: stateValue,
      pluginOutput: body,
    );

    final alertsNotifier = ref.read(alertsProvider.notifier);

    if (type == 'add') {
      alertsNotifier.addAlert(
        title: title,
        body: body,
        connectionAlias: connectionAlias,
        log: log,
      );
    } else if (type == 'clear') {
      alertsNotifier.clearAlert(
        connectionAlias: connectionAlias,
        log: log,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
