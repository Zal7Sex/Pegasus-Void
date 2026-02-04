import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../services/background_service.dart';
import '../services/permission_handler.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _serviceRunning = false;
  bool _permissionsGranted = false;
  String _deviceId = '';
  String _deviceInfo = '';
  String _backendUrl = '';
  String _connectionStatus = 'Disconnected';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _loadDeviceInfo();
    await _checkPermissions();
    await _loadBackendUrl();
    await _checkServiceStatus();
  }

  Future<void> _loadDeviceInfo() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedDeviceId = prefs.getString('device_id');

    if (savedDeviceId == null) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      savedDeviceId = androidInfo.id;
      await prefs.setString('device_id', savedDeviceId);
    }

    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;

    setState(() {
      _deviceId = savedDeviceId!;
      _deviceInfo = '${androidInfo.brand} ${androidInfo.model}\nAndroid ${androidInfo.version.release}';
    });
  }

  Future<void> _loadBackendUrl() async {
    String url = await ApiService.getBaseUrl();
    setState(() {
      _backendUrl = url;
    });
  }

  Future<void> _checkPermissions() async {
    bool granted = await PermissionService.checkAllPermissions();
    setState(() {
      _permissionsGranted = granted;
    });
  }

  Future<void> _requestPermissions() async {
    bool granted = await PermissionService.requestAllPermissions();
    await PermissionService.requestBatteryOptimization();
    
    setState(() {
      _permissionsGranted = granted;
    });

    if (granted) {
      _showSnackbar('Semua permission diberikan!', Colors.green);
    } else {
      _showSnackbar('Beberapa permission ditolak', Colors.orange);
    }
  }

  Future<void> _checkServiceStatus() async {
    // Simulate checking service status
    setState(() {
      _serviceRunning = true;
      _connectionStatus = 'Connected';
    });
  }

  Future<void> _startService() async {
    if (!_permissionsGranted) {
      _showSnackbar('Harap izinkan semua permission terlebih dahulu', Colors.red);
      return;
    }

    try {
      await BackgroundService.initializeService();
      setState(() {
        _serviceRunning = true;
        _connectionStatus = 'Connected';
      });
      _showSnackbar('Service berhasil dijalankan', Colors.green);
    } catch (e) {
      _showSnackbar('Gagal menjalankan service: $e', Colors.red);
    }
  }

  Future<void> _stopService() async {
    try {
      await BackgroundService.stopService();
      setState(() {
        _serviceRunning = false;
        _connectionStatus = 'Disconnected';
      });
      _showSnackbar('Service dihentikan', Colors.orange);
    } catch (e) {
      _showSnackbar('Gagal menghentikan service: $e', Colors.red);
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blue, width: 2),
                      ),
                      child: const Icon(
                        Icons.devices,
                        size: 50,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'PEGASUS VOID',
                      style: TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Background Device Controller',
                      style: TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 12,
                        color: Colors.blue.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Connection Status
              _buildInfoCard(
                title: 'CONNECTION STATUS',
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _serviceRunning ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _connectionStatus,
                      style: TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 16,
                        color: _serviceRunning ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Device Info
              _buildInfoCard(
                title: 'DEVICE INFORMATION',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Device ID', _deviceId),
                    const SizedBox(height: 10),
                    _buildInfoRow('Device', _deviceInfo),
                    const SizedBox(height: 10),
                    _buildInfoRow('Backend', _backendUrl),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Permissions Status
              _buildInfoCard(
                title: 'PERMISSIONS',
                child: Row(
                  children: [
                    Icon(
                      _permissionsGranted ? Icons.check_circle : Icons.cancel,
                      color: _permissionsGranted ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _permissionsGranted ? 'All Granted' : 'Not Granted',
                      style: TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 14,
                        color: _permissionsGranted ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Action Buttons
              if (!_permissionsGranted)
                _buildActionButton(
                  'REQUEST PERMISSIONS',
                  Icons.security,
                  Colors.orange,
                  _requestPermissions,
                ),

              if (_permissionsGranted && !_serviceRunning)
                _buildActionButton(
                  'START SERVICE',
                  Icons.play_arrow,
                  Colors.green,
                  _startService,
                ),

              if (_serviceRunning)
                _buildActionButton(
                  'STOP SERVICE',
                  Icons.stop,
                  Colors.red,
                  _stopService,
                ),

              const SizedBox(height: 20),

              // Info Text
              Center(
                child: Text(
                  _serviceRunning
                      ? 'Service berjalan di background\nDevice siap dikontrol'
                      : 'Service tidak aktif',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'ShareTechMono',
                    fontSize: 12,
                    color: Colors.blue.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'ShareTechMono',
              fontSize: 12,
              color: Colors.blue.withOpacity(0.7),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'ShareTechMono',
            fontSize: 11,
            color: Colors.blue.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'ShareTechMono',
            fontSize: 13,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
      String text, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                fontFamily: 'ShareTechMono',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
