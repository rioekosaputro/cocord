import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Android foreground service that keeps the radio (mic, voice mesh, MQTT
/// link, boombox) alive while the app is in the background.
class BackgroundService {
  static bool _inited = false;

  static void _init() {
    if (_inited) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'freqwave_radio',
        channelName: 'FreqWave Radio',
        channelDescription: 'Shown while FreqWave is tuned in to a frequency.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
    _inited = true;
  }

  static Future<void> requestNotificationPermission() async {
    if (!Platform.isAndroid) return;
    try {
      final p = await FlutterForegroundTask.checkNotificationPermission();
      if (p != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }
    } catch (e) {
      debugPrint('[Background] notification permission: $e');
    }
  }

  static Future<void> start({
    required String text,
    required bool micGranted,
  }) async {
    if (!Platform.isAndroid) return;
    _init();
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.updateService(
          notificationTitle: 'FreqWave // ON AIR',
          notificationText: text,
        );
        return;
      }
      final result = await FlutterForegroundTask.startService(
        serviceId: 4801,
        serviceTypes: [
          if (micGranted) ForegroundServiceTypes.microphone,
          ForegroundServiceTypes.mediaPlayback,
        ],
        notificationTitle: 'FreqWave // ON AIR',
        notificationText: text,
      );
      if (result is ServiceRequestFailure) {
        debugPrint('[Background] start failed: ${result.error}');
      }
    } catch (e) {
      debugPrint('[Background] start error: $e');
    }
  }

  static Future<void> update(String text) async {
    if (!Platform.isAndroid || !_inited) return;
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.updateService(notificationText: text);
      }
    } catch (e) {
      debugPrint('[Background] update error: $e');
    }
  }

  static Future<void> stop() async {
    if (!Platform.isAndroid || !_inited) return;
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
    } catch (e) {
      debugPrint('[Background] stop error: $e');
    }
  }

  static void minimize() {
    if (Platform.isAndroid) FlutterForegroundTask.minimizeApp();
  }
}
