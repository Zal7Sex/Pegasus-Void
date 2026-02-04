import 'dart:io';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:torch_light/torch_light.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class DeviceController {
  static bool _flashlightOn = false;

  // Toggle Flashlight
  static Future<Map<String, dynamic>> toggleFlashlight(bool turnOn) async {
    try {
      if (turnOn) {
        await TorchLight.enableTorch();
        _flashlightOn = true;
      } else {
        await TorchLight.disableTorch();
        _flashlightOn = false;
      }
      
      return {
        'success': true,
        'message': 'Flashlight ${turnOn ? "dinyalakan" : "dimatikan"}',
        'state': _flashlightOn,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
        'state': _flashlightOn,
      };
    }
  }

  // Vibrate Device
  static Future<Map<String, dynamic>> vibrateDevice(int duration) async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        await Vibration.vibrate(duration: duration);
        return {
          'success': true,
          'message': 'Device bergetar selama $duration ms',
        };
      } else {
        return {
          'success': false,
          'message': 'Device tidak memiliki vibrator',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // Change Wallpaper
  static Future<Map<String, dynamic>> changeWallpaper(String imageUrl) async {
    try {
      // Download image
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': 'Gagal download gambar',
        };
      }

      // Save to temporary directory
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/wallpaper.jpg');
      await file.writeAsBytes(response.bodyBytes);

      // Set wallpaper using platform channel
      const platform = MethodChannel('com.pegasus.void/wallpaper');
      await platform.invokeMethod('setWallpaper', {'path': file.path});

      return {
        'success': true,
        'message': 'Wallpaper berhasil diubah',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // Get Device Status
  static Future<Map<String, dynamic>> getDeviceStatus() async {
    try {
      return {
        'success': true,
        'flashlight': _flashlightOn,
        'battery': await _getBatteryLevel(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  static Future<int> _getBatteryLevel() async {
    try {
      const platform = MethodChannel('com.pegasus.void/battery');
      final int batteryLevel = await platform.invokeMethod('getBatteryLevel');
      return batteryLevel;
    } catch (e) {
      print('Error getting battery: $e');
      return -1;
    }
  }

  // Execute Command
  static Future<Map<String, dynamic>> executeCommand(Map<String, dynamic> command) async {
    String commandType = command['command'] ?? '';
    Map<String, dynamic> params = command['params'] ?? {};

    switch (commandType) {
      case 'flashlight':
        return await toggleFlashlight(params['turnOn'] ?? false);
      
      case 'vibrate':
        return await vibrateDevice(params['duration'] ?? 500);
      
      case 'wallpaper':
        return await changeWallpaper(params['imageUrl'] ?? '');
      
      case 'status':
        return await getDeviceStatus();
      
      default:
        return {
          'success': false,
          'message': 'Unknown command: $commandType',
        };
    }
  }
}
