// services/preferences_service.dart
import 'dart:convert';

import 'package:ninexmano_matrix/models/animation_model.dart';
import 'package:ninexmano_matrix/models/config_model.dart';
import 'package:ninexmano_matrix/models/list_animation_model.dart';
import 'package:ninexmano_matrix/models/system_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();
  static const String _deviceConfigKey = 'device_config';

  // Key templates
  static const String _systemDataKey = 'system_data';
  static const String _userAnimationsKey = 'user_animations';
  static const String _lastSyncKey = 'last_sync';
  static const String _selectedAnimationsKey = 'selected_animations';
  static const String _defaultAnimationsKey = 'default_animations';

  // Duration cache (1 jam)
  static const Duration cacheDuration = Duration(hours: 1);

  late SharedPreferences _prefs;
  bool _isInitialized = false;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
    print('✅ PreferencesService initialized');
  }

  // ============ DYNAMIC KEY GENERATORS ============

  // Key untuk data API
  String _apiKey(String dataType) => 'api_$dataType';

  // Key untuk data pilihan user
  String _userKey(String dataType) => 'user_$dataType';

  // Key untuk settings user
  String _settingsKey(String settingName) => 'settings_$settingName';

  Future<bool> saveDefaultAnimations(
    List<AnimationModel> defaultAnimations,
  ) async {
    if (!_isInitialized) await initialize();

    try {
      final animationsData = defaultAnimations
          .map((anim) => anim.toMap())
          .toList();
      final jsonString = jsonEncode(animationsData);
      final success = await _prefs.setString(_defaultAnimationsKey, jsonString);

      if (success) {
        print(
          '💾 Default animations saved (${defaultAnimations.length} animations)',
        );
      }
      return success;
    } catch (e) {
      print('❌ Error saving default animations: $e');
      return false;
    }
  }

  // Get default animations
  Future<List<AnimationModel>> getDefaultAnimations() async {
    if (!_isInitialized) await initialize();

    try {
      final jsonString = _prefs.getString(_defaultAnimationsKey);
      if (jsonString == null) return [];

      final animationsList = jsonDecode(jsonString) as List<dynamic>;

      return animationsList
          .map((animMap) {
            try {
              final map = animMap as Map<String, dynamic>;
              return AnimationModel.fromList(map['name'] as String, [
                map['channelCount'],
                map['animationLength'],
                map['description'],
                map['delayData'],
                ...(map['frameData'] as List<dynamic>).cast<String>(),
              ]);
            } catch (e) {
              print('❌ Error parsing default animation: $e');
              return null;
            }
          })
          .where((animation) => animation != null)
          .cast<AnimationModel>()
          .toList();
    } catch (e) {
      print('❌ Error reading default animations: $e');
      return [];
    }
  }

  // Check if animation is default
  Future<bool> isDefaultAnimation(String animationName) async {
    final defaultAnimations = await getDefaultAnimations();
    return defaultAnimations.any((anim) => anim.name == animationName);
  }
  // ============ API DATA METHODS (System & Animations dari Firebase) ============

  // Save system data dari API
  Future<bool> saveApiSystemData(SystemModel systemData) async {
    if (!_isInitialized) await initialize();

    try {
      final jsonString = jsonEncode(systemData.toJson());
      final success = await _prefs.setString(
        _apiKey(_systemDataKey),
        jsonString,
      );

      if (success) {
        await _updateLastSync();
        print('💾 API System data saved to preferences');
      }
      return success;
    } catch (e) {
      print('❌ Error saving API system data to preferences: $e');
      return false;
    }
  }

  // Get system data dari API
  Future<SystemModel?> getApiSystemData() async {
    if (!_isInitialized) await initialize();

    try {
      final jsonString = _prefs.getString(_apiKey(_systemDataKey));
      if (jsonString == null) return null;

      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return SystemModel.fromJson(jsonMap);
    } catch (e) {
      print('❌ Error reading API system data from preferences: $e');
      return null;
    }
  }

  // Save user animations dari API
  Future<bool> saveApiUserAnimations(ListAnimationModel animations) async {
    if (!_isInitialized) await initialize();

    try {
      final animationsData = {
        'source': animations.source,
        'lastSync': animations.lastSync.toIso8601String(),
        'animations': animations.animations
            .map((anim) => anim.toMap())
            .toList(),
      };

      final jsonString = jsonEncode(animationsData);
      final success = await _prefs.setString(
        _apiKey(_userAnimationsKey),
        jsonString,
      );

      if (success) {
        await _updateLastSync();
        print(
          '💾 API User animations saved to preferences (${animations.length} animations)',
        );
      }
      return success;
    } catch (e) {
      print('❌ Error saving API user animations to preferences: $e');
      return false;
    }
  }

  // Get user animations dari API
  Future<ListAnimationModel?> getApiUserAnimations() async {
    if (!_isInitialized) await initialize();

    try {
      final jsonString = _prefs.getString(_apiKey(_userAnimationsKey));
      if (jsonString == null) return null;

      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final source = data['source'] as String? ?? 'USER (Cached)';
      final lastSync = DateTime.parse(data['lastSync'] as String);
      final animationsList = data['animations'] as List<dynamic>;

      final animations = animationsList
          .map((animMap) {
            try {
              final map = animMap as Map<String, dynamic>;
              return AnimationModel.fromList(map['name'] as String, [
                map['channelCount'],
                map['animationLength'],
                map['description'],
                map['delayData'],
                ...(map['frameData'] as List<dynamic>).cast<String>(),
              ]);
            } catch (e) {
              print('❌ Error parsing animation from API cache: $e');
              return null;
            }
          })
          .where((animation) => animation != null)
          .cast<AnimationModel>()
          .toList();

      return ListAnimationModel(
        animations: animations,
        source: source,
        lastSync: lastSync,
      );
    } catch (e) {
      print('❌ Error reading API user animations from preferences: $e');
      return null;
    }
  }

  // Di PreferencesService - hanya method getter/setter sederhana
  List<Map<String, dynamic>> getSelectedAnimations() {
    final data = _prefs.getStringList(_selectedAnimationsKey) ?? [];
    return data
        .map((jsonStr) {
          try {
            return Map<String, dynamic>.from(jsonDecode(jsonStr));
          } catch (e) {
            return <String, dynamic>{};
          }
        })
        .where((map) => map.isNotEmpty)
        .toList();
  }

  Future<void> saveSelectedAnimations(
    List<Map<String, dynamic>> animations,
  ) async {
    final jsonList = animations.map((map) => jsonEncode(map)).toList();
    await _prefs.setStringList(_selectedAnimationsKey, jsonList);
  }

  // ============ USER SELECTED DATA METHODS (Pilihan User) ============

  // Save animasi yang dipilih user
  Future<bool> saveUserSelectedAnimations(
    List<AnimationModel> selectedAnimations,
  ) async {
    if (!_isInitialized) await initialize();

    try {
      final animationsData = selectedAnimations
          .map((anim) => anim.toMap())
          .toList();
      final jsonString = jsonEncode(animationsData);
      final success = await _prefs.setString(
        _userKey(_selectedAnimationsKey),
        jsonString,
      );

      if (success) {
        print(
          '💾 User selected animations saved (${selectedAnimations.length} animations)',
        );
      }
      return success;
    } catch (e) {
      print('❌ Error saving user selected animations: $e');
      return false;
    }
  }

  // Get animasi yang dipilih user
  Future<List<AnimationModel>> getUserSelectedAnimations() async {
    if (!_isInitialized) await initialize();

    try {
      final jsonString = _prefs.getString(_userKey(_selectedAnimationsKey));
      if (jsonString == null) return [];

      final animationsList = jsonDecode(jsonString) as List<dynamic>;

      return animationsList
          .map((animMap) {
            try {
              final map = animMap as Map<String, dynamic>;
              return AnimationModel.fromList(map['name'] as String, [
                map['channelCount'],
                map['animationLength'],
                map['description'],
                map['delayData'],
                ...(map['frameData'] as List<dynamic>).cast<String>(),
              ]);
            } catch (e) {
              print('❌ Error parsing user selected animation: $e');
              return null;
            }
          })
          .where((animation) => animation != null)
          .cast<AnimationModel>()
          .toList();
    } catch (e) {
      print('❌ Error reading user selected animations: $e');
      return [];
    }
  }

  // Add single animation to user selections
  Future<bool> addUserSelectedAnimation(AnimationModel animation) async {
    final currentSelections = await getUserSelectedAnimations();

    // Cek jika sudah ada
    if (currentSelections.any((anim) => anim.name == animation.name)) {
      print('⚠️ Animation ${animation.name} already in selections');
      return true;
    }

    final newSelections = [...currentSelections, animation];
    return await saveUserSelectedAnimations(newSelections);
  }

  // Remove animation from user selections
  Future<bool> removeUserSelectedAnimation(String animationName) async {
    final currentSelections = await getUserSelectedAnimations();
    final newSelections = currentSelections
        .where((anim) => anim.name != animationName)
        .toList();
    return await saveUserSelectedAnimations(newSelections);
  }

  // Clear all user selections
  Future<bool> clearUserSelectedAnimations() async {
    if (!_isInitialized) await initialize();
    return await _prefs.remove(_userKey(_selectedAnimationsKey));
  }

  // ============ USER SETTINGS METHODS ============

  // Save user setting
  Future<bool> saveUserSetting(String settingName, dynamic value) async {
    if (!_isInitialized) await initialize();

    try {
      final jsonString = jsonEncode(value);
      return await _prefs.setString(_settingsKey(settingName), jsonString);
    } catch (e) {
      print('❌ Error saving user setting $settingName: $e');
      return false;
    }
  }

  // Get user setting
  Future<dynamic> getUserSetting(String settingName) async {
    if (!_isInitialized) await initialize();

    try {
      final jsonString = _prefs.getString(_settingsKey(settingName));
      if (jsonString == null) return null;

      return jsonDecode(jsonString);
    } catch (e) {
      print('❌ Error reading user setting $settingName: $e');
      return null;
    }
  }

  // Contoh settings yang umum
  Future<bool> saveLastSelectedChannel(int channel) async {
    return await saveUserSetting('last_selected_channel', channel);
  }

  Future<int> getLastSelectedChannel() async {
    final channel = await getUserSetting('last_selected_channel');
    return channel is int ? channel : 4; // default channel 4
  }

  Future<bool> saveAutoSyncEnabled(bool enabled) async {
    return await saveUserSetting('auto_sync_enabled', enabled);
  }

  Future<bool> getAutoSyncEnabled() async {
    final enabled = await getUserSetting('auto_sync_enabled');
    return enabled is bool ? enabled : true; // default enabled
  }

  // ============ CACHE MANAGEMENT ============

  // Check if API cache is valid
  Future<bool> isApiCacheValid() async {
    if (!_isInitialized) await initialize();

    final lastSync = await getLastSync();
    if (lastSync == null) return false;

    final now = DateTime.now();
    return now.difference(lastSync) < cacheDuration;
  }

  // Get last sync time
  Future<DateTime?> getLastSync() async {
    if (!_isInitialized) await initialize();

    final lastSyncString = _prefs.getString(_lastSyncKey);
    return lastSyncString != null ? DateTime.parse(lastSyncString) : null;
  }

  // Update last sync time
  Future<void> _updateLastSync() async {
    if (!_isInitialized) await initialize();
    await _prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  // ============ CLEAR METHODS ============

  // Clear all API cache
  Future<void> clearApiCache() async {
    if (!_isInitialized) await initialize();

    await _prefs.remove(_apiKey(_systemDataKey));
    await _prefs.remove(_apiKey(_userAnimationsKey));
    await _prefs.remove(_lastSyncKey);

    print('🗑️ API cache cleared');
  }

  // Clear user data
  Future<void> clearUserData() async {
    if (!_isInitialized) await initialize();

    await _prefs.remove(_userKey(_selectedAnimationsKey));

    // Clear semua settings yang dimulai dengan 'settings_'
    final keys = _prefs
        .getKeys()
        .where((key) => key.startsWith('settings_'))
        .toList();
    for (final key in keys) {
      await _prefs.remove(key);
    }

    print('🗑️ User data cleared');
  }

  // Clear everything
  Future<void> clearAll() async {
    if (!_isInitialized) await initialize();
    await _prefs.clear();
    print('🗑️ All preferences cleared');
  }

  // ============ STATISTICS ============

  // Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    if (!_isInitialized) await initialize();

    final apiSystemData = await getApiSystemData();
    final apiUserAnimations = await getApiUserAnimations();
    final userSelectedAnimations = await getUserSelectedAnimations();
    final lastSync = await getLastSync();
    final cacheValid = await isApiCacheValid();

    return {
      'api_system_data': apiSystemData != null,
      'api_user_animations_count': apiUserAnimations?.length ?? 0,
      'user_selected_animations_count': userSelectedAnimations.length,
      'last_sync': lastSync?.toLocal().toString() ?? 'Never',
      'api_cache_valid': cacheValid,
      'total_storage_keys': _prefs.getKeys().length,
    };
  }

  Future<bool> saveDeviceConfig(ConfigModel config) async {
    if (!_isInitialized) await initialize();

    try {
      final configMap = config.toMap();
      final jsonString = jsonEncode(configMap);
      final success = await _prefs.setString(_deviceConfigKey, jsonString);

      if (success) {
        print('💾 Device config saved to preferences');
        print('📊 Config summary: ${config.summary}');
      }
      return success;
    } catch (e) {
      print('❌ Error saving device config to preferences: $e');
      return false;
    }
  }

  // Get device config
  Future<ConfigModel?> getDeviceConfig() async {
    if (!_isInitialized) await initialize();

    try {
      final jsonString = _prefs.getString(_deviceConfigKey);
      if (jsonString == null) return null;

      final configMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return ConfigModel.fromMap(configMap);
    } catch (e) {
      print('❌ Error reading device config from preferences: $e');
      return null;
    }
  }

  // Check if device config exists
  Future<bool> hasDeviceConfig() async {
    if (!_isInitialized) await initialize();
    return _prefs.containsKey(_deviceConfigKey);
  }

  // Clear device config
  Future<bool> clearDeviceConfig() async {
    if (!_isInitialized) await initialize();
    final success = await _prefs.remove(_deviceConfigKey);
    if (success) {
      print('🗑️ Device config cleared from preferences');
    }
    return success;
  }

  // Get all stored keys (untuk debug)
  Set<String> getAllKeys() {
    return _prefs.getKeys();
  }
}
