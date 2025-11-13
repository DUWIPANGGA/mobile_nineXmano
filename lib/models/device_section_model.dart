class DeviceSection {
  final String id;
  final String email;
  final int channelCount;
  final int deviceCount;

  DeviceSection({
    required this.id,
    required this.email,
    required this.channelCount,
    required this.deviceCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'channelCount': channelCount,
      'deviceCount': deviceCount,
    };
  }

  factory DeviceSection.fromMap(Map<String, dynamic> map) {
    return DeviceSection(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      channelCount: map['channelCount'] ?? 0,
      deviceCount: map['deviceCount'] ?? 0,
    );
  }
}