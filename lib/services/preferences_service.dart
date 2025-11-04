import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  static SharedPreferences? _preferences;

  // Initialize preferences
  Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();
  }

  // Check if preferences is initialized
  bool get isInitialized => _preferences != null;

  // ============ CRUD OPERATIONS ============

  // CREATE/UPDATE - Save data dengan key
  Future<bool> saveData(String key, dynamic value) async {
    if (!isInitialized) await initialize();

    try {
      if (value is String) {
        return await _preferences!.setString(key, value);
      } else if (value is int) {
        return await _preferences!.setInt(key, value);
      } else if (value is double) {
        return await _preferences!.setDouble(key, value);
      } else if (value is bool) {
        return await _preferences!.setBool(key, value);
      } else if (value is List<String>) {
        return await _preferences!.setStringList(key, value);
      } else if (value is Map || value is List) {
        // Untuk object dan list, convert ke JSON string
        return await _preferences!.setString(key, jsonEncode(value));
      } else {
        throw Exception('Unsupported data type for key: $key');
      }
    } catch (e) {
      print('Error saving data for key $key: $e');
      return false;
    }
  }

  // READ - Get data berdasarkan type
  dynamic getData(String key) {
    if (!isInitialized) {
      throw Exception('Preferences not initialized. Call initialize() first.');
    }

    return _preferences!.get(key);
  }

  String getString(String key, {String defaultValue = ''}) {
    if (!isInitialized) return defaultValue;
    return _preferences!.getString(key) ?? defaultValue;
  }

  int getInt(String key, {int defaultValue = 0}) {
    if (!isInitialized) return defaultValue;
    return _preferences!.getInt(key) ?? defaultValue;
  }

  double getDouble(String key, {double defaultValue = 0.0}) {
    if (!isInitialized) return defaultValue;
    return _preferences!.getDouble(key) ?? defaultValue;
  }

  bool getBool(String key, {bool defaultValue = false}) {
    if (!isInitialized) return defaultValue;
    return _preferences!.getBool(key) ?? defaultValue;
  }

  List<String> getStringList(String key, {List<String>? defaultValue}) {
    if (!isInitialized) return defaultValue ?? [];
    return _preferences!.getStringList(key) ?? defaultValue ?? [];
  }

  // Get JSON object (Map)
  Map<String, dynamic>? getJsonObject(String key) {
    if (!isInitialized) return null;
    
    final jsonString = _preferences!.getString(key);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        print('Error decoding JSON for key $key: $e');
        return null;
      }
    }
    return null;
  }

  // Get JSON array (List)
  List<dynamic>? getJsonArray(String key) {
    if (!isInitialized) return null;
    
    final jsonString = _preferences!.getString(key);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        return jsonDecode(jsonString) as List<dynamic>;
      } catch (e) {
        print('Error decoding JSON array for key $key: $e');
        return null;
      }
    }
    return null;
  }

  // DELETE - Remove data by key
  Future<bool> removeData(String key) async {
    if (!isInitialized) await initialize();
    
    try {
      return await _preferences!.remove(key);
    } catch (e) {
      print('Error removing data for key $key: $e');
      return false;
    }
  }

  // CHECK - Check if key exists
  bool containsKey(String key) {
    if (!isInitialized) return false;
    return _preferences!.containsKey(key);
  }

  // ============ BATCH OPERATIONS ============

  // Save multiple data sekaligus
  Future<bool> saveMultiple(Map<String, dynamic> data) async {
    if (!isInitialized) await initialize();

    try {
      bool allSuccess = true;
      for (final entry in data.entries) {
        final success = await saveData(entry.key, entry.value);
        if (!success) allSuccess = false;
      }
      return allSuccess;
    } catch (e) {
      print('Error saving multiple data: $e');
      return false;
    }
  }

  // Get multiple data
  Map<String, dynamic> getMultiple(List<String> keys) {
    if (!isInitialized) return {};

    final result = <String, dynamic>{};
    for (final key in keys) {
      if (_preferences!.containsKey(key)) {
        result[key] = _preferences!.get(key);
      }
    }
    return result;
  }

  // Remove multiple data
  Future<bool> removeMultiple(List<String> keys) async {
    if (!isInitialized) await initialize();

    try {
      bool allSuccess = true;
      for (final key in keys) {
        final success = await removeData(key);
        if (!success) allSuccess = false;
      }
      return allSuccess;
    } catch (e) {
      print('Error removing multiple data: $e');
      return false;
    }
  }

  // ============ SPECIFIC DATA TYPES ============

  // Save object dengan model conversion
  Future<bool> saveObject<T>(String key, T object, Map<String, dynamic> Function(T) toJson) async {
    try {
      final json = toJson(object);
      return await saveData(key, json);
    } catch (e) {
      print('Error saving object for key $key: $e');
      return false;
    }
  }

  // Get object dengan model conversion
  T? getObject<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    try {
      final json = getJsonObject(key);
      if (json != null) {
        return fromJson(json);
      }
      return null;
    } catch (e) {
      print('Error getting object for key $key: $e');
      return null;
    }
  }

  // Save list of objects
  Future<bool> saveObjectList<T>(String key, List<T> objects, Map<String, dynamic> Function(T) toJson) async {
    try {
      final jsonList = objects.map((obj) => toJson(obj)).toList();
      return await saveData(key, jsonList);
    } catch (e) {
      print('Error saving object list for key $key: $e');
      return false;
    }
  }

  // Get list of objects
  List<T> getObjectList<T>(String key, T Function(Map<String, dynamic>) fromJson, {List<T> defaultValue = const []}) {
    try {
      final jsonArray = getJsonArray(key);
      if (jsonArray != null) {
        return jsonArray.map((json) => fromJson(json as Map<String, dynamic>)).toList();
      }
      return defaultValue;
    } catch (e) {
      print('Error getting object list for key $key: $e');
      return defaultValue;
    }
  }

  // ============ UTILITY METHODS ============

  // Get all keys
  Set<String> getAllKeys() {
    if (!isInitialized) return {};
    return _preferences!.getKeys();
  }

  // Clear all data
  Future<bool> clearAll() async {
    if (!isInitialized) await initialize();
    
    try {
      return await _preferences!.clear();
    } catch (e) {
      print('Error clearing all data: $e');
      return false;
    }
  }

  // Get data size (estimated)
  int getDataSize() {
    if (!isInitialized) return 0;
    return _preferences!.getKeys().length;
  }

  // Backup all data to Map
  Map<String, dynamic> backupAllData() {
    if (!isInitialized) return {};
    
    final backup = <String, dynamic>{};
    for (final key in _preferences!.getKeys()) {
      backup[key] = _preferences!.get(key);
    }
    return backup;
  }

  // Restore from backup
  Future<bool> restoreFromBackup(Map<String, dynamic> backup) async {
    if (!isInitialized) await initialize();

    try {
      await clearAll();
      return await saveMultiple(backup);
    } catch (e) {
      print('Error restoring from backup: $e');
      return false;
    }
  }
}