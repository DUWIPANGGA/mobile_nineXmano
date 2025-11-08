// services/config_service.dart
import 'dart:async';
import 'dart:convert';

import 'package:ninexmano_matrix/models/config_model.dart';
import 'package:ninexmano_matrix/services/preferences_service.dart';

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  final PreferencesService _preferencesService = PreferencesService();

  // Current config state
  ConfigModel? _currentConfig;

  // Stream controller untuk notify config changes
  final _configController = StreamController<ConfigModel?>.broadcast();
  Stream<ConfigModel?> get configStream => _configController.stream;

  // Getter untuk current config
  ConfigModel? get currentConfig => _currentConfig;

  // Initialize service
  Future<void> initialize() async {
    await _preferencesService.initialize();
    await _loadConfig();
  }

  // Load config dari preferences
  Future<void> _loadConfig() async {
    try {
      _currentConfig = await _preferencesService.getDeviceConfig();
      if (_currentConfig != null) {
        print('📂 Config loaded from preferences: ${_currentConfig!.summary}');
        _configController.add(_currentConfig);
      } else {
        print('📭 No config found in preferences');
        _configController.add(null);
      }
    } catch (e) {
      print('❌ Error loading config: $e');
      _configController.add(null);
    }
  }

  // Simpan config ke preferences
  Future<bool> saveConfig(ConfigModel config) async {
    try {
      final success = await _preferencesService.saveDeviceConfig(config);
      if (success) {
        _currentConfig = config;
        _configController.add(config);

        print('💾 Config saved to preferences: ${config.summary}');
        _printConfigDetails(config);
      }
      return success;
    } catch (e) {
      print('❌ Error saving config: $e');
      return false;
    }
  }

  // Print config details
  void _printConfigDetails(ConfigModel config) {
    print('📊 Config details:');
    print('   - Firmware: ${config.firmware}');
    print('   - MAC: ${config.mac}');
    print('   - Channels: ${config.jumlahChannel}');
    print('   - Email: ${config.email}');
    print('   - SSID: ${config.ssid}');
    print(
      '   - Delays: ${config.delay1}, ${config.delay2}, ${config.delay3}, ${config.delay4}',
    );
    print(
      '   - Trigger Modes: ${config.trigger1Mode}, ${config.trigger2Mode}, ${config.trigger3Mode}',
    );
    print('   - Quick Trigger: ${config.quickTrigger}');
  }

  // Parse dan simpan config dari string Arduino
  Future<ConfigModel?> parseAndSaveConfig(String arduinoData) async {
    try {
      print('🔧 Parsing Arduino config data...');
      print('   - Raw data length: ${arduinoData.length}');
      print(
        '   - First 100 chars: ${arduinoData.substring(0, arduinoData.length < 100 ? arduinoData.length : 100)}...',
      );

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
      _currentConfig = null;
      _configController.add(null);
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

  // Get config statistics
  Future<Map<String, dynamic>> getConfigStats() async {
    final config = await _preferencesService.getDeviceConfig();
    final configExists = await hasConfig();

    return {
      'hasConfig': configExists,
      'isValid': config?.isValid ?? false,
      'firmware': config?.firmware ?? 'Unknown',
      'channels': config?.jumlahChannel ?? 0,
      'email': config?.email ?? 'Unknown',
      'ssid': config?.ssid ?? 'Unknown',
      'mac': config?.mac ?? 'Unknown',
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  // Update specific config fields
  Future<bool> updateConfigFields(Map<String, dynamic> updates) async {
    try {
      final currentConfig =
          await _preferencesService.getDeviceConfig() ?? getDefaultConfig();
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

  // ========== TRIGGER-RELATED METHODS ==========

  // Update trigger data untuk specific trigger
  Future<bool> updateTriggerData(
    String triggerType,
    List<int> triggerData,
    int triggerMode,
  ) async {
    try {
      final currentConfig =
          _currentConfig ?? await _preferencesService.getDeviceConfig();
      if (currentConfig == null) {
        print('❌ No config available for trigger update');
        return false;
      }

      ConfigModel updatedConfig;

      switch (triggerType) {
        case 'QUICK':
          updatedConfig = currentConfig.copyWith(
            trigger1Data: triggerData,
            trigger1Mode: triggerMode,
          );
          break;
        case 'LOW BEAM':
          updatedConfig = currentConfig.copyWith(
            trigger2Data: triggerData,
            trigger2Mode: triggerMode,
          );
          break;
        case 'HIGH BEAM':
          updatedConfig = currentConfig.copyWith(
            trigger3Data: triggerData,
            trigger3Mode: triggerMode,
          );
          break;
        case 'FOG LAMP':
          updatedConfig = currentConfig.copyWith(quickTrigger: triggerMode);
          break;
        default:
          print('❌ Unknown trigger type: $triggerType');
          return false;
      }

      final success = await saveConfig(updatedConfig);
      if (success) {
        print('✅ Trigger $triggerType updated with mode $triggerMode');
        print(
          '   - Data: ${triggerData.take(5)}... (${triggerData.length} bytes)',
        );
      }
      return success;
    } catch (e) {
      print('❌ Error updating trigger data: $e');
      return false;
    }
  }

  // Get trigger data untuk specific trigger
  List<int>? getTriggerData(String triggerType) {
    if (_currentConfig == null) return null;

    switch (triggerType) {
      case 'QUICK':
        return _currentConfig!.trigger1Data;
      case 'LOW BEAM':
        return _currentConfig!.trigger2Data;
      case 'HIGH BEAM':
        return _currentConfig!.trigger3Data;
      default:
        return null;
    }
  }

  // Get trigger mode untuk specific trigger
  int? getTriggerMode(String triggerType) {
    if (_currentConfig == null) return null;

    switch (triggerType) {
      case 'QUICK':
        return _currentConfig!.trigger1Mode;
      case 'LOW BEAM':
        return _currentConfig!.trigger2Mode;
      case 'HIGH BEAM':
        return _currentConfig!.trigger3Mode;
      case 'FOG LAMP':
        return _currentConfig!.quickTrigger;
      default:
        return null;
    }
  }

  // ========== DEVICE INFO METHODS ==========

  // Get device info summary
  Map<String, dynamic>? getDeviceInfo() {
    if (_currentConfig == null) return null;

    return {
      'firmware': _currentConfig!.firmware,
      'mac': _currentConfig!.mac,
      'channels': _currentConfig!.jumlahChannel,
      'email': _currentConfig!.email,
      'deviceId': _currentConfig!.devID,
      'isValid': _currentConfig!.isValid,
    };
  }

  // Check if device is configured
  bool get isDeviceConfigured {
    return _currentConfig != null && _currentConfig!.isValid;
  }

  // Get channel count (dengan fallback)
  int get channelCount {
    return _currentConfig?.jumlahChannel ?? 8; // Default 80 channels
  }

  // ========== VALIDATION METHODS ==========

  // Validate config
  bool validateConfig(ConfigModel config) {
    return config.isValid;
  }

  // Validate trigger data
  bool validateTriggerData(List<int> data) {
    return data.isNotEmpty &&
        data.length <= 80; // Max 80 bytes untuk trigger data
  }

  // ========== UTILITY METHODS ==========

  // Reset to default config
  Future<bool> resetToDefault() async {
    final defaultConfig = getDefaultConfig();
    return await saveConfig(defaultConfig);
  }

  // Export config as JSON string
  String exportConfigAsJson() {
    if (_currentConfig == null) return '';

    try {
      final configMap = _currentConfig!.toMap();
      // Remove sensitive data
      configMap.remove('password');
      return jsonEncode(configMap);
    } catch (e) {
      print('❌ Error exporting config as JSON: $e');
      return '';
    }
  }

  // Import config from JSON string
  Future<bool> importConfigFromJson(String jsonString) async {
    try {
      final configMap = jsonDecode(jsonString) as Map<String, dynamic>;
      final config = ConfigModel.fromMap(configMap);

      if (validateConfig(config)) {
        return await saveConfig(config);
      } else {
        print('❌ Imported config is not valid');
        return false;
      }
    } catch (e) {
      print('❌ Error importing config from JSON: $e');
      return false;
    }
  }

  // Dispose method
  void dispose() {
    _configController.close();
  }

  // ========== DEBUG METHODS ==========

  // Print full config debug info
  void printDebugInfo() {
    if (_currentConfig == null) {
      print('🔍 No config available for debug');
      return;
    }

    print('🚀 === CONFIG DEBUG INFO ===');
    print(_currentConfig!.debugInfo);
    print('📊 Trigger Data Summary:');
    print(
      '   - Trigger1: ${_currentConfig!.trigger1Data.take(5)}... (Mode: ${_currentConfig!.trigger1Mode})',
    );
    print(
      '   - Trigger2: ${_currentConfig!.trigger2Data.take(5)}... (Mode: ${_currentConfig!.trigger2Mode})',
    );
    print(
      '   - Trigger3: ${_currentConfig!.trigger3Data.take(5)}... (Mode: ${_currentConfig!.trigger3Mode})',
    );
    print('   - Quick Trigger: ${_currentConfig!.quickTrigger}');
    print('===========================');
  }

  // Check config health status
  Map<String, dynamic> getHealthStatus() {
    if (_currentConfig == null) {
      return {'status': 'NO_CONFIG', 'message': 'No configuration available'};
    }

    final config = _currentConfig!;
    final issues = <String>[];

    if (!config.isValid) issues.add('Invalid configuration');
    if (config.jumlahChannel == 0) issues.add('Channel count is zero');
    if (config.email.isEmpty) issues.add('Email is empty');
    if (config.mac.isEmpty) issues.add('MAC address is empty');

    return {
      'status': issues.isEmpty ? 'HEALTHY' : 'ISSUES',
      'issues': issues,
      'channelCount': config.jumlahChannel,
      'firmware': config.firmware,
      'isConfigured': config.isValid,
    };
  }
}
