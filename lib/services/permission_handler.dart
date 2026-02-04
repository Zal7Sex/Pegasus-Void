import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestAllPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.storage,
      Permission.location,
      Permission.phone,
      Permission.notification,
      Permission.scheduleExactAlarm,
      Permission.ignoreBatteryOptimizations,
    ].request();

    bool allGranted = true;
    statuses.forEach((permission, status) {
      if (!status.isGranted) {
        allGranted = false;
        print('Permission ${permission.toString()} ditolak');
      }
    });

    return allGranted;
  }

  static Future<bool> checkAllPermissions() async {
    bool cameraGranted = await Permission.camera.isGranted;
    bool storageGranted = await Permission.storage.isGranted;
    bool locationGranted = await Permission.location.isGranted;
    bool phoneGranted = await Permission.phone.isGranted;
    bool notificationGranted = await Permission.notification.isGranted;

    return cameraGranted &&
        storageGranted &&
        locationGranted &&
        phoneGranted &&
        notificationGranted;
  }

  static Future<void> requestBatteryOptimization() async {
    if (!await Permission.ignoreBatteryOptimizations.isGranted) {
      await Permission.ignoreBatteryOptimizations.request();
    }
  }
}
