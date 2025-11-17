// models/config_show_model.dart
class ConfigShowModel {
  final String firmware;
  final int speedRun;
  final int jumlahChannel;
  final String email;
  final String devID;

  ConfigShowModel({
    required this.firmware,
    required this.speedRun,
    required this.jumlahChannel,
    required this.email,
    required this.devID,
  });

  // Factory constructor untuk parse config2 string
  factory ConfigShowModel.fromConfig2String(String data) {
    final parts = data.split(',');

    print('🔍 [CONFIG2 PARSER] Parsing config2 data with ${parts.length} parts');
    
    // Debug print
    for (int i = 0; i < parts.length; i++) {
      print('   [$i] "${parts[i]}"');
    }

    // Validasi minimum length
    if (parts.length < 6) {
      throw FormatException(
        'Invalid config2 data length: ${parts.length}. Expected at least 6 parts. Data: $data'
      );
    }

    return ConfigShowModel(
      firmware: parts[1],
      speedRun: int.tryParse(parts[2]) ?? 50,
      jumlahChannel: int.tryParse(parts[3]) ?? 16,
      email: parts[4],
      devID: parts[5],
    );
  }

  // Convert ke Map untuk preferences
  Map<String, dynamic> toMap() {
    return {
      'firmware': firmware,
      'speedRun': speedRun,
      'jumlahChannel': jumlahChannel,
      'email': email,
      'devID': devID,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  // Factory dari Map
  factory ConfigShowModel.fromMap(Map<String, dynamic> map) {
    return ConfigShowModel(
      firmware: map['firmware'] as String? ?? '',
      speedRun: map['speedRun'] as int? ?? 50,
      jumlahChannel: map['jumlahChannel'] as int? ?? 16,
      email: map['email'] as String? ?? '',
      devID: map['devID'] as String? ?? '',
    );
  }

  // Copy with method
  ConfigShowModel copyWith({
    String? firmware,
    int? speedRun,
    int? jumlahChannel,
    String? email,
    String? devID,
  }) {
    return ConfigShowModel(
      firmware: firmware ?? this.firmware,
      speedRun: speedRun ?? this.speedRun,
      jumlahChannel: jumlahChannel ?? this.jumlahChannel,
      email: email ?? this.email,
      devID: devID ?? this.devID,
    );
  }

  // Validasi data
  bool get isValid {
    return firmware.isNotEmpty && email.isNotEmpty && devID.isNotEmpty;
  }

  // Summary info
  String get summary {
    return 'ConfigShow: FW $firmware | Speed: $speedRun | Channels: $jumlahChannel | Email: $email';
  }

  // Debug info
  String get debugInfo {
    return '''
ConfigShowModel Debug Info:
- Firmware: $firmware
- Speed Run: $speedRun
- Jumlah Channel: $jumlahChannel
- Email: $email
- Device ID: $devID
''';
  }

  @override
  String toString() {
    return 'ConfigShowModel(firmware: $firmware, speed: $speedRun, channels: $jumlahChannel, email: $email)';
  }
}