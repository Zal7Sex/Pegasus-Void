class DeviceInfoModel {
  final String deviceId;
  final String deviceName;
  final String model;
  final String brand;
  final String osVersion;
  final String appVersion;
  final DateTime lastSeen;
  final bool isOnline;

  DeviceInfoModel({
    required this.deviceId,
    required this.deviceName,
    required this.model,
    required this.brand,
    required this.osVersion,
    required this.appVersion,
    required this.lastSeen,
    required this.isOnline,
  });

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'model': model,
      'brand': brand,
      'osVersion': osVersion,
      'appVersion': appVersion,
      'lastSeen': lastSeen.toIso8601String(),
      'isOnline': isOnline,
    };
  }

  factory DeviceInfoModel.fromJson(Map<String, dynamic> json) {
    return DeviceInfoModel(
      deviceId: json['deviceId'] ?? '',
      deviceName: json['deviceName'] ?? '',
      model: json['model'] ?? '',
      brand: json['brand'] ?? '',
      osVersion: json['osVersion'] ?? '',
      appVersion: json['appVersion'] ?? '',
      lastSeen: DateTime.parse(json['lastSeen'] ?? DateTime.now().toIso8601String()),
      isOnline: json['isOnline'] ?? false,
    );
  }
}
