class Device {
  final String name;
  final List<String>? users;

  Device({
    required this.name,
    this.users,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      name: json['name'],
      users: (json['users'] as List?)?.cast<String>(),
    );
  }
}
