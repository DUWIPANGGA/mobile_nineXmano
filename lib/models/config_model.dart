// models/config_model.dart
class ConfigModel {
  final String firmware;
  final String mac;
  final int typeLicense;
  final int jumlahChannel;
  final String email;
  final String ssid;
  final String password;
  final int delay1;
  final int delay2;
  final int delay3;
  final int delay4;
  final int selection1;
  final int selection2;
  final int selection3;
  final int selection4;
  final String devID;
  final String mitraID;
  final int animWelcome;
  final int durasiWelcome;
  final List<int> trigger1Data;
  final List<int> trigger2Data;
  final List<int> trigger3Data;
  final int trigger1Mode;
  final int trigger2Mode;
  final int trigger3Mode;
  final int quickTrigger;

  ConfigModel({
    required this.firmware,
    required this.mac,
    required this.typeLicense,
    required this.jumlahChannel,
    required this.email,
    required this.ssid,
    required this.password,
    required this.delay1,
    required this.delay2,
    required this.delay3,
    required this.delay4,
    required this.selection1,
    required this.selection2,
    required this.selection3,
    required this.selection4,
    required this.devID,
    required this.mitraID,
    required this.animWelcome,
    required this.durasiWelcome,
    required this.trigger1Data,
    required this.trigger2Data,
    required this.trigger3Data,
    required this.trigger1Mode,
    required this.trigger2Mode,
    required this.trigger3Mode,
    required this.quickTrigger,
  });

  // Factory constructor untuk parse dari string Arduino
  // models/config_model.dart - FIXED VERSION
// In models/config_model.dart - FIXED VERSION
// models/config_model.dart - PERBAIKAN PARSING TRIGGER DATA
factory ConfigModel.fromArduinoString(String data) {
  final parts = data.split(',');

  print('🔍 [PARSER] Parsing config data with ${parts.length} parts');
  
  // Debug: Print all parts for analysis
  for (int i = 0; i < parts.length; i++) {
    print('   [$i] "${parts[i]}"');
  }

  // Validate minimum length based on your data structure
  if (parts.length < 54) {
    throw FormatException(
      'Invalid config data length: ${parts.length}. Expected at least 54 parts. Data: $data'
    );
  }

  try {
    // PERBAIKAN: Parse trigger data arrays (10 elements each) dengan index yang benar
    final trigger1Data = List.generate(10, (index) {
      final value = int.tryParse(parts[20 + index]) ?? 0;
      return value;
    });
    
    final trigger2Data = List.generate(10, (index) {
      final value = int.tryParse(parts[30 + index]) ?? 0;
      return value;
    });
    
    final trigger3Data = List.generate(10, (index) {
      final value = int.tryParse(parts[40 + index]) ?? 0;
      return value;
    });

    // PERBAIKAN: Debug trigger data dengan lebih detail
    print('🎯 [PARSER] Trigger1 Data (indices 20-29):');
    for (int i = 20; i <= 29; i++) {
      print('   - Index $i: "${parts[i]}" -> ${int.tryParse(parts[i]) ?? 0}');
    }
    
    print('🎯 [PARSER] Trigger2 Data (indices 30-39):');
    for (int i = 30; i <= 39; i++) {
      print('   - Index $i: "${parts[i]}" -> ${int.tryParse(parts[i]) ?? 0}');
    }
    
    print('🎯 [PARSER] Trigger3 Data (indices 40-49):');
    for (int i = 40; i <= 49; i++) {
      print('   - Index $i: "${parts[i]}" -> ${int.tryParse(parts[i]) ?? 0}');
    }

    print('🎯 [PARSER] Trigger Modes:');
    print('   - Trigger1 Mode (index 50): "${parts[50]}" -> ${int.tryParse(parts[50]) ?? 0}');
    print('   - Trigger2 Mode (index 51): "${parts[51]}" -> ${int.tryParse(parts[51]) ?? 0}');
    print('   - Trigger3 Mode (index 52): "${parts[52]}" -> ${int.tryParse(parts[52]) ?? 0}');
    print('   - Quick Trigger (index 53): "${parts[53]}" -> ${int.tryParse(parts[53]) ?? 0}');

    final config = ConfigModel(
      firmware: parts[1],
      mac: parts[2],
      typeLicense: int.tryParse(parts[3]) ?? 0,
      jumlahChannel: int.tryParse(parts[4]) ?? 0,
      email: parts[5],
      ssid: parts[6],
      password: parts[7],
      delay1: int.tryParse(parts[8]) ?? 0,
      delay2: int.tryParse(parts[9]) ?? 0,
      delay3: int.tryParse(parts[10]) ?? 0,
      delay4: int.tryParse(parts[11]) ?? 0,
      selection1: int.tryParse(parts[12]) ?? 0,
      selection2: int.tryParse(parts[13]) ?? 0,
      selection3: int.tryParse(parts[14]) ?? 0,
      selection4: int.tryParse(parts[15]) ?? 0,
      devID: parts[16],
      mitraID: parts[17],
      animWelcome: int.tryParse(parts[18]) ?? 0,
      durasiWelcome: (int.tryParse(parts[19]) ?? 1) - 1, // Convert back to 0-based
      trigger1Data: trigger1Data,
      trigger2Data: trigger2Data,
      trigger3Data: trigger3Data,
      trigger1Mode: int.tryParse(parts[50]) ?? 0, // Fixed index
      trigger2Mode: int.tryParse(parts[51]) ?? 0, // Fixed index
      trigger3Mode: int.tryParse(parts[52]) ?? 0, // Fixed index
      quickTrigger: (int.tryParse(parts[53]) ?? 1), // Fixed index
    );

    print('✅ [PARSER] Config parsed successfully: ${config.summary}');
    
    // PERBAIKAN: Print trigger data yang sudah di-parse
    print('🎯 [PARSER] Parsed Trigger Data:');
    print('   - Trigger1: ${parts[50]}');
    print('   - Trigger2: ${parts[51]}');
    print('   - Trigger3: ${parts[52]}');
    
    return config;
    
  } catch (e, stackTrace) {
    print('❌ [PARSER] Error parsing config data: $e');
    print('📋 [PARSER] Stack trace: $stackTrace');
    rethrow;
  }
}
  // Helper untuk parse trigger data - ENHANCED VERSION
static List<int> _parseTriggerData(List<String> parts, int startIndex, int length) {
  try {
    return List.generate(length, (index) {
      final partIndex = startIndex + index;
      if (partIndex < parts.length) {
        final value = int.tryParse(parts[partIndex]) ?? 0;
        // Validate trigger data range (typically 0-255 for bytes)
        return value.clamp(0, 255);
      }
      return 0;
    });
  } catch (e) {
    print('❌ [PARSER] Error parsing trigger data at index $startIndex: $e');
    return List.filled(length, 0);
  }
}

  // Convert ke Map untuk disimpan di preferences
  Map<String, dynamic> toMap() {
  return {
    'firmware': firmware,
    'mac': mac,
    'typeLicense': typeLicense,
    'jumlahChannel': jumlahChannel,
    'email': email,
    'ssid': ssid,
    'password': password,
    'delay1': delay1,
    'delay2': delay2,
    'delay3': delay3,
    'delay4': delay4,
    'selection1': selection1,
    'selection2': selection2,
    'selection3': selection3,
    'selection4': selection4,
    'devID': devID,
    'mitraID': mitraID,
    'animWelcome': animWelcome,
    'durasiWelcome': durasiWelcome,
    'trigger1Data': trigger1Data,
    'trigger2Data': trigger2Data,
    'trigger3Data': trigger3Data,
    'trigger1Mode': trigger1Mode,
    'trigger2Mode': trigger2Mode,
    'trigger3Mode': trigger3Mode,
    'quickTrigger': quickTrigger,
    'lastUpdated': DateTime.now().toIso8601String(),
    'isValid': isValid,
  };
}
  // Factory dari Map
  factory ConfigModel.fromMap(Map<String, dynamic> map) {
    return ConfigModel(
      firmware: map['firmware'] as String? ?? '',
      mac: map['mac'] as String? ?? '',
      typeLicense: map['typeLicense'] as int? ?? 0,
      jumlahChannel: map['jumlahChannel'] as int? ?? 0,
      email: map['email'] as String? ?? '',
      ssid: map['ssid'] as String? ?? '',
      password: map['password'] as String? ?? '',
      delay1: map['delay1'] as int? ?? 0,
      delay2: map['delay2'] as int? ?? 0,
      delay3: map['delay3'] as int? ?? 0,
      delay4: map['delay4'] as int? ?? 0,
      selection1: map['selection1'] as int? ?? 0,
      selection2: map['selection2'] as int? ?? 0,
      selection3: map['selection3'] as int? ?? 0,
      selection4: map['selection4'] as int? ?? 0,
      devID: map['devID'] as String? ?? '',
      mitraID: map['mitraID'] as String? ?? '',
      animWelcome: map['animWelcome'] as int? ?? 0,
      durasiWelcome: map['durasiWelcome'] as int? ?? 0,
      trigger1Data: List<int>.from(map['trigger1Data'] as List? ?? []),
      trigger2Data: List<int>.from(map['trigger2Data'] as List? ?? []),
      trigger3Data: List<int>.from(map['trigger3Data'] as List? ?? []),
      trigger1Mode: map['trigger1Mode'] as int? ?? 0,
      trigger2Mode: map['trigger2Mode'] as int? ?? 0,
      trigger3Mode: map['trigger3Mode'] as int? ?? 0,
      quickTrigger: map['quickTrigger'] as int? ?? 0,
    );
  }

  // Copy with method
  ConfigModel copyWith({
    String? firmware,
    String? mac,
    int? typeLicense,
    int? jumlahChannel,
    String? email,
    String? ssid,
    String? password,
    int? delay1,
    int? delay2,
    int? delay3,
    int? delay4,
    int? selection1,
    int? selection2,
    int? selection3,
    int? selection4,
    String? devID,
    String? mitraID,
    int? animWelcome,
    int? durasiWelcome,
    List<int>? trigger1Data,
    List<int>? trigger2Data,
    List<int>? trigger3Data,
    int? trigger1Mode,
    int? trigger2Mode,
    int? trigger3Mode,
    int? quickTrigger,
  }) {
    return ConfigModel(
      firmware: firmware ?? this.firmware,
      mac: mac ?? this.mac,
      typeLicense: typeLicense ?? this.typeLicense,
      jumlahChannel: jumlahChannel ?? this.jumlahChannel,
      email: email ?? this.email,
      ssid: ssid ?? this.ssid,
      password: password ?? this.password,
      delay1: delay1 ?? this.delay1,
      delay2: delay2 ?? this.delay2,
      delay3: delay3 ?? this.delay3,
      delay4: delay4 ?? this.delay4,
      selection1: selection1 ?? this.selection1,
      selection2: selection2 ?? this.selection2,
      selection3: selection3 ?? this.selection3,
      selection4: selection4 ?? this.selection4,
      devID: devID ?? this.devID,
      mitraID: mitraID ?? this.mitraID,
      animWelcome: animWelcome ?? this.animWelcome,
      durasiWelcome: durasiWelcome ?? this.durasiWelcome,
      trigger1Data: trigger1Data ?? this.trigger1Data,
      trigger2Data: trigger2Data ?? this.trigger2Data,
      trigger3Data: trigger3Data ?? this.trigger3Data,
      trigger1Mode: trigger1Mode ?? this.trigger1Mode,
      trigger2Mode: trigger2Mode ?? this.trigger2Mode,
      trigger3Mode: trigger3Mode ?? this.trigger3Mode,
      quickTrigger: quickTrigger ?? this.quickTrigger,
    );
  }

  // Validasi data
  bool get isValid {
    return firmware.isNotEmpty &&
        mac.isNotEmpty;}

  // Summary info
  String get summary {
    return 'Config: FW $firmware | MAC: ${mac.substring(0, 8)}... | Channels: $jumlahChannel | Email: $email';
  }

  // Debug info
  String get debugInfo {
    return '''
ConfigModel Debug Info:
- Firmware: $firmware
- MAC: $mac 
- Type License: $typeLicense
- Jumlah Channel: $jumlahChannel
- Email: $email
- SSID: $ssid
- Password: ${password.isNotEmpty ? '***' : 'Empty'}
- Delays: $delay1, $delay2, $delay3, $delay4
- Selections: $selection1, $selection2, $selection3, $selection4
- DevID: $devID
- MitraID: $mitraID
- Anim Welcome: $animWelcome
- Durasi Welcome: $durasiWelcome
- Quick Trigger: $quickTrigger
- Trigger1: ${trigger1Data.take(5)}... (Mode: $trigger1Mode)
- Trigger2: ${trigger2Data.take(5)}... (Mode: $trigger2Mode)
- Trigger3: ${trigger3Data.take(5)}... (Mode: $trigger3Mode)
''';
  }

  @override
  String toString() {
    return 'ConfigModel(firmware: $firmware, channels: $jumlahChannel, email: $email)';
  }
}