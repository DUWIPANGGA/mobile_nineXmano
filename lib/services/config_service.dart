// services/config_service.dart
import 'package:ninexmano_matrix/models/config_model.dart';
import 'package:ninexmano_matrix/services/preferences_service.dart';

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  final PreferencesService _preferencesService = PreferencesService();

  // Simpan config ke preferences
  Future<bool> saveConfig(ConfigModel config) async {
    try {
      final success = await _preferencesService.saveDeviceConfig(config);
      if (success) {
        print('💾 Config saved to preferences: ${config.summary}');
        
        // Print debug info
        print('📊 Config details:');
        print('   - Firmware: ${config.firmware}');
        print('   - MAC: ${config.mac}');
        print('   - Channels: ${config.jumlahChannel}');
        print('   - Email: ${config.email}');
        print('   - SSID: ${config.ssid}');
        print('   - Delays: ${config.delay1}, ${config.delay2}, ${config.delay3}, ${config.delay4}');
      }
      return success;
    } catch (e) {
      print('❌ Error saving config: $e');
      return false;
    }
  }

  // Load config dari preferences
  Future<ConfigModel?> loadConfig() async {
    try {
      final config = await _preferencesService.getDeviceConfig();
      if (config != null) {
        print('📂 Config loaded from preferences: ${config.summary}');
      } else {
        print('📭 No config found in preferences');
      }
      return config;
    } catch (e) {
      print('❌ Error loading config: $e');
      return null;
    }
  }

  // Parse dan simpan config dari string Arduino
  Future<ConfigModel?> parseAndSaveConfig(String arduinoData) async {
    try {
      print('🔧 Parsing Arduino config data...');
      print('   - Raw data: ${arduinoData.substring(0, 100)}...');
      
      final config = ConfigModel.fromArduinoString(arduinoData);
      
      if (config.isValid) {
        final saved = await saveConfig(config);
        if (saved) {
          print('✅ Config parsed and saved to preferences successfully');
          print('📋 Config summary: ${config.summary}');
          return config;
        } else {
          print('⚠️ Failed to save config to preferences');
          return null;
        }
      } else {
        print('⚠️ Config data is invalid');
        return null;
      }
    } catch (e) {
      print('❌ Error parsing Arduino config: $e');
      return null;
    }
  }

  // Get default config
  ConfigModel getDefaultConfig() {
    return ConfigModel(
      firmware: '1.0.0',
      mac: '000000000000000000',
      typeLicense: 2,
      jumlahChannel: 8,
      email: 'user@example.com',
      ssid: 'MaNo',
      password: '',
      delay1: 100,
      delay2: 100,
      delay3: 100,
      delay4: 100,
      selection1: 1,
      selection2: 2,
      selection3: 3,
      selection4: 4,
      devID: '000000000000',
      mitraID: 'MANO',
      animWelcome: 1,
      durasiWelcome: 5,
      trigger1Data: List.filled(10, 0),
      trigger2Data: List.filled(10, 0),
      trigger3Data: List.filled(10, 0),
      trigger1Mode: 0,
      trigger2Mode: 0,
      trigger3Mode: 0,
      quickTrigger: 0,
    );
  }

  // Clear config dari preferences
  Future<void> clearConfig() async {
    final success = await _preferencesService.clearDeviceConfig();
    if (success) {
      print('🗑️ Config cleared from preferences');
    } else {
      print('⚠️ Failed to clear config from preferences');
    }
  }

  // Check if config exists di preferences
  Future<bool> hasConfig() async {
    final hasConfig = await _preferencesService.hasDeviceConfig();
    print('🔍 Config exists in preferences: $hasConfig');
    return hasConfig;
  }

  Future<Map<String, dynamic>> getConfigStats() async {
  final config = await loadConfig();
  final configExists = await hasConfig(); // Ganti nama variable
    
  return {
    'hasConfig': configExists, // Pakai variable yang sudah dideklarasikan
    'isValid': config?.isValid ?? false,
    'firmware': config?.firmware ?? 'Unknown',
    'channels': config?.jumlahChannel ?? 0,
    'email': config?.email ?? 'Unknown',
    'ssid': config?.ssid ?? 'Unknown',
    'lastUpdated': DateTime.now().toIso8601String(),
  };
}

  // Update specific config fields
  Future<bool> updateConfigFields(Map<String, dynamic> updates) async {
    try {
      final currentConfig = await loadConfig() ?? getDefaultConfig();
      final updatedConfig = currentConfig.copyWith(
        firmware: updates['firmware'],
        email: updates['email'],
        ssid: updates['ssid'],
        password: updates['password'],
        jumlahChannel: updates['jumlahChannel'],
        delay1: updates['delay1'],
        delay2: updates['delay2'],
        delay3: updates['delay3'],
        delay4: updates['delay4'],
      );
      
      return await saveConfig(updatedConfig);
    } catch (e) {
      print('❌ Error updating config fields: $e');
      return false;
    }
  }
}