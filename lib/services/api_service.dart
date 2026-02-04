import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/device_info.dart';

class ApiService {
  static String? _baseUrl;
  static Timer? _heartbeatTimer;
  static Timer? _commandCheckTimer;

  static Future<String> getBaseUrl() async {
    if (_baseUrl != null) return _baseUrl!;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      String? savedUrl = prefs.getString('backend_url');
      
      if (savedUrl != null && savedUrl.isNotEmpty) {
        _baseUrl = savedUrl;
        return _baseUrl!;
      }
      
      String data = await rootBundle.loadString('assets/data.txt');
      _baseUrl = data.trim();
      await prefs.setString('backend_url', _baseUrl!);
      return _baseUrl!;
    } catch (e) {
      print('Error loading backend URL: $e');
      return '';
    }
  }

  static Future<bool> registerDevice(DeviceInfoModel deviceInfo) async {
    try {
      String baseUrl = await getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/api/device/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(deviceInfo.toJson()),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error registering device: $e');
      return false;
    }
  }

  static Future<bool> sendHeartbeat(String deviceId) async {
    try {
      String baseUrl = await getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/api/device/heartbeat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'deviceId': deviceId}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error sending heartbeat: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> checkCommands(String deviceId) async {
    try {
      String baseUrl = await getBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/api/device/commands/$deviceId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error checking commands: $e');
      return null;
    }
  }

  static Future<bool> sendCommandResponse(
      String deviceId, String commandId, Map<String, dynamic> result) async {
    try {
      String baseUrl = await getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/api/device/command-response'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'deviceId': deviceId,
          'commandId': commandId,
          'result': result,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error sending command response: $e');
      return false;
    }
  }

  static void startHeartbeat(String deviceId) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 10),
      (timer) => sendHeartbeat(deviceId),
    );
  }

  static void startCommandCheck(String deviceId, Function(Map<String, dynamic>) onCommand) {
    _commandCheckTimer?.cancel();
    _commandCheckTimer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) async {
        final commands = await checkCommands(deviceId);
        if (commands != null && commands['command'] != null) {
          onCommand(commands);
        }
      },
    );
  }

  static void stopTimers() {
    _heartbeatTimer?.cancel();
    _commandCheckTimer?.cancel();
  }
}
