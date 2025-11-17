// services/preferences_service.dart
import 'dart:async';
import 'dart:convert';

import 'package:iTen/models/animation_model.dart';
import 'package:iTen/models/config_model.dart';
import 'package:iTen/models/config_show_model.dart';
import 'package:iTen/models/list_animation_model.dart';
import 'package:iTen/models/system_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();
static const String _configShowKey = 'config_show_data';
  static const String _deviceConfigKey = 'device_config';
  static const String _systemDataKey = 'system_data';
  static const String _userAnimationsKey = 'user_animations';
  static const String _lastSyncKey = 'last_sync';
  static const String _selectedAnimationsKey = 'selected_animations';
  static const String _defaultAnimationsKey = 'default_animations';

  static const Duration cacheDuration = Duration(hours: 1);

  SharedPreferences? _prefs;
  bool _isInitializing = false;
  Completer<void>? _initCompleter;

  Future<void> initialize() async {
    if (_prefs != null) {
      print('✅ PreferencesService already initialized');
      return;
    }
    
    if (_isInitializing) {
      print('🔄 PreferencesService is already initializing, waiting...');
      await _initCompleter?.future;
      return;
    }

    _isInitializing = true;
    _initCompleter = Completer<void>();

    try {
      print('🔄 Initializing SharedPreferences...');
      _prefs = await SharedPreferences.getInstance();
      print('✅ SharedPreferences initialized successfully');
      _initCompleter?.complete();
    } catch (e, stackTrace) {
      print('❌ Error initializing SharedPreferences: $e');
      print('Stack trace: $stackTrace');
      _initCompleter?.completeError(e);
      rethrow;
    } finally {
      // _isInitialized = true;
      _isInitializing = false;
    }
  }

  // Helper method untuk memastikan initialized
  Future<void> _ensureInitialized() async {
    if (_prefs == null) {
      print('🔄 PreferencesService not initialized, initializing now...');
      await initialize();
    }
  }

  // Check if service is initialized
  bool get isInitialized => _prefs != null;

  // ============ DYNAMIC KEY GENERATORS ============

  // Key untuk data API
  String _apiKey(String dataType) => 'api_$dataType';

  // Key untuk data pilihan user
  String _userKey(String dataType) => 'user_$dataType';

  // Key untuk settings user
  String _settingsKey(String settingName) => 'settings_$settingName';

  // ============ DEVICE CONFIG METHODS ============

  Future<bool> saveDeviceConfig(ConfigModel config) async {
    try {
      await _ensureInitialized();
      
      final configMap = config.toMap();
      final jsonString = jsonEncode(configMap);
      final success = await _prefs!.setString(_deviceConfigKey, jsonString);

      if (success) {
        print('💾 Device config saved to preferences');
        print('📊 Config summary: ${config.summary}');
      } else {
        print('❌ Failed to save device config');
      }
      return success;
    } catch (e, stackTrace) {
      print('❌ Error saving device config to preferences: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  Future<ConfigModel?> getDeviceConfig() async {
    try {
      await _ensureInitialized();
      
      final jsonString = _prefs!.getString(_deviceConfigKey);
      if (jsonString == null) {
        print('📭 No device config found in preferences');
        return null;
      }

      final configMap = jsonDecode(jsonString) as Map<String, dynamic>;
      final config = ConfigModel.fromMap(configMap);
      print('📖 Device config loaded: ${config.summary}');
      return config;
    } catch (e, stackTrace) {
      print('❌ Error reading device config from preferences: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  Future<bool> hasDeviceConfig() async {
    try {
      await _ensureInitialized();
      final hasConfig = _prefs!.containsKey(_deviceConfigKey);
      print('🔍 Device config exists: $hasConfig');
      return hasConfig;
    } catch (e) {
      print('❌ Error checking device config: $e');
      return false;
    }
  }

  Future<bool> clearDeviceConfig() async {
    try {
      await _ensureInitialized();
      final success = await _prefs!.remove(_deviceConfigKey);
      if (success) {
        print('🗑️ Device config cleared from preferences');
      } else {
        print('❌ Failed to clear device config');
      }
      return success;
    } catch (e) {
      print('❌ Error clearing device config: $e');
      return false;
    }
  }

  // ============ DEFAULT ANIMATIONS METHODS ============

  Future<bool> saveDefaultAnimations(List<AnimationModel> defaultAnimations) async {
    try {
      await _ensureInitialized();

      final animationsData = defaultAnimations.map((anim) => anim.toMap()).toList();
      final jsonString = jsonEncode(animationsData);
      final success = await _prefs!.setString(_defaultAnimationsKey, jsonString);

      if (success) {
        print('💾 Default animations saved (${defaultAnimations.length} animations)');
      } else {
        print('❌ Failed to save default animations');
      }
      return success;
    } catch (e, stackTrace) {
      print('❌ Error saving default animations: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  Future<List<AnimationModel>> getDefaultAnimations() async {
    try {
      await _ensureInitialized();

      final jsonString = _prefs!.getString(_defaultAnimationsKey);
      if (jsonString == null) {
        print('📭 No default animations found');
        return [];
      }

      final animationsList = jsonDecode(jsonString) as List<dynamic>;

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
              print('❌ Error parsing default animation: $e');
              return null;
            }
          })
          .where((animation) => animation != null)
          .cast<AnimationModel>()
          .toList();

      print('📖 Loaded ${animations.length} default animations');
      return animations;
    } catch (e, stackTrace) {
      print('❌ Error reading default animations: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  // Check if animation is default
  Future<bool> isDefaultAnimation(String animationName) async {
    try {
      final defaultAnimations = await getDefaultAnimations();
      final isDefault = defaultAnimations.any((anim) => anim.name == animationName);
      print('🔍 Animation "$animationName" is default: $isDefault');
      return isDefault;
    } catch (e) {
      print('❌ Error checking if animation is default: $e');
      return false;
    }
  }

  // ============ SELECTED ANIMATIONS METHODS ============

  List<Map<String, dynamic>> getSelectedAnimations() {
    try {
      if (_prefs == null) {
        print('⚠️ PreferencesService not initialized, returning empty list');
        return [];
      }
      
      final data = _prefs!.getStringList(_selectedAnimationsKey) ?? [];
      final animations = data
          .map((jsonStr) {
            try {
              return Map<String, dynamic>.from(jsonDecode(jsonStr));
            } catch (e) {
              print('❌ Error parsing selected animation: $e');
              return <String, dynamic>{};
            }
          })
          .where((map) => map.isNotEmpty)
          .toList();

      print('📖 Loaded ${animations.length} selected animations');
      return animations;
    } catch (e, stackTrace) {
      print('❌ Error getting selected animations: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  Future<void> saveSelectedAnimations(List<Map<String, dynamic>> animations) async {
    try {
      await _ensureInitialized();
      final jsonList = animations.map((map) => jsonEncode(map)).toList();
      await _prefs!.setStringList(_selectedAnimationsKey, jsonList);
      print('💾 Selected animations saved (${animations.length} animations)');
    } catch (e, stackTrace) {
      print('❌ Error saving selected animations: $e');
      print('Stack trace: $stackTrace');
    }
  }

  // ============ USER SELECTED DATA METHODS ============

  Future<bool> saveUserSelectedAnimations(List<AnimationModel> selectedAnimations) async {
    try {
      await _ensureInitialized();

      final animationsData = selectedAnimations.map((anim) => anim.toMap()).toList();
      final jsonString = jsonEncode(animationsData);
      final success = await _prefs!.setString(_userKey(_selectedAnimationsKey), jsonString);

      if (success) {
        print('💾 User selected animations saved (${selectedAnimations.length} animations)');
      } else {
        print('❌ Failed to save user selected animations');
      }
      return success;
    } catch (e, stackTrace) {
      print('❌ Error saving user selected animations: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  Future<List<AnimationModel>> getUserSelectedAnimations() async {
    try {
      await _ensureInitialized();

      final jsonString = _prefs!.getString(_userKey(_selectedAnimationsKey));
      if (jsonString == null) {
        print('📭 No user selected animations found');
        return [];
      }

      final animationsList = jsonDecode(jsonString) as List<dynamic>;

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
              print('❌ Error parsing user selected animation: $e');
              return null;
            }
          })
          .where((animation) => animation != null)
          .cast<AnimationModel>()
          .toList();

      print('📖 Loaded ${animations.length} user selected animations');
      return animations;
    } catch (e, stackTrace) {
      print('❌ Error reading user selected animations: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  Future<bool> addUserSelectedAnimation(AnimationModel animation) async {
    try {
      final currentSelections = await getUserSelectedAnimations();

      if (currentSelections.any((anim) => anim.name == animation.name)) {
        print('⚠️ Animation ${animation.name} already in selections');
        return true;
      }

      final newSelections = [...currentSelections, animation];
      return await saveUserSelectedAnimations(newSelections);
    } catch (e) {
      print('❌ Error adding user selected animation: $e');
      return false;
    }
  }

  Future<bool> removeUserSelectedAnimation(String animationName) async {
    try {
      final currentSelections = await getUserSelectedAnimations();
      final newSelections = currentSelections.where((anim) => anim.name != animationName).toList();
      return await saveUserSelectedAnimations(newSelections);
    } catch (e) {
      print('❌ Error removing user selected animation: $e');
      return false;
    }
  }

  Future<bool> clearUserSelectedAnimations() async {
    try {
      await _ensureInitialized();
      final success = await _prefs!.remove(_userKey(_selectedAnimationsKey));
      if (success) {
        print('🗑️ User selected animations cleared');
      } else {
        print('❌ Failed to clear user selected animations');
      }
      return success;
    } catch (e) {
      print('❌ Error clearing user selected animations: $e');
      return false;
    }
  }

  // ============ USER SETTINGS METHODS ============

  Future<bool> saveUserSetting(String settingName, dynamic value) async {
    try {
      await _ensureInitialized();
      final jsonString = jsonEncode(value);
      final success = await _prefs!.setString(_settingsKey(settingName), jsonString);
      
      if (success) {
        print('💾 User setting "$settingName" saved: $value');
      } else {
        print('❌ Failed to save user setting "$settingName"');
      }
      return success;
    } catch (e, stackTrace) {
      print('❌ Error saving user setting $settingName: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  Future<dynamic> getUserSetting(String settingName) async {
    try {
      await _ensureInitialized();
      final jsonString = _prefs!.getString(_settingsKey(settingName));
      if (jsonString == null) {
        print('📭 User setting "$settingName" not found');
        return null;
      }

      final value = jsonDecode(jsonString);
      print('📖 User setting "$settingName" loaded: $value');
      return value;
    } catch (e, stackTrace) {
      print('❌ Error reading user setting $settingName: $e');
      print('Stack trace: $stackTrace');
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

  // ============ API DATA METHODS ============

  Future<bool> saveApiSystemData(SystemModel systemData) async {
    try {
      await _ensureInitialized();

      final jsonString = jsonEncode(systemData.toJson());
      final success = await _prefs!.setString(_apiKey(_systemDataKey), jsonString);

      if (success) {
        await _updateLastSync();
        print('💾 API System data saved to preferences');
      } else {
        print('❌ Failed to save API system data');
      }
      return success;
    } catch (e, stackTrace) {
      print('❌ Error saving API system data to preferences: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  Future<SystemModel?> getApiSystemData() async {
    try {
      await _ensureInitialized();

      final jsonString = _prefs!.getString(_apiKey(_systemDataKey));
      if (jsonString == null) {
        print('📭 No API system data found');
        return null;
      }

      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return SystemModel.fromJson(jsonMap);
    } catch (e, stackTrace) {
      print('❌ Error reading API system data from preferences: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  Future<bool> saveApiUserAnimations(ListAnimationModel animations) async {
    try {
      await _ensureInitialized();

      final animationsData = {
        'source': animations.source,
        'lastSync': animations.lastSync.toIso8601String(),
        'animations': animations.animations.map((anim) => anim.toMap()).toList(),
      };

      final jsonString = jsonEncode(animationsData);
      final success = await _prefs!.setString(_apiKey(_userAnimationsKey), jsonString);

      if (success) {
        await _updateLastSync();
        print('💾 API User animations saved to preferences (${animations.length} animations)');
      } else {
        print('❌ Failed to save API user animations');
      }
      return success;
    } catch (e, stackTrace) {
      print('❌ Error saving API user animations to preferences: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  Future<ListAnimationModel?> getApiUserAnimations() async {
    try {
      await _ensureInitialized();

      final jsonString = _prefs!.getString(_apiKey(_userAnimationsKey));
      if (jsonString == null) {
        print('📭 No API user animations found');
        return null;
      }

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
    } catch (e, stackTrace) {
      print('❌ Error reading API user animations from preferences: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  // ============ CACHE MANAGEMENT ============

  Future<bool> isApiCacheValid() async {
    try {
      await _ensureInitialized();

      final lastSync = await getLastSync();
      if (lastSync == null) {
        print('📭 No last sync time found');
        return false;
      }

      final now = DateTime.now();
      final isValid = now.difference(lastSync) < cacheDuration;
      print('🔍 API cache valid: $isValid (last sync: $lastSync)');
      return isValid;
    } catch (e) {
      print('❌ Error checking API cache validity: $e');
      return false;
    }
  }

  Future<DateTime?> getLastSync() async {
    try {
      await _ensureInitialized();

      final lastSyncString = _prefs!.getString(_lastSyncKey);
      if (lastSyncString == null) {
        return null;
      }

      return DateTime.parse(lastSyncString);
    } catch (e) {
      print('❌ Error reading last sync time: $e');
      return null;
    }
  }

  Future<void> _updateLastSync() async {
    try {
      await _ensureInitialized();
      await _prefs!.setString(_lastSyncKey, DateTime.now().toIso8601String());
      print('🕒 Last sync time updated');
    } catch (e) {
      print('❌ Error updating last sync time: $e');
    }
  }

  // ============ CLEAR METHODS ============

  Future<void> clearApiCache() async {
    try {
      await _ensureInitialized();

      await _prefs!.remove(_apiKey(_systemDataKey));
      await _prefs!.remove(_apiKey(_userAnimationsKey));
      await _prefs!.remove(_lastSyncKey);

      print('🗑️ API cache cleared');
    } catch (e) {
      print('❌ Error clearing API cache: $e');
    }
  }

  Future<void> clearUserData() async {
    try {
      await _ensureInitialized();

      await _prefs!.remove(_userKey(_selectedAnimationsKey));

      final keys = _prefs!.getKeys().where((key) => key.startsWith('settings_')).toList();
      for (final key in keys) {
        await _prefs!.remove(key);
      }

      print('🗑️ User data cleared (${keys.length} settings removed)');
    } catch (e) {
      print('❌ Error clearing user data: $e');
    }
  }

  Future<void> clearAll() async {
    try {
      await _ensureInitialized();
      await _prefs!.clear();
      print('🗑️ All preferences cleared');
    } catch (e) {
      print('❌ Error clearing all preferences: $e');
    }
  }

  // ============ STATISTICS ============

  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      await _ensureInitialized();

      final apiSystemData = await getApiSystemData();
      final apiUserAnimations = await getApiUserAnimations();
      final userSelectedAnimations = await getUserSelectedAnimations();
      final lastSync = await getLastSync();
      final cacheValid = await isApiCacheValid();

      final stats = {
        'api_system_data': apiSystemData != null,
        'api_user_animations_count': apiUserAnimations?.length ?? 0,
        'user_selected_animations_count': userSelectedAnimations.length,
        'last_sync': lastSync?.toLocal().toString() ?? 'Never',
        'api_cache_valid': cacheValid,
        'total_storage_keys': _prefs!.getKeys().length,
      };

      print('📊 Cache statistics: $stats');
      return stats;
    } catch (e) {
      print('❌ Error getting cache statistics: $e');
      return {
        'error': e.toString(),
        'total_storage_keys': 0,
      };
    }
  }

  // Get all stored keys (untuk debug)
  Set<String> getAllKeys() {
    if (_prefs == null) {
      print('⚠️ PreferencesService not initialized, returning empty keys');
      return {};
    }
    return _prefs!.getKeys();
  }

  // Test method untuk verifikasi initialization
  Future<bool> testConnection() async {
    try {
      await _ensureInitialized();
      final testKey = '_test_connection_';
      final testValue = 'test_${DateTime.now().millisecondsSinceEpoch}';
      
      final saveSuccess = await _prefs!.setString(testKey, testValue);
      final readValue = _prefs!.getString(testKey);
      final readSuccess = readValue == testValue;
      
      await _prefs!.remove(testKey);
      
      print('🧪 PreferencesService test: ${saveSuccess && readSuccess ? 'PASSED' : 'FAILED'}');
      return saveSuccess && readSuccess;
    } catch (e) {
      print('❌ PreferencesService test failed: $e');
      return false;
    }
  }

  // Config Show Methods
Future<bool> saveConfigShow(ConfigShowModel configShow) async {
  try {
    await _ensureInitialized();
    
    final configShowMap = configShow.toMap();
    final jsonString = jsonEncode(configShowMap);
    final success = await _prefs!.setString(_configShowKey, jsonString);

    if (success) {
      print('💾 ConfigShow saved to preferences');
      print('📊 ConfigShow summary: ${configShow.summary}');
    } else {
      print('❌ Failed to save config show');
    }
    return success;
  } catch (e, stackTrace) {
    print('❌ Error saving config show to preferences: $e');
    print('Stack trace: $stackTrace');
    return false;
  }
}

Future<ConfigShowModel?> getConfigShow() async {
  try {
    await _ensureInitialized();
    
    final jsonString = _prefs!.getString(_configShowKey);
    if (jsonString == null) {
      print('📭 No config show found in preferences');
      return null;
    }

    final configShowMap = jsonDecode(jsonString) as Map<String, dynamic>;
    final configShow = ConfigShowModel.fromMap(configShowMap);
    print('📖 ConfigShow loaded: ${configShow.summary}');
    return configShow;
  } catch (e, stackTrace) {
    print('❌ Error reading config show from preferences: $e');
    print('Stack trace: $stackTrace');
    return null;
  }
}

Future<bool> hasConfigShow() async {
  try {
    await _ensureInitialized();
    final hasConfigShow = _prefs!.containsKey(_configShowKey);
    print('🔍 ConfigShow exists: $hasConfigShow');
    return hasConfigShow;
  } catch (e) {
    print('❌ Error checking config show: $e');
    return false;
  }
}

Future<bool> clearConfigShow() async {
  try {
    await _ensureInitialized();
    final success = await _prefs!.remove(_configShowKey);
    if (success) {
      print('🗑️ ConfigShow cleared from preferences');
    } else {
      print('❌ Failed to clear config show');
    }
    return success;
  } catch (e) {
    print('❌ Error clearing config show: $e');
    return false;
  }
}
}