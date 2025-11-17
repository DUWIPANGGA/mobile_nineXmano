// services/config_show_service.dart
import 'dart:async';

import 'package:iTen/models/config_show_model.dart';
import 'package:iTen/services/preferences_service.dart';

class ConfigShowService {
  static final ConfigShowService _instance = ConfigShowService._internal();
  factory ConfigShowService() => _instance;
  ConfigShowService._internal();

  final PreferencesService _preferencesService = PreferencesService();
  
  // Current config show state
  ConfigShowModel? _currentConfigShow;

  // Stream controller untuk notify config show changes
  final _configShowController = StreamController<ConfigShowModel?>.broadcast();
  Stream<ConfigShowModel?> get configShowStream => _configShowController.stream;

  // Getter untuk current config show
  ConfigShowModel? get currentConfigShow => _currentConfigShow;

  // Initialize service
  Future<void> initialize() async {
    await _preferencesService.initialize();
    await _loadConfigShow();
  }

  // Load config show dari preferences
  Future<void> _loadConfigShow() async {
    try {
      _currentConfigShow = await _preferencesService.getConfigShow();
      if (_currentConfigShow != null) {
        print('📂 ConfigShow loaded from preferences: ${_currentConfigShow!.summary}');
        _configShowController.add(_currentConfigShow);
      } else {
        print('📭 No config show found in preferences');
        _configShowController.add(null);
      }
    } catch (e) {
      print('❌ Error loading config show: $e');
      _configShowController.add(null);
    }
  }

  // Simpan config show ke preferences
  Future<bool> saveConfigShow(ConfigShowModel configShow) async {
    try {
      final success = await _preferencesService.saveConfigShow(configShow);
      if (success) {
        _currentConfigShow = configShow;
        _configShowController.add(configShow);

        print('💾 ConfigShow saved to preferences: ${configShow.summary}');
        _printConfigShowDetails(configShow);
      }
      return success;
    } catch (e) {
      print('❌ Error saving config show: $e');
      return false;
    }
  }

  // Print config show details
  void _printConfigShowDetails(ConfigShowModel configShow) {
    print('📊 ConfigShow details:');
    print('   - Firmware: ${configShow.firmware}');
    print('   - Speed Run: ${configShow.speedRun}');
    print('   - Channels: ${configShow.jumlahChannel}');
    print('   - Email: ${configShow.email}');
    print('   - Device ID: ${configShow.devID}');
  }

  // Parse dan simpan config show dari string Arduino (config2)
  Future<ConfigShowModel?> parseAndSaveConfigShow(String arduinoData) async {
    try {
      print('🔧 [CONFIG SHOW SERVICE] Parsing Arduino config2 data...');
      print('   - Raw data: $arduinoData');
      print('   - Data length: ${arduinoData.length} characters');
      print('   - Starts with config2: ${arduinoData.startsWith('config2,')}');

      // Validate the data format first
      if (!arduinoData.startsWith('config2,')) {
        throw FormatException('Invalid config2 data format. Must start with "config2,"');
      }

      final configShow = ConfigShowModel.fromConfig2String(arduinoData);

      print('📋 [CONFIG SHOW SERVICE] ConfigShow validation:');
      print('   - Is valid: ${configShow.isValid}');
      print('   - Firmware: ${configShow.firmware}');
      print('   - Speed Run: ${configShow.speedRun}');
      print('   - Channels: ${configShow.jumlahChannel}');
      print('   - Email: ${configShow.email}');
      print('   - Device ID: ${configShow.devID}');

      if (configShow.isValid) {
        final saved = await saveConfigShow(configShow);
        if (saved) {
          print('✅ [CONFIG SHOW SERVICE] ConfigShow parsed and saved successfully!');
          print('🎉 [CONFIG SHOW SERVICE] ${configShow.summary}');
          return configShow;
        } else {
          print('⚠️ [CONFIG SHOW SERVICE] Failed to save config show to preferences');
          return null;
        }
      } else {
        print('❌ [CONFIG SHOW SERVICE] Config show data is invalid');
        print('💡 [CONFIG SHOW SERVICE] Debug info: ${configShow.debugInfo}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ [CONFIG SHOW SERVICE] Error parsing Arduino config2: $e');
      print('📋 [CONFIG SHOW SERVICE] Stack trace: $stackTrace');
      print('💡 [CONFIG SHOW SERVICE] Problematic data: $arduinoData');
      return null;
    }
  }

  // Get default config show
  ConfigShowModel getDefaultConfigShow() {
    return ConfigShowModel(
      firmware: '1.0.0',
      speedRun: 50,
      jumlahChannel: 16,
      email: 'user@example.com',
      devID: '000000000000',
    );
  }

  // Clear config show dari preferences
  Future<void> clearConfigShow() async {
    final success = await _preferencesService.clearConfigShow();
    if (success) {
      _currentConfigShow = null;
      _configShowController.add(null);
      print('🗑️ ConfigShow cleared from preferences');
    } else {
      print('⚠️ Failed to clear config show from preferences');
    }
  }

  // Check if config show exists di preferences
  Future<bool> hasConfigShow() async {
    final hasConfigShow = await _preferencesService.hasConfigShow();
    print('🔍 ConfigShow exists in preferences: $hasConfigShow');
    return hasConfigShow;
  }

  // Update specific config show fields
  Future<bool> updateConfigShowFields(Map<String, dynamic> updates) async {
    try {
      final currentConfigShow = await _preferencesService.getConfigShow() ?? getDefaultConfigShow();
      final updatedConfigShow = currentConfigShow.copyWith(
        firmware: updates['firmware'],
        speedRun: updates['speedRun'],
        jumlahChannel: updates['jumlahChannel'],
        email: updates['email'],
        devID: updates['devID'],
      );

      return await saveConfigShow(updatedConfigShow);
    } catch (e) {
      print('❌ Error updating config show fields: $e');
      return false;
    }
  }

  // Get device info summary untuk sync page
  Map<String, dynamic>? getDeviceInfoForSync() {
    if (_currentConfigShow == null) return null;

    return {
      'firmware': _currentConfigShow!.firmware,
      'speedRun': _currentConfigShow!.speedRun,
      'channels': _currentConfigShow!.jumlahChannel,
      'email': _currentConfigShow!.email,
      'deviceId': _currentConfigShow!.devID,
      'isValid': _currentConfigShow!.isValid,
    };
  }

  // Check if device is configured untuk sync
  bool get isDeviceConfiguredForSync {
    return _currentConfigShow != null && _currentConfigShow!.isValid;
  }

  // Dispose method
  void dispose() {
    _configShowController.close();
  }

  // Print full config show debug info
  void printDebugInfo() {
    if (_currentConfigShow == null) {
      print('🔍 No config show available for debug');
      return;
    }

    print('🚀 === CONFIG SHOW DEBUG INFO ===');
    print(_currentConfigShow!.debugInfo);
    print('===========================');
  }
}