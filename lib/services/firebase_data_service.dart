  import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:iTen/models/animation_model.dart';
import 'package:iTen/models/list_animation_model.dart';
import 'package:iTen/models/system_model.dart';
import 'package:iTen/services/connectivity_service.dart';
import 'package:iTen/services/preferences_service.dart';

  enum FirebaseNode {
    USER,
    SYSTEM
  }

  class FirebaseDataService {
    static final FirebaseDataService _instance = FirebaseDataService._internal();
    factory FirebaseDataService() => _instance;
    final PreferencesService _prefsService = PreferencesService();
  final ConnectivityService _connectivityService = ConnectivityService();

    FirebaseDataService._internal();

    static const String _databaseURL = "https://mano-database-ba7bb-default-rtdb.firebaseio.com/";
    
    late Dio _dio;
    bool _isInitialized = false;

    void initialize() {
      print('🔄 Initializing FirebaseDataService...');
      _dio = Dio(
        BaseOptions(
          baseUrl: _databaseURL,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      // Interceptor untuk logging
      _dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          print('🔥 Firebase Request: ${options.method} ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('✅ Firebase Response: ${response.statusCode}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          print('❌ Firebase Error: ${e.message}');
          return handler.next(e);
        },
      ));
      
      _isInitialized = true;
      print('✅ FirebaseDataService initialized successfully');
    }
  Future<void> clearCache() async {
      try {
        await _prefsService.clearApiCache();
        print('🗑️ FirebaseDataService cache cleared');
      } catch (e) {
        print('❌ Error clearing cache: $e');
      }
    }
    // Helper method untuk mendapatkan path node
    String _getNodePath(FirebaseNode node, [String? subPath]) {
      final nodePath = node.name;
      if (subPath != null && subPath.isNotEmpty) {
        return '$nodePath/$subPath';
      }
      return nodePath;
    }
 Future<bool> checkAnimationExists(AnimationModel animation) async {
  try {
    final config = await _prefsService.getDeviceConfig();
    String email = config?.email ?? 'CC';
    
    // Format yang sama dengan yang akan disimpan
    String expectedIdentifier = '${animation.channelCount.toString().padLeft(3, '0')} ${animation.name} $email';
    
    print('🔍 Checking duplicate for identifier: $expectedIdentifier');

    // Get all user animations dari Firebase (bukan dari cache)
    final response = await _dio.get('USER.json');
    
    if (response.statusCode == 200 && response.data != null) {
      final data = response.data as Map<String, dynamic>;
      
      // Cek setiap entry di Firebase
      for (final entry in data.entries) {
        final animationData = entry.value;
        if (animationData is Map && animationData['identifier'] == expectedIdentifier) {
          print('⚠️ Duplicate found: $expectedIdentifier');
          return true;
        }
      }
    }
    
    print('✅ No duplicate found for: $expectedIdentifier');
    return false;
  } catch (e) {
    print('❌ Error checking animation existence: $e');
    return false; // Jika error, anggap tidak ada duplikasi (biarkan proses continue)
  }
}
 Future<bool> get _shouldFetchFromFirebase async {
    final isConnected = await _connectivityService.isConnected;
    if (!isConnected) {
      print('🌐 No internet connection - using local data');
      return false;
    }
    
    // Optional: Tambahkan logika cache validation di sini
    final isCacheValid = await _prefsService.isApiCacheValid();
    if (isCacheValid) {
      print('📂 Cache is valid - considering using local data');
      // Bisa return false jika ingin selalu gunakan cache ketika ada koneksi
    }
    
    return true;
  }
 Future<bool> saveLocalAnimationToCloud(AnimationModel animation) async {
    try {
      if (!_isInitialized) {
        throw Exception('Service not initialized. Call initialize() first.');
      }

      // CEK KONEKSI DULU - jika offline, throw error
      final isConnected = await _connectivityService.isConnected;
      if (!isConnected) {
        throw Exception('No internet connection - cannot save to cloud');
      }


    // Ambil config dari preferences untuk mendapatkan email
    final config = await _prefsService.getDeviceConfig();
    
    // Gunakan email dari config jika ada, jika kosong gunakan "CC"
    String email = config?.email ?? 'CC';
    if (email.isEmpty) {
      email = 'CC';
    }

    // Format key: [channel] [nama animasi] [email]
    String channelPart = animation.channelCount.toString().padLeft(3, '0');
    String key = '$channelPart ${animation.name} $email';

    print('💾 Checking duplicate for: $key');
    print('📧 Using email: $email');

    // ✅ CEK DUPLIKASI DULU
    final isDuplicate = await checkAnimationExists(animation);
    if (isDuplicate) {
      print('❌ Animation already exists in cloud: $key');
      throw Exception('Animation "$key" already exists in cloud storage');
    }

    print('✅ No duplicate found, proceeding with save...');

    // Prepare data dalam format yang sesuai dengan struktur Firebase
    Map<String, dynamic> firebaseData = {
      'identifier': key, // Simpan identifier sebagai field
      'channel': animation.channelCount.toString(),
      'name': animation.name,
      'email': email,
      'animationLength': animation.animationLength,
      'description': animation.description.isEmpty ? '' : animation.description,
      'delayData': animation.delayData,
      'frameData': animation.frameData,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'isDefault': false,
      'source': 'user_upload',
    };

    print('📊 Data prepared with ${animation.frameData.length} frames');

    // ✅ GUNAKAN POST (STORE) - Firebase auto-generate key
    final response = await _dio.post(
      'USER.json',
      data: jsonEncode(firebaseData),
    );

    if (response.statusCode == 200) {
      final generatedKey = response.data['name']; // Key yang di-generate Firebase
      print('✅ Animation saved to cloud with Firebase key: $generatedKey');
      print('📝 Stored with identifier: $key');
      return true;
    }
    
    return false;
  } on DioException catch (e) {
    print('❌ Error saving animation to cloud: $e');
    
    // Log detail error
    if (e.response != null) {
      print('🔍 Error response: ${e.response?.data}');
      print('🔍 Error status: ${e.response?.statusCode}');
    }
    
    throw _handleError(e);
  } catch (e) {
    print('❌ Unexpected error saving to cloud: $e');
    rethrow;
  }
}
// Method untuk mendapatkan email yang akan digunakan
Future<String> getCloudEmail() async {
  final config = await _prefsService.getDeviceConfig();
  String email = config?.email ?? 'CC';
  if (email.isEmpty) {
    email = 'CC';
  }
  return email;
}
Future<Map<String, String>> saveMultipleAnimationsToCloud(
  List<AnimationModel> animations,
) async {
  final results = <String, String>{};
  
  for (final animation in animations) {
    try {
      print('\n🔄 Processing: ${animation.name}');
      
      final success = await saveLocalAnimationToCloud(animation);
      
      if (success) {
        results[animation.name] = 'success';
        print('✅ Successfully saved: ${animation.name}');
      } else {
        results[animation.name] = 'failed';
        print('❌ Failed to save: ${animation.name}');
      }
    } catch (e) {
      // Tangani error duplikasi khusus
      if (e.toString().contains('already exists')) {
        results[animation.name] = 'duplicate';
        print('⚠️ Duplicate skipped: ${animation.name}');
      } else {
        results[animation.name] = 'error';
        print('❌ Error saving ${animation.name}: $e');
      }
    }
  }
  
  print('\n📊 Final results:');
  results.forEach((name, status) {
    print('   - $name: $status');
  });
  
  return results;
}

// Method untuk mendapatkan email dari config
Future<String?> getDeviceEmail() async {
  final config = await _prefsService.getDeviceConfig();
  return config?.email;
}

// Method untuk mengecek apakah device sudah dikonfigurasi
Future<bool> isDeviceConfigured() async {
  final config = await _prefsService.getDeviceConfig();
  return config != null && config.email.isNotEmpty;
}
   Future<ListAnimationModel> getUserAnimationsWithCache() async {
    try {
      // Cek cache dulu tanpa peduli koneksi
      final cachedData = await _prefsService.getApiUserAnimations();
      
      // Cek apakah harus fetch dari Firebase
      final shouldFetch = await _shouldFetchFromFirebase;
      
      if (!shouldFetch) {
        if (cachedData != null && cachedData.isNotEmpty) {
          print('📂 Using cached user animations (offline mode)');
          return cachedData;
        } else {
          print('📂 No cached data available offline');
          return ListAnimationModel.empty('USER');
        }
      }
      
      // Jika ada koneksi, fetch dari Firebase
      print('🌐 Fetching user animations from Firebase...');
      final freshData = await getUserAnimations();
      
      return freshData;
    } catch (e) {
      print('❌ Error in getUserAnimationsWithCache: $e');
      
      // Fallback ke cache
      final cachedData = await _prefsService.getApiUserAnimations();
      if (cachedData != null && cachedData.isNotEmpty) {
        print('🔄 Using cache as fallback due to error');
        return cachedData;
      }
      
      return ListAnimationModel.empty('USER');
    }
  }


    // Add to user selections
    Future<bool> addToUserSelections(AnimationModel animation) async {
      return await _prefsService.addUserSelectedAnimation(animation);
    }

    // Force refresh API data
    Future<void> forceRefreshApiData() async {
      print('🔄 Force refreshing API data from Firebase...');
      
      // Clear API cache
      await _prefsService.clearApiCache();
      
      // Fetch fresh data
      final freshAnimations = await getUserAnimations();
      
      // Save to API cache
      if (freshAnimations.isNotEmpty) {
        await _prefsService.saveApiUserAnimations(freshAnimations);
      }
      
      print('✅ API force refresh completed');
    }
    // GET data spesifik dari node dengan sub-path + AUTO SAVE ke preferences
     Future<dynamic> getData(FirebaseNode node, String subPath) async {
    try {
      if (!_isInitialized) {
        throw Exception('Service not initialized. Call initialize() first.');
      }
      
      // Cek koneksi dulu
      final shouldFetch = await _shouldFetchFromFirebase;
      if (!shouldFetch) {
        print('📂 Offline mode - returning null for getData');
        return null;
      }
      
      final path = _getNodePath(node, subPath);
      final response = await _dio.get('$path.json');
      
      if (response.statusCode == 200) {
        final data = response.data;
        
        // AUTO SAVE ke preferences berdasarkan node type
        await _autoSaveToPreferences(node, subPath, data);
        
        return data;
      }
      return null;
    } on DioException catch (e) {
      print('❌ Error getting data from ${node.name}/$subPath: $e');
      
      // Fallback ke cache untuk error koneksi
      if (e.type == DioExceptionType.connectionError || 
          e.type == DioExceptionType.connectionTimeout) {
        print('📂 Connection error - falling back to cache');
        return await _getCachedData(node, subPath);
      }
      
      throw _handleError(e);
    }
  }
   Future<dynamic> _getCachedData(FirebaseNode node, String subPath) async {
    switch (node) {
      case FirebaseNode.SYSTEM:
        final systemData = await _prefsService.getApiSystemData();
        return systemData?.toJson();
      
      case FirebaseNode.USER:
        if (subPath.isEmpty) {
          final userAnimations = await _prefsService.getApiUserAnimations();
          return userAnimations?.toFirebaseMap();
        } else {
          // Untuk subPath spesifik, cari di cached animations
          final userAnimations = await _prefsService.getApiUserAnimations();
          final animation = userAnimations?.animations
              .firstWhere((anim) => anim.name == subPath);
          return animation?.toList();
        }
    }
  }

    // Method untuk auto save ke preferences berdasarkan node
    Future<void> _autoSaveToPreferences(FirebaseNode node, String subPath, dynamic data) async {
      try {
        switch (node) {
          case FirebaseNode.SYSTEM:
            await _handleSystemData(data);
            break;
          
          case FirebaseNode.USER:
            await _handleUserData(subPath, data);
            break;
        }
      } catch (e) {
        print('❌ Error auto-saving to preferences: $e');
      }
    }

    // Handle SYSTEM data - simpan deskripsi dan system info
    Future<void> _handleSystemData(dynamic data) async {
      if (data is Map<String, dynamic>) {
        try {
          final systemModel = SystemModel.fromJson(data);
          await _prefsService.saveApiSystemData(systemModel);
          print('💾 Auto-saved SYSTEM data to preferences');
          print('   - Info: ${systemModel.info}');
          print('   - Version: ${systemModel.version}');
          print('   - Deskripsi: ${systemModel.deskripsi}');
        } catch (e) {
          print('❌ Error parsing SYSTEM data: $e');
        }
      }
    }

    // Handle USER data - simpan animasi
    // Handle USER data - simpan animasi
  Future<void> _handleUserData(String subPath, dynamic data) async {
    print('🔍 DEBUG _handleUserData:');
    print('   - subPath: $subPath');
    print('   - data type: ${data.runtimeType}');
    print('   - data: $data');
    
    // Jika subPath kosong (root user node), berarti semua animasi
    if (subPath.isEmpty && data is Map<String, dynamic>) {
      try {
        print('🔍 Parsing USER animations map...');
        print('   - Map keys: ${data.keys}');
        print('   - Map length: ${data.length}');
        
        // Debug: print first item untuk melihat struktur
        if (data.isNotEmpty) {
          final firstKey = data.keys.first;
          final firstValue = data[firstKey];
          print('   - First key: $firstKey');
          print('   - First value type: ${firstValue.runtimeType}');
          print('   - First value: $firstValue');
        }
        
        final animationList = ListAnimationModel.fromFirebaseData('USER', data);
        await _prefsService.saveApiUserAnimations(animationList);
        print('💾 Auto-saved USER animations to preferences');
        print('   - Total animations: ${animationList.length}');
        print('   - Valid animations: ${animationList.validCount}');
        print('   - Total frames: ${animationList.totalFrames}');
      } catch (e) {
        print('❌ Error parsing USER animations: $e');
        print('❌ Stack trace: ${e.toString()}');
      }
    }
    // Jika subPath ada (spesifik animasi), simpan sebagai user selection
    else if (subPath.isNotEmpty && data is List) {
      try {
        print('🔍 Parsing single animation...');
        final animation = AnimationModel.fromList(subPath, data);
        await _prefsService.addUserSelectedAnimation(animation);
        print('💾 Auto-saved user selected animation to preferences');
        print('   - Name: ${animation.name}');
        print('   - Channels: ${animation.channelCount}');
        print('   - Frames: ${animation.totalFrames}');
      } catch (e) {
        print('❌ Error parsing user selected animation: $e');
        print('❌ Stack trace: ${e.toString()}');
      }
    } else {
      print('❌ Unexpected data format for USER node');
      print('   - Expected: Map for root, List for subPath');
      print('   - Actual: ${data.runtimeType} for subPath: $subPath');
    }
  }
  // Di FirebaseDataService class

  // Get user selected animations dari preferences
  Future<List<AnimationModel>> getUserSelectedAnimations() async {
    return await _prefsService.getUserSelectedAnimations();
  }
  // Di FirebaseDataService class

  // Save user setting
  Future<bool> saveUserSetting(String settingName, dynamic value) async {
    return await _prefsService.saveUserSetting(settingName, value);
  }

  // Get user setting
  Future<dynamic> getUserSetting(String settingName) async {
    return await _prefsService.getUserSetting(settingName);
  }
  // Remove animation dari user selections
  Future<bool> removeUserSelectedAnimation(String animationName) async {
    return await _prefsService.removeUserSelectedAnimation(animationName);
  }

  // Clear all user selections
  Future<bool> clearUserSelectedAnimations() async {
    return await _prefsService.clearUserSelectedAnimations();
  }
    // ============ ENHANCED METHODS dengan Auto-Save ============

    // GET semua data dari node + AUTO SAVE
    Future<Map<String, dynamic>?> getAllData(FirebaseNode node) async {
    try {
      if (!_isInitialized) {
        throw Exception('Service not initialized. Call initialize() first.');
      }
      
      // Cek koneksi dulu
      final shouldFetch = await _shouldFetchFromFirebase;
      if (!shouldFetch) {
        print('📂 Offline mode - returning cached data for ${node.name}');
        return await _getCachedData(node, '');
      }
      
      final path = _getNodePath(node);
      print('📥 Fetching all data from: $path');
      
      final response = await _dio.get('$path.json');
      
      if (response.statusCode == 200) {
        final data = response.data;
        
        if (data == null) {
          print('ℹ️ No data found in node: $path');
          return {};
        }
        
        // AUTO SAVE ke preferences
        await _autoSaveToPreferences(node, '', data);
        
        return data;
      }
      return null;
    } on DioException catch (e) {
      print('❌ Error getting all data from ${node.name}: $e');
      
      // Fallback ke cache untuk error koneksi
      if (e.type == DioExceptionType.connectionError || 
          e.type == DioExceptionType.connectionTimeout) {
        print('📂 Connection error - falling back to cache');
        return await _getCachedData(node, '');
      }
      
      throw _handleError(e);
    }
  }


    // ============ USER NODE METHODS dengan Auto-Save ============

    // Get ListAnimationModel dari USER node + AUTO SAVE
    Future<ListAnimationModel> getUserAnimations() async {
      try {
        final data = await getAllData(FirebaseNode.USER);
        if (data != null) {
          final animationList = ListAnimationModel.fromFirebaseData('USER', data);
          
          // Sudah auto-save di getAllData, tapi kita log saja
          print('💾 User animations already auto-saved to preferences');
          
          return animationList;
        }
        return ListAnimationModel.empty('USER');
      } catch (e) {
        print('Error getting USER animations: $e');
        return ListAnimationModel.empty('USER');
      }
    }

    // Get specific animation by name + AUTO SAVE sebagai user selection
    Future<AnimationModel?> getUserAnimation(String animationName) async {
      try {
        final data = await getData(FirebaseNode.USER, animationName);
        if (data is List) {
          final animation = AnimationModel.fromList(animationName, data);
          
          // Sudah auto-save di getData, tapi kita log saja
          print('💾 User animation selection already auto-saved');
          
          return animation;
        }
        return null;
      } catch (e) {
        print('Error getting USER animation $animationName: $e');
        return null;
      }
    }

    // ============ SYSTEM NODE METHODS dengan Auto-Save ============

    // Get System Data + AUTO SAVE
    Future<SystemModel?> getSystemModel() async {
      try {
        final data = await getAllData(FirebaseNode.SYSTEM);
        if (data != null) {
          final systemModel = SystemModel.fromJson(data);
          
          // Sudah auto-save di getAllData, tapi kita log saja
          print('💾 System data already auto-saved to preferences');
          
          return systemModel;
        }
        return null;
      } catch (e) {
        print('Error getting system model: $e');
        return null;
      }
    }

    // Get specific system configuration + AUTO SAVE
    Future<String?> getSystemConfigValue(String configKey) async {
      try {
        // Untuk config spesifik, kita ambil semua system data dulu
        final systemModel = await getSystemModel();
        if (systemModel != null) {
          // Auto-save sudah dilakukan di getSystemModel()
          switch (configKey) {
            case 'version':
              return systemModel.version;
            case 'version2':
              return systemModel.version2;
            case 'info':
              return systemModel.info;
            case 'deskripsi':
              return systemModel.deskripsi;
            case 'deskripsi2':
              return systemModel.deskripsi2;
            case 'link':
              return systemModel.link;
            case 'link2':
              return systemModel.link2;
            default:
              return null;
          }
        }
        return null;
      } catch (e) {
        print('Error getting system config: $e');
        return null;
      }
    }

    // ============ TEST FUNCTION untuk verifikasi ============

    // Test auto-save functionality
    Future<void> testAutoSaveFunctionality() async {
      try {
        print('🧪 Testing Auto-Save Functionality...');
        
        // 1. Test SYSTEM data auto-save
        print('\n📋 TEST 1: SYSTEM Data Auto-Save');
        final systemData = await getData(FirebaseNode.SYSTEM, '');
        print('✅ SYSTEM data fetched: ${systemData != null}');
        
        // Check if saved in preferences
        final cachedSystem = await _prefsService.getApiSystemData();
        print('✅ SYSTEM data auto-saved: ${cachedSystem != null}');
        if (cachedSystem != null) {
          print('   - Info: ${cachedSystem.info}');
          print('   - Deskripsi: ${cachedSystem.deskripsi}');
        }
        
        // 2. Test USER animations auto-save
        print('\n📋 TEST 2: USER Animations Auto-Save');
        final userData = await getData(FirebaseNode.USER, '');
        print('✅ USER data fetched: ${userData != null}');
        
        // Check if saved in preferences
        final cachedAnimations = await _prefsService.getApiUserAnimations();
        print('✅ USER animations auto-saved: ${cachedAnimations != null}');
        if (cachedAnimations != null) {
          print('   - Total animations: ${cachedAnimations.length}');
        }
        
        // 3. Test specific animation auto-save (as user selection)
        print('\n📋 TEST 3: Specific Animation Auto-Save');
        // Coba ambil animasi pertama jika ada
        if (cachedAnimations != null && cachedAnimations.isNotEmpty) {
          final firstAnimationName = cachedAnimations[0].name;
          final specificAnimation = await getData(FirebaseNode.USER, firstAnimationName);
          print('✅ Specific animation fetched: ${specificAnimation != null}');
          
          // Check if saved as user selection
          final userSelections = await _prefsService.getUserSelectedAnimations();
          final isSelected = userSelections.any((anim) => anim.name == firstAnimationName);
          print('✅ Animation auto-saved as user selection: $isSelected');
        }
        
        // 4. Show final cache status
        print('\n📋 TEST 4: Final Cache Status');
        final stats = await _prefsService.getCacheStats();
        stats.forEach((key, value) {
          print('   - $key: $value');
        });
        
        print('\n🎉 Auto-Save Test Completed!');
        
      } catch (e) {
        print('❌ Auto-Save Test Failed: $e');
      }
    }
    
    // POST data ke node (auto-generate ID)
    Future<String?> createData(FirebaseNode node, Map<String, dynamic> data, {String? subPath}) async {
      try {
        if (!_isInitialized) {
          throw Exception('Service not initialized. Call initialize() first.');
        }
        
        final path = _getNodePath(node, subPath);
        final response = await _dio.post(
          '$path.json',
          data: jsonEncode(data),
        );
        
        if (response.statusCode == 200) {
          return response.data['name'];
        }
        return null;
      } on DioException catch (e) {
        print('❌ Error creating data in ${node.name}: $e');
        throw _handleError(e);
      }
    }

    // PUT data (replace seluruh data di path)
    Future<bool> updateData(FirebaseNode node, String subPath, Map<String, dynamic> data) async {
      try {
        if (!_isInitialized) {
          throw Exception('Service not initialized. Call initialize() first.');
        }
        
        final path = _getNodePath(node, subPath);
        final response = await _dio.put(
          '$path.json',
          data: jsonEncode(data),
        );
        
        return response.statusCode == 200;
      } on DioException catch (e) {
        print('❌ Error updating data in ${node.name}/$subPath: $e');
        throw _handleError(e);
      }
    }

    // DELETE data
    Future<bool> deleteData(FirebaseNode node, String subPath) async {
      try {
        if (!_isInitialized) {
          throw Exception('Service not initialized. Call initialize() first.');
        }
        
        final path = _getNodePath(node, subPath);
        final response = await _dio.delete('$path.json');
        
        return response.statusCode == 200;
      } on DioException catch (e) {
        print('❌ Error deleting data from ${node.name}/$subPath: $e');
        throw _handleError(e);
      }
    }

    // ============ BATCH OPERATIONS ============

    // Multiple updates dalam satu request
    Future<bool> batchUpdate(Map<String, dynamic> updates) async {
      try {
        if (!_isInitialized) {
          throw Exception('Service not initialized. Call initialize() first.');
        }
        
        final response = await _dio.patch(
          '.json',
          data: jsonEncode(updates),
        );
        
        return response.statusCode == 200;
      } on DioException catch (e) {
        print('❌ Error in batch update: $e');
        throw _handleError(e);
      }
    }

    // ============ USER NODE METHODS (untuk Animasi) ============


    // Create new animation di USER
    Future<bool> createUserAnimation(AnimationModel animation) async {
      try {
        final updates = {
          animation.name: animation.toList(),
        };
        return await batchUpdate(updates);
      } catch (e) {
        print('Error creating USER animation: $e');
        return false;
      }
    }

    // Update existing animation di USER
    Future<bool> updateUserAnimation(AnimationModel animation) async {
      try {
        return await createUserAnimation(animation);
      } catch (e) {
        print('Error updating USER animation: $e');
        return false;
      }
    }

    // Delete animation dari USER
    Future<bool> deleteUserAnimation(String animationName) async {
      try {
        return await deleteData(FirebaseNode.USER, animationName);
      } catch (e) {
        print('Error deleting USER animation: $e');
        return false;
      }
    }

    // Get all animation names dari USER
    Future<List<String>> getUserAnimationNames() async {
      try {
        final collection = await getUserAnimations();
        return collection.names;
      } catch (e) {
        print('Error getting USER animation names: $e');
        return [];
      }
    }

    // Get animations by channel count dari USER
    Future<List<AnimationModel>> getUserAnimationsByChannel(int channelCount) async {
      try {
        final collection = await getUserAnimations();
        return collection.filterByChannel(channelCount).animations;
      } catch (e) {
        print('Error getting USER animations by channel: $e');
        return [];
      }
    }

    // Save ListAnimationModel ke USER
    Future<bool> saveUserAnimations(ListAnimationModel listModel) async {
      try {
        final updates = listModel.toFirebaseMap();
        return await batchUpdate(updates);
      } catch (e) {
        print('Error saving USER animations: $e');
        return false;
      }
    }


    // Update System Data dengan model
    Future<bool> updateSystemModel(SystemModel systemModel) async {
      try {
        return await updateData(
          FirebaseNode.SYSTEM,
          '', // root of SYSTEM node
          systemModel.toJson(),
        );
      } catch (e) {
        print('Error updating system model: $e');
        return false;
      }
    }

    // ============ UTILITY METHODS ============

    // Check jika data exists
    Future<bool> exists(FirebaseNode node, String subPath) async {
      try {
        final data = await getData(node, subPath);
        return data != null;
      } catch (e) {
        return false;
      }
    }

    Future<int> getCount(FirebaseNode node) async {
      try {
        final data = await getAllData(node);
        return data?.length ?? 0;
      } catch (e) {
        return 0;
      }
    }

    Future<bool> testConnection() async {
    try {
      print('🧪 Testing connectivity...');
      final isConnected = await _connectivityService.isConnected;
      
      if (!isConnected) {
        print('❌ No internet connection');
        return false;
      }

      print('🌐 Internet available, testing Firebase connection...');
      final response = await _dio.get('.json', 
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        )
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Connection test failed: $e');
      return false;
    }
  }

    // Error handling
    String _handleError(DioException error) {
      if (error.response != null) {
        final statusCode = error.response!.statusCode;
        final errorData = error.response!.data;
        
        switch (statusCode) {
          case 400:
            return 'Bad Request: $errorData';
          case 401:
            return 'Unauthorized - Check Firebase Rules';
          case 403:
            return 'Forbidden - Database rules may be blocking access';
          case 404:
            return 'Data not found';
          case 500:
            return 'Internal Server Error: $errorData';
          default:
            return 'Error $statusCode: $errorData';
        }
      } else {
        return 'Network error: ${error.message}';
      }
    }

    // Cleanup
    void dispose() {
      _dio.close();
      _isInitialized = false;
    }
  }