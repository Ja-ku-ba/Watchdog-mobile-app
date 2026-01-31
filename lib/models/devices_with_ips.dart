class DeviceWithIp {
  final String device_name;
  final String device_ip;

  DeviceWithIp({
    required this.device_name,
    required this.device_ip,
  });

  factory DeviceWithIp.fromJson(Map<String, dynamic> json) {
    return DeviceWithIp(
      device_name: json['device_name'],
      device_ip: json['device_ip'],
    );
  }
}
